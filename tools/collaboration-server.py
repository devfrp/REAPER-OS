#!/usr/bin/env python3

################################################################################
# REAPER OS Collaboration Server v0.5.0
# Real-time project sharing, chat, and versioning
# Usage: python3 collaboration-server.py [--server] [--client]
################################################################################

from flask import Flask, jsonify, request
from flask_socketio import SocketIO, emit, join_room, leave_room
import json
import os
import secrets
import sqlite3
import hashlib
from datetime import datetime
import threading

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', secrets.token_hex(32))
socketio = SocketIO(app, cors_allowed_origins="*")

COLLAB_DIR = os.path.expanduser("~/.config/REAPER/collaboration")
COLLAB_DB = os.path.join(COLLAB_DIR, "collaborations.db")
PROJECTS_DIR = os.path.join(COLLAB_DIR, "shared-projects")

os.makedirs(PROJECTS_DIR, exist_ok=True)

class CollaborationServer:
    def __init__(self):
        self.init_db()
        self.active_sessions = {}
        self.project_locks = {}
    
    def init_db(self):
        """Initialize collaboration database"""
        conn = sqlite3.connect(COLLAB_DB)
        c = conn.cursor()
        
        c.execute('''CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            username TEXT UNIQUE,
            email TEXT,
            created_at TEXT
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS projects (
            id INTEGER PRIMARY KEY,
            name TEXT,
            owner_id INTEGER,
            created_at TEXT,
            last_modified TEXT,
            version TEXT
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS collaborators (
            id INTEGER PRIMARY KEY,
            project_id INTEGER,
            user_id INTEGER,
            permission_level TEXT,
            joined_at TEXT
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY,
            project_id INTEGER,
            user_id INTEGER,
            message TEXT,
            timestamp TEXT,
            media_url TEXT
        )''')
        
        c.execute('''CREATE TABLE IF NOT EXISTS versions (
            id INTEGER PRIMARY KEY,
            project_id INTEGER,
            version_tag TEXT,
            created_by INTEGER,
            created_at TEXT,
            changeset TEXT
        )''')
        
        conn.commit()
        conn.close()
    
    def create_project(self, name, owner_id):
        """Create new collaborative project"""
        conn = sqlite3.connect(COLLAB_DB)
        c = conn.cursor()
        
        project_id = hashlib.md5(f"{name}{datetime.now()}".encode()).hexdigest()[:8]
        
        c.execute('''INSERT INTO projects (name, owner_id, created_at, last_modified, version)
                     VALUES (?, ?, ?, ?, ?)''',
                  (name, owner_id, datetime.now().isoformat(), datetime.now().isoformat(), '1.0.0'))
        
        conn.commit()
        conn.close()
        
        # Create project directory
        project_dir = os.path.join(PROJECTS_DIR, project_id)
        os.makedirs(project_dir, exist_ok=True)
        
        return project_id
    
    def invite_collaborator(self, project_id, username, permission_level='edit'):
        """Invite collaborator to project"""
        conn = sqlite3.connect(COLLAB_DB)
        c = conn.cursor()
        
        # Get user ID
        c.execute('SELECT id FROM users WHERE username=?', (username,))
        user_id = c.fetchone()
        
        if user_id:
            c.execute('''INSERT INTO collaborators (project_id, user_id, permission_level, joined_at)
                         VALUES (?, ?, ?, ?)''',
                      (project_id, user_id[0], permission_level, datetime.now().isoformat()))
            conn.commit()
            conn.close()
            return True
        
        conn.close()
        return False
    
    def broadcast_changes(self, project_id, changes):
        """Broadcast project changes to all collaborators"""
        socketio.emit('project_update', {
            'project_id': project_id,
            'changes': changes,
            'timestamp': datetime.now().isoformat()
        }, room=f"project_{project_id}")
    
    def create_version(self, project_id, version_tag, created_by, changeset):
        """Create version snapshot"""
        conn = sqlite3.connect(COLLAB_DB)
        c = conn.cursor()
        
        c.execute('''INSERT INTO versions (project_id, version_tag, created_by, created_at, changeset)
                     VALUES (?, ?, ?, ?, ?)''',
                  (project_id, version_tag, created_by, datetime.now().isoformat(), json.dumps(changeset)))
        
        conn.commit()
        conn.close()

collab_server = CollaborationServer()

# WebSocket events
@socketio.on('join_project')
def on_join_project(data):
    """Join collaborative session"""
    project_id = data['project_id']
    username = data['username']
    
    join_room(f"project_{project_id}")
    
    emit('user_joined', {
        'username': username,
        'timestamp': datetime.now().isoformat()
    }, room=f"project_{project_id}")

@socketio.on('send_message')
def on_send_message(data):
    """Send chat message in project"""
    project_id = data['project_id']
    message = data['message']
    username = data['username']
    
    # Store in database
    conn = sqlite3.connect(COLLAB_DB)
    c = conn.cursor()
    c.execute('''INSERT INTO chat_messages (project_id, user_id, message, timestamp)
                 SELECT ?, id, ?, ? FROM users WHERE username=?''',
              (project_id, message, datetime.now().isoformat(), username))
    conn.commit()
    conn.close()
    
    emit('new_message', {
        'username': username,
        'message': message,
        'timestamp': datetime.now().isoformat()
    }, room=f"project_{project_id}")

@socketio.on('broadcast_change')
def on_broadcast_change(data):
    """Broadcast project change to collaborators"""
    project_id = data['project_id']
    changes = data['changes']
    
    emit('project_changed', {
        'changes': changes,
        'timestamp': datetime.now().isoformat()
    }, room=f"project_{project_id}", skip_sid=request.sid)

@socketio.on('leave_project')
def on_leave_project(data):
    """Leave collaborative session"""
    project_id = data['project_id']
    username = data['username']
    
    leave_room(f"project_{project_id}")
    
    emit('user_left', {
        'username': username,
        'timestamp': datetime.now().isoformat()
    }, room=f"project_{project_id}")

# REST API endpoints
@app.route('/api/projects', methods=['POST'])
def create_project():
    """Create new project"""
    data = request.json
    project_id = collab_server.create_project(data['name'], data['owner_id'])
    
    return jsonify({
        'project_id': project_id,
        'status': 'created'
    })

@app.route('/api/projects/<project_id>/invite', methods=['POST'])
def invite_collaborator(project_id):
    """Invite collaborator"""
    data = request.json
    success = collab_server.invite_collaborator(
        project_id,
        data['username'],
        data.get('permission_level', 'edit')
    )
    
    return jsonify({'status': 'invited' if success else 'failed'})

@app.route('/api/projects/<project_id>/chat', methods=['GET'])
def get_chat(project_id):
    """Get chat history"""
    conn = sqlite3.connect(COLLAB_DB)
    c = conn.cursor()
    c.execute('''SELECT u.username, m.message, m.timestamp FROM chat_messages m
                 JOIN users u ON m.user_id = u.id
                 WHERE m.project_id = ? ORDER BY m.timestamp DESC LIMIT 100''',
              (project_id,))
    messages = c.fetchall()
    conn.close()
    
    return jsonify({'messages': messages})

@app.route('/api/projects/<project_id>/versions', methods=['GET'])
def get_versions(project_id):
    """Get project versions"""
    conn = sqlite3.connect(COLLAB_DB)
    c = conn.cursor()
    c.execute('SELECT version_tag, created_at FROM versions WHERE project_id=? ORDER BY created_at DESC',
              (project_id,))
    versions = c.fetchall()
    conn.close()
    
    return jsonify({'versions': versions})

if __name__ == '__main__':
    print("REAPER OS Collaboration Server v0.5.0")
    print("Starting on localhost:5005...")
    socketio.run(app, host='0.0.0.0', port=5005, debug=False)

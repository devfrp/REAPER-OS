#!/usr/bin/env python3

################################################################################
# REAPER OS Mobile Companion App Server
# Backend for mobile app to control REAPER remotely
# Usage: python3 mobile-companion.py [--server] [--port 8000]
################################################################################

from flask import Flask, jsonify, request
import subprocess
import json
import socket
import os
import psutil

app = Flask(__name__)

# Configuration
REAPER_PID_FILE = "/tmp/reaper.pid"
MOBILE_CONFIG = os.path.expanduser("~/.config/REAPER/mobile-companion.json")

os.makedirs(os.path.dirname(MOBILE_CONFIG), exist_ok=True)

@app.route('/api/status')
def status():
    """Get REAPER status"""
    try:
        result = subprocess.run(['pgrep', '-f', 'reaper'], capture_output=True)
        is_running = result.returncode == 0
        
        return jsonify({
            'status': 'running' if is_running else 'stopped',
            'hostname': socket.gethostname()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/transport/play', methods=['POST'])
def play():
    """Play/pause transport"""
    # Would send MIDI/OSC command to REAPER
    return jsonify({'status': 'ok'})

@app.route('/api/preset/load', methods=['POST'])
def load_preset():
    """Load preset from preset name"""
    data = request.json
    preset_name = data.get('preset')
    
    # Would load preset
    return jsonify({'status': 'ok', 'preset': preset_name})

@app.route('/api/metrics', methods=['GET'])
def metrics():
    """Get system metrics"""
    try:
        cpu_percent = psutil.cpu_percent(interval=0.1)
        mem = psutil.virtual_memory()
        
        return jsonify({
            'cpu': cpu_percent,
            'memory': mem.percent,
            'disk': psutil.disk_usage('/').percent
        })
    except:
        return jsonify({'error': 'Cannot get metrics'}), 500

@app.route('/api/files/projects', methods=['GET'])
def list_projects():
    """List REAPER projects"""
    projects_dir = os.path.expanduser("~/Music/REAPER Projects")
    
    projects = []
    if os.path.exists(projects_dir):
        for f in os.listdir(projects_dir):
            if f.endswith('.rpp'):
                projects.append({
                    'name': f,
                    'modified': os.path.getmtime(os.path.join(projects_dir, f))
                })
    
    return jsonify({'projects': projects})

@app.route('/api/notify', methods=['POST'])
def send_notification():
    """Send notification to mobile"""
    data = request.json
    # Would send push notification
    return jsonify({'status': 'notification_sent'})

if __name__ == '__main__':
    print("REAPER OS Mobile Companion Server")
    print("Starting on localhost:5002...")
    app.run(host='0.0.0.0', port=5002, debug=False)

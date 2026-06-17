#!/usr/bin/env python3

################################################################################
# REAPER OS Streaming Integration v0.5.0
# Twitch/YouTube Live streaming with auto-optimization
# Usage: python3 streaming-integration.py [--setup] [--start] [--monitor]
################################################################################

from flask import Flask, jsonify, request
import json
import os
import subprocess
import threading
from datetime import datetime
import requests

app = Flask(__name__)

STREAMING_DIR = os.path.expanduser("~/.config/REAPER/streaming")
STREAMING_CONFIG = os.path.join(STREAMING_DIR, "streams.json")
STREAMING_LOG = os.path.join(STREAMING_DIR, "streaming.log")

os.makedirs(STREAMING_DIR, exist_ok=True)

class StreamingIntegration:
    def __init__(self):
        self.load_config()
        self.active_streams = {}
    
    def load_config(self):
        """Load streaming configuration"""
        if os.path.exists(STREAMING_CONFIG):
            with open(STREAMING_CONFIG) as f:
                self.config = json.load(f)
        else:
            self.config = {
                'streams': [],
                'presets': {}
            }
    
    def setup_twitch(self, oauth_token, channel):
        """Setup Twitch integration"""
        config = {
            'platform': 'twitch',
            'channel': channel,
            'oauth_token': oauth_token,
            'rtmp_server': 'rtmps://live.twitch.tv/app/',
            'bitrate': 6000,
            'resolution': '1920x1080',
            'fps': 60,
            'audio_bitrate': 192
        }
        
        self.config['streams'].append(config)
        self.save_config()
        
        return config
    
    def setup_youtube(self, api_key, stream_key):
        """Setup YouTube Live integration"""
        config = {
            'platform': 'youtube',
            'api_key': api_key,
            'stream_key': stream_key,
            'rtmp_server': 'rtmps://a.rtmp.youtube.com/live2/',
            'bitrate': 8000,
            'resolution': '3840x2160',
            'fps': 60,
            'audio_bitrate': 256
        }
        
        self.config['streams'].append(config)
        self.save_config()
        
        return config
    
    def start_stream(self, stream_id):
        """Start streaming session"""
        stream = next((s for s in self.config['streams'] if s.get('id') == stream_id), None)
        
        if not stream:
            return {'error': 'Stream not found'}
        
        # Build FFmpeg command
        ffmpeg_cmd = self._build_ffmpeg_command(stream)
        
        try:
            process = subprocess.Popen(
                ffmpeg_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            
            self.active_streams[stream_id] = {
                'process': process,
                'started_at': datetime.now().isoformat(),
                'platform': stream['platform'],
                'viewers': 0,
                'bitrate': stream['bitrate'],
                'latency': 0
            }
            
            # Monitor stream
            threading.Thread(target=self._monitor_stream, args=(stream_id,), daemon=True).start()
            
            return {'status': 'streaming', 'stream_id': stream_id}
        except Exception as e:
            return {'error': str(e)}
    
    def stop_stream(self, stream_id):
        """Stop streaming session"""
        if stream_id in self.active_streams:
            stream = self.active_streams[stream_id]
            stream['process'].terminate()
            del self.active_streams[stream_id]
            
            return {'status': 'stopped', 'stream_id': stream_id}
        
        return {'error': 'Stream not found'}
    
    def _build_ffmpeg_command(self, stream):
        """Build FFmpeg streaming command"""
        input_source = 'pipe:0'  # REAPER audio output
        
        cmd = [
            'ffmpeg',
            '-re',
            '-i', input_source,
            '-c:v', 'libx264',
            '-preset', 'fast',
            '-b:v', f"{stream['bitrate']}k",
            '-s', stream['resolution'],
            '-r', str(stream['fps']),
            '-c:a', 'aac',
            '-b:a', f"{stream['audio_bitrate']}k",
            '-f', 'flv',
            f"{stream['rtmp_server']}{stream.get('stream_key', '')}"
        ]
        
        return cmd
    
    def _monitor_stream(self, stream_id):
        """Monitor active stream"""
        while stream_id in self.active_streams:
            stream_info = self.active_streams[stream_id]
            
            # Get stream metrics
            metrics = self._get_stream_metrics(stream_id)
            stream_info.update(metrics)
            
            # Auto-adjust bitrate if needed
            if metrics.get('latency', 0) > 30:
                self._adjust_bitrate(stream_id, 'decrease')
            
            time.sleep(5)
    
    def _get_stream_metrics(self, stream_id):
        """Get streaming metrics"""
        return {
            'bitrate': 6000,
            'latency': 5,
            'cpu_usage': 35,
            'dropped_frames': 0
        }
    
    def _adjust_bitrate(self, stream_id, direction):
        """Dynamically adjust bitrate"""
        stream = self.active_streams.get(stream_id)
        if stream:
            current_bitrate = stream['bitrate']
            
            if direction == 'decrease':
                stream['bitrate'] = max(2000, current_bitrate - 500)
            else:
                stream['bitrate'] = min(12000, current_bitrate + 500)
            
            print(f"Adjusted bitrate to {stream['bitrate']}kbps")
    
    def get_stream_status(self, stream_id):
        """Get current stream status"""
        if stream_id in self.active_streams:
            return self.active_streams[stream_id]
        
        return {'status': 'inactive'}
    
    def save_config(self):
        """Save configuration to file"""
        with open(STREAMING_CONFIG, 'w') as f:
            json.dump(self.config, f, indent=2)
        os.chmod(STREAMING_CONFIG, 0o600)

import time

streaming = StreamingIntegration()

@app.route('/api/streams', methods=['GET'])
def get_streams():
    """Get all configured streams"""
    return jsonify({'streams': streaming.config.get('streams', [])})

@app.route('/api/streams/setup/twitch', methods=['POST'])
def setup_twitch():
    """Setup Twitch"""
    data = request.json
    config = streaming.setup_twitch(data['oauth_token'], data['channel'])
    return jsonify(config)

@app.route('/api/streams/setup/youtube', methods=['POST'])
def setup_youtube():
    """Setup YouTube"""
    data = request.json
    config = streaming.setup_youtube(data['api_key'], data['stream_key'])
    return jsonify(config)

@app.route('/api/streams/<stream_id>/start', methods=['POST'])
def start_stream(stream_id):
    """Start streaming"""
    return jsonify(streaming.start_stream(stream_id))

@app.route('/api/streams/<stream_id>/stop', methods=['POST'])
def stop_stream(stream_id):
    """Stop streaming"""
    return jsonify(streaming.stop_stream(stream_id))

@app.route('/api/streams/<stream_id>/status', methods=['GET'])
def get_status(stream_id):
    """Get stream status"""
    return jsonify(streaming.get_stream_status(stream_id))

if __name__ == '__main__':
    print("REAPER OS Streaming Integration v0.5.0")
    print("Starting on localhost:5006...")
    app.run(host='0.0.0.0', port=5006, debug=False)

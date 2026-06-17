#!/usr/bin/env python3

################################################################################
# REAPER OS Mastering Suite v0.5.0
# Professional mastering tools with loudness correction and format optimization
# Usage: python3 mastering-suite.py [--loudness-correct] [--format-optimize]
################################################################################

from flask import Flask, jsonify, request, send_file
import json
import os
import subprocess
from datetime import datetime
import numpy as np
from scipy import signal
import io

app = Flask(__name__)

MASTERING_DIR = os.path.expanduser("~/.config/REAPER/mastering-suite")
MASTERING_DB = os.path.join(MASTERING_DIR, "masters.json")
REFERENCE_TRACKS = os.path.join(MASTERING_DIR, "references")

os.makedirs(MASTERING_DIR, exist_ok=True)
os.makedirs(REFERENCE_TRACKS, exist_ok=True)

class MasteringSuite:
    def __init__(self):
        self.standards = {
            'spotify': {'loudness': -14, 'true_peak': -1},
            'youtube': {'loudness': -13, 'true_peak': -1},
            'apple_music': {'loudness': -16, 'true_peak': -1},
            'soundcloud': {'loudness': -13, 'true_peak': -1},
            'broadcast': {'loudness': -23, 'true_peak': -2},
            'cinema': {'loudness': -27, 'true_peak': -2}
        }
    
    def measure_loudness(self, audio_file):
        """Measure loudness in LUFS"""
        try:
            result = subprocess.run(
                ['ffmpeg-normalize', '-print_json', audio_file],
                capture_output=True, text=True, timeout=60
            )
            
            if result.returncode == 0:
                return json.loads(result.stdout)
        except Exception as e:
            return {'error': str(e)}
    
    def loudness_correct(self, audio_file, target_standard='spotify'):
        """Correct loudness to standard"""
        if target_standard not in self.standards:
            return {'error': f'Unknown standard: {target_standard}'}
        
        target_loudness = self.standards[target_standard]['loudness']
        
        try:
            output_file = f"{audio_file}.corrected.wav"
            
            cmd = [
                'ffmpeg-normalize',
                audio_file,
                '-t', str(target_loudness),
                '-o', output_file
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode == 0:
                return {
                    'status': 'corrected',
                    'input': audio_file,
                    'output': output_file,
                    'target': target_standard,
                    'target_loudness': target_loudness
                }
        except Exception as e:
            return {'error': str(e)}
    
    def check_compliance(self, audio_file, standard):
        """Check compliance with standard"""
        if standard not in self.standards:
            return {'error': f'Unknown standard: {standard}'}
        
        measurements = self.measure_loudness(audio_file)
        spec = self.standards[standard]
        
        compliant = {
            'loudness': abs(measurements.get('integrated_loudness', 0) - spec['loudness']) < 1,
            'true_peak': measurements.get('true_peak', 0) <= spec['true_peak'],
            'overall': False
        }
        
        compliant['overall'] = compliant['loudness'] and compliant['true_peak']
        
        return {
            'standard': standard,
            'measurements': measurements,
            'requirements': spec,
            'compliance': compliant
        }
    
    def optimize_for_platform(self, audio_file, platform):
        """Optimize audio for specific platform"""
        if platform not in self.standards:
            return {'error': f'Unknown platform: {platform}'}
        
        # Loudness correction
        corrected = self.loudness_correct(audio_file, platform)
        
        # Format optimization
        output_file = corrected['output']
        optimized_file = f"{output_file}.{platform}.mp3"
        
        format_specs = {
            'spotify': {'bitrate': '320k', 'sample_rate': '44100'},
            'youtube': {'bitrate': 'vbr9', 'sample_rate': '48000'},
            'apple_music': {'bitrate': '320k', 'sample_rate': '44100'},
            'soundcloud': {'bitrate': '128k', 'sample_rate': '44100'}
        }
        
        specs = format_specs.get(platform, format_specs['spotify'])
        
        try:
            cmd = [
                'ffmpeg',
                '-i', output_file,
                '-b:a', specs['bitrate'],
                '-ar', specs['sample_rate'],
                optimized_file
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode == 0:
                return {
                    'platform': platform,
                    'original': audio_file,
                    'optimized': optimized_file,
                    'format': specs
                }
        except Exception as e:
            return {'error': str(e)}
    
    def compare_reference(self, audio_file, reference_file):
        """Compare with reference mastering"""
        current = self.measure_loudness(audio_file)
        reference = self.measure_loudness(reference_file)
        
        return {
            'current_mix': current,
            'reference_mix': reference,
            'loudness_diff': (current.get('integrated_loudness', 0) - 
                             reference.get('integrated_loudness', 0)),
            'peak_diff': (current.get('true_peak', 0) - 
                         reference.get('true_peak', 0))
        }
    
    def export_multiformat(self, audio_file, formats=None):
        """Export to multiple formats optimized"""
        if formats is None:
            formats = ['spotify', 'youtube', 'apple_music', 'soundcloud']
        
        results = []
        
        for fmt in formats:
            result = self.optimize_for_platform(audio_file, fmt)
            results.append(result)
        
        return {
            'source': audio_file,
            'exports': results,
            'timestamp': datetime.now().isoformat()
        }

mastering = MasteringSuite()

@app.route('/api/measure', methods=['POST'])
def measure():
    """Measure loudness"""
    data = request.json
    return jsonify(mastering.measure_loudness(data['file']))

@app.route('/api/correct', methods=['POST'])
def correct_loudness():
    """Correct loudness to standard"""
    data = request.json
    return jsonify(mastering.loudness_correct(
        data['file'],
        data.get('standard', 'spotify')
    ))

@app.route('/api/check-compliance', methods=['POST'])
def check_compliance():
    """Check compliance with standard"""
    data = request.json
    return jsonify(mastering.check_compliance(data['file'], data['standard']))

@app.route('/api/optimize', methods=['POST'])
def optimize():
    """Optimize for platform"""
    data = request.json
    return jsonify(mastering.optimize_for_platform(data['file'], data['platform']))

@app.route('/api/compare', methods=['POST'])
def compare():
    """Compare with reference"""
    data = request.json
    return jsonify(mastering.compare_reference(data['file'], data['reference']))

@app.route('/api/export-multiformat', methods=['POST'])
def export_multiformat():
    """Export to multiple formats"""
    data = request.json
    return jsonify(mastering.export_multiformat(
        data['file'],
        data.get('formats')
    ))

@app.route('/api/standards', methods=['GET'])
def get_standards():
    """Get loudness standards"""
    return jsonify(mastering.standards)

if __name__ == '__main__':
    print("REAPER OS Mastering Suite v0.5.0")
    print("Starting on localhost:5007...")
    app.run(host='0.0.0.0', port=5007, debug=False)

#!/usr/bin/env python3
"""
REAPER OS System Monitoring Dashboard
Flask web application for real-time system monitoring
"""

from flask import Flask, render_template, jsonify
import psutil
import json
import subprocess
from datetime import datetime
from threading import Thread
import time

app = Flask(__name__)

class SystemMonitor:
    def __init__(self):
        self.metrics = {
            "cpu": {"usage": 0, "cores": psutil.cpu_count()},
            "memory": {"total": 0, "used": 0, "percent": 0},
            "disk": {"total": 0, "used": 0, "percent": 0},
            "jack": {"status": "offline", "latency": 0, "load": 0},
            "audio": {"devices": []},
            "processes": [],
            "temperature": {"cpu": 0}
        }
        self.history = {
            "cpu": [],
            "memory": [],
            "disk": []
        }
    
    def update(self):
        """Update all metrics"""
        try:
            # CPU
            self.metrics["cpu"]["usage"] = psutil.cpu_percent(interval=1)
            
            # Memory
            mem = psutil.virtual_memory()
            self.metrics["memory"]["total"] = self._format_bytes(mem.total)
            self.metrics["memory"]["used"] = self._format_bytes(mem.used)
            self.metrics["memory"]["percent"] = mem.percent
            
            # Disk
            disk = psutil.disk_usage('/')
            self.metrics["disk"]["total"] = self._format_bytes(disk.total)
            self.metrics["disk"]["used"] = self._format_bytes(disk.used)
            self.metrics["disk"]["percent"] = disk.percent
            
            # JACK status
            self.update_jack_status()
            
            # Audio devices
            self.update_audio_devices()
            
            # Top processes
            self.update_top_processes()
            
            # Temperature
            self.update_temperature()
            
            # Store history
            self._store_history()
            
        except Exception as e:
            print(f"Error updating metrics: {e}")
    
    def update_jack_status(self):
        """Check JACK status"""
        try:
            result = subprocess.run(
                ["jack_lsp"],
                capture_output=True,
                timeout=2
            )
            
            if result.returncode == 0:
                self.metrics["jack"]["status"] = "online"
                # Get latency
                try:
                    latency_result = subprocess.run(
                        ["bash", "-c", "jack_latency 2>/dev/null | grep -i latency | head -1"],
                        capture_output=True,
                        text=True,
                        timeout=2
                    )
                    if latency_result.stdout:
                        self.metrics["jack"]["latency"] = latency_result.stdout.strip()
                except:
                    pass
            else:
                self.metrics["jack"]["status"] = "offline"
        
        except:
            self.metrics["jack"]["status"] = "offline"
    
    def update_audio_devices(self):
        """Get audio devices"""
        try:
            result = subprocess.run(
                ["bash", "-c", "aplay -l | grep 'card'"],
                capture_output=True,
                text=True,
                timeout=2
            )
            
            devices = []
            for line in result.stdout.split('\n'):
                if line.strip():
                    devices.append(line.strip())
            
            self.metrics["audio"]["devices"] = devices
        
        except:
            self.metrics["audio"]["devices"] = []
    
    def update_top_processes(self):
        """Get top CPU consuming processes"""
        try:
            processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
                try:
                    pinfo = proc.as_dict(attrs=['pid', 'name', 'cpu_percent'])
                    if pinfo['cpu_percent'] and pinfo['cpu_percent'] > 0.1:
                        processes.append(pinfo)
                except:
                    pass
            
            # Sort by CPU and take top 5
            processes.sort(key=lambda x: x['cpu_percent'], reverse=True)
            self.metrics["processes"] = processes[:5]
        
        except Exception as e:
            print(f"Error getting processes: {e}")
    
    def update_temperature(self):
        """Get CPU temperature if available"""
        try:
            temps = psutil.sensors_temperatures()
            if 'coretemp' in temps:
                cpu_temp = temps['coretemp'][0].current
                self.metrics["temperature"]["cpu"] = f"{cpu_temp}°C"
        except:
            self.metrics["temperature"]["cpu"] = "N/A"
    
    def _store_history(self):
        """Store metrics in history for graphing"""
        timestamp = datetime.now().isoformat()
        
        # Keep last 60 datapoints
        self.history["cpu"].append({
            "time": timestamp,
            "value": self.metrics["cpu"]["usage"]
        })
        if len(self.history["cpu"]) > 60:
            self.history["cpu"].pop(0)
        
        self.history["memory"].append({
            "time": timestamp,
            "value": self.metrics["memory"]["percent"]
        })
        if len(self.history["memory"]) > 60:
            self.history["memory"].pop(0)
        
        self.history["disk"].append({
            "time": timestamp,
            "value": self.metrics["disk"]["percent"]
        })
        if len(self.history["disk"]) > 60:
            self.history["disk"].pop(0)
    
    @staticmethod
    def _format_bytes(bytes_size):
        """Format bytes to human readable"""
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes_size < 1024:
                return f"{bytes_size:.1f}{unit}"
            bytes_size /= 1024
        return f"{bytes_size:.1f}PB"

# Initialize monitor
monitor = SystemMonitor()

# Background update thread
def update_thread():
    """Background thread to update metrics"""
    while True:
        try:
            monitor.update()
            time.sleep(5)
        except Exception as e:
            print(f"Update thread error: {e}")

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('dashboard.html')

@app.route('/api/metrics')
def api_metrics():
    """API endpoint for current metrics"""
    return jsonify(monitor.metrics)

@app.route('/api/history')
def api_history():
    """API endpoint for historical data"""
    return jsonify(monitor.history)

@app.route('/api/jack-latency')
def api_jack_latency():
    """Get JACK latency info"""
    try:
        result = subprocess.run(
            ["bash", "-c", "jack_latency 2>/dev/null"],
            capture_output=True,
            text=True,
            timeout=2
        )
        return jsonify({"latency": result.stdout.strip()})
    except:
        return jsonify({"latency": "Unknown"})

@app.route('/api/system-info')
def api_system_info():
    """Get system information"""
    try:
        uptime_result = subprocess.run(
            ["uptime", "-p"],
            capture_output=True,
            text=True
        )
        
        return jsonify({
            "uptime": uptime_result.stdout.strip(),
            "kernel": subprocess.run(
                ["uname", "-r"],
                capture_output=True,
                text=True
            ).stdout.strip(),
            "cpu_cores": psutil.cpu_count(),
            "boot_time": datetime.fromtimestamp(psutil.boot_time()).isoformat()
        })
    except Exception as e:
        return jsonify({"error": str(e)})

@app.route('/api/network')
def api_network():
    """Get network stats"""
    try:
        net = psutil.net_if_stats()
        interfaces = {}
        for iface, stats in net.items():
            interfaces[iface] = {
                "status": "up" if stats.isup else "down",
                "speed": f"{stats.speed} Mbps"
            }
        return jsonify(interfaces)
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == '__main__':
    # Start background update thread
    update_thread_obj = Thread(target=update_thread, daemon=True)
    update_thread_obj.start()
    
    # Start Flask app
    print("Starting REAPER OS System Dashboard...")
    print("Visit http://localhost:5000 in your browser")
    app.run(debug=False, host='0.0.0.0', port=5000)

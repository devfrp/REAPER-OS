#!/usr/bin/env python3

################################################################################
# REAPER OS Advanced Web Dashboard
# Professional monitoring with charts, alerts, and real-time statistics
# Usage: python3 advanced-dashboard.py [--port 5000] [--host localhost]
################################################################################

from flask import Flask, render_template, jsonify, request
from datetime import datetime, timedelta
import json
import os
import subprocess
import threading
import time
import psutil
import socket

app = Flask(__name__)

# Configuration
DASHBOARD_DIR = os.path.expanduser("~/.config/REAPER/dashboard")
HISTORY_FILE = os.path.join(DASHBOARD_DIR, "metrics-history.json")
CONFIG_FILE = os.path.join(DASHBOARD_DIR, "dashboard-config.json")
MAX_HISTORY = 1440  # 24 hours @ 1-minute intervals

os.makedirs(DASHBOARD_DIR, exist_ok=True)

# Global metrics storage
metrics_history = []
current_metrics = {}

def load_history():
    """Load metrics history from file"""
    global metrics_history
    if os.path.exists(HISTORY_FILE):
        try:
            with open(HISTORY_FILE, 'r') as f:
                metrics_history = json.load(f)[-MAX_HISTORY:]
        except:
            metrics_history = []

def save_history():
    """Save metrics history to file"""
    os.makedirs(DASHBOARD_DIR, exist_ok=True)
    with open(HISTORY_FILE, 'w') as f:
        json.dump(metrics_history[-MAX_HISTORY:], f)

def get_system_metrics():
    """Gather all system metrics"""
    global current_metrics
    
    # CPU
    cpu_percent = psutil.cpu_percent(interval=0.1)
    cpu_count = psutil.cpu_count()
    cpu_freq = psutil.cpu_freq()
    
    # Memory
    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()
    
    # Disk
    disk = psutil.disk_usage('/')
    
    # Network
    net = psutil.net_io_counters()
    
    # Load average
    load_avg = os.getloadavg()
    
    # JACK status
    jack_running = subprocess.run(
        ["systemctl", "is-active", "--quiet", "jackd"],
        capture_output=True
    ).returncode == 0
    
    # Temperature (if available)
    try:
        temps = psutil.sensors_temperatures()
        temp = temps.get('coretemp', [{}])[0].current if temps else None
    except:
        temp = None
    
    current_metrics = {
        'timestamp': datetime.now().isoformat(),
        'cpu': {
            'percent': cpu_percent,
            'cores': cpu_count,
            'freq_mhz': cpu_freq.current if cpu_freq else 0,
            'load_avg': list(load_avg)
        },
        'memory': {
            'total_gb': mem.total / (1024**3),
            'used_gb': mem.used / (1024**3),
            'percent': mem.percent,
            'swap_gb': swap.total / (1024**3),
            'swap_used_gb': swap.used / (1024**3)
        },
        'disk': {
            'total_gb': disk.total / (1024**3),
            'used_gb': disk.used / (1024**3),
            'free_gb': disk.free / (1024**3),
            'percent': disk.percent
        },
        'network': {
            'bytes_sent': net.bytes_sent,
            'bytes_recv': net.bytes_recv,
            'packets_sent': net.packets_sent,
            'packets_recv': net.packets_recv
        },
        'audio': {
            'jack_running': jack_running,
            'latency_estimate': get_jack_latency() if jack_running else None
        },
        'system': {
            'temperature': temp,
            'uptime_seconds': time.time() - psutil.boot_time()
        }
    }
    
    return current_metrics

def get_jack_latency():
    """Get JACK latency estimate"""
    try:
        result = subprocess.run(
            ["jack_latency_test", "-c", "1"],
            capture_output=True, text=True, timeout=10
        )
        # Parse output for latency value
        for line in result.stdout.split('\n'):
            if 'total latency' in line:
                return float(line.split()[-2])
    except:
        pass
    return None

def get_processes():
    """Get top CPU/Memory consuming processes"""
    processes = []
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
        try:
            pinfo = proc.as_dict(attrs=['pid', 'name', 'cpu_percent', 'memory_percent'])
            processes.append(pinfo)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    
    # Sort by CPU usage and get top 10
    processes.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
    return processes[:10]

def metrics_collection_thread():
    """Background thread to collect metrics every minute"""
    load_history()
    
    while True:
        try:
            metrics = get_system_metrics()
            metrics_history.append(metrics)
            
            # Keep only last 24 hours
            if len(metrics_history) > MAX_HISTORY:
                metrics_history = metrics_history[-MAX_HISTORY:]
            
            save_history()
            time.sleep(60)  # Collect every minute
        except Exception as e:
            print(f"Error in metrics collection: {e}")
            time.sleep(60)

# Routes
@app.route('/')
def dashboard():
    """Main dashboard page"""
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>REAPER OS Advanced Dashboard</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto; background: #1a1a1a; color: #fff; }
            
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 20px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.3);
            }
            
            .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
            
            .grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 20px;
                margin: 20px 0;
            }
            
            .card {
                background: #2a2a2a;
                border-radius: 10px;
                padding: 20px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.5);
                border: 1px solid #3a3a3a;
            }
            
            .card h3 { color: #667eea; margin-bottom: 15px; }
            
            .metric {
                display: flex;
                justify-content: space-between;
                padding: 8px 0;
                border-bottom: 1px solid #3a3a3a;
            }
            
            .metric:last-child { border-bottom: none; }
            
            .metric-label { color: #aaa; }
            .metric-value { color: #fff; font-weight: bold; }
            
            .progress-bar {
                width: 100%;
                height: 8px;
                background: #3a3a3a;
                border-radius: 4px;
                margin-top: 5px;
                overflow: hidden;
            }
            
            .progress-fill {
                height: 100%;
                background: linear-gradient(90deg, #667eea, #764ba2);
                transition: width 0.3s ease;
            }
            
            .status-ok { color: #4caf50; }
            .status-warning { color: #ff9800; }
            .status-danger { color: #f44336; }
            
            canvas { max-width: 100%; }
            
            .refresh-time {
                text-align: center;
                color: #888;
                font-size: 12px;
                margin-top: 20px;
            }
            
            .theme-toggle {
                position: fixed;
                bottom: 20px;
                right: 20px;
                background: #667eea;
                border: none;
                color: white;
                padding: 10px 20px;
                border-radius: 50px;
                cursor: pointer;
                box-shadow: 0 2px 10px rgba(0,0,0,0.3);
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>REAPER OS Advanced Dashboard</h1>
            <p>Real-time system monitoring</p>
        </div>
        
        <div class="container">
            <!-- System Overview -->
            <div class="grid">
                <div class="card">
                    <h3>CPU Usage</h3>
                    <div id="cpu-info"></div>
                    <div class="progress-bar"><div class="progress-fill" id="cpu-bar" style="width: 0%"></div></div>
                    <canvas id="cpu-chart"></canvas>
                </div>
                
                <div class="card">
                    <h3>Memory Usage</h3>
                    <div id="memory-info"></div>
                    <div class="progress-bar"><div class="progress-fill" id="mem-bar" style="width: 0%"></div></div>
                    <canvas id="memory-chart"></canvas>
                </div>
                
                <div class="card">
                    <h3>Disk Usage</h3>
                    <div id="disk-info"></div>
                    <div class="progress-bar"><div class="progress-fill" id="disk-bar" style="width: 0%"></div></div>
                </div>
            </div>
            
            <!-- Audio Monitoring -->
            <div class="grid">
                <div class="card">
                    <h3>Audio System</h3>
                    <div id="audio-info"></div>
                </div>
                
                <div class="card">
                    <h3>System Health</h3>
                    <div id="health-info"></div>
                </div>
                
                <div class="card">
                    <h3>Top Processes</h3>
                    <div id="processes-info"></div>
                </div>
            </div>
            
            <!-- History Charts -->
            <div class="card">
                <h3>24-Hour History</h3>
                <canvas id="history-chart"></canvas>
            </div>
            
            <div class="refresh-time">Last updated: <span id="update-time">--:--:--</span></div>
        </div>
        
        <button class="theme-toggle" onclick="toggleTheme()">🌓 Theme</button>
        
        <script>
            let cpuChart, memChart, historyChart;
            
            async function updateMetrics() {
                const response = await fetch('/api/metrics');
                const data = await response.json();
                
                updateCPU(data.cpu);
                updateMemory(data.memory);
                updateDisk(data.disk);
                updateAudio(data.audio);
                updateHealth(data);
                updateTime();
            }
            
            function updateCPU(cpu) {
                const cpuBar = document.getElementById('cpu-bar');
                cpuBar.style.width = cpu.percent + '%';
                
                document.getElementById('cpu-info').innerHTML = `
                    <div class="metric">
                        <span>CPU Usage</span>
                        <span>${cpu.percent.toFixed(1)}%</span>
                    </div>
                    <div class="metric">
                        <span>Cores</span>
                        <span>${cpu.cores}</span>
                    </div>
                    <div class="metric">
                        <span>Frequency</span>
                        <span>${cpu.freq_mhz.toFixed(0)} MHz</span>
                    </div>
                    <div class="metric">
                        <span>Load (1/5/15m)</span>
                        <span>${cpu.load_avg.map(l => l.toFixed(2)).join(' / ')}</span>
                    </div>
                `;
            }
            
            function updateMemory(mem) {
                const memBar = document.getElementById('mem-bar');
                memBar.style.width = mem.percent + '%';
                
                document.getElementById('memory-info').innerHTML = `
                    <div class="metric">
                        <span>Usage</span>
                        <span>${mem.used_gb.toFixed(1)}/${mem.total_gb.toFixed(1)} GB (${mem.percent}%)</span>
                    </div>
                    <div class="metric">
                        <span>Swap</span>
                        <span>${mem.swap_used_gb.toFixed(1)}/${mem.swap_gb.toFixed(1)} GB</span>
                    </div>
                `;
            }
            
            function updateDisk(disk) {
                const diskBar = document.getElementById('disk-bar');
                diskBar.style.width = disk.percent + '%';
                
                document.getElementById('disk-info').innerHTML = `
                    <div class="metric">
                        <span>Usage</span>
                        <span>${disk.used_gb.toFixed(1)}/${disk.total_gb.toFixed(1)} GB (${disk.percent}%)</span>
                    </div>
                    <div class="metric">
                        <span>Free</span>
                        <span>${disk.free_gb.toFixed(1)} GB</span>
                    </div>
                `;
            }
            
            function updateAudio(audio) {
                const status = audio.jack_running ? 
                    '<span class="status-ok">✓ Running</span>' : 
                    '<span class="status-danger">✗ Stopped</span>';
                
                document.getElementById('audio-info').innerHTML = `
                    <div class="metric">
                        <span>JACK</span>
                        ${status}
                    </div>
                    ${audio.latency_estimate ? `
                    <div class="metric">
                        <span>Latency</span>
                        <span>${audio.latency_estimate.toFixed(1)}ms</span>
                    </div>
                    ` : ''}
                `;
            }
            
            function updateHealth(data) {
                let status = 'status-ok';
                let message = 'System Healthy';
                
                if (data.cpu.percent > 80) {
                    status = 'status-warning';
                    message = 'High CPU Usage';
                } else if (data.memory.percent > 80) {
                    status = 'status-warning';
                    message = 'High Memory Usage';
                } else if (data.disk.percent > 90) {
                    status = 'status-danger';
                    message = 'Disk Almost Full';
                }
                
                document.getElementById('health-info').innerHTML = `
                    <div class="metric">
                        <span>Status</span>
                        <span class="${status}">${message}</span>
                    </div>
                    <div class="metric">
                        <span>Uptime</span>
                        <span>${Math.floor(data.system.uptime_seconds / 3600)}h</span>
                    </div>
                `;
            }
            
            function updateTime() {
                const now = new Date();
                document.getElementById('update-time').textContent = 
                    now.toLocaleTimeString();
            }
            
            function toggleTheme() {
                document.body.style.background = 
                    document.body.style.background === '#1a1a1a' ? '#f5f5f5' : '#1a1a1a';
                document.body.style.color = 
                    document.body.style.color === '#fff' ? '#000' : '#fff';
            }
            
            // Update every 2 seconds
            setInterval(updateMetrics, 2000);
            updateMetrics();
        </script>
    </body>
    </html>
    '''

@app.route('/api/metrics')
def api_metrics():
    """Get current metrics"""
    return jsonify(current_metrics)

@app.route('/api/history')
def api_history():
    """Get metrics history"""
    return jsonify(metrics_history)

@app.route('/api/processes')
def api_processes():
    """Get top processes"""
    return jsonify(get_processes())

@app.route('/api/alerts', methods=['GET'])
def api_alerts():
    """Get system alerts"""
    alerts = []
    
    if current_metrics.get('cpu', {}).get('percent', 0) > 80:
        alerts.append({'type': 'warning', 'message': 'High CPU usage'})
    
    if current_metrics.get('memory', {}).get('percent', 0) > 85:
        alerts.append({'type': 'warning', 'message': 'High memory usage'})
    
    if current_metrics.get('disk', {}).get('percent', 0) > 90:
        alerts.append({'type': 'danger', 'message': 'Disk space critical'})
    
    return jsonify(alerts)

@app.route('/api/export', methods=['POST'])
def export_report():
    """Export metrics as PDF/JSON"""
    try:
        with open(f"{DASHBOARD_DIR}/report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json", 'w') as f:
            json.dump({
                'generated': datetime.now().isoformat(),
                'metrics_history': metrics_history[-100:],
                'current_metrics': current_metrics
            }, f, indent=2)
        return jsonify({'status': 'success', 'message': 'Report exported'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

def main():
    """Start the dashboard"""
    # Start metrics collection thread
    metrics_thread = threading.Thread(target=metrics_collection_thread, daemon=True)
    metrics_thread.start()
    
    # Start Flask app
    app.run(
        host=os.getenv('DASHBOARD_HOST', 'localhost'),
        port=int(os.getenv('DASHBOARD_PORT', 5001)),
        debug=False
    )

if __name__ == '__main__':
    main()

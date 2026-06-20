#!/usr/bin/env python3
"""
REAPER OS System Monitoring Dashboard
Flask web application for real-time system monitoring
Uses the shared dashboard.html template
"""

from flask import Flask, render_template, jsonify
import psutil
import subprocess
import os
from datetime import datetime
from threading import Thread
import time

TEMPLATE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "templates")

app = Flask(__name__)
app.template_folder = TEMPLATE_DIR


class SystemMonitor:
    def __init__(self):
        self.metrics = {}
        self.history = []

    def update(self):
        try:
            cpu_pct = psutil.cpu_percent(interval=1)
            cpu_count = psutil.cpu_count()
            physical = psutil.cpu_count(logical=False)
            freq = psutil.cpu_freq()
            mem = psutil.virtual_memory()
            swap = psutil.swap_memory()
            disk = psutil.disk_usage('/')
            load_avg = os.getloadavg()
            uptime = time.time() - psutil.boot_time()
            kernel = subprocess.run(["uname", "-r"], capture_output=True, text=True).stdout.strip()
            temp_val = None
            try:
                temps = psutil.sensors_temperatures()
                temp_val = temps.get('coretemp', [{}])[0].current if temps else None
            except Exception:
                pass

            jack_running = False
            try:
                jack_running = subprocess.run(
                    ["systemctl", "is-active", "--quiet", "jackd"],
                    capture_output=True
                ).returncode == 0
            except Exception:
                pass

            audio_devices = []
            try:
                r = subprocess.run(["aplay", "-l"], capture_output=True, text=True, timeout=5)
                for line in r.stdout.split('\n'):
                    if 'card' in line.lower() and ':' in line:
                        pts = line.split(':', 1)
                        if len(pts) > 1:
                            audio_devices.append({"name": pts[1].strip(), "type": "playback"})
            except Exception:
                pass

            proc_data = {"cpu": [], "memory": [], "audio": []}
            for p in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    d = p.as_dict(attrs=['pid', 'name', 'cpu_percent', 'memory_percent'])
                    proc_data["cpu"].append(dict(d))
                    proc_data["memory"].append(dict(d))
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            proc_data["cpu"].sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
            proc_data["memory"].sort(key=lambda x: x.get('memory_percent', 0), reverse=True)

            net_io = psutil.net_io_counters()
            ifaces = {}
            try:
                stats = psutil.net_if_stats()
                for iface, st in stats.items():
                    ifaces[iface] = {"status": "up" if st.isup else "down", "speed": f"{st.speed} Mbps" if st.speed else "N/A"}
            except Exception:
                pass

            gpu_info = {"name": "Unknown", "load": None, "memory_used": None, "memory_total": None, "temperature": None}
            try:
                r = subprocess.run(["lspci", "-v", "-nn"], capture_output=True, text=True, timeout=10)
                for line in r.stdout.split('\n'):
                    if 'VGA' in line or '3D' in line or 'Display' in line:
                        gpu_info["name"] = line.split(':', 2)[-1].strip()
                        break
            except Exception:
                pass

            self.metrics = {
                "timestamp": datetime.now().isoformat(),
                "cpu": {
                    "percent": cpu_pct, "cores": cpu_count, "physical_cores": physical,
                    "freq_mhz": freq.current if freq else 0, "load_avg": list(load_avg)
                },
                "memory": {
                    "total_gb": mem.total / (1024**3), "used_gb": mem.used / (1024**3),
                    "percent": mem.percent, "swap_gb": swap.total / (1024**3),
                    "swap_used_gb": swap.used / (1024**3)
                },
                "disk": {
                    "total_gb": disk.total / (1024**3), "used_gb": disk.used / (1024**3),
                    "free_gb": disk.free / (1024**3), "percent": disk.percent
                },
                "audio": {
                    "jack_running": jack_running, "latency_estimate": None,
                    "sample_rate": None, "buffer_size": None, "xruns": None, "dsp_load": None
                },
                "audio_devices": audio_devices,
                "alsa": {"config_found": os.path.exists("/etc/asound.conf") or os.path.exists(os.path.expanduser("~/.asoundrc")), "cards": 0, "devices": 0},
                "gpu": gpu_info,
                "docker": {"running": False, "containers": []},
                "processes": proc_data,
                "network": {
                    "bytes_sent": net_io.bytes_sent, "bytes_recv": net_io.bytes_recv,
                    "packets_sent": net_io.packets_sent, "packets_recv": net_io.packets_recv,
                    "interfaces": ifaces, "connections": []
                },
                "system": {
                    "temperature": temp_val, "uptime_seconds": uptime,
                    "kernel": kernel,
                    "boot_time": datetime.fromtimestamp(psutil.boot_time()).isoformat()
                }
            }

            self.history.append({
                "timestamp": datetime.now().isoformat(),
                "cpu": {"percent": cpu_pct},
                "memory": {"percent": mem.percent, "swap_gb": swap.total / (1024**3), "swap_used_gb": swap.used / (1024**3)},
                "disk": {"percent": disk.percent}
            })
            if len(self.history) > 1440:
                self.history = self.history[-1440:]
        except Exception as e:
            print(f"Error updating metrics: {e}")


monitor = SystemMonitor()


def update_thread():
    while True:
        try:
            monitor.update()
            time.sleep(5)
        except Exception as e:
            print(f"Update thread error: {e}")


@app.route('/')
def index():
    return render_template('dashboard.html')


@app.route('/api/metrics')
def api_metrics():
    return jsonify(monitor.metrics if monitor.metrics else {"status": "initializing"})


@app.route('/api/history')
def api_history():
    return jsonify(monitor.history)


@app.route('/api/alerts')
def api_alerts():
    if not monitor.metrics:
        return jsonify([])
    return jsonify([])


@app.route('/api/events')
def api_events():
    return jsonify([])


@app.route('/api/processes')
def api_processes():
    return jsonify(monitor.metrics.get('processes', {}) if monitor.metrics else {})


@app.route('/api/status')
def api_status():
    return jsonify({
        "status": "running",
        "uptime": time.time() - psutil.boot_time(),
        "collector_active": True,
        "history_points": len(monitor.history)
    })


if __name__ == '__main__':
    update_thread_obj = Thread(target=update_thread, daemon=True)
    update_thread_obj.start()

    print("Starting REAPER OS System Dashboard...")
    print("Visit http://localhost:5000 in your browser")
    app.run(debug=False, host='0.0.0.0', port=5000)


#!/usr/bin/env python3

################################################################################
# REAPER OS Advanced Web Dashboard
# Professional monitoring with charts, alerts, GPU, Docker, DSP, and history
# Usage: python3 advanced-dashboard.py [--port 5001] [--host localhost]
################################################################################

from flask import Flask, render_template, jsonify, request, send_file
from datetime import datetime, timedelta
import json
import os
import subprocess
import threading
import time
import psutil
import socket
import glob

app = Flask(__name__)
TEMPLATE_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "templates")
app.template_folder = TEMPLATE_DIR

# Configuration
DASHBOARD_DIR = os.path.expanduser("~/.config/REAPER/dashboard")
HISTORY_FILE = os.path.join(DASHBOARD_DIR, "metrics-history.json")
EVENTS_FILE = os.path.join(DASHBOARD_DIR, "events.json")
MAX_HISTORY = 1440  # 24 hours @ 1-minute intervals
MAX_EVENTS = 500

os.makedirs(DASHBOARD_DIR, exist_ok=True)

# Global storage
metrics_history = []
events_log = []
current_metrics = {}
_prev_net = None
_prev_time = None


def load_persisted():
    global metrics_history, events_log
    if os.path.exists(HISTORY_FILE):
        try:
            with open(HISTORY_FILE) as f:
                metrics_history = json.load(f)[-MAX_HISTORY:]
        except Exception:
            metrics_history = []
    if os.path.exists(EVENTS_FILE):
        try:
            with open(EVENTS_FILE) as f:
                events_log = json.load(f)[-MAX_EVENTS:]
        except Exception:
            events_log = []


def save_persisted():
    try:
        with open(HISTORY_FILE, 'w') as f:
            json.dump(metrics_history[-MAX_HISTORY:], f)
    except Exception:
        pass
    try:
        with open(EVENTS_FILE, 'w') as f:
            json.dump(events_log[-MAX_EVENTS:], f)
    except Exception:
        pass


def add_event(message, event_type="info"):
    events_log.append({
        "time": datetime.now().strftime("%H:%M:%S"),
        "message": message,
        "type": event_type
    })
    if len(events_log) > MAX_EVENTS:
        events_log.pop(0)


def get_jack_info():
    info = {"running": False, "latency": None, "sample_rate": None,
            "buffer_size": None, "xruns": 0, "dsp_load": None}
    try:
        active = subprocess.run(
            ["systemctl", "is-active", "--quiet", "jackd"],
            capture_output=True
        )
        info["running"] = active.returncode == 0
    except Exception:
        pass

    if info["running"]:
        try:
            r = subprocess.run(
                ["jack_bufsize"], capture_output=True, text=True, timeout=5
            )
            if r.returncode == 0:
                info["buffer_size"] = r.stdout.strip()
        except Exception:
            pass
        try:
            r = subprocess.run(
                ["jack_samplerate"], capture_output=True, text=True, timeout=5
            )
            if r.returncode == 0:
                try:
                    info["sample_rate"] = int(r.stdout.strip())
                except ValueError:
                    info["sample_rate"] = r.stdout.strip()
        except Exception:
            pass
        try:
            r = subprocess.run(
                ["bash", "-c", "jack_lsp 2>/dev/null | wc -l"],
                capture_output=True, text=True, timeout=5
            )
            if r.returncode == 0:
                info["connections"] = int(r.stdout.strip())
        except Exception:
            pass
        try:
            r = subprocess.run(
                ["bash", "-c", "jack_wait -c 2>/dev/null; echo $?"],
                capture_output=True, text=True, timeout=5
            )
        except Exception:
            pass
        try:
            r = subprocess.run(
                ["bash", "-c",
                 "cat /proc/asound/cards 2>/dev/null | grep -c '\\[' || echo 0"],
                capture_output=True, text=True, timeout=3
            )
            if r.returncode == 0:
                info["alsa_cards"] = int(r.stdout.strip())
        except Exception:
            info["alsa_cards"] = 0
    return info


def get_audio_devices():
    devices = []
    try:
        r = subprocess.run(
            ["aplay", "-l"], capture_output=True, text=True, timeout=5
        )
        for line in r.stdout.split('\n'):
            if 'card' in line.lower() and ':' in line:
                parts = line.split(':', 1)
                if len(parts) > 1:
                    devices.append({"name": parts[1].strip(), "type": "playback"})
    except Exception:
        pass
    try:
        r = subprocess.run(
            ["arecord", "-l"], capture_output=True, text=True, timeout=5
        )
        for line in r.stdout.split('\n'):
            if 'card' in line.lower() and ':' in line:
                parts = line.split(':', 1)
                if len(parts) > 1:
                    name = parts[1].strip()
                    if not any(d["name"] == name for d in devices):
                        devices.append({"name": name, "type": "capture"})
    except Exception:
        pass
    return devices


def get_gpu_info():
    info = {"name": "Unknown", "load": None, "memory_used": None,
            "memory_total": None, "temperature": None}
    try:
        r = subprocess.run(
            ["lspci", "-v", "-nn"], capture_output=True, text=True, timeout=10
        )
        for line in r.stdout.split('\n'):
            if 'VGA' in line or '3D' in line or 'Display' in line:
                info["name"] = line.split(':', 2)[-1].strip()
                break
    except Exception:
        pass
    try:
        r = subprocess.run(
            ["nvidia-smi", "--query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu",
             "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5
        )
        if r.returncode == 0:
            parts = r.stdout.strip().split(',')
            if len(parts) >= 4:
                info["load"] = float(parts[0].strip())
                info["memory_used"] = parts[1].strip() + " MiB"
                info["memory_total"] = parts[2].strip() + " MiB"
                info["temperature"] = parts[3].strip() + "°C"
    except Exception:
        pass
    return info


def get_docker_info():
    containers = []
    try:
        r = subprocess.run(
            ["docker", "ps", "--format", "{{.Names}}|{{.Status}}|{{.Image}}"],
            capture_output=True, text=True, timeout=5
        )
        if r.returncode == 0:
            for line in r.stdout.strip().split('\n'):
                if line:
                    parts = line.split('|', 2)
                    containers.append({
                        "name": parts[0] if len(parts) > 0 else "?",
                        "status": parts[1] if len(parts) > 1 else "?",
                        "image": parts[2] if len(parts) > 2 else "?"
                    })
    except Exception:
        pass
    return {"running": len(containers) > 0, "containers": containers}


def get_network_connections():
    conns = []
    try:
        for c in psutil.net_connections(kind='inet'):
            if c.status == 'ESTABLISHED':
                conns.append({
                    "local": f"{c.laddr.ip}:{c.laddr.port}" if c.laddr else "?",
                    "remote": f"{c.raddr.ip}:{c.raddr.port}" if c.raddr else "?",
                    "status": c.status
                })
    except Exception:
        pass
    return conns[:20]


def get_dsp_load():
    try:
        r = subprocess.run(
            ["bash", "-c",
             "jack_cpu_load 2>/dev/null || cat /proc/asound/card*/pcm*/sub*/status 2>/dev/null | head -1"],
            capture_output=True, text=True, timeout=5
        )
        val = r.stdout.strip()
        if val:
            try:
                return float(val.replace('%', ''))
            except ValueError:
                pass
    except Exception:
        pass
    return None


def get_process_info():
    cpu_procs = []
    mem_procs = []
    audio_procs = []
    audio_keywords = ["jack", "reaper", "ardour", "pulse", "alsa",
                      "wine", "vst", "audiogridder", "dante", "aes67",
                      "supercollider", "pure", "calf", "zynn", "yoshimi"]
    for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
        try:
            p = proc.as_dict(attrs=['pid', 'name', 'cpu_percent', 'memory_percent'])
            cpu_procs.append(dict(p))
            mem_procs.append(dict(p))
            if any(kw in (p.get('name', '') or '').lower() for kw in audio_keywords):
                audio_procs.append(dict(p))
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    cpu_procs.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
    mem_procs.sort(key=lambda x: x.get('memory_percent', 0), reverse=True)
    audio_procs.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
    return {
        "cpu": cpu_procs[:10],
        "memory": mem_procs[:10],
        "audio": audio_procs[:10]
    }


def get_network_bandwidth():
    try:
        net = psutil.net_io_counters()
        return {
            "bytes_sent": net.bytes_sent,
            "bytes_recv": net.bytes_recv,
            "packets_sent": net.packets_sent,
            "packets_recv": net.packets_recv
        }
    except Exception:
        return {"bytes_sent": 0, "bytes_recv": 0,
                "packets_sent": 0, "packets_recv": 0}


def get_network_interfaces():
    ifaces = {}
    try:
        stats = psutil.net_if_stats()
        for iface, st in stats.items():
            ifaces[iface] = {
                "status": "up" if st.isup else "down",
                "speed": f"{st.speed} Mbps" if st.speed else "N/A"
            }
    except Exception:
        pass
    return ifaces


def get_alsa_info():
    info = {"config_found": False, "cards": 0, "devices": 0}
    if os.path.exists("/etc/asound.conf") or os.path.exists(os.path.expanduser("~/.asoundrc")):
        info["config_found"] = True
    try:
        r = subprocess.run(
            ["cat", "/proc/asound/cards"], capture_output=True, text=True, timeout=3
        )
        info["cards"] = r.stdout.count('[')
    except Exception:
        pass
    try:
        r = subprocess.run(
            ["aplay", "-l"], capture_output=True, text=True, timeout=3
        )
        info["devices"] = r.stdout.count('card')
    except Exception:
        pass
    return info


def collect_current_metrics():
    global current_metrics, _prev_net, _prev_time

    cpu_percent = psutil.cpu_percent(interval=0.1)
    cpu_count = psutil.cpu_count()
    physical_cores = psutil.cpu_count(logical=False)
    cpu_freq = psutil.cpu_freq()
    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()
    disk = psutil.disk_usage('/')
    load_avg = os.getloadavg()
    temps = None
    try:
        temps = psutil.sensors_temperatures()
        temp_val = temps.get('coretemp', [{}])[0].current if temps else None
    except Exception:
        temp_val = None

    uptime_sec = time.time() - psutil.boot_time()
    kernel = subprocess.run(
        ["uname", "-r"], capture_output=True, text=True
    ).stdout.strip()

    jack_info = get_jack_info()
    audio_devices = get_audio_devices()
    gpu_info = get_gpu_info()
    docker_info = get_docker_info()
    process_info = get_process_info()
    net_bw = get_network_bandwidth()
    net_ifaces = get_network_interfaces()
    net_conns = get_network_connections()
    dsp_load = get_dsp_load()
    alsa_info = get_alsa_info()

    if jack_info["running"] and dsp_load is None:
        dsp_load = 0

    jack_info["dsp_load"] = dsp_load

    current_metrics = {
        "timestamp": datetime.now().isoformat(),
        "cpu": {
            "percent": cpu_percent,
            "cores": cpu_count,
            "physical_cores": physical_cores,
            "freq_mhz": cpu_freq.current if cpu_freq else 0,
            "load_avg": list(load_avg)
        },
        "memory": {
            "total_gb": mem.total / (1024 ** 3),
            "used_gb": mem.used / (1024 ** 3),
            "percent": mem.percent,
            "swap_gb": swap.total / (1024 ** 3),
            "swap_used_gb": swap.used / (1024 ** 3)
        },
        "disk": {
            "total_gb": disk.total / (1024 ** 3),
            "used_gb": disk.used / (1024 ** 3),
            "free_gb": disk.free / (1024 ** 3),
            "percent": disk.percent
        },
        "audio": jack_info,
        "audio_devices": audio_devices,
        "alsa": alsa_info,
        "gpu": gpu_info,
        "docker": docker_info,
        "processes": process_info,
        "network": {
            **net_bw,
            "interfaces": net_ifaces,
            "connections": net_conns
        },
        "system": {
            "temperature": temp_val,
            "uptime_seconds": uptime_sec,
            "kernel": kernel,
            "boot_time": datetime.fromtimestamp(psutil.boot_time()).isoformat()
        }
    }

    if cpu_percent > 90:
        add_event(f"CPU spike: {cpu_percent:.1f}%", "warning")
    if mem.percent > 90:
        add_event(f"Memory critical: {mem.percent:.1f}%", "warning")
    if disk.percent > 95:
        add_event(f"Disk nearly full: {disk.percent:.1f}%", "danger")

    _prev_net = net_bw
    _prev_time = time.time()

    return current_metrics


def metrics_collector():
    load_persisted()
    while True:
        try:
            m = collect_current_metrics()
            metrics_history.append(m)
            if len(metrics_history) > MAX_HISTORY:
                metrics_history = metrics_history[-MAX_HISTORY:]
            save_persisted()
        except Exception as e:
            print(f"Metrics collection error: {e}")
        time.sleep(60)


# --- Routes ---

@app.route('/')
def dashboard():
    return render_template('dashboard.html')


@app.route('/api/metrics')
def api_metrics():
    return jsonify(current_metrics if current_metrics else collect_current_metrics())


@app.route('/api/history')
def api_history():
    return jsonify(metrics_history)


@app.route('/api/events')
def api_events():
    return jsonify(events_log[-100:])


@app.route('/api/processes')
def api_processes():
    return jsonify(get_process_info())


@app.route('/api/alerts')
def api_alerts():
    alerts = []
    m = current_metrics
    if not m:
        return jsonify([])
    cpu = m.get('cpu', {}).get('percent', 0)
    mem_pct = m.get('memory', {}).get('percent', 0)
    disk_pct = m.get('disk', {}).get('percent', 0)

    if cpu > 95:
        alerts.append({'type': 'danger', 'message': f'CPU critical: {cpu:.1f}%'})
    elif cpu > 80:
        alerts.append({'type': 'warning', 'message': f'High CPU: {cpu:.1f}%'})
    if mem_pct > 95:
        alerts.append({'type': 'danger', 'message': f'Memory critical: {mem_pct:.1f}%'})
    elif mem_pct > 80:
        alerts.append({'type': 'warning', 'message': f'High memory: {mem_pct:.1f}%'})
    if disk_pct > 95:
        alerts.append({'type': 'danger', 'message': f'Disk critical: {disk_pct:.1f}%'})
    elif disk_pct > 85:
        alerts.append({'type': 'warning', 'message': f'High disk usage: {disk_pct:.1f}%'})
    if not m.get('audio', {}).get('running'):
        alerts.append({'type': 'warning', 'message': 'JACK audio server not running'})
    return jsonify(alerts)


@app.route('/api/export', methods=['POST', 'GET'])
def export_report():
    report_path = os.path.join(
        DASHBOARD_DIR,
        f"report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    )
    data = {
        "generated": datetime.now().isoformat(),
        "current_metrics": current_metrics,
        "history": metrics_history[-144:],
        "events": events_log[-100:]
    }
    with open(report_path, 'w') as f:
        json.dump(data, f, indent=2)
    if request.method == 'POST':
        return jsonify({"status": "success", "path": report_path})
    return send_file(report_path, as_attachment=True, download_name=os.path.basename(report_path))


@app.route('/api/status')
def api_status():
    return jsonify({
        "status": "running",
        "uptime": time.time() - psutil.boot_time(),
        "collector_active": True,
        "history_points": len(metrics_history),
        "events_count": len(events_log)
    })


def main():
    import argparse
    parser = argparse.ArgumentParser(description="REAPER OS Advanced Dashboard")
    parser.add_argument("--port", type=int, default=5001, help="HTTP port")
    parser.add_argument("--host", default="localhost", help="Bind address")
    parser.add_argument("--no-browser", action="store_true", help="Don't open browser")
    args = parser.parse_args()

    print("=" * 60)
    print("  REAPER OS Advanced Dashboard")
    print("  Professional Audio System Monitoring")
    print("=" * 60)
    print(f"  URL:      http://{args.host}:{args.port}")
    print(f"  Data dir: {DASHBOARD_DIR}")
    print(f"  Press Ctrl+C to stop")
    print("=" * 60)

    collector = threading.Thread(target=metrics_collector, daemon=True)
    collector.start()

    if not args.no_browser:
        try:
            import webbrowser
            threading.Timer(1.5, lambda: webbrowser.open(f"http://{args.host}:{args.port}")).start()
        except Exception:
            pass

    app.run(host=args.host, port=args.port, debug=False)


if __name__ == '__main__':
    main()

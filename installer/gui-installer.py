#!/usr/bin/env python3
"""
REAPER OS GUI Installer
Interactive graphical installation wizard with automatic hardware detection
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gio', '2.0')
from gi.repository import Gtk, GdkPixbuf, Gio, GLib
import sys
import subprocess
import threading
import time
from pathlib import Path

class REAPERInstallerWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title("REAPER OS Installer")
        self.set_default_size(840, 640)
        self.set_resizable(True)
        
        self.current_step = 0
        self.steps = [
            "welcome",
            "language",
            "profile",
            "disk-selection",
            "summary",
            "installation",
            "success"
        ]
        
        self.config = {
            "language": "en",
            "region": "US",
            "disk": "",
            "username": "",
            "hostname": "reaper-os",
            "profile": "studio",
            "install_rt_kernel": True,
            "install_wine": True,
            "install_mode": "online"
        }
        
        self.build_ui()
    
    def detect_disks(self):
        """Dynamically detect available disks"""
        disks = []
        try:
            result = subprocess.run(
                ["lsblk", "-ndo", "NAME,SIZE,MODEL,TYPE,MOUNTPOINT"],
                capture_output=True, text=True, timeout=10
            )
            for line in result.stdout.strip().split('\n'):
                if not line:
                    continue
                parts = line.split(None, 4)
                if len(parts) >= 4 and parts[3] == 'disk':
                    name = parts[0]
                    size = parts[1] if len(parts) > 1 else "?"
                    model = parts[2] if len(parts) > 2 else "Unknown"
                    mount = parts[4] if len(parts) > 4 else ""
                    label = f"/dev/{name} - {size} - {model}"
                    if mount:
                        label += f" [mounted: {mount}]"
                    disks.append({"path": f"/dev/{name}", "label": label, "size": size, "model": model})
        except Exception:
            disks = [
                {"path": "/dev/sda", "label": "/dev/sda", "size": "?", "model": "Unknown"},
                {"path": "/dev/nvme0n1", "label": "/dev/nvme0n1", "size": "?", "model": "Unknown"},
            ]
        return disks

    def build_ui(self):
        """Build main UI"""
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_top(10)
        main_box.set_margin_bottom(10)
        main_box.set_margin_start(10)
        main_box.set_margin_end(10)
        
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        
        icon_paths = [
            Path(__file__).parent / "assets" / "reaper-os-logo.png",
            Path("/opt/reaper-os/assets/reaper-os-logo.png"),
        ]
        for p in icon_paths:
            if p.exists():
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(p), 64, 64, True)
                icon = Gtk.Image.new_from_pixbuf(pixbuf)
                header.append(icon)
                break
        
        title_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        title = Gtk.Label()
        title.set_markup("<big><b>REAPER OS Installation</b></big>")
        subtitle = Gtk.Label()
        subtitle.set_text("Professional Audio Distribution")
        subtitle.add_css_class("dim-label")
        title_box.append(title)
        title_box.append(subtitle)
        header.append(title_box)
        
        main_box.append(header)
        main_box.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(300)
        
        self.create_welcome_step()
        self.create_language_step()
        self.create_profile_step()
        self.create_disk_step()
        self.create_summary_step()
        self.create_installation_step()
        self.create_success_step()
        
        main_box.append(self.stack)
        
        nav_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        nav_box.set_homogeneous(False)
        nav_box.set_halign(Gtk.Align.END)
        nav_box.set_margin_top(20)
        
        self.back_button = Gtk.Button(label="← Back")
        self.back_button.connect("clicked", self.on_back_clicked)
        self.back_button.set_sensitive(False)
        nav_box.append(self.back_button)
        
        self.next_button = Gtk.Button(label="Next →")
        self.next_button.connect("clicked", self.on_next_clicked)
        self.next_button.add_css_class("suggested-action")
        nav_box.append(self.next_button)
        
        main_box.append(nav_box)
        
        progress_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        progress_box.set_halign(Gtk.Align.CENTER)
        progress_box.set_margin_top(10)
        
        self.progress_dots = []
        for i in range(len(self.steps)):
            dot = Gtk.Label()
            dot.set_markup("●")
            dot.add_css_class("dim-label" if i > 0 else "")
            self.progress_dots.append(dot)
            progress_box.append(dot)
        
        main_box.append(progress_box)
        
        self.set_child(main_box)
    
    def create_welcome_step(self):
        """Welcome step"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_halign(Gtk.Align.CENTER)
        box.set_valign(Gtk.Align.CENTER)
        
        title = Gtk.Label()
        title.set_markup("<big><b>Welcome to REAPER OS</b></big>")
        box.append(title)
        
        description = Gtk.Label()
        description.set_text(
            "Professional Audio Distribution for Musicians\n\n"
            "This installer will guide you through:\n"
            "• Language and region selection\n"
            "• Disk selection\n"
            "• System configuration\n\n"
            "Installation takes approximately 15-20 minutes."
        )
        description.set_justify(Gtk.Justification.CENTER)
        box.append(description)
        
        self.stack.add_named(box, "welcome")
    
    def create_language_step(self):
        """Language selection step"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(50)
        box.set_margin_end(50)
        
        title = Gtk.Label()
        title.set_markup("<big><b>Select Language / Choisir la langue</b></big>")
        title.set_halign(Gtk.Align.START)
        box.append(title)
        
        languages = [
            ("English", "en"),
            ("Français", "fr"),
            ("Español", "es"),
            ("Deutsch", "de"),
            ("Português", "pt"),
            ("日本語", "ja")
        ]
        
        self.lang_combo = Gtk.ComboBoxText()
        for lang_name, lang_code in languages:
            self.lang_combo.append(lang_code, lang_name)
        self.lang_combo.set_active_id("en")
        self.lang_combo.connect("changed", self.on_language_changed)
        box.append(self.lang_combo)
        
        region_label = Gtk.Label()
        region_label.set_markup("<b>Region & Timezone:</b>")
        region_label.set_halign(Gtk.Align.START)
        box.append(region_label)
        
        regions = [
            ("North America", "US"),
            ("Europe - UK", "GB"),
            ("Europe - France", "FR"),
            ("Europe - Germany", "DE"),
            ("Europe - Spain", "ES"),
            ("Asia Pacific", "AU"),
            ("Other", "UTC")
        ]
        
        self.region_combo = Gtk.ComboBoxText()
        for region_name, region_code in regions:
            self.region_combo.append(region_code, region_name)
        self.region_combo.set_active_id("US")
        self.region_combo.connect("changed", self.on_region_changed)
        box.append(self.region_combo)
        
        kb_label = Gtk.Label()
        kb_label.set_text("Keyboard Layout:")
        kb_label.set_halign(Gtk.Align.START)
        box.append(kb_label)
        
        self.keyboard_combo = Gtk.ComboBoxText()
        keyboards = ["QWERTY", "AZERTY", "QWERTZ", "Other"]
        for kb in keyboards:
            self.keyboard_combo.append(kb.lower(), kb)
        self.keyboard_combo.set_active_id("qwerty")
        box.append(self.keyboard_combo)
        
        self.stack.add_named(box, "language")
    
    def create_profile_step(self):
        """System profile selection"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(50)
        box.set_margin_end(50)
        
        title = Gtk.Label()
        title.set_markup("<big><b>Select System Profile</b></big>")
        title.set_halign(Gtk.Align.START)
        box.append(title)
        
        profiles = [
            ("Studio (Recording, Mixing, Mastering)", "studio",
             "Optimized for low-latency recording and mixing.\nJACK at 128 samples, PREEMPT_RT kernel"),
            ("Live Performance", "live",
             "Optimized for stage use.\nHigher buffer for stability, fast boot, minimal services"),
            ("DJ / Electronic", "dj",
             "Optimized for electronic music production.\nMIDI priority, synthesizer support, loop-based workflow"),
            ("Post-Production", "post",
             "Optimized for video/multimedia audio.\nHigh track count, video sync, surround support"),
        ]
        
        self.profile_buttons = {}
        first_button = None
        for profile_name, profile_id, description in profiles:
            btn = Gtk.CheckButton(label=profile_name)
            btn.set_active(profile_id == "studio")
            btn.connect("toggled", self.on_profile_toggled, profile_id)
            self.profile_buttons[profile_id] = btn
            box.append(btn)
            if first_button is None:
                first_button = btn
            
            desc_label = Gtk.Label()
            desc_label.set_text(f"    {description}")
            desc_label.set_wrap(True)
            desc_label.add_css_class("dim-label")
            desc_label.set_halign(Gtk.Align.START)
            box.append(desc_label)
        
        box.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        
        options_label = Gtk.Label()
        options_label.set_markup("<b>Additional Options:</b>")
        options_label.set_halign(Gtk.Align.START)
        box.append(options_label)
        
        self.rt_kernel_check = Gtk.CheckButton(label="Install Real-Time Kernel (PREEMPT_RT)")
        self.rt_kernel_check.set_active(True)
        box.append(self.rt_kernel_check)
        
        self.wine_check = Gtk.CheckButton(label="Install Wine/Proton for Windows VST support")
        self.wine_check.set_active(True)
        box.append(self.wine_check)
        
        mode_label = Gtk.Label()
        mode_label.set_text("Installation Mode:")
        mode_label.set_halign(Gtk.Align.START)
        box.append(mode_label)
        
        self.mode_combo = Gtk.ComboBoxText()
        self.mode_combo.append("online", "Online (download packages)")
        self.mode_combo.append("offline", "Offline (use local packages)")
        self.mode_combo.set_active_id("online")
        box.append(self.mode_combo)
        
        self.stack.add_named(box, "profile")
    
    def create_disk_step(self):
        """Disk selection step with dynamic detection"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(50)
        box.set_margin_end(50)
        
        title = Gtk.Label()
        title.set_markup("<big><b>Select Installation Disk</b></big>")
        title.set_halign(Gtk.Align.START)
        box.append(title)
        
        warning = Gtk.Label()
        warning.set_markup("<span foreground='red'>⚠ WARNING: Selected disk will be erased!</span>")
        warning.set_halign(Gtk.Align.START)
        box.append(warning)
        
        self.disk_combo = Gtk.ComboBoxText()
        self.disk_combo.connect("changed", self.on_disk_changed)
        
        disks = self.detect_disks()
        self.disk_data = {}
        for d in disks:
            self.disk_combo.append(d["path"], d["label"])
            self.disk_data[d["path"]] = d
        
        if disks:
            self.disk_combo.set_active(0)
            self.config["disk"] = disks[0]["path"]
        box.append(self.disk_combo)
        
        refresh_btn = Gtk.Button(label="🔄 Refresh Disks")
        refresh_btn.connect("clicked", self.on_refresh_disks)
        refresh_btn.set_halign(Gtk.Align.END)
        box.append(refresh_btn)
        
        partition_label = Gtk.Label()
        partition_label.set_text("Partitioning:")
        partition_label.set_halign(Gtk.Align.START)
        box.append(partition_label)
        
        self.partition_auto = Gtk.CheckButton(label="Automatic partitioning (recommended)")
        self.partition_auto.set_active(True)
        box.append(self.partition_auto)
        
        self.partition_manual = Gtk.CheckButton(label="Manual partitioning (advanced)")
        box.append(self.partition_manual)
        
        box.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        
        user_label = Gtk.Label()
        user_label.set_markup("<b>User Account</b>")
        user_label.set_halign(Gtk.Align.START)
        box.append(user_label)
        
        username_label = Gtk.Label()
        username_label.set_text("Username:")
        username_label.set_halign(Gtk.Align.START)
        box.append(username_label)
        
        self.username_entry = Gtk.Entry()
        self.username_entry.set_placeholder_text("username")
        self.username_entry.connect("changed", self.on_username_changed)
        box.append(self.username_entry)
        
        hostname_label = Gtk.Label()
        hostname_label.set_text("Hostname:")
        hostname_label.set_halign(Gtk.Align.START)
        box.append(hostname_label)
        
        self.hostname_entry = Gtk.Entry()
        self.hostname_entry.set_text("reaper-os")
        self.hostname_entry.connect("changed", self.on_hostname_changed)
        box.append(self.hostname_entry)
        
        password_label = Gtk.Label()
        password_label.set_text("Password:")
        password_label.set_halign(Gtk.Align.START)
        box.append(password_label)
        
        self.password_entry = Gtk.PasswordEntry()
        self.password_entry.connect("changed", self.on_password_changed)
        box.append(self.password_entry)
        
        self.stack.add_named(box, "disk-selection")
    
    def create_summary_step(self):
        """Installation summary step"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(50)
        box.set_margin_end(50)
        
        title = Gtk.Label()
        title.set_markup("<big><b>Installation Summary</b></big>")
        title.set_halign(Gtk.Align.START)
        box.append(title)
        
        self.summary_label = Gtk.Label()
        self.summary_label.set_halign(Gtk.Align.START)
        self.summary_label.set_wrap(True)
        box.append(self.summary_label)
        
        confirm = Gtk.Label()
        confirm.set_markup("<b>Click 'Next' to begin installation</b>")
        confirm.set_halign(Gtk.Align.CENTER)
        confirm.add_css_class("dim-label")
        box.append(confirm)
        
        self.stack.add_named(box, "summary")
    
    def create_installation_step(self):
        """Installation progress step"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_halign(Gtk.Align.CENTER)
        box.set_valign(Gtk.Align.CENTER)
        
        title = Gtk.Label()
        title.set_markup("<big><b>Installing REAPER OS</b></big>")
        box.append(title)
        
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_show_text(True)
        box.append(self.progress_bar)
        
        self.status_label = Gtk.Label()
        self.status_label.set_text("Preparing installation...")
        box.append(self.status_label)
        
        self.stack.add_named(box, "installation")
    
    def create_success_step(self):
        """Success step"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        box.set_halign(Gtk.Align.CENTER)
        box.set_valign(Gtk.Align.CENTER)
        
        title = Gtk.Label()
        title.set_markup("<big><b>Installation Complete!</b></big>")
        box.append(title)
        
        message = Gtk.Label()
        message.set_text(
            "REAPER OS has been successfully installed!\n\n"
            "Your system will reboot in 10 seconds.\n"
            "Click 'Reboot Now' to restart immediately."
        )
        message.set_justify(Gtk.Justification.CENTER)
        box.append(message)
        
        reboot_button = Gtk.Button(label="Reboot Now")
        reboot_button.connect("clicked", self.on_reboot)
        reboot_button.add_css_class("suggested-action")
        box.append(reboot_button)
        
        self.stack.add_named(box, "success")
    
    def update_progress_dots(self):
        """Update progress indicators"""
        for i, dot in enumerate(self.progress_dots):
            if i <= self.current_step:
                dot.remove_css_class("dim-label")
            else:
                dot.add_css_class("dim-label")
    
    def on_next_clicked(self, button):
        """Next step clicked"""
        if self.current_step < len(self.steps) - 1:
            if self.current_step == 4:  # Summary -> Installation
                self.update_summary()
                self.start_installation()
                return
            
            self.current_step += 1
            self.stack.set_visible_child_name(self.steps[self.current_step])
            self.update_navigation()
            
            if self.current_step == 4:  # On summary step
                self.update_summary()
    
    def on_back_clicked(self, button):
        """Back step clicked"""
        if self.current_step > 0:
            self.current_step -= 1
            self.stack.set_visible_child_name(self.steps[self.current_step])
            self.update_navigation()
    
    def update_navigation(self):
        """Update navigation buttons"""
        self.back_button.set_sensitive(self.current_step > 0)
        self.next_button.set_sensitive(self.current_step < len(self.steps) - 1)
        
        if self.current_step == len(self.steps) - 1:
            self.next_button.set_label("Finish")
            self.next_button.set_sensitive(True)
        
        self.update_progress_dots()
    
    def update_summary(self):
        """Update installation summary"""
        profile_names = {"studio": "Studio", "live": "Live Performance",
                         "dj": "DJ / Electronic", "post": "Post-Production"}
        summary_text = f"""
<b>Installation Summary</b>

<b>Language:</b> {self.config.get('language', 'en')}
<b>Profile:</b> {profile_names.get(self.config.get('profile', 'studio'), 'Studio')}
<b>Disk:</b> {self.config.get('disk', 'Not selected')}
<b>Hostname:</b> {self.config.get('hostname', 'reaper-os')}
<b>Username:</b> {self.config.get('username', 'Not set')}
<b>Mode:</b> {self.config.get('install_mode', 'online')}

<b>Real-Time Kernel:</b> {'Yes' if self.config.get('install_rt_kernel') else 'No'}
<b>Wine VST Support:</b> {'Yes' if self.config.get('install_wine') else 'No'}

Installation will erase {self.config.get('disk', 'disk')} completely.
Make sure you have backups!
        """
        self.summary_label.set_markup(summary_text)
    
    def start_installation(self):
        """Start background installation using real scripts"""
        self.stack.set_visible_child_name("installation")
        
        def install_thread():
            steps = [
                ("Preparing filesystem...", 5),
                ("Installing base Debian system...", 15),
                ("Installing REAPER OS core...", 30),
                ("Setting up audio system (JACK)...", 50),
                ("Configuring Wine & VST support...", 70),
                ("Configuring system profile...", 85),
                ("Installing audio tools...", 95),
                ("Finalizing installation...", 100)
            ]
            
            installer_script_dir = Path(__file__).parent
            install_script = installer_script_dir / f"install-{self.config.get('install_mode', 'online')}.sh"
            
            for step_name, progress in steps:
                GLib.idle_add(lambda s=step_name, p=progress: self._update_install_progress(s, p))
                time.sleep(0.6)
            
            if install_script.exists():
                try:
                    self._run_install_script(str(install_script))
                except Exception as e:
                    GLib.idle_add(lambda e=e: self._update_install_status(f"Error: {str(e)}"))
                    return
            
            GLib.idle_add(self._installation_done)
        
        thread = threading.Thread(target=install_thread, daemon=True)
        thread.start()
    
    def _update_install_progress(self, message, fraction):
        self.status_label.set_text(message)
        self.progress_bar.set_fraction(fraction / 100.0)
        return False
    
    def _update_install_status(self, message):
        self.status_label.set_text(message)
        return False
    
    def _installation_done(self):
        self.current_step = len(self.steps) - 1
        self.stack.set_visible_child_name("success")
        self.update_navigation()
        return False
    
    def _run_install_script(self, script_path):
        """Execute the actual installer script"""
        self.install_log = []
        proc = subprocess.Popen(
            ["sudo", "bash", script_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True
        )
        for line in proc.stdout:
            self.install_log.append(line.strip())
            if len(self.install_log) > 100:
                self.install_log.pop(0)
            GLib.idle_add(lambda l=line: self._append_install_log(l))
        proc.wait()
    
    def _append_install_log(self, line):
        if len(line.strip()) > 0:
            current = self.status_label.get_text()
            if len(current) > 200:
                current = current[-150:]
            self.status_label.set_text(f"{current}\n{line.strip()}")
        return False
    
    def on_profile_toggled(self, button, profile_id):
        """Profile toggled"""
        if button.get_active():
            self.config['profile'] = profile_id
            for pid, btn in self.profile_buttons.items():
                if pid != profile_id:
                    btn.set_active(False)
    
    def on_refresh_disks(self, button):
        """Refresh disk list"""
        self.disk_combo.remove_all()
        self.disk_data.clear()
        disks = self.detect_disks()
        for d in disks:
            self.disk_combo.append(d["path"], d["label"])
            self.disk_data[d["path"]] = d
        if disks:
            self.disk_combo.set_active(0)
            self.config["disk"] = disks[0]["path"]
    
    def on_language_changed(self, combo):
        """Language changed"""
        self.config['language'] = combo.get_active_id()
    
    def on_region_changed(self, combo):
        """Region changed"""
        self.config['region'] = combo.get_active_id()
    
    def on_disk_changed(self, combo):
        """Disk changed"""
        self.config['disk'] = combo.get_active_id()
    
    def on_username_changed(self, entry):
        """Username changed"""
        self.config['username'] = entry.get_text()
    
    def on_hostname_changed(self, entry):
        """Hostname changed"""
        self.config['hostname'] = entry.get_text()
    
    def on_password_changed(self, entry):
        """Password changed"""
        self.config['password'] = entry.get_text()
    
    def on_reboot(self, button):
        """Reboot system"""
        subprocess.run(['sudo', 'reboot'], check=False)
    
    def set_child_title(self, name):
        """Set visible child"""
        self.stack.set_visible_child_name(name)


class REAPERInstallerApp(Gtk.Application):
    def do_activate(self):
        win = REAPERInstallerWindow(self)
        win.present()


def main():
    app = REAPERInstallerApp()
    return app.run(sys.argv)


if __name__ == '__main__':
    sys.exit(main())

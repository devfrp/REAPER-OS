#!/usr/bin/env python3
"""
REAPER OS GUI Installer
Interactive graphical installation wizard
"""

import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, GdkPixbuf, Gio
import sys
import subprocess
import threading
from pathlib import Path

class REAPERInstallerWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title("REAPER OS Installer")
        self.set_default_size(800, 600)
        self.set_resizable(False)
        
        # Current step
        self.current_step = 0
        self.steps = [
            "welcome",
            "language",
            "region",
            "disk-selection",
            "summary",
            "installation",
            "success"
        ]
        
        # Configuration
        self.config = {
            "language": "en",
            "region": "US",
            "disk": "",
            "username": "",
            "hostname": "reaper-os"
        }
        
        self.build_ui()
    
    def build_ui(self):
        """Build main UI"""
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_top(10)
        main_box.set_margin_bottom(10)
        main_box.set_margin_start(10)
        main_box.set_margin_end(10)
        
        # Header
        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=20)
        
        # Logo/Icon (optionnel)
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
        
        # Title
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
        
        # Separator
        main_box.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        
        # Steps stack
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(300)
        
        # Create steps
        self.create_welcome_step()
        self.create_language_step()
        self.create_region_step()
        self.create_disk_step()
        self.create_summary_step()
        self.create_installation_step()
        self.create_success_step()
        
        main_box.append(self.stack)
        
        # Navigation buttons
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
        
        # Progress indicator
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
        title.set_markup("<big><b>Select Language</b></big>")
        title.set_halign(Gtk.Align.START)
        box.append(title)
        
        languages = [
            ("English", "en"),
            ("Français", "fr"),
            ("Español", "es"),
            ("Deutsch", "de")
        ]
        
        self.lang_combo = Gtk.ComboBoxText()
        for lang_name, lang_code in languages:
            self.lang_combo.append(lang_code, lang_name)
        self.lang_combo.set_active_id("en")
        self.lang_combo.connect("changed", self.on_language_changed)
        box.append(self.lang_combo)
        
        self.stack.add_named(box, "language")
    
    def create_region_step(self):
        """Region selection step"""
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=15)
        box.set_margin_start(50)
        box.set_margin_end(50)
        
        title = Gtk.Label()
        title.set_markup("<big><b>Select Region & Timezone</b></big>")
        title.set_halign(Gtk.Align.START)
        box.append(title)
        
        # Region combo
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
        
        # Keyboard layout
        label = Gtk.Label()
        label.set_text("Keyboard Layout:")
        label.set_halign(Gtk.Align.START)
        box.append(label)
        
        self.keyboard_combo = Gtk.ComboBoxText()
        keyboards = ["QWERTY", "AZERTY", "QWERTZ", "Other"]
        for kb in keyboards:
            self.keyboard_combo.append(kb.lower(), kb)
        self.keyboard_combo.set_active_id("qwerty")
        box.append(self.keyboard_combo)
        
        self.stack.add_named(box, "region")
    
    def create_disk_step(self):
        """Disk selection step"""
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
        
        # Disk list (would be populated dynamically)
        self.disk_combo = Gtk.ComboBoxText()
        self.disk_combo.append("sda", "/dev/sda (1TB)")
        self.disk_combo.append("sdb", "/dev/sdb (500GB)")
        self.disk_combo.set_active_id("sda")
        self.disk_combo.connect("changed", self.on_disk_changed)
        box.append(self.disk_combo)
        
        # Partitioning options
        label = Gtk.Label()
        label.set_text("Partitioning:")
        label.set_halign(Gtk.Align.START)
        box.append(label)
        
        self.partition_auto = Gtk.CheckButton(label="Automatic partitioning")
        self.partition_auto.set_active(True)
        box.append(self.partition_auto)
        
        self.partition_manual = Gtk.CheckButton(label="Manual partitioning")
        box.append(self.partition_manual)
        
        # User info
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
            if self.current_step == 4:  # Before installation
                self.update_summary()
                self.start_installation()
            
            self.current_step += 1
            self.stack.set_visible_child_name(self.steps[self.current_step])
            self.update_navigation()
    
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
        summary_text = f"""
<b>Installation Summary</b>

<b>Language:</b> {self.config['language']}
<b>Region:</b> {self.config['region']}
<b>Disk:</b> {self.config['disk']}
<b>Username:</b> {self.config['username']}

Installation will erase {self.config['disk']} completely.
Make sure you have backups!
        """
        self.summary_label.set_markup(summary_text)
    
    def start_installation(self):
        """Start background installation"""
        self.set_child_title("installation")
        
        def install_thread():
            try:
                # Simulate installation steps
                steps = [
                    ("Preparing filesystem", 10),
                    ("Installing base system", 30),
                    ("Installing REAPER", 50),
                    ("Setting up audio system", 70),
                    ("Configuring Wine/VST", 85),
                    ("Final touches", 95),
                    ("Completing installation", 100)
                ]
                
                for step_name, progress in steps:
                    self.status_label.set_text(step_name)
                    self.progress_bar.set_fraction(progress / 100.0)
                    
                    import time
                    time.sleep(1)  # Simulate work
                
                # Move to success
                self.current_step += 1
                self.stack.set_visible_child_name("success")
                
            except Exception as e:
                self.status_label.set_text(f"Error: {str(e)}")
        
        # Run installation in background
        thread = threading.Thread(target=install_thread, daemon=True)
        thread.start()
    
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

#!/usr/bin/env python3
"""
REAPER OS Audio Profile Manager GUI
Switch between audio profiles with visual interface
"""

import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, GLib
import json
import subprocess
from pathlib import Path
from datetime import datetime

class AudioProfileManager(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title("Audio Profile Manager")
        self.set_default_size(600, 500)
        
        self.config_dir = Path.home() / ".config" / "reaper-audio-profiles"
        self.current_profile = None
        
        self.build_ui()
        self.load_profiles()
        self.setup_system_tray()
    
    def build_ui(self):
        """Build UI"""
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        main_box.set_margin_top(10)
        main_box.set_margin_bottom(10)
        main_box.set_margin_start(10)
        main_box.set_margin_end(10)
        
        # Header
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        title = Gtk.Label()
        title.set_markup("<big><b>Audio Profiles</b></big>")
        header_box.append(title)
        main_box.append(header_box)
        
        # Quick presets
        self.create_quick_presets(main_box)
        
        # Separator
        main_box.append(Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL))
        
        # Profile list with scroll
        scroll = Gtk.ScrolledWindow()
        scroll.set_child(self.create_profile_list())
        scroll.set_vexpand(True)
        main_box.append(scroll)
        
        # Buttons bar
        button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=5)
        
        refresh_button = Gtk.Button(label="🔄 Refresh")
        refresh_button.connect("clicked", self.on_refresh)
        button_box.append(refresh_button)
        
        new_button = Gtk.Button(label="➕ New")
        new_button.connect("clicked", self.on_new_profile)
        button_box.append(new_button)
        
        edit_button = Gtk.Button(label="✏️ Edit")
        edit_button.connect("clicked", self.on_edit_profile)
        button_box.append(edit_button)
        
        delete_button = Gtk.Button(label="🗑️ Delete")
        delete_button.connect("clicked", self.on_delete_profile)
        button_box.append(delete_button)
        
        main_box.append(button_box)
        
        # Status bar
        self.status_label = Gtk.Label()
        self.status_label.set_halign(Gtk.Align.START)
        self.status_label.set_text("Ready")
        self.status_label.add_css_class("dim-label")
        main_box.append(self.status_label)
        
        self.set_child(main_box)
    
    def create_quick_presets(self, parent):
        """Create quick preset buttons"""
        presets_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        presets_box.set_halign(Gtk.Align.CENTER)
        
        presets = [
            ("🎙️ Studio", "studio"),
            ("🎪 Live", "live"),
            ("🎙️ Podcast", "podcast")
        ]
        
        for label, profile_id in presets:
            button = Gtk.Button(label=label)
            button.connect("clicked", lambda b, p=profile_id: self.load_profile(p))
            button.add_css_class("pill")
            presets_box.append(button)
        
        parent.append(presets_box)
    
    def create_profile_list(self):
        """Create profile list view"""
        # List store: Profile Name, Status, Modified Date
        store = Gtk.ListStore(str, str, str, str)  # name, status, date, id
        
        # Tree view
        tree = Gtk.TreeView(model=store)
        tree.set_headers_visible(True)
        tree.set_search_column(0)
        
        # Columns
        col1 = Gtk.TreeViewColumn("Profile")
        col1.set_expand(True)
        cell1 = Gtk.CellRendererText()
        col1.pack_start(cell1, True)
        col1.add_attribute(cell1, "text", 0)
        tree.append_column(col1)
        
        col2 = Gtk.TreeViewColumn("Status")
        cell2 = Gtk.CellRendererText()
        col2.pack_start(cell2, True)
        col2.add_attribute(cell2, "text", 1)
        tree.append_column(col2)
        
        col3 = Gtk.TreeViewColumn("Modified")
        cell3 = Gtk.CellRendererText()
        col3.pack_start(cell3, True)
        col3.add_attribute(cell3, "text", 2)
        tree.append_column(col3)
        
        tree.connect("row-activated", self.on_profile_double_click)
        
        self.profile_store = store
        self.profile_tree = tree
        
        return tree
    
    def load_profiles(self):
        """Load profiles from disk"""
        self.profile_store.clear()
        
        if not self.config_dir.exists():
            self.config_dir.mkdir(parents=True, exist_ok=True)
            return
        
        for profile_file in self.config_dir.glob("*.json"):
            try:
                with open(profile_file) as f:
                    data = json.load(f)
                
                profile_name = data.get("name", profile_file.stem)
                is_active = "✓ Active" if data.get("active") else ""
                modified = data.get("modified", "Unknown")
                
                self.profile_store.append([
                    profile_name,
                    is_active,
                    modified,
                    profile_file.stem
                ])
            
            except Exception as e:
                print(f"Error loading profile {profile_file}: {e}")
    
    def load_profile(self, profile_id):
        """Load a profile"""
        profile_file = self.config_dir / f"{profile_id}.json"
        
        if not profile_file.exists():
            self.show_error(f"Profile not found: {profile_id}")
            return
        
        try:
            # Run audio-config-manager to load profile
            result = subprocess.run(
                ["bash", "tools/audio-config-manager.sh", "load", profile_id],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                self.status_label.set_text(f"✓ Loaded profile: {profile_id}")
                self.load_profiles()
            else:
                self.show_error(f"Failed to load profile: {result.stderr}")
        
        except Exception as e:
            self.show_error(f"Error: {str(e)}")
    
    def on_refresh(self, button):
        """Refresh profiles"""
        self.load_profiles()
        self.status_label.set_text("✓ Refreshed")
    
    def on_new_profile(self, button):
        """Create new profile"""
        dialog = Gtk.Dialog(
            title="New Audio Profile",
            transient_for=self,
            modal=True,
            destroy_with_parent=True
        )
        
        dialog.add_buttons(
            Gtk.ResponseType.CANCEL, "Cancel",
            Gtk.ResponseType.OK, "Create"
        )
        
        content = dialog.get_content_area()
        content.set_spacing(10)
        
        # Profile name
        label = Gtk.Label(label="Profile Name:")
        label.set_halign(Gtk.Align.START)
        content.append(label)
        
        entry = Gtk.Entry()
        entry.set_placeholder_text("e.g., studio-setup, live-gig")
        content.append(entry)
        
        dialog.connect("response", self.on_new_profile_response, entry)
        dialog.present()
    
    def on_new_profile_response(self, dialog, response_id, entry):
        """Handle new profile dialog"""
        if response_id == Gtk.ResponseType.OK:
            profile_name = entry.get_text()
            if profile_name:
                try:
                    # Create profile
                    profile_data = {
                        "name": profile_name,
                        "created": datetime.now().isoformat(),
                        "modified": datetime.now().isoformat(),
                        "active": False,
                        "jack_config": {},
                        "alsa_config": {}
                    }
                    
                    profile_file = self.config_dir / f"{profile_name.lower()}.json"
                    with open(profile_file, 'w') as f:
                        json.dump(profile_data, f, indent=2)
                    
                    self.status_label.set_text(f"✓ Created profile: {profile_name}")
                    self.load_profiles()
                
                except Exception as e:
                    self.show_error(f"Error creating profile: {str(e)}")
        
        dialog.close()
    
    def on_edit_profile(self, button):
        """Edit selected profile"""
        selection = self.profile_tree.get_selection()
        tree_iter = selection.get_selected()[1]
        
        if tree_iter:
            profile_id = self.profile_store.get_value(tree_iter, 3)
            # Would open profile editor
            self.status_label.set_text(f"Edit: {profile_id}")
    
    def on_delete_profile(self, button):
        """Delete selected profile"""
        selection = self.profile_tree.get_selection()
        tree_iter = selection.get_selected()[1]
        
        if tree_iter:
            profile_name = self.profile_store.get_value(tree_iter, 0)
            profile_id = self.profile_store.get_value(tree_iter, 3)
            
            # Confirmation dialog
            dialog = Gtk.MessageDialog(
                transient_for=self,
                flags=0,
                message_type=Gtk.MessageType.WARNING,
                buttons=Gtk.ButtonsType.OK_CANCEL,
                text="Delete Profile?"
            )
            dialog.format_secondary_text(f"Delete '{profile_name}'?")
            
            response = dialog.run()
            dialog.close()
            
            if response == Gtk.ResponseType.OK:
                try:
                    profile_file = self.config_dir / f"{profile_id}.json"
                    profile_file.unlink()
                    self.status_label.set_text(f"✓ Deleted profile: {profile_name}")
                    self.load_profiles()
                except Exception as e:
                    self.show_error(f"Error deleting profile: {str(e)}")
    
    def on_profile_double_click(self, treeview, path, column):
        """Double-click to load profile"""
        tree_iter = self.profile_store.get_iter(path)
        profile_id = self.profile_store.get_value(tree_iter, 3)
        self.load_profile(profile_id)
    
    def setup_system_tray(self):
        """Setup system tray integration"""
        # This would integrate with system tray in Xfce/Gnome
        # For now, just minimize to tray capability
        pass
    
    def show_error(self, message):
        """Show error dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            flags=0,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text="Error"
        )
        dialog.format_secondary_text(message)
        dialog.run()
        dialog.close()


class AudioProfileApp(Gtk.Application):
    def do_activate(self):
        win = AudioProfileManager(self)
        win.present()


def main():
    import sys
    app = AudioProfileApp()
    return app.run(sys.argv)


if __name__ == '__main__':
    import sys
    exit(main())

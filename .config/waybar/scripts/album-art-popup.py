#!/usr/bin/env python3
"""Album art popup with playback controls on hover."""
import os
import sys
import subprocess
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GdkPixbuf", "2.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Pango, PangoCairo

GLib.set_prgname("album-art-popup")

ART_FILE = "/tmp/waybar-album-art.png"
APP_ID = "album-art-popup"


def playerctl(cmd):
    subprocess.Popen(
        ["playerctl", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )


def get_playback_status():
    try:
        result = subprocess.run(
            ["playerctl", "status"], capture_output=True, text=True, timeout=1
        )
        return result.stdout.strip().lower()
    except Exception:
        return "stopped"


class AlbumArtPopup(Gtk.Window):
    def __init__(self, size):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)
        self.set_title(APP_ID)
        self.set_app_paintable(True)
        self.set_decorated(False)
        self.set_resizable(True)
        self.set_default_size(size, size)
        self.size = size
        self._controls_visible = False

        # Transparent background for rounded corners
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)

        # Drawing area for full control
        self.drawing_area = Gtk.DrawingArea()
        self.drawing_area.set_size_request(size, size)
        self.drawing_area.connect("draw", self.on_draw)

        # Event box for pointer events
        event_box = Gtk.EventBox()
        event_box.add(self.drawing_area)
        event_box.set_events(
            Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK
            | Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.POINTER_MOTION_MASK
        )
        event_box.connect("enter-notify-event", self.on_enter)
        event_box.connect("leave-notify-event", self.on_leave)
        event_box.connect("button-press-event", self.on_click)
        event_box.connect("motion-notify-event", self.on_motion)
        self.add(event_box)

        # Load art
        self._art_mtime = 0
        self._pixbuf = None
        self.load_art()

        # Button definitions (Nerd Font FA icons)
        self.buttons = [
            {"icon": "\uf04a", "cmd": "previous", "hover": False},
            {"icon": "\uf04c", "cmd": "play-pause", "hover": False},
            {"icon": "\uf04e", "cmd": "next", "hover": False},
        ]
        self._pause_icon = "\uf04c"
        self._play_icon = "\uf04b"

        # Watch for art file changes and playback status
        GLib.timeout_add(1000, self.check_art_update)
        GLib.timeout_add(500, self.update_play_icon)

    def load_art(self):
        try:
            self._pixbuf_full = GdkPixbuf.Pixbuf.new_from_file(ART_FILE)
            self._pixbuf = None  # will be scaled in on_draw
            self._art_mtime = self._get_mtime()
            self.drawing_area.queue_draw()
        except Exception:
            self._pixbuf_full = None
            self._pixbuf = None
            self._art_mtime = 0

    def _get_mtime(self):
        try:
            return os.path.getmtime(ART_FILE)
        except Exception:
            return 0

    def check_art_update(self):
        mtime = self._get_mtime()
        if mtime != self._art_mtime:
            self.load_art()
        return True

    def update_play_icon(self):
        status = get_playback_status()
        self.buttons[1]["icon"] = self._pause_icon if status == "playing" else self._play_icon
        if self._controls_visible:
            self.drawing_area.queue_draw()
        return True

    def _get_button_rects(self):
        alloc = self.drawing_area.get_allocation()
        cur_size = min(alloc.width, alloc.height)
        btn_size = max(32, cur_size // 8)
        spacing = max(16, cur_size // 16)
        total_w = btn_size * 3 + spacing * 2
        start_x = (alloc.width - total_w) // 2
        y = alloc.height - btn_size - max(12, cur_size // 20)
        rects = []
        for i in range(3):
            bx = start_x + i * (btn_size + spacing)
            rects.append((bx, y, btn_size, btn_size))
        return rects

    def on_enter(self, widget, event):
        self._controls_visible = True
        self.drawing_area.queue_draw()

    def on_leave(self, widget, event):
        # Ignore synthetic leave events from button grabs
        if event.detail == Gdk.NotifyType.INFERIOR or event.mode != Gdk.CrossingMode.NORMAL:
            return
        self._controls_visible = False
        for btn in self.buttons:
            btn["hover"] = False
        self.drawing_area.queue_draw()

    def on_motion(self, widget, event):
        if not self._controls_visible:
            return
        rects = self._get_button_rects()
        changed = False
        for i, (bx, by, bw, bh) in enumerate(rects):
            was = self.buttons[i]["hover"]
            self.buttons[i]["hover"] = (
                bx <= event.x <= bx + bw and by <= event.y <= by + bh
            )
            if was != self.buttons[i]["hover"]:
                changed = True
        if changed:
            self.drawing_area.queue_draw()

    def on_click(self, widget, event):
        if not self._controls_visible:
            return
        rects = self._get_button_rects()
        for i, (bx, by, bw, bh) in enumerate(rects):
            if bx <= event.x <= bx + bw and by <= event.y <= by + bh:
                playerctl(self.buttons[i]["cmd"])
                if self.buttons[i]["cmd"] == "play-pause":
                    GLib.timeout_add(100, self.update_play_icon)
                return

    def on_draw(self, widget, cr):
        import math

        alloc = widget.get_allocation()
        w, h = alloc.width, alloc.height

        # Draw album art scaled to current window size
        if self._pixbuf_full:
            scaled = self._pixbuf_full.scale_simple(w, h, GdkPixbuf.InterpType.BILINEAR)
            if scaled:
                Gdk.cairo_set_source_pixbuf(cr, scaled, 0, 0)
                cr.paint()

        # Draw controls overlay on hover
        if self._controls_visible:
            import cairo

            # Gradient from bottom
            grad = cairo.LinearGradient(0, h * 0.5, 0, h)
            grad.add_color_stop_rgba(0, 0, 0, 0, 0)
            grad.add_color_stop_rgba(1, 0, 0, 0, 0.7)
            cr.set_source(grad)
            cr.rectangle(0, h * 0.5, w, h * 0.5)
            cr.fill()

            # Draw buttons
            rects = self._get_button_rects()
            for i, (bx, by, bw, bh) in enumerate(rects):
                btn = self.buttons[i]
                btn_radius = bw / 2

                # Button circle
                cr.arc(bx + btn_radius, by + btn_radius, btn_radius, 0, 2 * math.pi)
                if btn["hover"]:
                    cr.set_source_rgba(0.1, 0.1, 0.15, 0.9)
                else:
                    cr.set_source_rgba(0.1, 0.1, 0.15, 0.7)
                cr.fill()

                # Button icon (Pango for proper Nerd Font rendering)
                cr.set_source_rgba(
                    0.66, 0.69, 0.84, 1.0 if btn["hover"] else 0.85
                )
                layout = PangoCairo.create_layout(cr)
                font_size = max(12, min(w, h) // 20)
                font_desc = Pango.FontDescription(f"JetBrainsMono Nerd Font Propo {font_size}")
                layout.set_font_description(font_desc)
                layout.set_text(btn["icon"], -1)
                ink, logical = layout.get_pixel_extents()
                tx = bx + (bw - logical.width) / 2
                ty = by + (bh - logical.height) / 2
                cr.move_to(tx, ty)
                PangoCairo.show_layout(cr, layout)

        return True


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <size>", file=sys.stderr)
        sys.exit(1)

    size = int(sys.argv[1])
    win = AlbumArtPopup(size)
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()

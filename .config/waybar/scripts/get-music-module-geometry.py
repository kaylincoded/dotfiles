#!/usr/bin/env python3
"""Get the geometry of the waybar music module via AT-SPI."""
import gi
gi.require_version("Atspi", "2.0")
from gi.repository import Atspi

desktop = Atspi.get_desktop(0)
for i in range(desktop.get_child_count()):
    app = desktop.get_child_at_index(i)
    if "waybar" not in app.get_name().lower():
        continue
    frame = app.get_child_at_index(0)
    bar = frame.get_child_at_index(0)
    right = bar.get_child_at_index(2)  # modules-right
    for j in range(right.get_child_count()):
        panel = right.get_child_at_index(j)
        # Music module has a marquee label with track info — it's the widest panel
        try:
            iface = panel.get_component_iface()
            ext = iface.get_extents(Atspi.CoordType.SCREEN)
            if ext.width > 100:  # music module is the only wide one in modules-right
                print(f"{ext.x} {ext.y} {ext.width} {ext.height}")
                break
        except Exception:
            pass

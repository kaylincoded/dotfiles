<h1 align="center">
  <br>
  <code>~/.config</code>
  <br>
</h1>

<p align="center">
  <b>kaylin's dotfiles</b> — hyprland rice on arch, tuned for daily use.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WM-Hyprland-b4befe?style=flat-square" />
  <img src="https://img.shields.io/badge/OS-Arch_Linux-1793d1?style=flat-square&logo=archlinux&logoColor=white" />
  <img src="https://img.shields.io/badge/Bar-Waybar-cba6f7?style=flat-square" />
  <img src="https://img.shields.io/badge/Terminal-Ghostty-89dceb?style=flat-square" />
</p>

---

## What's Inside

```
.config/
├── hypr/              # hyprland wm — bindings, layout, look & feel
│   ├── hyprland.conf        main config, sources everything below
│   ├── bindings.conf        keybinds
│   ├── looknfeel.conf       borders, rounding, gaps
│   ├── monitors.conf        display setup (2560×1440 @ 180hz)
│   ├── input.conf           keyboard & touchpad
│   ├── autostart.conf       startup apps
│   ├── hypridle.conf        idle/lock timeouts
│   ├── hyprlock.conf        lock screen
│   └── ...
├── waybar/            # status bar — custom styling + album art popup
│   ├── config.jsonc         modules & layout
│   ├── style.css            rounded containers, hover glow
│   └── scripts/             album art toggle & live updater
├── ghostty/           # terminal emulator
├── walker/            # app launcher
├── waypaper/          # wallpaper manager (mpvpaper backend)
└── btop/              # system monitor
```

## Highlights

- **Rounded everything** — 18px corners on windows, bar modules, and launcher
- **Gradient borders** — ice blue `#89dceb` → lavender `#b4befe` → mauve `#cba6f7` at 45°
- **Waybar styling** — semi-transparent pill modules with subtle borders and smooth hover transitions
- **Album art popup** — right-click the now-playing module to toggle a pinned album art window that updates live on track change
- **Video wallpapers** — via mpvpaper, persisted across reboots with waypaper

## Setup

```bash
git clone git@github.com:kaylincoded/dotfiles.git
```

Copy what you need into `~/.config/`. These configs assume:

- [Hyprland](https://hyprland.org) as the compositor
- [Waybar](https://github.com/Alexays/Waybar) for the bar
- [Ghostty](https://ghostty.org) as the terminal
- [Walker](https://github.com/abenz1267/walker) as the launcher
- [waypaper](https://github.com/anufrievroman/waypaper) + [mpvpaper](https://github.com/GhostNaN/mpvpaper) for wallpapers
- [playerctl](https://github.com/altdesktop/playerctl) for the album art scripts
- [JetBrainsMono Nerd Font](https://www.nerdfonts.com/)
- An [omarchy](https://omarchy.com) base install (theme colors, menu scripts)

## License

Do whatever you want with these. It's just config files.

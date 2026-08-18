# dotfilestw 🌇

![](screenshots/desktop.png)
![](screenshots/rofi.png)
![](screenshots/split-terminals.png)

My personal Arch Linux rice: i3wm + Alacritty + picom + dunst, tied together with
[herdr](https://herdr.dev) as a terminal workspace manager instead of tmux.

## Installation

### ⚠️ Requirements ⚠️

**Arch Linux** with **Xorg** and **i3wm** installed.

### Steps

1. Install git:

    ```bash
    sudo pacman -S git
    ```

2. Clone the repository:

    ```bash
    cd $HOME
    git clone --depth 1 https://github.com/luqastw/dotfilestw
    cd dotfilestw
    ```

3. Run the installer:

    ```bash
    ./INSTALL.sh
    ```

    This installs the pacman + AUR dependencies, herdr, and symlinks every config
    folder into `~/.config` (backing up anything already there). You can also run
    a single step:

    ```bash
    ./INSTALL.sh deps      # dependencies only
    ./INSTALL.sh configs   # symlink configs only
    ./INSTALL.sh help      # usage
    ```

---

For additional details or troubleshooting, visit the [issues page](https://github.com/luqastw/dotfilestw/issues).

---

## Keybinds

### ⚡ Launch Applications

| Action              | Keybind             | Description                    |
|----------------------|----------------------|---------------------------------|
| Terminal             | `SUPER + RETURN`     | Launch Alacritty                |
| App Launcher         | `SUPER + D`          | Launch rofi (`drun`)            |

---

### 🧰 System Scripts

| Action                    | Keybind                  | Description                          |
|----------------------------|----------------------------|----------------------------------------|
| Screenshot (full, clipboard) | `SUPER + F11`            | Copy full screenshot via maim + xclip, notify-send confirms |
| Screenshot (select, clipboard) | `SUPER + SHIFT + F11`  | Copy selected-area screenshot         |
| Screenshot (scrot)         | `SUPER + Z` then `S`      | Enter special mode, take scrot -s     |
| Toggle Scratchpad Terminal  | `SUPER + minus`          | Show/hide dropdown Alacritty (auto-spawns) |
| Stash Window to Scratchpad  | `SUPER + SHIFT + minus`  | Move focused window to the general scratchpad pool |
| Cycle Scratchpad Pool       | `SUPER + equal`          | Show next stashed scratchpad window |
| Power Menu                | Click power block on bar  | Runs `power_dmenu.sh` (rofi: lock/exit/suspend/reboot/shutdown) |
| Wifi Toggle / Manage       | Click / right-click wifi block on bar | Toggles radio via nmcli, right-click opens `nmtui` |
| Bluetooth Toggle / Manage  | Click / right-click BT block on bar | Toggles power via bluetoothctl, right-click opens `blueman-manager` |
| Volume Up/Down/Mute        | `XF86AudioRaiseVolume` / `LowerVolume` / `Mute` | Adjusts volume via pactl |

---

### 🪟 Window Actions

| Action           | Keybind                | Description                        |
|-------------------|--------------------------|--------------------------------------|
| Kill Window       | `SUPER + C`              | Close the focused window            |
| Toggle Floating   | `SUPER + SHIFT + SPACE`  | Toggle floating for active window   |
| Toggle Focus Mode | `SUPER + SPACE`          | Toggle focus between tiling/floating|
| Fullscreen        | `SUPER + F`              | Toggle fullscreen mode              |
| Focus Parent      | `SUPER + A`              | Focus the parent container          |
| Stacking Layout   | `SUPER + S`              | Set stacking layout                 |
| Tabbed Layout     | `SUPER + W`              | Set tabbed layout                   |
| Toggle Split      | `SUPER + E`              | Toggle split orientation            |
| Split Vertical    | `SUPER + V`              | Split container vertically          |
| Split Horizontal  | `SUPER + SHIFT + V`      | Split container horizontally        |

---

### 📌 Window Focus

Use `SUPER + [key]` to change focus between windows (HJKL navigation):

| Direction | Keybind       |
|-----------|---------------|
| Left      | `SUPER + H`   |
| Right     | `SUPER + L`   |
| Up        | `SUPER + K`   |
| Down      | `SUPER + J`   |

---

### 🪟 Move Window

Use `SUPER + SHIFT + [key]` to move the focused window:

| Direction | Keybind             |
|-----------|----------------------|
| Left      | `SUPER + SHIFT + H`  |
| Right     | `SUPER + SHIFT + L`  |
| Up        | `SUPER + SHIFT + K`  |
| Down      | `SUPER + SHIFT + J`  |

---

### 📏 Resize Mode

Press `SUPER + R` to enter resize mode, then:

| Direction    | Keybind |
|---------------|---------|
| Shrink width  | `L`     |
| Expand width  | `H`     |
| Grow height   | `K`     |
| Shrink height | `J`     |

Exit with `Enter`, `Escape`, or `SUPER + R`.

---

### 🔢 Workspaces

| Action                       | Keybind                                  |
|-------------------------------|--------------------------------------------|
| Switch to workspace 1-10      | `SUPER + Y/U/I/O/P` (1-5), `SUPER + 6-0` (6-10) |
| Move window to workspace 1-10 | `SUPER + SHIFT +` same keys                |

---

### 🌀 i3 Session

| Action        | Keybind             |
|----------------|------------------------|
| Reload config  | `SUPER + SHIFT + C`   |
| Restart i3     | `SUPER + SHIFT + R`   |
| Exit i3        | `SUPER + SHIFT + E`   |

---

### 🧵 herdr

Prefix key is `F12`.

| Action         | Keybind          |
|-----------------|--------------------|
| Toggle sidebar  | `F12` then `P`    |
| Previous tab    | `F12` then `B`    |

---

## Notes

- `SUPER` is `Mod4` (the Windows/Command key).
- Window focus/movement uses HJKL, VIM-style directional navigation.
- herdr replaces tmux as the terminal multiplexer/workspace manager in this setup.

---

## Details

- OS: **[Arch Linux](https://archlinux.org)**
- WM: **[i3wm](https://github.com/i3/i3)**
- Bar: **[i3blocks](https://github.com/vivien/i3blocks)**
- Terminal: **[Alacritty](https://github.com/alacritty/alacritty)**
- Terminal workspace manager: **[herdr](https://herdr.dev)**
- Compositor: **[picom](https://github.com/yshui/picom)**
- Notifications: **[dunst](https://github.com/dunst-project/dunst)**
- Launcher: **[rofi](https://github.com/davatorium/rofi)**
- Wallpaper: **[nitrogen](https://github.com/l3ib/nitrogen)**
- Editor: **[Neovim](https://github.com/neovim/neovim)** ([LazyVim](https://github.com/LazyVim/LazyVim))
- System info: **[fastfetch](https://github.com/fastfetch-cli/fastfetch)**
- Icons/Cursor: **Papirus-Dark** / **Bibata-Modern-Ice**

## Screenshots

![](screenshots/desktop.png)
![](screenshots/rofi.png)
![](screenshots/split-terminals.png)

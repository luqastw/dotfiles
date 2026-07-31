# dotfilestw 🌇

![](screenshots/desktop.png)
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
    ```

3. Install the official-repo dependencies:

    ```bash
    sudo pacman -S --needed i3-wm i3blocks i3lock alacritty picom dunst dex xss-lock \
      network-manager-applet unclutter dmenu maim xclip scrot thunar kwallet \
      polkit-kde-agent sysstat libpulse acpi xorg-xrdb xorg-xinput neovim fastfetch \
      ttf-jetbrains-mono-nerd papirus-icon-theme
    ```

4. Install the AUR dependencies (via `yay`, `paru`, or your helper of choice):

    ```bash
    yay -S --needed betterlockscreen nitrogen fcitx bibata-cursor-theme
    ```

5. Install herdr (not packaged in pacman/AUR, uses its own installer):

    ```bash
    curl -fsSL https://herdr.dev/install.sh | sh
    ```

6. Copy (or symlink) each folder into `~/.config/`, e.g.:

    ```bash
    cd dotfilestw
    cp -r i3 i3blocks alacritty picom.conf dunst gtk-3.0 gtk-4.0 herdr nitrogen nvim ~/.config/
    ```

---

For additional details or troubleshooting, visit the [issues page](https://github.com/luqastw/dotfilestw/issues).

---

## Keybinds

### ⚡ Launch Applications

| Action              | Keybind             | Description                    |
|----------------------|----------------------|---------------------------------|
| Terminal             | `SUPER + RETURN`     | Launch Alacritty                |
| App Launcher         | `SUPER + D`          | Launch dmenu                    |

---

### 🧰 System Scripts

| Action                    | Keybind                  | Description                          |
|----------------------------|----------------------------|----------------------------------------|
| Screenshot (full, clipboard) | `SUPER + F11`            | Copy full screenshot via maim + xclip |
| Screenshot (select, clipboard) | `SUPER + SHIFT + F11`  | Copy selected-area screenshot         |
| Screenshot (scrot)         | `SUPER + Z` then `S`      | Enter special mode, take scrot -s     |
| Power Menu                | Click power block on bar  | Runs `power_dmenu.sh` (lock/exit/suspend/reboot/shutdown) |
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
- Launcher: **[dmenu](https://tools.suckless.org/dmenu/)**
- Wallpaper: **[nitrogen](https://github.com/l3ib/nitrogen)**
- Editor: **[Neovim](https://github.com/neovim/neovim)** ([LazyVim](https://github.com/LazyVim/LazyVim))
- System info: **[fastfetch](https://github.com/fastfetch-cli/fastfetch)**
- Icons/Cursor: **Papirus-Dark** / **Bibata-Modern-Ice**

## Screenshots

![](screenshots/desktop.png)
![](screenshots/split-terminals.png)

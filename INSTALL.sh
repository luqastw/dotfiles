#!/usr/bin/env bash
#
# dotfilestw installer — installs dependencies and links the configs
# in this repo into ~/.config.
#
# Usage:
#   ./INSTALL.sh [command]
#
# Commands:
#   all        Install dependencies and link configs (default)
#   deps       Install pacman + AUR dependencies only
#   configs    Link configs only (skip dependency install)
#   help       Show this message

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACMAN_DEPS=(
  i3-wm i3blocks i3lock alacritty picom dunst dex xss-lock
  network-manager-applet unclutter dmenu maim xclip scrot thunar kwallet
  polkit-kde-agent sysstat libpulse acpi xorg-xrdb xorg-xinput neovim
  fastfetch ttf-jetbrains-mono-nerd papirus-icon-theme
)

AUR_DEPS=(
  betterlockscreen nitrogen fcitx bibata-cursor-theme
)

# source (relative to repo) -> destination (relative to ~/.config)
CONFIG_DIRS=(
  "i3:i3"
  "i3blocks:i3blocks"
  "alacritty:alacritty"
  "dunst:dunst"
  "gtk-3.0:gtk-3.0"
  "gtk-4.0:gtk-4.0"
  "herdr:herdr"
  "nitrogen:nitrogen"
  "nvim:nvim"
  "fastfetch:fastfetch"
)

CONFIG_FILES=(
  "picom.conf:picom.conf"
)

# ---- helpers ----------------------------------------------------------

info()  { printf '\033[1;34m[*]\033[0m %s\n' "$1"; }
ok()    { printf '\033[1;32m[+]\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
error() { printf '\033[1;31m[x]\033[0m %s\n' "$1" >&2; }

confirm() {
  local prompt="$1"
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

require_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    error "pacman not found — this script only supports Arch Linux."
    exit 1
  fi
}

# ---- steps --------------------------------------------------------------

install_pacman_deps() {
  info "Installing official-repo dependencies..."
  sudo pacman -S --needed "${PACMAN_DEPS[@]}"
  ok "Official-repo dependencies installed."
}

install_aur_deps() {
  local helper=""
  if command -v yay >/dev/null 2>&1; then
    helper="yay"
  elif command -v paru >/dev/null 2>&1; then
    helper="paru"
  else
    warn "No AUR helper (yay/paru) found."
    if confirm "Install yay now?"; then
      local tmpdir
      tmpdir="$(mktemp -d)"
      git clone --depth 1 https://aur.archlinux.org/yay.git "$tmpdir/yay"
      (cd "$tmpdir/yay" && makepkg -si --noconfirm)
      rm -rf "$tmpdir"
      helper="yay"
    else
      error "Skipping AUR dependencies: ${AUR_DEPS[*]}"
      return
    fi
  fi

  info "Installing AUR dependencies via $helper..."
  "$helper" -S --needed "${AUR_DEPS[@]}"
  ok "AUR dependencies installed."
}

install_herdr() {
  if command -v herdr >/dev/null 2>&1; then
    ok "herdr already installed, skipping."
    return
  fi
  info "Installing herdr..."
  curl -fsSL https://herdr.dev/install.sh | sh
  ok "herdr installed."
}

install_deps() {
  require_arch
  install_pacman_deps
  install_aur_deps
  install_herdr
}

link_configs() {
  info "Linking configs into ~/.config..."
  mkdir -p "$HOME/.config"

  local entry src dest src_path dest_path
  for entry in "${CONFIG_DIRS[@]}" "${CONFIG_FILES[@]}"; do
    src="${entry%%:*}"
    dest="${entry##*:}"
    src_path="$DOTFILES_DIR/$src"
    dest_path="$HOME/.config/$dest"

    if [[ -L "$dest_path" && "$(readlink -f "$dest_path")" == "$src_path" ]]; then
      ok "$dest already linked."
      continue
    fi

    if [[ -e "$dest_path" || -L "$dest_path" ]]; then
      local backup="${dest_path}.bak.$(date +%Y%m%d%H%M%S)"
      warn "Backing up existing ~/.config/$dest to $backup"
      mv "$dest_path" "$backup"
    fi

    mkdir -p "$(dirname "$dest_path")"
    ln -s "$src_path" "$dest_path"
    ok "Linked $dest -> $src_path"
  done
}

usage() {
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
}

# ---- entrypoint -----------------------------------------------------------

main() {
  local cmd="${1:-all}"
  case "$cmd" in
    all)
      install_deps
      link_configs
      ;;
    deps)
      install_deps
      ;;
    configs)
      link_configs
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      error "Unknown command: $cmd"
      usage
      exit 1
      ;;
  esac
}

main "$@"

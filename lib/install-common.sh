#!/usr/bin/env bash
#
# Shared helpers for arch-install.sh (and the deprecated INSTALL.sh wrapper):
# color output, dependency lists, and the install/link steps both scripts use.
# Meant to be sourced, not executed directly.
#
# See docs/ARCH_PREFLIGHT_SPEC.md for the design this supports.

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

PACMAN_DEPS=(
  i3-wm i3blocks i3lock alacritty picom dunst dex xss-lock rofi
  network-manager-applet networkmanager bluez bluez-utils blueman
  unclutter maim xclip scrot thunar kwallet
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
  "rofi:rofi"
)

CONFIG_FILES=(
  "picom.conf:picom.conf"
)

# ---- output helpers -------------------------------------------------------
# Any non-empty NO_COLOR (set by arch-install.sh's --no-color, or inherited
# from the environment per the no-color.org convention) strips ANSI codes.

if [[ -n "${NO_COLOR:-}" ]]; then
  C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_RESET=""
else
  C_INFO=$'\033[1;34m'; C_OK=$'\033[1;32m'; C_WARN=$'\033[1;33m'
  C_ERR=$'\033[1;31m'; C_RESET=$'\033[0m'
fi

info()  { printf '%s[*]%s %s\n' "$C_INFO" "$C_RESET" "$1"; }
ok()    { printf '%s[+]%s %s\n' "$C_OK" "$C_RESET" "$1"; }
warn()  { printf '%s[!]%s %s\n' "$C_WARN" "$C_RESET" "$1"; }
error() { printf '%s[x]%s %s\n' "$C_ERR" "$C_RESET" "$1" >&2; }

confirm() {
  local prompt="$1" reply
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ---- config state -----------------------------------------------------
# Shared by link_configs() and arch-install.sh's T11/T12 preflight checks so
# "is this config linked" is defined in exactly one place.

# Prints one of: linked / real / absent for a single dest path.
config_entry_state() {
  local src_path="$1" dest_path="$2"
  if [[ -L "$dest_path" && "$(readlink -f "$dest_path")" == "$src_path" ]]; then
    echo "linked"
  elif [[ -e "$dest_path" || -L "$dest_path" ]]; then
    echo "real"
  else
    echo "absent"
  fi
}

# Fills the three arrays named by the caller (nameref) with the dest name
# ("i3", "picom.conf", ...) of every CONFIG_DIRS/CONFIG_FILES entry in that
# state. Usage: check_config_state linked_arr real_arr absent_arr
check_config_state() {
  local -n _linked="$1" _real="$2" _absent="$3"
  _linked=(); _real=(); _absent=()

  local entry src dest src_path dest_path state
  for entry in "${CONFIG_DIRS[@]}" "${CONFIG_FILES[@]}"; do
    src="${entry%%:*}"
    dest="${entry##*:}"
    src_path="$DOTFILES_DIR/$src"
    dest_path="$HOME/.config/$dest"
    state="$(config_entry_state "$src_path" "$dest_path")"
    case "$state" in
      linked) _linked+=("$dest") ;;
      real)   _real+=("$dest") ;;
      absent) _absent+=("$dest") ;;
    esac
  done
}

# ---- install steps ----------------------------------------------------

install_pacman_deps() {
  local -a pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && pkgs=("${PACMAN_DEPS[@]}")
  info "Installing official-repo dependencies..."
  sudo pacman -S --needed "${pkgs[@]}"
  ok "Official-repo dependencies installed."
}

# Accepts an explicit package list (defaults to the full AUR_DEPS array when
# called with no args, so it stays usable standalone).
install_aur_deps() {
  local -a pkgs=("$@")
  [[ ${#pkgs[@]} -eq 0 ]] && pkgs=("${AUR_DEPS[@]}")
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
  "$helper" -S --needed "${pkgs[@]}"
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

link_configs() {
  info "Linking configs into ~/.config..."
  mkdir -p "$HOME/.config"

  local entry src dest src_path dest_path state
  for entry in "${CONFIG_DIRS[@]}" "${CONFIG_FILES[@]}"; do
    src="${entry%%:*}"
    dest="${entry##*:}"
    src_path="$DOTFILES_DIR/$src"
    dest_path="$HOME/.config/$dest"
    state="$(config_entry_state "$src_path" "$dest_path")"

    if [[ "$state" == "linked" && "${FORCE:-0}" -ne 1 ]]; then
      ok "$dest already linked."
      continue
    fi

    if [[ "$state" == "real" ]]; then
      local backup="${dest_path}.bak.$(date +%Y%m%d%H%M%S)"
      warn "Backing up existing ~/.config/$dest to $backup"
      mv "$dest_path" "$backup"
    elif [[ "$state" == "linked" ]]; then
      rm -f "$dest_path"
    fi

    mkdir -p "$(dirname "$dest_path")"
    ln -s "$src_path" "$dest_path"
    ok "Linked $dest -> $src_path"
  done
}

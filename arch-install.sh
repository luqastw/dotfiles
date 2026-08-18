#!/usr/bin/env bash
#
# arch-install.sh — Arch-only preflight installer for dotfilestw.
#
# Runs every check up front (Phase 1: DETECT, zero side effects), prints one
# pass/warn/fail report (Phase 2: REPORT), then asks once before touching the
# filesystem (Phase 3: DECIDE+APPLY). See docs/ARCH_PREFLIGHT_SPEC.md for the
# full design and the rationale behind each check.
#
# Usage:
#   ./arch-install.sh [flags]
#
# Run './arch-install.sh --help' for flags and exit codes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# --no-color has to be known before lib/install-common.sh defines its color
# variables, so it's pre-scanned here instead of in the main arg parser.
# Per the NO_COLOR convention (no-color.org): any pre-set non-empty value
# already means "disable color", so only default to empty (not "0") here —
# lib/install-common.sh treats "set and non-empty" as the disable signal.
NO_COLOR="${NO_COLOR:-}"
for _arg in "$@"; do
  [[ "$_arg" == "--no-color" ]] && NO_COLOR=1
done
export NO_COLOR

# shellcheck source=lib/install-common.sh
source "$SCRIPT_DIR/lib/install-common.sh"

LOG_FILE="$DOTFILES_DIR/.install.log"
printf '\n=== %s -- arch-install.sh %s ===\n' "$(date -Iseconds)" "$*" >> "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

CHECK_ONLY=0
ASSUME_YES=0
DEPS_ONLY=0
SKIP_DEPS=0
FORCE=0

# ---- usage ------------------------------------------------------------

usage() {
  cat <<'EOF'
arch-install.sh — Arch-only preflight installer for dotfilestw.

Usage:
  ./arch-install.sh [flags]

Flags:
  --check, --dry-run   Phase 1+2 only (detect + report). Never mutates.
  -y, --yes             Non-interactive: auto-confirm the batch prompt.
  --deps-only           Only the dependency phase (pacman + AUR + herdr).
  --skip-deps           Only link configs, skip the dependency phase.
  --force               Re-link configs even if already correctly symlinked.
  --no-color            Plain output, for logs/CI.
  -h, --help            Show this message.

Exit codes:
  0    fully installed / everything OK, or apply completed successfully
  1    hard failure (wrong distro, running as root, no sudo)
  2    --check only: something in the requested scope is missing/unlinked
  130  user declined the batch prompt
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --check|--dry-run) CHECK_ONLY=1 ;;
      -y|--yes) ASSUME_YES=1 ;;
      --deps-only) DEPS_ONLY=1 ;;
      --skip-deps) SKIP_DEPS=1 ;;
      --force) FORCE=1 ;;
      --no-color) : ;; # already handled above, before sourcing the lib
      -h|--help) usage; exit 0 ;;
      *)
        error "Unknown flag: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done
  if [[ "$DEPS_ONLY" -eq 1 && "$SKIP_DEPS" -eq 1 ]]; then
    error "--deps-only and --skip-deps are mutually exclusive."
    exit 1
  fi
}

# ---- Phase 1: DETECT ---------------------------------------------------

DISTRO_OK=0
ROOT_OK=0
SUDO_OK=0
NETWORK_OK=0
DISK_OK=0
XORG_I3_OK=0
MISSING_PACMAN=()
AUR_HELPER=""
MISSING_AUR=()
HERDR_OK=0
LINKED=()
REAL=()
ABSENT=()
REPORT=()

report() { REPORT+=("$1|$2"); }

check_distro() {
  if command -v pacman >/dev/null 2>&1 \
    && grep -qE '^(ID=arch$|ID_LIKE=.*arch)' /etc/os-release 2>/dev/null; then
    DISTRO_OK=1
    report OK "Distro: Arch Linux (pacman found)"
  else
    DISTRO_OK=0
    report FAIL "Not Arch Linux (pacman/os-release check failed) — this script only supports Arch Linux."
  fi
}

check_root() {
  if [[ "$EUID" -ne 0 ]]; then
    ROOT_OK=1
    report OK "Not running as root"
  else
    ROOT_OK=0
    report FAIL "Running as root — run as a regular user, the script calls sudo internally."
  fi
}

check_sudo() {
  if sudo -v >/dev/null 2>&1; then
    SUDO_OK=1
    report OK "sudo available"
  else
    SUDO_OK=0
    report FAIL "sudo not available for this user."
  fi
}

check_network() {
  if curl -Is --max-time 3 https://archlinux.org >/dev/null 2>&1; then
    NETWORK_OK=1
    report OK "Network: archlinux.org reachable"
  else
    NETWORK_OK=0
    report WARN "Network: archlinux.org unreachable — pacman sync / AUR clone may fail."
  fi
}

check_disk_space() {
  local avail_kb
  avail_kb="$(df -Pk / | awk 'NR==2 {print $4}')"
  if [[ "${avail_kb:-0}" -ge 512000 ]]; then
    DISK_OK=1
    report OK "Disk space: $((avail_kb / 1024))M free on /"
  else
    DISK_OK=0
    report WARN "Disk space low: $((avail_kb / 1024))M free on / (< 500M recommended)"
  fi
}

check_xorg_i3() {
  if { command -v Xorg >/dev/null 2>&1 || command -v X >/dev/null 2>&1; } \
    && command -v i3 >/dev/null 2>&1; then
    XORG_I3_OK=1
    report OK "Xorg + i3wm present"
  else
    XORG_I3_OK=0
    report WARN "Xorg/i3wm not found — install and configure i3 first, this repo only themes an existing i3 session."
  fi
}

check_pacman_deps() {
  MISSING_PACMAN=()
  local pkg
  for pkg in "${PACMAN_DEPS[@]}"; do
    pacman -Qi "$pkg" >/dev/null 2>&1 || MISSING_PACMAN+=("$pkg")
  done
  if [[ ${#MISSING_PACMAN[@]} -eq 0 ]]; then
    report OK "All pacman dependencies present"
  else
    report WARN "${#MISSING_PACMAN[@]} pacman dep(s) missing: ${MISSING_PACMAN[*]}"
  fi
}

check_aur_helper() {
  if command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
  elif command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
  else
    AUR_HELPER=""
  fi
}

# Once installed, AUR packages register in the same local pacman db as repo
# packages, so `pacman -Qi` finds them without needing a helper — the helper
# is only required to *install* whatever comes back missing.
check_aur_deps() {
  MISSING_AUR=()
  local pkg
  for pkg in "${AUR_DEPS[@]}"; do
    pacman -Qi "$pkg" >/dev/null 2>&1 || MISSING_AUR+=("$pkg")
  done
  if [[ ${#MISSING_AUR[@]} -eq 0 ]]; then
    report OK "All AUR dependencies present"
  else
    report WARN "${#MISSING_AUR[@]} AUR dep(s) missing: ${MISSING_AUR[*]}"
    if [[ -z "$AUR_HELPER" ]]; then
      report WARN "AUR helper: none found (yay/paru) — needed to install the missing AUR deps."
    fi
  fi
}

check_herdr() {
  if command -v herdr >/dev/null 2>&1; then
    HERDR_OK=1
    report OK "herdr installed"
  else
    HERDR_OK=0
    report WARN "herdr not installed"
  fi
}

check_configs() {
  check_config_state LINKED REAL ABSENT
  local total=$(( ${#CONFIG_DIRS[@]} + ${#CONFIG_FILES[@]} ))
  if [[ ${#REAL[@]} -gt 0 ]]; then
    report WARN "${#REAL[@]} existing config(s) not symlinked, will be backed up: ${REAL[*]}"
  fi
  if [[ ${#ABSENT[@]} -gt 0 ]]; then
    report WARN "${#ABSENT[@]} config(s) not yet linked: ${ABSENT[*]}"
  fi
  if [[ ${#LINKED[@]} -eq $total ]]; then
    report OK "All $total configs already linked"
  fi
}

detect() {
  check_distro
  [[ "$DISTRO_OK" -eq 1 ]] || return 0
  check_root
  check_sudo
  { [[ "$ROOT_OK" -eq 1 ]] && [[ "$SUDO_OK" -eq 1 ]]; } || return 0
  check_network
  check_disk_space
  check_xorg_i3
  check_pacman_deps
  check_aur_helper
  check_aur_deps
  check_herdr
  check_configs
}

# ---- Phase 2: REPORT ----------------------------------------------------

rice_status() {
  local total=$(( ${#CONFIG_DIRS[@]} + ${#CONFIG_FILES[@]} ))
  local deps_total=$(( ${#PACMAN_DEPS[@]} + ${#AUR_DEPS[@]} ))
  local deps_missing=$(( ${#MISSING_PACMAN[@]} + ${#MISSING_AUR[@]} ))
  if [[ ${#LINKED[@]} -eq $total && $deps_missing -eq 0 && "$HERDR_OK" -eq 1 ]]; then
    echo "FULLY INSTALLED"
  elif [[ ${#LINKED[@]} -gt 0 || $deps_missing -lt $deps_total ]]; then
    echo "PARTIALLY INSTALLED"
  else
    echo "NOT INSTALLED"
  fi
}

print_report() {
  if [[ "$DISTRO_OK" -ne 1 ]]; then
    printf '%s %s\n' "${C_ERR}[FALHA]${C_RESET}" "${REPORT[0]#*|}"
    return
  fi

  printf '%s\n' "==================== PREFLIGHT ===================="
  local line status msg tag
  for line in "${REPORT[@]}"; do
    status="${line%%|*}"
    msg="${line#*|}"
    case "$status" in
      OK)   tag="${C_OK}[OK]${C_RESET}   " ;;
      WARN) tag="${C_WARN}[AVISO]${C_RESET}" ;;
      FAIL) tag="${C_ERR}[FALHA]${C_RESET}" ;;
    esac
    printf '%s %s\n' "$tag" "$msg"
  done
  printf '%s\n' "====================================================="

  if [[ "$DISTRO_OK" -eq 1 && "$ROOT_OK" -eq 1 && "$SUDO_OK" -eq 1 ]]; then
    local total=$(( ${#CONFIG_DIRS[@]} + ${#CONFIG_FILES[@]} ))
    local deps_missing=$(( ${#MISSING_PACMAN[@]} + ${#MISSING_AUR[@]} ))
    printf 'Rice status: %s (%s/%s configs linked, %s deps missing)\n' \
      "$(rice_status)" "${#LINKED[@]}" "$total" "$deps_missing"
  fi
}

# ---- Phase 3: DECIDE + APPLY --------------------------------------------

hard_fail() {
  [[ "$DISTRO_OK" -ne 1 || "$ROOT_OK" -ne 1 || "$SUDO_OK" -ne 1 ]]
}

PLAN=()

build_plan() {
  PLAN=()
  if [[ "$SKIP_DEPS" -ne 1 ]]; then
    [[ ${#MISSING_PACMAN[@]} -gt 0 ]] && PLAN+=("install ${#MISSING_PACMAN[@]} missing pacman package(s)")
    if [[ ${#MISSING_AUR[@]} -gt 0 ]]; then
      if [[ -z "$AUR_HELPER" ]]; then
        PLAN+=("install yay, then ${#MISSING_AUR[@]} missing AUR package(s)")
      else
        PLAN+=("install ${#MISSING_AUR[@]} missing AUR package(s) via $AUR_HELPER")
      fi
    fi
    [[ "$HERDR_OK" -ne 1 ]] && PLAN+=("install herdr")
  fi
  if [[ "$DEPS_ONLY" -ne 1 ]]; then
    local to_link=$(( ${#REAL[@]} + ${#ABSENT[@]} ))
    if [[ "$FORCE" -eq 1 ]]; then
      to_link=$(( ${#CONFIG_DIRS[@]} + ${#CONFIG_FILES[@]} ))
    fi
    if [[ $to_link -gt 0 ]]; then
      local msg="symlink $to_link config(s)"
      [[ ${#REAL[@]} -gt 0 ]] && msg="$msg (${#REAL[@]} existing will be backed up)"
      PLAN+=("$msg")
    fi
  fi
}

apply() {
  if [[ "$SKIP_DEPS" -ne 1 ]]; then
    [[ ${#MISSING_PACMAN[@]} -gt 0 ]] && install_pacman_deps "${MISSING_PACMAN[@]}"
    [[ ${#MISSING_AUR[@]} -gt 0 ]] && install_aur_deps "${MISSING_AUR[@]}"
    [[ "$HERDR_OK" -ne 1 ]] && install_herdr
  fi
  if [[ "$DEPS_ONLY" -ne 1 ]]; then
    link_configs
  fi
}

decide_and_apply() {
  if hard_fail; then
    exit 1
  fi

  # build_plan() already respects --deps-only/--skip-deps/--force, so an
  # empty plan means "nothing to do within the requested scope" — this is
  # also what --check's exit code is derived from, so both stay in sync.
  build_plan
  if [[ ${#PLAN[@]} -eq 0 ]]; then
    ok "Nothing to do for the selected scope — already installed."
    exit 0
  fi

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    exit 2
  fi

  info "This will:"
  local step
  for step in "${PLAN[@]}"; do
    printf '  - %s\n' "$step"
  done

  if [[ "$ASSUME_YES" -ne 1 ]] && ! confirm "Proceed?"; then
    warn "Aborted by user."
    exit 130
  fi

  apply
  ok "Done."
}

main() {
  parse_args "$@"
  detect
  print_report
  decide_and_apply
}

main "$@"

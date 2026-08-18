#!/usr/bin/env bash
#
# dotfilestw installer — DEPRECATED, use ./arch-install.sh instead.
#
# Thin backward-compat wrapper kept for one release since this path is
# linked from git history and muscle memory. See docs/ARCH_PREFLIGHT_SPEC.md
# for why arch-install.sh replaced this script (preflight checks before any
# mutation, dependency/distro/already-installed feedback up front).
#
# Old commands map to new flags:
#   all        -> (no flags: full preflight + apply)
#   deps       -> --deps-only
#   configs    -> --skip-deps
#   help       -> --help

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf '\033[1;33m[!]\033[0m %s\n' \
  "INSTALL.sh is deprecated, use ./arch-install.sh instead." >&2

cmd="${1:-all}"
case "$cmd" in
  all)
    shift || true
    exec "$DOTFILES_DIR/arch-install.sh" "$@"
    ;;
  deps)
    shift
    exec "$DOTFILES_DIR/arch-install.sh" --deps-only "$@"
    ;;
  configs)
    shift
    exec "$DOTFILES_DIR/arch-install.sh" --skip-deps "$@"
    ;;
  help|-h|--help)
    exec "$DOTFILES_DIR/arch-install.sh" --help
    ;;
  *)
    exec "$DOTFILES_DIR/arch-install.sh" "$@"
    ;;
esac

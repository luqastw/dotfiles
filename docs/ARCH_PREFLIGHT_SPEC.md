# Spec — Arch-only preflight installer

Status: draft, not implemented.
Target file: `arch-install.sh` (repo root), intended to replace `INSTALL.sh` as the
primary entrypoint. `INSTALL.sh`'s existing functions (`install_pacman_deps`,
`install_aur_deps`, `install_herdr`, `link_configs`) are reused, not rewritten —
this spec restructures the *flow* around them, not the underlying logic.

## 1. Problem with the current flow

`INSTALL.sh` checks and mutates in the same pass: `require_arch` runs right before
`install_pacman_deps`, missing-AUR-helper is discovered mid-install, and there is no
single point where the user sees "here is everything that's wrong before I touch your
machine." Each check is inline and destructive steps can start before the user has
the full picture.

## 2. New flow — tests before apply

Three phases, strictly ordered, phase 2 never mutates:

```
Phase 1: DETECT   → run all checks, collect results, zero side effects
Phase 2: REPORT    → print a single pass/fail/warn table, compute overall status
Phase 3: DECIDE+APPLY → prompt (or --yes), then run only what's needed
```

Phase 1 must be safe to run as `./arch-install.sh --check` with no prompts and no
writes — this is the mode used for "just tell me what's missing."

## 3. Preflight checks (Phase 1)

Each check produces one of `OK` / `WARN` / `FAIL` plus a one-line message. `FAIL` on
T01 aborts before any other check bothers running (no point probing package state on
a non-Arch box).

| id | check | pass condition | outcome on failure |
|----|-------|-----------------|---------------------|
| T01 | distro | `pacman` in `$PATH` **and** `ID=arch` or `ID_LIKE` contains `arch` in `/etc/os-release` | `FAIL` → abort immediately, exit 1 |
| T02 | root guard | `EUID != 0` | `FAIL` → abort (script must run as regular user, sudo internally) |
| T03 | sudo available | `sudo -v` succeeds (prompts for password once, upfront) | `FAIL` → abort |
| T04 | network reachable | `curl -Is --max-time 3 https://archlinux.org` succeeds | `WARN` → pacman sync / AUR clone likely to fail, let user decide |
| T05 | disk space | ≥ 500 MB free on `/` | `WARN` |
| T06 | Xorg + i3wm present | `Xorg`/`X` and `i3` binaries in `$PATH` | `WARN` — this rice themes an existing i3 session, it doesn't install the WM itself (per README prerequisite) |
| T07 | pacman deps | `pacman -Qi` for every entry in `PACMAN_DEPS` | `WARN` + list of missing names |
| T08 | AUR helper | `yay` or `paru` in `$PATH` | `WARN` if `AUR_DEPS` has missing entries and no helper exists |
| T09 | AUR deps | helper query (`yay -Qi` / `paru -Qi`) for every entry in `AUR_DEPS` | `WARN` + list of missing names |
| T10 | herdr | `command -v herdr` | `WARN` (not a pacman package, installed via curl\|sh) |
| T11 | existing configs | for each `CONFIG_DIRS`/`CONFIG_FILES` entry: symlinked-to-repo / real-file-present / absent | informational, drives T12 |
| T12 | overall rice state | derived from T07+T09+T10+T11 | `not installed` / `partial` / `fully installed` |

T11/T12 reuse the exact symlink-comparison already in `link_configs()`
(`INSTALL.sh:132`) — don't reimplement it, extract it into a `check_config_state()`
helper both the check and the apply step call.

## 4. Report format (Phase 2)

Keep the existing `info`/`ok`/`warn`/`error` tag style (`INSTALL.sh:52-55`) — no new
dependency for this. Emit one line per check, then a summary banner:

```
==================== PREFLIGHT ====================
[OK]    Distro: Arch Linux (pacman found)
[OK]    Not running as root
[OK]    sudo available
[OK]    Network: archlinux.org reachable
[OK]    Disk space: 4.2G free
[OK]    Xorg + i3wm present
[AVISO] 3 pacman deps missing: rofi, dunst, picom
[AVISO] AUR helper: none found (yay/paru)
[AVISO] 2 AUR deps missing: nitrogen, bibata-cursor-theme
[AVISO] herdr not installed
[AVISO] ~/.config/i3 exists and is not a symlink — will be backed up
=====================================================
Rice status: PARTIALLY INSTALLED (7/12 configs linked, 5 deps missing)
```

Distro `FAIL` short-circuits: print just that one line and exit, skip the banner
entirely — no point reporting on checks that never ran.

## 5. TUI choice

Researched for prior art: `gum` (charmbracelet, `pacman -S gum`) is the current
standard for glamorous bash prompts (`choose`/`confirm`/`spin`/`style`); JaKooLit's
[Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland) and
[ML4W dotfiles installer](https://github.com/mylinuxforwork/ml4w-dotfiles-installer)
both lean on plain colored prompts plus menu-driven confirms rather than a curses
library — no dependency, works over any SSH/TTY session.

Decision: **no new required dependency.** Keep pure bash + `read -p`, matching
`confirm()` (`INSTALL.sh:57-61`) — this is a single-user rice script, not a
framework; adding `gum`/`dialog` as a hard requirement contradicts the point of a
preflight check ("tell me what's missing") by introducing one more thing that can be
missing.

Optional enhancement, not required for v1: if `gum` is already on `$PATH`, use
`gum confirm`/`gum choose` for the decision menu in section 6; otherwise fall back to
the plain `read -p` menu. Never auto-install `gum` to get there.

## 6. Decision + apply (Phase 3)

- T01/T02/T03 `FAIL` → exit before this phase exists.
- Rice status `fully installed` (all configs linked, all deps present) → print
  status, exit 0. No prompt, no mutation. This makes re-running the script the
  standard way to "check everything's still fine."
- Otherwise, single umbrella prompt summarizing exactly what will happen, e.g.:

  ```
  This will:
    - install 3 missing pacman packages
    - install yay, then 2 missing AUR packages
    - install herdr
    - symlink 4 configs (1 existing ~/.config/i3 will be backed up)
  Proceed? [y/N]
  ```

  One confirm for the whole batch, not one per package/config — the current
  per-AUR-helper confirm (`INSTALL.sh:86`) stays as-is since installing a new helper
  binary is a distinct trust boundary from installing packages through it.
- Decline → exit 130, nothing touched.
- Accept (or `--yes`) → run only the phases that had `WARN`s: skip
  `install_pacman_deps` entirely if T07 was `OK`, skip AUR if T09 was `OK`, etc. Don't
  re-run steps that preflight already confirmed are satisfied.

## 7. CLI

```
arch-install.sh [flags]

  --check, --dry-run   Phase 1+2 only. Never mutates. Exit code reflects status.
  -y, --yes             Non-interactive: auto-confirm the Phase 3 batch prompt.
  --deps-only           Only the dependency phase (old `deps` subcommand).
  --skip-deps           Only link configs (old `configs` subcommand).
  --force               Re-link configs even if already correctly symlinked
                         (repo moved path, etc).
  --no-color            Plain output, for logs/CI.
  -h, --help
```

Exit codes, same meaning in every mode (not just `--check`):

| code | meaning |
|------|---------|
| `0` | fully installed / everything OK, or apply completed successfully |
| `1` | T01/T02/T03 hard failure (wrong distro, running as root, no sudo) |
| `2` | `--check` only: reachable but with `WARN`s (missing deps, unlinked configs, etc.) |
| `130` | user declined the Phase 3 batch prompt |

This lets a caller script branch on preflight result without parsing text.

## 8. Logging

Append a timestamped transcript to `$DOTFILES_DIR/.install.log`. The repo has no
`.gitignore` today — add one with a `.install.log` entry as part of this change,
otherwise the log gets committed by accident on the first `git add .`. The README
already points users at the issues page for troubleshooting; a log file they can
paste is more useful than scrollback.

## 9. Acceptance criteria

- Fresh non-Arch box (mock `/etc/os-release`): exits 1, prints only the distro line,
  touches nothing.
- Fresh Arch box, run twice back to back: 2nd run reports `FULLY INSTALLED`, exits 0,
  no `sudo pacman`/`ln` calls made.
- `sudo pacman -R rofi` then re-run: report lists `rofi` under missing pacman deps,
  offers to reinstall just that one, nothing else touched.
- `./arch-install.sh --check` on a box with 2 missing deps: exits 2, filesystem
  unchanged (verify no new symlinks, no pacman transaction).
- Declining the Phase 3 prompt: exit 130, filesystem unchanged.

## 10. Migration path

1. Extract `check_config_state()` out of `link_configs()` in `INSTALL.sh` (shared by
   both old and new script during transition).
2. Add `arch-install.sh` implementing phases 1–3 above, calling into the existing
   `install_pacman_deps`/`install_aur_deps`/`install_herdr`/`link_configs` functions
   from `INSTALL.sh` (source it, or move shared functions to a `lib.sh`).
3. Update `README.md` step 3 to point at `arch-install.sh`.
4. Keep `INSTALL.sh` as a thin deprecated wrapper (`exec ./arch-install.sh "$@"`) for
   one release before removing it, since it's linked from git history / muscle
   memory.

## References

- [charmbracelet/gum](https://github.com/charmbracelet/gum) — TUI primitives
  considered and deferred (see §5).
- [JaKooLit/Arch-Hyprland](https://github.com/JaKooLit/Arch-Hyprland) — distro-specific
  automated installer, plain-bash prompts.
- [mylinuxforwork/ml4w-dotfiles-installer](https://github.com/mylinuxforwork/ml4w-dotfiles-installer) —
  multi-distro "profile manager" framing for dependency handling.

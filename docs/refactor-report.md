# Refactor handoff

The repository now exports a portable workstation module and Core/Desktop/Full
presets, with an explicit GPU interface and a staged installer. Hardware and
personal policy remain in `hosts/nvtank-laptop`; compatibility imports preserve
the original `nixos` output and original root paths. [Audit](audit.md) explains
material decisions; [architecture](architecture.md) explains composition.

## Repository structure

```text
flake.nix, flake.lock             pinned inputs, exported modules and checks
configuration.nix                original-host compatibility import
hardware-configuration.nix       original-hardware compatibility import
hosts/nvtank-laptop/              original hardware/account/base/apps/maintenance
hosts/example/                   hoang/AMD evaluation fixture, not an install target
modules/core/                    CLI, fonts and workstation helper
modules/desktop/                 GNOME, Hyprland, end4, portals/audio, terminal/UI
modules/development/             language and cloud toolchains
modules/hardware/                explicit graphics profiles
modules/localization/            optional Vietnamese input
modules/maintenance/             opt-in store optimisation
modules/shell/                   preserved rich Zsh and themes
modules/end4-*                   preserved Lua/QML assets plus default animations
profiles/                        Core/Desktop/Full defaults
scripts/                         staging, detection, validation, install and rollback
tests/                           Nix assertions, Bash/mocked flows, Python rollback
docs/, .github/                  user/developer guides, CI and contribution templates
```

## Install and operate

```bash
git clone https://github.com/nvtank/nixos-hyprland-workstation.git
cd nixos-hyprland-workstation
./install.sh --dry-run
./install.sh --prepare-only --profile desktop --existing-host YOUR_OUTPUT
# Review the printed candidate. For a complete interactive build/test/switch flow:
./install.sh --profile desktop --existing-host YOUR_OUTPUT
```

Omit `--existing-host` on non-flake systems or when the existing flake has one
output. The CLI always creates a fresh candidate. It does not activate in
prepare-only or default non-interactive modes. [Installation](installation.md)
covers both integration and standalone modes and all confirmation flags.

The portable interface is `inputs.workstation.nixosModules.workstation` plus
`workstation.enable = true; workstation.profile = "desktop";`. No account,
hostname, disk or sudo policy is created. [Configuration](configuration.md)
contains a complete consumer flake example and every supported option.

## Compatibility and recovery

The personal host keeps the same account, groups, home, shell, hostname, disks,
bootloader, NVIDIA, GNOME/GDM, pinned compositor, apps and maintenance policy.
No package names were removed. Root-run home theme downloads/chowns were removed;
existing files remain, and `workstation themes` installs the Btop theme explicitly.
Custom Lua/QML, capture shortcuts, natural scrolling and animation intent remain.
The end4 installer now works with the actual pinned blank shell override file.
9Router now binds loopback; the personal host retains its legacy latest tag, while
public use requires a digest. The old Cốc Cốc helper now provides guidance rather
than automatically activating a system.

For system recovery use an older boot generation or
`sudo nixos-rebuild switch --rollback`. For user dotfiles use `end4-rollback` as
the desktop user; it preserves displaced configs. These do not restore personal
documents. [Recovery](rollback.md) includes failed test/login and uninstall steps.

## Tests and remaining work

See [validation](validation.md) for exact commands, results and hardware gaps.
All eight flake checks pass; Core, Desktop and Full system closures were built
without activation. No graphical login or
GPU runtime validation is claimed. During implementation, no commits, pushes or releases were created; publication is a separate owner-authorized step.
The initial lock was already dirty; its exact working-tree bytes were retained.
SHA-256: `b4c2bde7ef2fa9ebd269ec6eb6ed0d79c82e4c186fed521f1fd3b577d79b5299`.

Built fixture closures (not activated):

- Core: `/nix/store/qmrgaxqxy864smv65jzplkljdasp9jfq-nixos-system-hoang-laptop-25.11.20260630.b6018f8`
- Desktop: `/nix/store/kvnrbshrmrbv2hxrg39l2z6rg02pmmq2-nixos-system-hoang-laptop-25.11.20260630.b6018f8`
- Full: `/nix/store/dgdbzxb42lwkyccq8080lhvsz2m90vwg-nixos-system-hoang-laptop-25.11.20260630.b6018f8`

These use the example's container/tmpfs hardware; do not activate them on a real laptop.

Recommended next steps are real laptop/AMD/PRIME login tests, a headless VM smoke
test, private security/conduct reporting setup, CI action SHA pinning and replacing
the personal 9Router latest tag with a reviewed digest. Review screenshot provenance
before broad distribution. Optional proprietary downloads need separate runtime
and availability testing.

## Changed existing paths

This list includes pre-existing dirty paths; `flake.lock` and the existing
`end4-keybinds.lua` edits were not rewritten by this refactor.

- `.gitignore`
- `README.md`
- `configuration.nix`
- `flake.lock`
- `flake.nix`
- `hardware-configuration.nix`
- `modules/9router.nix`
- `modules/base.nix`
- `modules/coccoc.nix`
- `modules/common.nix`
- `modules/desktop.nix`
- `modules/dev.nix`
- `modules/end4-hyprland.nix`
- `modules/end4-keybinds.lua`
- `modules/maintenance.nix`
- `modules/packages.nix`
- `modules/shell.nix`
- `modules/terminal.nix`
- `modules/ui.nix`
- `modules/user.nix`
- `modules/vietnamese.nix`

## New paths

- `.github/ISSUE_TEMPLATE/bug_report.yml`
- `.github/ISSUE_TEMPLATE/config.yml`
- `.github/ISSUE_TEMPLATE/feature_request.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/workflows/validate.yml`
- `9ROUTER_SETUP.md`
- `CHANGELOG.md`
- `CODE_OF_CONDUCT.md`
- `CONTRIBUTING.md`
- `LICENSE`
- `SECURITY.md`
- `docs/architecture.md`
- `docs/audit.md`
- `docs/coccoc-installation.md`
- `docs/configuration.md`
- `docs/development.md`
- `docs/installation.md`
- `docs/licenses.md`
- `docs/macos-window-controls.md`
- `docs/rollback.md`
- `docs/troubleshooting.md`
- `docs/validation.md`
- `hosts/example/default.nix`
- `hosts/nvtank-laptop/base.nix`
- `hosts/nvtank-laptop/default.nix`
- `hosts/nvtank-laptop/dev.nix`
- `hosts/nvtank-laptop/hardware-configuration.nix`
- `hosts/nvtank-laptop/maintenance.nix`
- `hosts/nvtank-laptop/packages.nix`
- `hosts/nvtank-laptop/user.nix`
- `install-coccoc.sh`
- `install.sh`
- `modules/core/commands.nix`
- `modules/core/default.nix`
- `modules/desktop/common.nix`
- `modules/desktop/end4.nix`
- `modules/desktop/gnome.nix`
- `modules/desktop/hyprland.nix`
- `modules/desktop/terminal.nix`
- `modules/desktop/ui.nix`
- `modules/development/cloud.nix`
- `modules/development/default.nix`
- `modules/end4-general.lua`
- `modules/hardware/graphics.nix`
- `modules/localization/vietnamese.nix`
- `modules/maintenance/default.nix`
- `modules/shell/default.nix`
- `modules/workstation.nix`
- `profiles/core.nix`
- `profiles/desktop.nix`
- `profiles/full.nix`
- `scripts/detect.sh`
- `scripts/end4-rollback.py`
- `scripts/install.sh`
- `scripts/prepare.py`
- `scripts/prepare.sh`
- `scripts/uninstall.sh`
- `scripts/validate.sh`
- `scripts/workstation`
- `tests/end4-rollback.py`
- `tests/end4-setup.sh`
- `tests/installer-flow.sh`
- `tests/installer.sh`
- `tests/portability.nix`
- `docs/refactor-report.md`

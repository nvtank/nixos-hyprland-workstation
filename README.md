# NixOS Hyprland Workstation

A reusable NixOS 25.11 developer workstation with **Hyprland, Quickshell and
end4-pC**, plus **GNOME/GDM as the default fallback**. Adopt it on an existing
NixOS installation without borrowing another computer's disks, accounts or GPU.

![Hyprland desktop](docs/images/hyprland-desktop.png)

The repository preserves nvtank's original laptop configuration and desktop
customizations while exporting opt-in modules for other hosts. The installer
builds a staged candidate and requires explicit activation. It does not install
NixOS onto an empty disk.

- **Core:** Git, CLI utilities, Zsh enhancements and fonts.
- **Desktop:** Core, GNOME/GDM, pinned Hyprland, Quickshell/end4-pC, Kitty,
  Wayland portals, clipboard, notifications, screenshots, recording and lock UI.
- **Full:** Desktop plus Node.js, Python, Java, Go, C/C++ and cloud tools.
- Docker, Vietnamese input, Cốc Cốc, 9Router and maintenance tasks are optional.
- Existing users, hostname, filesystems and bootloader remain host decisions.
- Intel/AMD and explicit NVIDIA/PRIME profiles; detection never selects drivers.

## Requirements and support

The installer targets an **existing x86_64 NixOS installation**, tested by
configuration evaluation against the pinned 25.11 package set. It requires Bash,
Git, Nix with flakes enabled, Python 3.12+, tar, coreutils and hostname; activation
also requires sudo, nixos-rebuild and systemd. GPU detection uses optional pciutils.
Network access and enough disk space for your chosen profile are needed for
uncached inputs and packages.

Other architectures require manual evaluation; this release does not claim
hardware validation across all GPUs. Proprietary drivers and Terraform need an
explicit unfree license policy. [Known limitations and validation](docs/validation.md).

## Install into an existing NixOS system

```bash
git clone https://github.com/nvtank/nixos-hyprland-workstation.git
cd nixos-hyprland-workstation
./install.sh --dry-run
./install.sh
```

Run as your normal user. Select a profile and optional features. If the existing
flake has several configurations, specify `--existing-host YOUR_OUTPUT`.
The installer snapshots sources under `.workstation/TIMESTAMP`, evaluates and
builds a candidate, shows its closure diff, and offers temporary activation.
Persistent switching is offered after the test succeeds and you check the desktop.
No system changes occur unless you explicitly approve activation.

For review first:

```bash
./install.sh --prepare-only --profile desktop --existing-host YOUR_OUTPUT
# Review the printed candidate path and its workstation.nix and existing/ snapshot.
./scripts/validate.sh /absolute/path/to/candidate
```

Non-interactive use **builds only** by default:

```bash
./install.sh --non-interactive --profile desktop --gpu amd --existing-host YOUR_OUTPUT
```

Keep the candidate directory for future rebuilds. It is a snapshot: subsequent
changes to `/etc/nixos` are not automatically included. The advanced standalone
mode needs your hardware, bootloader and state version. Read the complete
[installation guide](docs/installation.md) before activation.

## Configure reusable modules

Add this project as a pinned flake input, then include
`workstation.nixosModules.workstation` in your existing `nixosSystem.modules`:

```nix
workstation = {
  enable = true;
  profile = "desktop";
  hardware.gpu = "preserve"; # Keep your working drivers by default
  desktop = {
    gnome.enable = true;
    hyprland.enable = true;
    vietnamese.enable = false;
  };
  development.cloudTools.enable = false;
  development.docker.enable = false;
};
```

The module creates no user, changes no password/UID/sudo policy, and sets no
hostname or disks. Enabling Zsh does not change anyone's login shell. See
[configuration](docs/configuration.md) for complete examples, profiles, AMD,
NVIDIA and hybrid graphics, and existing display-manager conflicts.

## After installation

Select **Hyprland** or **GNOME** from GDM's session menu. Run the following as
your desktop user when ready to replace only your Hyprland/Quickshell dotfiles:

```bash
end4-setup --check
end4-setup
workstation themes
workstation doctor
```

`end4-setup` backs up `hypr` and `quickshell` before replacement, stages upstream
sources and custom assets first, and refuses conflicting symlinks. It does not
run automatically at NixOS activation. Backups live under
`${XDG_STATE_HOME:-~/.local/state}/end4-nixos/backups/`.
Existing Bat themes and personal settings remain intact; there is no root-run
home-directory theme downloader.

## Keyboard shortcuts

![Keyboard shortcuts](docs/images/hyprland-shortcuts-en.svg)

| Shortcut | Action |
|---|---|
| Super + Enter / T | Kitty terminal |
| Super + Q | Close window |
| Super + M / Super + Shift + M | Minimize / show minimized windows |
| Super + F / Super + Shift + F | Maximize / fullscreen |
| Super + Shift + Space | Toggle floating |
| Super + 1…0 | Select workspace |
| Ctrl + Alt + Left/Right | Previous/next workspace |
| Ctrl + Grave | Last workspace |
| Super + I / Super + Slash | Settings / upstream shortcut sheet |
| Print / Ctrl + Print | Region / active monitor screenshot |
| Shift + Print / Alt + Print | Start/stop region / monitor recording |
| Super + Shift + S / R | Region screenshot / recording |
| Super + P | Display configuration |

The Lua overrides, translucent Kitty theme, custom lock visual, natural scrolling
and end4-pC selection remain included. See [window controls](docs/macos-window-controls.md).

## Updates and recovery

Set your actual flake path and output name, which need not match the hostname:

```bash
export WORKSTATION_FLAKE=/absolute/path/to/candidate#workstation
workstation rebuild build
workstation rebuild test
# Check login, networking, GPU and both desktop sessions before persisting:
workstation rebuild switch
```

`workstation update repository` pulls repository changes with `--ff-only`.
`workstation update inputs` explicitly changes pinned dependencies. Neither
activates a system; do not update the desktop stack without compatibility tests.
The generated wrapper is not a Git checkout: update its source deliberately as
explained in [configuration](docs/configuration.md).

To recover a system, choose an older boot generation or run
`sudo nixos-rebuild switch --rollback`. To restore the last end4 dotfile backup,
run `end4-rollback` as the desktop user. These are separate operations; **neither
restores documents or unrelated personal data**. See [rollback](docs/rollback.md)
and [troubleshooting](docs/troubleshooting.md).

## Architecture and contributing

```text
hosts/        personal host + non-installable evaluation example
modules/      reusable desktop, shell, development, hardware and localization
profiles/     core, desktop and full defaults
scripts/      detection, staging, validation, install and recovery helpers
tests/        module portability and isolated installer/rollback tests
docs/         installation, configuration, architecture, recovery and validation
.github/      CI and contribution templates
```

The original `.#nixos` output remains an alias of `.#nvtank-laptop`; its actual
hostname stays `nixos`. Original root/module paths retain compatibility imports.
**Do not install the personal host on another machine.**

![Desktop architecture](docs/images/hyprland-stack-en.svg)

Read [architecture](docs/architecture.md), [audit](docs/audit.md),
[development](docs/development.md), [CONTRIBUTING](CONTRIBUTING.md),
[Code of Conduct](CODE_OF_CONDUCT.md), [security policy](SECURITY.md) and
[changelog](CHANGELOG.md). Validation commands and hardware-testing gaps are
recorded in [docs/validation.md](docs/validation.md). The complete handoff and file
manifest are in [the refactor report](docs/refactor-report.md).

## Upstream acknowledgments and licenses

Thanks to [NixOS](https://nixos.org), [Hyprland](https://github.com/hyprwm/Hyprland),
[Quickshell](https://github.com/quickshell-mirror/quickshell),
[end4/dots-hyprland](https://github.com/end-4/dots-hyprland),
[pctrade/end4-pC](https://github.com/pctrade/end4-pC) and
[Catppuccin](https://github.com/catppuccin).
Original project code is licensed under GPL-3.0-only; upstream components retain
their own licenses. See [LICENSE](LICENSE) and [third-party notices](docs/licenses.md).

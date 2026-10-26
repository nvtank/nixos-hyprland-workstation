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

## Who can install this?

Use an **existing x86_64 NixOS 25.11 system** with a working account, bootloader
and network connection. Start from a functioning GNOME or other desktop session.
This project adds workstation modules; it does not install an OS onto an empty
disk. Keep a previous boot generation and an independent backup of personal data.

The installer preserves your existing hardware, users, hostname and services.
It never copies the owner's hardware configuration into your host. Intel/AMD and
explicit NVIDIA/PRIME settings are available, but graphical behavior still needs
testing on your own GPU. See [tested behavior and limits](docs/validation.md).

## Installation: clone, prepare, review, test

Run these commands as your **normal user**, not root. Do not clone over
`/etc/nixos`; use a directory in your home:

```bash
git clone https://github.com/nvtank/nixos-hyprland-workstation.git
cd nixos-hyprland-workstation
```

### 1. Enter the pinned installer environment

This provides Python, Git, PCI detection and validation tools without changing
your system configuration. You need Git and Nix to reach this step.

```bash
nix --extra-experimental-features 'nix-command flakes' develop
```

Inside that shell, enable flakes for its child commands if your system has not
already enabled them. This setting only affects the current terminal:

```bash
export NIX_CONFIG="${NIX_CONFIG:-}
experimental-features = nix-command flakes"
```

Stay in this shell for the following steps. `exit` leaves it when you are done.
No flake update, disk formatting or service activation happens here.

### 2. Inspect your system

```bash
./install.sh --dry-run
```

This checks prerequisites and prints a plan. **Dry-run does not build or activate
anything.** Existing GPU drivers are preserved by default.

If `/etc/nixos/flake.nix` has several outputs, list their names:

```bash
nix eval --json path:/etc/nixos#nixosConfigurations --apply builtins.attrNames
```

Use the exact output name with `--existing-host NAME` below. An output name can
differ from the hostname. With one output it is selected automatically. Without
a flake, the installer uses your existing `/etc/nixos/configuration.nix`.

### 3. Prepare one candidate

Desktop is the recommended first install: Hyprland/end4-pC plus GNOME/GDM fallback.
The following command prepares a private snapshot and makes **no system changes**:

```bash
CANDIDATE="$PWD/.workstation/my-host"
./install.sh --non-interactive --profile desktop --prepare-only --output "$CANDIDATE"
```

For multiple existing outputs, append `--existing-host NAME`. For another source
directory, append `--config-dir /absolute/path`. If the output already exists,
resume it in step 4 or choose a new output path; the installer will not overwrite it.

Inspect `$CANDIDATE/workstation.nix` and the copied host under `$CANDIDATE/existing/`.
Check the profile, desktops and GPU choice. Keep GNOME enabled for fallback.
Existing SDDM/GDM or PulseAudio/PipeWire conflicts must be reviewed explicitly;
validation stops rather than force-disabling your working services.

The source snapshot excludes common credential directories and key files. Back
those up separately. Do not put plaintext secrets in Nix files: store contents
are readable by other local users. See [snapshot boundaries](docs/installation.md).

### 4. Build and temporarily test that same candidate

```bash
./install.sh --candidate "$CANDIDATE"
```

This resumes your reviewed files, builds the candidate and displays a closure
diff. Read the changes, then:

1. Type `test` to request temporary activation.
2. Type `ACTIVATE` to confirm it. Sudo is used only at this point.
3. Check networking and both desktop sessions. Test suspend, external displays
   and GPU behavior where relevant.
4. Type `SWITCH` only after the temporary system works. Otherwise leave the test
   active without changing the default boot generation, or recover as shown below.

Keep a second terminal or TTY available. A successful build does not prove a
working graphical login. Nothing reboots automatically.

For **build only**, with no activation prompt:

```bash
./install.sh --candidate "$CANDIDATE" --non-interactive
```

If a build fails, the running system is unchanged. Edit the candidate, then retry
the same `--candidate` command. Do not rerun preparation into its existing path.
The installer records the previous system before activation and checks that the
expected candidate became active before reporting success.

For users who prefer one interactive flow, `./install.sh` selects features,
prepares a fresh timestamped candidate, builds it and offers the same confirmations.
[All flags and standalone mode](docs/installation.md).

## Profiles and common choices

| Profile | Contents | Default background services |
|---|---|---|
| Core | Git, CLI utilities, Zsh enhancements, fonts | No new desktop, Docker or auto-upgrade |
| Desktop | Core + GNOME/GDM, Hyprland, Quickshell/end4-pC, Kitty, Wayland integrations | Desktop/session services |
| Full | Desktop + Node.js, Python, Java, Go, C/C++, AWS/Kubernetes/Terraform tools | Docker remains opt-in |

Choose optional features when preparing a **new** candidate:

```bash
# Vietnamese input, retaining existing GPU drivers:
./install.sh --profile desktop --vietnamese

# AMD Desktop for an existing user such as hoang on hoang-laptop:
./install.sh --profile desktop --gpu amd

# Full language toolchains without cloud tools or Terraform's unfree license:
./install.sh --profile full --without-cloud-tools
```

The normal Full profile includes Terraform. To include it, explicitly permit its
license in your own copied host configuration; see [license policy](docs/configuration.md).
The installer does not silently allow every proprietary package. NVIDIA also
requires an explicit compatible driver/license choice. Hybrid setups require
reviewed PCI bus IDs; detection does not configure them automatically.

Docker is enabled only with `--docker` or its module option; no account is added
to the Docker group. Cốc Cốc, 9Router and automatic maintenance are opt-in.

## Already using the original nvtank workstation?

The public installer is for adopting the modules into another host. On the
original laptop, keep using the preserved `nixos` / `nvtank-laptop` output;
there is no need to import the workstation a second time. Check a source change
without activation:

```bash
nix build .#nixosConfigurations.nvtank-laptop.config.system.build.toplevel --no-link --no-write-lock-file
```

Only test or switch that output on its original hardware after reviewing the
build. Other users should follow the integration steps above.

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

For Desktop/Full with end4 enabled, run the following as your desktop user when
ready to replace only your Hyprland/Quickshell dotfiles. Then log out, select
**Hyprland** from GDM's session menu and sign in. GNOME remains selectable:

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

Keep the candidate directory; it contains the sources used for this installation.
In a new terminal, set `CANDIDATE` to its absolute path first. Original
`/etc/nixos` edits are not automatically included in this snapshot. To rebuild:

```bash
export WORKSTATION_FLAKE="$CANDIDATE#workstation"
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

If temporary activation fails, reboot into the previous default generation or
restore the path saved in `$CANDIDATE/previous-system` from a TTY as described in
[recovery](docs/rollback.md). After a persistent switch, choose an older boot
generation or run
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

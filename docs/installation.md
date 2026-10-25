# Installation

## Before starting

Use an existing, working NixOS system and a normal account. Keep a known-good
boot generation, recovery console and independent personal-data backup. Ensure
flakes are enabled in your current configuration. No partitioning or OS
bootstrap is supported. Read `./install.sh --help` for the exact flags.

Requirements: x86_64 Linux, Bash, Git, Nix, Python 3.12+, tar, coreutils (including
realpath), hostname; sudo/nixos-rebuild/systemctl for activation. Dependencies
are checked before preparing anything. Nix commands may fetch pinned sources
and binary substitutes; no remote installer scripts are executed.

## Mode A: integrate with an existing configuration (default)

```bash
git clone https://github.com/nvtank/nixos-hyprland-workstation.git
cd nixos-hyprland-workstation
./install.sh --dry-run --profile desktop
./install.sh --prepare-only --profile desktop --existing-host YOUR_OUTPUT
```

For non-flake systems, omit `--existing-host`. For flakes the installer selects
an output automatically only when exactly one exists. `--config-dir PATH`
selects a different source tree. It must include its existing lock file.

The installer creates a new private directory with:

- `existing/`: a source backup, preserving your hardware/account/service files.
- `workstation-source/`: the current project snapshot and unchanged lock file.
- `workstation.nix`: selected features, without account or filesystem settings.
- `flake.nix`: extends your selected existing output, or imports your copied
  `configuration.nix` alongside the workstation module.

It excludes Git metadata, result links, staging directories, common credential
directories, `.env` and `*.pem`/`*.key` files. Do not use a source snapshot as
a backup of excluded credentials; back them up separately. A source snapshot
is not a full host or personal-data backup. External symlinks, absolute imports,
local path flake inputs, secret-management providers and files outside the source
tree need manual review. Pure evaluation may reject these; stop and make the host
self-contained rather than removing its hardware configuration. Never place
plaintext secrets in files Nix copies into the world-readable store.

Review `workstation.nix`, especially GNOME/GDM and audio when an existing host
uses another display manager or PulseAudio. Conflicts are not automatically
forced away. Disable the new GDM through `workstation.desktop.gnome.enable = false`
or explicitly migrate your old login manager in the copied host configuration.
No script disables your original desktop. Keep GNOME enabled for fallback when
using the normal desktop preset.

Validate the printed directory:

```bash
./scripts/validate.sh /absolute/path/to/candidate
nix store diff-closures /run/current-system /absolute/path/to/candidate/candidate
```

The first validation locks the *new wrapper flake*. It does not update the
existing project's lock or any pinned workstation inputs. Commit the generated
flake/lock into a private host repository if you want to maintain it long term.

For a complete interactive build/test/switch flow, run `./install.sh` into a
fresh candidate directory. It prints a diff and asks for explicit temporary
activation. After testing login/network/GPU, it offers a persistent switch.
A `test` changes the running system but not the default boot generation. If it
fails, return to the original generation using [recovery](rollback.md).

To activate a candidate you prepared manually:

```bash
sudo nixos-rebuild test --flake path:/absolute/path/to/candidate#workstation --no-write-lock-file
# Verify actual login, graphics, networking and services first.
sudo nixos-rebuild switch --flake path:/absolute/path/to/candidate#workstation --no-write-lock-file
```

Do not point these commands at `hosts/example` or at the personal host on another
computer. Keep the candidate path after activation. Future rebuilds from your
original `/etc/nixos` intentionally return to its original configuration.

## Automated use

```bash
./install.sh --non-interactive --profile desktop --gpu amd --existing-host YOUR_OUTPUT
```

This prepares, validates, builds and prints the diff without activation.
`--dry-run` writes nothing and builds nothing. `--prepare-only` creates source
snapshots without building or activation. Optional feature flags are
`--vietnamese`, `--cloud-tools` and `--docker`. Full already defaults cloud tools
on; to disable them edit the candidate. Terraform requires explicit unfree
permission in your own configuration; a failed license check stops the build.

Automated activation requires `--activate test --allow-activation`; automated
switching additionally requires `--confirm-tested`, affirming that you reviewed
hardware and desktop behavior. The installer still builds, tests and verifies
the active system path before attempting a switch. CLI confirmation cannot
prove that your GPU or graphical login works; unattended graphical deployment is
not recommended.

`--gpu preserve` is the default. Intel/AMD/NVIDIA choices are explicit; hybrid
systems require manual PCI bus IDs in the candidate, as shown in
[configuration](configuration.md). Detection never silently selects a driver.

## Mode B: advanced standalone host

Supply valid hardware and bootloader **Nix modules** for your own machine:

```bash
./install.sh --mode standalone --profile desktop --prepare-only \
  --hardware /path/to/your/hardware-configuration.nix \
  --bootloader /path/to/your/bootloader.nix --state-version 25.11
```

The modules are copied to `existing/hardware.nix` and `existing/bootloader.nix`.
Their relative imports must be made self-contained in the candidate. The
hostname comes from the current machine. The supplied modules must also define
your existing accounts and access route, or you must add account imports before
validation. The installer never creates a user or authentication policy.

A bootloader module could enable systemd-boot only on a machine whose current
EFI setup supports it. Reuse your proven settings; do not copy the owner's.
`system.stateVersion` must match the target system's intended compatibility
baseline, not automatically the newest release. There is no disk formatting,
partitioning or unattended NixOS installation.

## Post-install verification

As your desktop user, run `end4-setup --check`, then `end4-setup` when ready.
Log out and select Hyprland in GDM. Check `hyprctl configerrors`, `qs --version`,
screenshots, recording, lock/unlock and display selection. Select GNOME and
verify fallback login too. For optional input support check `fcitx5-remote -n`.

`workstation doctor` provides read-only diagnostics. Its success is not a proof
of hardware or lock-screen correctness. Preserve backups until manual checks
pass. Nothing reboots automatically.

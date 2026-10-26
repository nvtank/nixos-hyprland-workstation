# Validation record

Validation was performed locally on 2026-10-25 against the working tree and its
existing lock. No system generation was activated; no host was rebooted. Local
Nix commands used `path:/etc/nixos` to include newly created files without staging
or committing them. No GitHub workflow run is claimed.

## Follow-up: fresh installation validation (2026-10-26)

The initial GitHub push/PR checks passed the scripts job but failed Nix evaluation:
[run 40210884233](https://github.com/nvtank/nixos-hyprland-workstation/actions/runs/40210884233).
The runner used Nix 2.35.4 and could not read Hyprland's `VERSION` from a generated
fileset store path. Earlier local results used Nix 2.31.5 and an existing store;
they did not establish cold-runner compatibility.

`lib/hyprland-package.nix` now supplies that same version metadata from the pinned
input directly, without changing upstream source revisions or `flake.lock`.
CI additionally runs `tests/clean-install.sh`, which generates and evaluates
real Desktop candidates for independent flake and non-flake host configurations.
Those tests check preserved host/home/filesystem choices, AMD, both desktops and
absence of the original owner's account/NVIDIA settings. They never activate a
system. Remote verification of this follow-up is recorded with its pull request.

The installer has a pinned development shell, a resumable `--candidate` workflow,
a `--without-cloud-tools` choice and a Python-version preflight check. Mocked
resume/build-only tests, ShellCheck, Python rollback tests and Nix formatting
passed locally. Fresh-runner results remain distinct from graphical hardware tests.

## Completed

| Check | Result |
|---|---|
| Baseline personal host `toplevel.drvPath` | Passed before moving modules |
| `nix flake check path:/etc/nixos --no-write-lock-file` | All 8 checks passed |
| Core/Desktop/Full, example and personal host evaluation | Passed |
| Complete Core system build (`--no-link`) | Passed; not activated |
| Complete Desktop system build (`--no-link`) | Passed; not activated |
| Complete Full system build (`--no-link`) | Passed; not activated |
| Packaged `end4-setup`, `end4-rollback`, `workstation` build | Passed |
| Real packaged end4 setup/rollback in isolated XDG directories | Passed |
| End4 failure after exchange and symlink-conflict refusal | Passed; both original trees preserved |
| Python rollback incomplete/path-traversal backup tests | Passed; unrelated files preserved |
| Installer arguments, profile generation, backup and missing files | Passed |
| Mocked whole installer: prepare/build-only/dry-run/failed build | Passed; no sudo or activation |
| ShellCheck for installer, helpers and Bash tests | Passed |
| Nix formatting and `git diff --check` | Passed |
| Working-tree lock vs pre-refactor snapshot | Byte-for-byte identical |
| Personal host settings vs baseline | Hostname, account/home/groups/shell, filesystems, stateVersion, NVIDIA, GNOME/GDM, Hyprland, Docker and auto-upgrade preserved |
| Personal package names vs baseline | No packages removed; Python runtime, FFmpeg and helper added |

Portability assertions cover username `hoang`, hostname `hoang-laptop`, AMD,
Desktop with GNOME/GDM and Hyprland; no `nvtank` account, personal filesystem or
NVIDIA driver is imported. A second user has `/srv/alice` as a nonstandard home.
Core omits graphical sessions; Full does not enable Docker automatically. All
six GPU option values evaluate with valid explicit hybrid IDs. Missing hybrid
IDs, invalid profile/GPU enums, end4 without Hyprland and unconfigured 9Router
are rejected by option/assertion tests. The optional Fcitx5 unit is absent when
GNOME uses its default IBus input method.

The installer also generated a candidate from an independent non-flake host
containing `hoang`, `/srv/hoang`, `hoang-laptop` and tmpfs/container hardware.
That candidate was locked with the existing workstation revisions and its system
derivation evaluated successfully. Its tmpfs/container settings are fixtures,
not a hardware recommendation or bootable laptop installer.

## Commands

```bash
nix flake check path:/etc/nixos --no-write-lock-file
nix build path:/etc/nixos#nixosConfigurations.core.config.system.build.toplevel --no-link --no-write-lock-file
nix build path:/etc/nixos#nixosConfigurations.desktop.config.system.build.toplevel --no-link --no-write-lock-file
nix build path:/etc/nixos#nixosConfigurations.full.config.system.build.toplevel --no-link --no-write-lock-file
bash tests/installer.sh
bash tests/installer-flow.sh
python3 tests/end4-rollback.py
shellcheck install.sh scripts/*.sh scripts/workstation install-coccoc.sh tests/*.sh
git ls-files -z --cached --others --exclude-standard '*.nix' | xargs -0 nix fmt path:$PWD -- --check
git diff --check
```

`tests/end4-setup.sh SETUP_BINARY ROLLBACK_BINARY` is also built and executed
by the flake's end4 integration check. It always sets isolated XDG paths.
The first full-installer sandbox run exposed `/usr/bin/env` in generated mocks;
the mocks now use the actual Bash interpreter and pass inside the Nix sandbox.
An earlier real setup test exposed a stale layout-line patch; the fix uses the
supported custom Lua hook and retains the intended animation defaults.

## Not established by these checks

- Real GNOME/Hyprland login, lock/PAM interaction, screen capture, external monitors,
  suspend, NVIDIA/PRIME routing and hardware acceleration.
- Complete rebuild/runtime of the personal host's proprietary/experimental apps,
  including Cốc Cốc and its vendor download, or the legacy 9Router container.
- GPU-dependent graphical integration in a VM. No VM test was run.
- Installer activation on another user's actual host; mutation paths are mocked.
- Architectures other than x86_64. Other Linux architectures need manual evaluation;
  this project's NVIDIA/Cốc Cốc profiles and installer are explicitly restricted.
- All optional upstream end4 widgets/integrations. Some require external services,
  credentials, additional runtime tools or GNOME GI typelibs; inspect their logs.
- Relocation of arbitrary absolute imports, out-of-tree secrets or local path
  inputs from another flake. Pure evaluation fails safely when dependencies are missing.

The original laptop's running generation and actual user dotfiles remain the
recovery baseline. Evaluation/build success does not establish graphical runtime
compatibility. Keep GNOME and a previous generation until manual checks pass.

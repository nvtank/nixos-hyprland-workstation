# Configuration

## Import into your own flake

Keep your hardware, accounts, bootloader, stateVersion and hostName in your host:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    workstation.url = "github:nvtank/nixos-hyprland-workstation";
  };
  outputs = { nixpkgs, workstation, ... }: {
    nixosConfigurations.hoang-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix # your existing host, hardware and accounts
        workstation.nixosModules.workstation
        {
          workstation = {
            enable = true;
            profile = "desktop";
            hardware.gpu = "amd";
          };
        }
      ];
    };
  };
}
```

Pin your flake lock when adopting the project. For the installer, the local
source snapshot already retains the project's lock. Do not add an input
`follows` override unless you intend to test a different package combination.
The exported module supplies its desktop inputs using `workstationInputs`, so
it does not replace your own `inputs` special argument.

`nixosModules.core`, `.desktop` and `.full` import the same module with profile
defaults. The files in `profiles/` are presets, so they require the main module
when imported directly. Import the exported module once; do not mix legacy
personal imports with it in a new host.

## Options

| Option under `workstation` | Default | Meaning |
|---|---|---|
| `enable` | false | Enable workstation configuration |
| `profile` | desktop | core, desktop or full |
| `desktop.gnome.enable` | profile != core | GNOME/GDM fallback |
| `desktop.hyprland.enable` | profile != core | Pinned compositor and portal |
| `desktop.end4.enable` | hyprland enabled | Quickshell, user setup, lock/capture helpers |
| `desktop.vietnamese.enable` | false | Fcitx5/Bamboo/Unikey |
| `development.enable` | full | Language toolchains |
| `development.cloudTools.enable` | full | AWS/Terraform/Kubernetes/Helm/eksctl/k9s |
| `development.docker.enable` | false | Docker daemon, no automatic group membership |
| `applications.coccoc.enable` | false | Proprietary amd64 browser |
| `applications.router9.enable` | false | Explicit Docker container service |
| `applications.router9.image` | empty | Required immutable `ghcr.io/decolua/9router@sha256:…` |
| `maintenance.enable` | false | Store optimisation, no generation deletion |
| `hardware.gpu` | preserve | Explicit driver preset |
| `hardware.nvidiaBusId` | empty | Required for PRIME hybrid |
| `hardware.integratedBusId` | empty | Required for PRIME hybrid |

All are typed NixOS options. Invalid enums fail evaluation. Assertions reject
end4 without Hyprland, missing hybrid bus IDs, unsupported proprietary platform
choices and 9Router without explicit Docker and a digest.

Core installs the existing rich Zsh tooling and fonts without GNOME, Hyprland,
Quickshell, language toolchains or proprietary applications. Some terminal tools
have substantial dependencies; Core is not intended as a minimal server image.
Full adds stable Node.js 22, Python, JDK17, Maven/Gradle, Go, C/C++ and cloud tools.
Full does not include every personal/experimental app. The installer flag
`--without-cloud-tools` installs the language toolchains without cloud packages. Cốc Cốc and Terraform need
an explicit `nixpkgs.config.allowUnfreePredicate` (or your existing broader policy).
For example, enable only Terraform when using the Full preset:

```nix
nixpkgs.config.allowUnfreePredicate = pkg:
  builtins.elem (pkgs.lib.getName pkg) [ "terraform" ];
```

Use this inside a module with `pkgs` in its argument list. Review actual
license errors for any additional applications you choose.

## Users and desktops

No public option creates/renames users, changes shells, adds wheel/docker/input
groups, changes home ownership or edits passwords. System-wide Zsh customization
applies to users who already use Zsh. Set your shell explicitly in your own host
if desired. Docker group membership is a separate root-equivalent permission.

GNOME and GDM remain defaults in Desktop/Full. A conflicting existing display
manager or PulseAudio configuration must be reviewed in your host. The module
does not force those services off. To keep your existing login manager, disable
`workstation.desktop.gnome.enable` and ensure that manager offers a Hyprland
session. For GNOME only, disable Hyprland; end4 defaults off with it. To run plain
Hyprland without end4, disable `desktop.end4.enable` and provide your own dotfiles.

end4 uses Blueman and GNOME settings helpers where available. With GNOME disabled,
its settings shortcut may need a custom app. Enable Bluetooth/NetworkManager in
your own host if you use them; this module does not change radio/pairing policy.

## Graphics

- `preserve`: no video driver choice; keep the working host setup.
- `intel`: enable graphics; use Mesa/kernel defaults (no legacy Intel Xorg driver).
- `amd`: Mesa plus the amdgpu Xorg driver; no NVIDIA configuration.
- `nvidia`: proprietary stable driver, modesetting; explicitly permit its license.
- `hybrid-intel-nvidia` / `hybrid-amd-nvidia`: PRIME render offload with both
  PCI bus IDs supplied. No automatic sync/offload guessing.

```nix
workstation.hardware = {
  gpu = "hybrid-intel-nvidia";
  integratedBusId = "PCI:0:2:0"; # Example only; inspect your actual machine.
  nvidiaBusId = "PCI:1:0:0";
};
```

Find IDs with `lspci -nn`; NixOS PRIME uses decimal PCI components. See the
pinned NixOS module's option descriptions and your machine documentation. Keep
existing PRIME/display-routing decisions if they already work. Older NVIDIA
cards, Secure Boot signing, external displays, suspend and driver/kernel
compatibility require hardware-specific review. Hyprland behavior varies by GPU.
This project's NVIDIA profiles currently assert x86_64 only. Non-x86_64 Core or
Mesa hosts can be evaluated manually but are not claimed as tested platforms.

## Maintain an installed candidate

A generated candidate contains frozen `existing/` and `workstation-source/`
copies. Edit the candidate's host files to make future local changes. Keep it
outside disposable directories and set:

```bash
export WORKSTATION_FLAKE=/absolute/path/to/candidate#workstation
```

`workstation update repository` requires a Git checkout; the wrapper snapshot is
not one. Pull changes in your original project checkout, inspect its diff and
create a fresh candidate using the intended host source. Avoid integrating an
already-integrated output a second time. Alternatively maintain a normal host
flake with the project as a remote pinned input (the example above).

`workstation update inputs` explicitly updates the chosen flake's inputs; a
wrapper may advance upstream dependencies. Review the complete lock diff and
build/test before switching. It does not activate anything. To keep the desktop
stack stable, leave its input revisions unchanged.

The original owner host intentionally retains its previous auto-upgrade, GC,
locale, Bluetooth, Docker and ADB policies. These are not reusable defaults.

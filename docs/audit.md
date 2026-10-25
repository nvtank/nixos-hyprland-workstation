# Audit and migration decisions

The audit used the actual working tree, including edits present before the refactor.
The original files and pre-existing diff were also saved locally under
`/tmp/workstation-refactor-baseline` during development. That temporary copy is
not a durable backup and is not distributed.

## Findings

| Area | Original behavior | Decision |
|---|---|---|
| Flake | One x86_64 output, `nixos`; stable/unstable, Antigravity and desktop inputs | Keep every input and the exact working-tree lock; export modules and evaluation fixtures |
| Main configuration | `nixos` hostname, systemd-boot, proprietary NVIDIA, Docker, many apps | Preserve under `hosts/nvtank-laptop`; root file remains a compatibility import |
| Hardware | Intel KVM/microcode, NVMe modules, personal root/EFI UUIDs | Move to personal host; never import through public module |
| User/dev | Creates `nvtank`, wheel, NetworkManager, Docker, ADB groups | Personal host only; public module never declares accounts or group membership |
| Base | Vietnam timezone, forced English locale, always-pairable Bluetooth | Personal host only; no inherited locale, radio or pairing policy |
| Desktop/UI | Duplicate X server, Bluetooth and GNOME declarations | Preserve legacy imports; public desktop separates GNOME, portals/audio and Hyprland |
| Shell | Rich Zsh, Kitty/Btop/Starship themes; root activation writes/chowns `/home/nvtank` and downloads unpinned Bat theme | Keep shell/terminal configuration; remove root home mutation; explicit `workstation themes`; existing Bat files survive |
| end4 | Store-backed wrappers install mutable `hypr` and `quickshell`; custom Lua, screenshot/recording and lock QML | Retain assets and exact upstream pins; isolated staging, conflict checks and recoverable rollback; repair a layout-line patch incompatible with the pinned blank override file |
| end4 backup | Setup changes `state_root` before writing pointer, so rollback cannot find it | Fix pointer; accept old misplaced pointer only when it resolves inside the expected backup root |
| Maintenance | Weekly upgrades, 7-day GC, TRIM, zram, boot generation limit | Preserve existing owner's host policy; all absent from public defaults |
| Apps | Cốc Cốc amd64 `.deb`, Antigravity, unstable Codex, Kiro and development packages | Keep owner's apps; public Full contains maintained toolchains; proprietary/experimental apps opt-in |
| 9Router | Pulls `latest` at boot, recreates named container, exposes port on every interface, personal data owner | Public option requires digest and explicit Docker; bind loopback and root-owned data; personal host retains legacy `latest` pending owner pin |
| Rebuild shortcuts | `/etc/nixos#nixos` baked into shared shell | Helper uses explicit `WORKSTATION_FLAKE`; personal host sets its old reference |
| Cốc Cốc helper | Immediately tests and switches without an approval prompt | Compatibility helper now explains the opt-in configuration and explicit build workflow |

## Dependency and compatibility notes

The root Nixpkgs input remains NixOS 25.11. Hyprland uses its own pinned unstable
Nixpkgs input; Quickshell follows the root package set. Matching compositor and
portal packages come from the same Hyprland input. No inputs were updated.
end4's Lua API and QML patches depend on these revisions. The store source trees
were inspected for the staged config entry points and upstream licenses.

Cốc Cốc is a proprietary x86_64 binary with a fixed source hash. Its wrapper was
fixed to use `makeWrapper` rather than a quoted heredoc containing an unresolved
`$out`. Its network source availability and browser runtime still need testing.
Node.js 20 in the personal application list is preserved; the public Full preset
uses Node.js 22 from the same stable pin. Private apps and broad unfree permission
remain personal choices. Public Core/Desktop do not automatically permit unfree
packages. Full cloud tools include Terraform and require explicit license policy.

The textual source audit found personal account names and filesystem identifiers,
but no embedded credentials in the inspected configuration/scripts. This is not a
forensic Git-history or secret-manager audit. Treat configuration and Nix store
paths as public; do not add plaintext secrets. Screenshots may contain personal
information and should be reviewed before publication.

## Architecture rationale

- One typed `workstation` interface controls config-only modules. Presets set
  defaults; explicit feature choices can override them without replacing the host.
- Flake exports close over the project's pinned desktop inputs via the uniquely
  named `workstationInputs` argument. Consumers need not replace their own `inputs`.
- Legacy imports remain for existing commands. The owner host keeps the old
  package set, hardware, accounts, desktops and maintenance policy. Import public
  modules for new hosts rather than legacy compatibility files.
- User config stays mutable and requires a user-run setup command. NixOS activation
  cannot silently overwrite dotfiles or download themes into a home directory.
- The default installer extends an existing flake's selected output, or imports a
  copied non-flake configuration. It stages a new flake rather than editing a live
  configuration. This supports review and recovery while preserving host policy.
- The example is an evaluation container fixture with tmpfs, not bootable hardware.
  This avoids pretending the owner's UUIDs are usable on other computers.
- Existing conflicting services fail evaluation/build; there is no generic
  `mkForce` mechanism that silently disables another login or audio service.

## Migration sequence

1. Snapshot the dirty baseline and evaluate the original personal output.
2. Isolate host policy and retain compatibility imports.
3. Expose opt-in modules and profile/GPU validation.
4. Harden end4 staging/rollback and implement a candidate-based installer.
5. Exercise portability and failure paths; add CI and recovery documentation.
6. Owner builds and tests on hardware before adopting the new generation.

See [validation](validation.md) for actual test results and remaining gaps.

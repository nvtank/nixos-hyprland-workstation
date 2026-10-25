# Architecture

`flake.nix` retains the original inputs and lock graph. It exports
`nixosModules.workstation` (also `default`) and Core/Desktop/Full preset modules.
The exported module closes over pinned desktop inputs as `workstationInputs`,
avoiding interference with a consumer's own flake arguments.

`modules/workstation.nix` defines the typed feature interface and composes
configuration fragments. The module is inert unless `workstation.enable` is
true. Profile defaults select coherent packages; features can be overridden.
No account, hostname, bootloader or disk settings are part of the public module.
`modules/hardware/graphics.nix` only selects drivers after an explicit choice.

`hosts/nvtank-laptop/` contains the owner's unchanged hardware identifiers,
account policy, baseline settings, developer applications and maintenance
choices. The root `configuration.nix` and `hardware-configuration.nix` forward to
it; the old module entry points forward to moved modules. Both `nixos` and
`nvtank-laptop` flake outputs refer to this host, whose hostname remains `nixos`.
Legacy module files are compatibility entry points, not reusable public APIs.

The example and Core/Desktop/Full outputs are evaluation fixtures with a tmpfs
root and container boot settings. Their `hoang-laptop` hostname and account
illustrate portability; they are not installable hardware configurations.

The desktop keeps GNOME/GDM as a fallback by default. Hyprland and its portal
come from the same pinned input. Quickshell is wrapped with Qt/QML and schema
dependencies. Custom Lua and lock QML remain in `modules/end4-*`, referenced by
`modules/desktop/end4.nix`. Keeping those assets in place reduces migration risk
and preserves external references to them.

`end4-setup` is explicitly user-run: it backs up `hypr` and `quickshell`, stages
upstream sources and patches, then exchanges the two trees. It holds an operation
lock, rejects top-level symlinks and preserves user settings outside those trees.
`end4-rollback` validates both restore trees first, preserves displaced live
configurations and supports the original no-argument interface. Neither is a
personal-data backup system.

The installer generates a fresh private candidate. Integration extends an
existing flake using `extendModules`, preserving its special arguments and
module set. Non-flake hosts import the copied configuration with the project's
stable Nixpkgs. Standalone mode requires the user to supply hardware and boot
modules. There is no partitioning or in-place rewrite of `/etc/nixos`.

CI evaluates all host/profile derivations, tests module semantics and scripts,
and checks formatting. Evaluation checks deliberately discard the derivation
string context after forcing it, so a check does not accidentally build an
entire GPU desktop. Full system builds and real graphical tests remain separate.
See [audit](audit.md) for the implementation-specific findings and decisions.

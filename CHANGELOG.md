# Changelog

## Unreleased — clean installation follow-up

- Read Hyprland's version metadata from the pinned input instead of its generated
  fileset path, addressing evaluation failure on a fresh GitHub Nix 2.35 runner.
- Add a pinned `nix develop` environment for installer prerequisites.
- Resume reviewed candidates with `--candidate` and provide a Full preset option
  without cloud tools; read actual candidate options before activation.
- Add real wrapper evaluation for independent flake/non-flake hosts and test the
  resume/build-only path. Rewrite README with concrete staged installation steps.

## Unreleased — portable workstation refactor

- Isolate personal hardware/account/base/application/maintenance policy under
  `hosts/nvtank-laptop`, preserving the original `nixos` output and root imports.
- Export typed workstation and Core/Desktop/Full preset modules; keep GNOME/GDM
  fallback and pinned Hyprland/Quickshell/end4 integration.
- Add explicit preserve/Intel/AMD/NVIDIA/PRIME graphics options without disk or
  account configuration in public modules.
- Add candidate-based installation, source snapshots, validation, closure diff,
  explicit test/switch activation and read-only diagnostics.
- Preserve custom Lua/QML and capture helpers; stage end4 configs privately,
  reject symlink conflicts, repair backup pointers and preserve live trees during rollback.
- Remove root-run home mutation/unpinned Bat theme download; provide explicit
  user theme setup and flake-aware rebuild helper.
- Make public Docker, Vietnamese input, proprietary apps, 9Router and maintenance
  optional. Require a public 9Router digest and bind its port to loopback.
- Fix Cốc Cốc's unresolved wrapper path; replace its automatic activation helper
  with opt-in configuration guidance.
- Add portability/failure tests, CI, contribution/security policies and recovery docs.
- Retain the exact working-tree flake lock from before this refactor; no dependency
  upgrades are included.

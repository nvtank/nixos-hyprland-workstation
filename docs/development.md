# Development

Use the existing lock; do not run `nix flake update` as part of a refactor.
New files must be tracked before Git-flake consumers or CI can see them. During
local uncommitted development use `path:$PWD` so new files are included.

```bash
git ls-files -z --cached --others --exclude-standard '*.nix' | xargs -0 nix fmt path:$PWD -- --check
nix flake check path:$PWD --no-build --no-write-lock-file
nix flake check path:$PWD --no-write-lock-file
bash tests/installer.sh
bash tests/installer-flow.sh
python3 tests/end4-rollback.py
shellcheck install.sh scripts/*.sh scripts/workstation install-coccoc.sh tests/installer.sh
```

The project formatter is `nixfmt-rfc-style` from its pinned Nixpkgs. If you need
standalone validation tools without touching the host configuration:

```bash
nix shell --inputs-from path:$PWD nixpkgs#shellcheck nixpkgs#nixfmt-rfc-style
```

Flake checks force evaluation of Core/Desktop/Full, example and personal
`toplevel.drvPath`, and separately build lightweight assertion/script checks.
They do not build all full system closures. The tests cover independent
usernames/homes, hostnames, absent personal user/disk settings, profile defaults,
GPU assertions and installer backup/failure behavior. Bash tests use temporary
sources and mock Nix commands where a build would otherwise be required.
No test calls sudo or activates a host.

For a real candidate or personal host, build the closure separately:

```bash
nix build path:$PWD#nixosConfigurations.nvtank-laptop.config.system.build.toplevel --no-link --no-write-lock-file
# Only on the original machine, after reviewing changes:
sudo nixos-rebuild test --flake path:$PWD#nvtank-laptop --no-write-lock-file
```

Graphical login, suspend, external screens, lock/unlock, GPU offload, recording,
PipeWire and GNOME fallback require hardware testing. Do not assert they work
based only on evaluation. A headless VM cannot establish proprietary GPU support.
VM coverage is a follow-up; current checks are isolated command/module tests.

When changing end4 patches, inspect both pinned source trees and run the built
`end4-setup` with isolated XDG directories as a normal user. Keep the original
no-argument rollback interface. Assert staging failures preserve the existing
config trees and successful rollback preserves unrelated data.

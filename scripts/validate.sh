#!/usr/bin/env bash
set -euo pipefail
[[ $# == 1 && -f "$1/flake.nix" && -f "$1/workstation.nix" ]] || { echo 'Usage: validate.sh PREPARED_DIRECTORY (missing candidate files)' >&2; exit 2; }
directory=$(realpath -e "$1")
# Resolve only the new wrapper; nested upstream lock files are retained unchanged.
if [[ ! -f "$directory/flake.lock" ]]; then nix flake lock "path:$directory"; fi
nix eval --no-write-lock-file "path:$directory#nixosConfigurations.workstation.config.system.build.toplevel.drvPath"
nix build --no-write-lock-file "path:$directory#nixosConfigurations.workstation.config.system.build.toplevel" --out-link "$directory/candidate"

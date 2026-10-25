#!/usr/bin/env bash
set -euo pipefail
printf 'User: %s\nHostname: %s\nArchitecture: %s\n' "$(id -un)" "$(hostname)" "$(uname -m)"
if command -v lspci >/dev/null; then
  lspci -nn | grep -Ei 'VGA|3D|Display' || true
else
  echo 'GPU detection unavailable (optional pciutils); existing drivers will be preserved.'
fi
if [[ -f /etc/nixos/flake.nix ]]; then echo 'Existing flake detected.'; fi
if [[ -f /etc/nixos/configuration.nix ]]; then echo 'Existing configuration.nix detected.'; fi

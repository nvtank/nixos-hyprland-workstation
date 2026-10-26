#!/usr/bin/env bash
# Real Nix evaluation of generated wrappers, suitable for a fresh Linux runner.
# This deliberately never calls nixos-rebuild, sudo or a switch script.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
python3 "$ROOT/tests/prepare-candidates.py" "$scratch"
for kind in nonflake flake; do
  candidate="$scratch/$kind/candidate"
  nix flake lock "path:$candidate"
  nix eval --no-write-lock-file "path:$candidate#nixosConfigurations.workstation.config.system.build.toplevel.drvPath"
  nix eval --json --no-write-lock-file "path:$candidate#nixosConfigurations.workstation.config" --apply 'c: {
    hostname = c.networking.hostName;
    home = c.users.users.hoang.home;
    personalUser = c.users.users ? nvtank;
    drivers = c.services.xserver.videoDrivers;
    rootDevice = c.fileSystems."/".device;
    bootloader = c.boot.loader.systemd-boot.enable;
    gnome = c.services.desktopManager.gnome.enable;
    gdm = c.services.displayManager.gdm.enable;
    hyprland = c.programs.hyprland.enable;
    docker = c.virtualisation.docker.enable;
  }' > "$scratch/$kind.json"
  python3 - "$scratch/$kind.json" <<'PY'
import json
import sys
c = json.load(open(sys.argv[1]))
assert c['hostname'] == 'hoang-laptop'
assert c['home'] == '/srv/hoang'
assert not c['personalUser']
assert 'nvidia' not in c['drivers']
assert c['rootDevice'] == 'none' and not c['bootloader']
assert c['gnome'] and c['gdm'] and c['hyprland']
assert not c['docker']
PY
  echo "Real $kind integration candidate passed"
done

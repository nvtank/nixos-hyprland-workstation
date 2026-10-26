#!/usr/bin/env python3
"""Generate real integration candidates; no mocks and no system activation."""
import importlib.util
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('prepare', root / 'scripts/prepare.py')
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)
base = Path(sys.argv[1]).resolve()
lock = json.loads((root / 'flake.lock').read_text())
node = lock['nodes'][lock['nodes']['root']['inputs']['nixpkgs']]
for kind in ('nonflake', 'flake'):
    original = base / kind / 'original'
    original.mkdir(parents=True)
    (original / 'configuration.nix').write_text('''{ ... }: {
  networking.hostName = "hoang-laptop";
  users.users.hoang = { isNormalUser = true; home = "/srv/hoang"; };
  system.stateVersion = "25.11";
  boot.isContainer = true;
  fileSystems."/" = { device = "none"; fsType = "tmpfs"; };
}
''')
    if kind == 'flake':
        (original / 'flake.nix').write_text('''{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  outputs = { nixpkgs, ... }: {
    nixosConfigurations.existing-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
''')
        (original / 'flake.lock').write_text(json.dumps({
            'version': 7, 'root': 'root', 'nodes': {
                'root': {'inputs': {'nixpkgs': 'nixpkgs'}}, 'nixpkgs': node,
            },
        }, indent=2))
    candidate = base / kind / 'candidate'
    candidate.mkdir()
    prepare.generate(dict(ROOT=str(root), output=str(candidate), config_dir=str(original),
        existing_host='existing-host', profile='desktop', mode='integrate',
        gpu='amd', vietnamese='false', cloud='auto', docker='false',
        gnome='true', hyprland='true'))
    assert (candidate / 'existing/configuration.nix').read_bytes() == (original / 'configuration.nix').read_bytes()
    assert (candidate / 'workstation-source/flake.lock').read_bytes() == (root / 'flake.lock').read_bytes()
print('Prepared independent flake and non-flake candidates')

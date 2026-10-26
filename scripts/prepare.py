#!/usr/bin/env python3
"""Generate a private, reviewable candidate from immutable source snapshots."""
import json
import os
from pathlib import Path
import shutil


def nix_string(value):
    return json.dumps(value).replace('${', r'\${')


def generate(env):
    out = Path(env['output'])
    ignore = shutil.ignore_patterns('.git', '.workstation', 'result', 'result-*', '__pycache__', '.aws', '.codex', '.agents', '.env', '*.pem', '*.key')
    source = Path(env['ROOT']).resolve()
    existing = Path(env['config_dir']).resolve()
    # Avoid recursive snapshots even for custom output directories within the source.
    def exclusions(directory, names):
        excluded = set(ignore(directory, names))
        for name in names:
            path = (Path(directory) / name).resolve()
            if path == out:
                excluded.add(name)
        return excluded
    shutil.copytree(source, out / 'workstation-source', ignore=exclusions, symlinks=True)
    module = {
        'enable': True, 'profile': env['profile'],
        'hardware.gpu': env['gpu'],
        'desktop.vietnamese.enable': env['vietnamese'] == 'true',
        'development.docker.enable': env['docker'] == 'true',
    }
    if env['cloud'] in ('true', 'false'):
        module['development.cloudTools.enable'] = env['cloud'] == 'true'
    if env['profile'] != 'core':
        module['desktop.gnome.enable'] = env['gnome'] == 'true'
        module['desktop.hyprland.enable'] = env['hyprland'] == 'true'
    values = '\n'.join(f'    {k} = {(nix_string(v) if isinstance(v, str) else json.dumps(v))};' for k, v in module.items())
    (out / 'workstation.nix').write_text('{ ... }: {\n  workstation = {\n' + values + '\n  };\n}\n')
    base = '  inputs.workstation.url = "path:./workstation-source";\n'
    if env['mode'] == 'integrate':
        shutil.copytree(existing, out / 'existing', ignore=exclusions, symlinks=True)
        if (existing / 'flake.nix').is_file():
            base += '  inputs.existing.url = "path:./existing";\n'
            body = f'''  outputs = {{ workstation, existing, ... }}: {{
    nixosConfigurations.workstation = existing.nixosConfigurations.{nix_string(env['existing_host'])}.extendModules {{
      modules = [ workstation.nixosModules.workstation ./workstation.nix ];
    }};
  }};
'''
        else:
            body = '''  outputs = { workstation, ... }: {
    nixosConfigurations.workstation = workstation.inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./existing/configuration.nix workstation.nixosModules.workstation ./workstation.nix ];
    };
  };
'''
    else:
        (out / 'existing').mkdir()
        for key in ('hardware', 'bootloader'):
            shutil.copy2(env[key], out / 'existing' / (key + '.nix'))
        body = '''  outputs = { workstation, ... }: {
    nixosConfigurations.workstation = workstation.inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./existing/hardware.nix ./existing/bootloader.nix
        workstation.nixosModules.workstation ./workstation.nix
        { networking.hostName = HOSTNAME; system.stateVersion = VERSION; }
      ];
    };
  };
'''.replace('HOSTNAME', nix_string(os.uname().nodename)).replace('VERSION', nix_string(env['state_version']))
    (out / 'flake.nix').write_text('{\n' + base + body + '}\n')
    (out / 'installation.json').write_text(json.dumps({k: env[k] for k in ('mode', 'profile', 'config_dir', 'existing_host', 'gpu')}, indent=2))


if __name__ == '__main__':
    generate(os.environ)

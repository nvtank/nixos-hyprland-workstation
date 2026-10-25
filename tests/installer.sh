#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
bash install.sh --help >/dev/null
fail() { echo "Test failed: $*" >&2; exit 1; }
reject() { if bash install.sh "$@" >/dev/null 2>&1; then fail "accepted $*"; fi; }
reject --unknown
reject --profile
reject --profile wrong
reject --gpu unsupported
reject --gpu hybrid-intel-nvidia
reject --non-interactive
reject --non-interactive --profile desktop --activate switch
reject --non-interactive --profile desktop --activate switch --allow-activation
bash scripts/uninstall.sh >/dev/null
if bash scripts/validate.sh /nonexistent >/dev/null 2>&1; then fail 'accepted missing files'; fi
# Test generation in isolation, including a nonstandard username/home and host.
python3 - <<'PY'
import importlib.util
import os
from pathlib import Path
import tempfile
spec = importlib.util.spec_from_file_location('prepare', 'scripts/prepare.py')
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)
with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    original = root / 'original'
    original.mkdir()
    config = '{ ... }: { networking.hostName = "hoang-laptop"; users.users.hoang.home = "/srv/hoang"; }'
    (original / 'configuration.nix').write_text(config)
    for profile in ('core', 'desktop', 'full'):
        output = root / profile
        output.mkdir()
        env = dict(ROOT=str(Path.cwd()), output=str(output), config_dir=str(original), existing_host='', profile=profile, mode='integrate', gpu='amd', vietnamese='false', cloud='false', docker='false', gnome='true', hyprland='true')
        prepare.generate(env)
        assert (output / 'existing/configuration.nix').read_text() == config
        module = (output / 'workstation.nix').read_text()
        assert f'profile = "{profile}"' in module
        assert 'nvtank' not in module and 'uuid' not in module and 'nvidia' not in module
        assert 'amd' in module
        assert (original / 'configuration.nix').read_text() == config
print('installer generation and source backup tests passed')
PY
# A failing build must stop validation; no activation command may be reached.
tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
mkdir "$tmp/bin" "$tmp/candidate"
touch "$tmp/candidate/flake.nix" "$tmp/candidate/workstation.nix" "$tmp/candidate/flake.lock"
cat > "$tmp/bin/nix" <<'MOCK'
#!/usr/bin/env bash
case "$1" in eval) exit 0 ;; build) exit 42 ;; *) exit 99 ;; esac
MOCK
mock_bash=$(command -v bash)
sed -i "1c#!$mock_bash" "$tmp/bin/nix"
chmod +x "$tmp/bin/nix"
if PATH="$tmp/bin:$PATH" bash scripts/validate.sh "$tmp/candidate" >/dev/null 2>&1; then fail 'ignored failed build'; fi
echo 'installer tests passed'

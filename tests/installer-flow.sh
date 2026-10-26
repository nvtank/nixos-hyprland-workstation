#!/usr/bin/env bash
# Exercise the real CLI in a copied repository with OS detection and Nix mocked.
# No test runs sudo, nixos-rebuild, or a real system activation.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/repo" "$scratch/host" "$scratch/bin"
cp -R "$ROOT/scripts" "$ROOT/install.sh" "$scratch/repo/"
touch "$scratch/NIXOS"
python3 - "$scratch/repo/scripts/install.sh" "$scratch/NIXOS" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
assert '[[ -f /etc/NIXOS ]]' in s
p.write_text(s.replace('[[ -f /etc/NIXOS ]]', '[[ -f ' + sys.argv[2] + ' ]]'))
PY
printf '{ ... }: { networking.hostName = "hoang-laptop"; }\n' > "$scratch/host/configuration.nix"
export MOCK_LOG="$scratch/commands" MOCK_FAIL_BUILD=false
touch "$MOCK_LOG"
cat > "$scratch/bin/nix" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$MOCK_LOG"
case "$1" in
  flake) exit 0 ;;
  eval) printf '"mock-evaluated-derivation"\n' ;;
  build)
    [[ "$MOCK_FAIL_BUILD" != true ]] || exit 42
    while (($#)); do
      if [[ "$1" == --out-link ]]; then
        mkdir -p "$2/bin"
        touch "$2/bin/switch-to-configuration"
        exit 0
      fi
      shift
    done
    exit 43 ;;
  store) echo 'mock closure diff' ;;
  *) exit 44 ;;
esac
MOCK
cat > "$scratch/bin/sudo" <<'MOCK'
#!/usr/bin/env bash
printf 'UNEXPECTED SUDO\n' >> "$MOCK_LOG"
exit 99
MOCK
cat > "$scratch/bin/uname" <<'MOCK'
#!/usr/bin/env bash
echo x86_64
MOCK
# Nix build sandboxes do not provide /usr/bin/env for generated mock scripts.
mock_bash=$(command -v bash)
for mock in "$scratch/bin/"*; do sed -i "1c#!$mock_bash" "$mock"; done
chmod +x "$scratch/bin/"*
export PATH="$scratch/bin:$PATH"
bash "$scratch/repo/install.sh" --non-interactive --profile desktop --gpu amd \
  --config-dir "$scratch/host" --output "$scratch/prepared" --prepare-only > "$scratch/prepare.log"
[[ -f "$scratch/prepared/existing/configuration.nix" ]]
[[ ! -s "$MOCK_LOG" ]] # preparation never builds or activates a non-flake host
bash "$scratch/repo/install.sh" --non-interactive --profile core \
  --config-dir "$scratch/host" --output "$scratch/built" > "$scratch/build.log"
grep -q 'Build passed. No system changes applied.' "$scratch/build.log"
export MOCK_FAIL_BUILD=true
if bash "$scratch/repo/install.sh" --non-interactive --profile desktop \
  --config-dir "$scratch/host" --output "$scratch/failed" > "$scratch/failed.log" 2>&1; then
  echo 'Installer ignored build failure' >&2; exit 1
fi
if grep -q 'UNEXPECTED SUDO' "$MOCK_LOG"; then echo 'Unexpected activation attempt' >&2; exit 1; fi
if grep -q 'Persistent generation verified' "$scratch/failed.log"; then echo 'False success report' >&2; exit 1; fi
[[ "$(cat "$scratch/host/configuration.nix")" == '{ ... }: { networking.hostName = "hoang-laptop"; }' ]]
# Dry-run must not create its output directory or issue any Nix command.
: > "$MOCK_LOG"
bash "$scratch/repo/install.sh" --non-interactive --profile desktop --dry-run \
  --config-dir "$scratch/host" --output "$scratch/dry" >/dev/null
[[ ! -e "$scratch/dry" && ! -s "$MOCK_LOG" ]]
echo 'Mocked installer flow tests passed'

# A reviewed candidate can be resumed without rereading the original host tree.
export MOCK_FAIL_BUILD=false
bash "$scratch/repo/install.sh" --non-interactive --candidate "$scratch/prepared" > "$scratch/resume.log"
grep -q 'Build passed. No system changes applied.' "$scratch/resume.log"
if bash "$scratch/repo/install.sh" --candidate "$scratch/prepared" --profile core >/dev/null 2>&1; then
  echo 'Resume accepted conflicting selection flags' >&2; exit 1
fi

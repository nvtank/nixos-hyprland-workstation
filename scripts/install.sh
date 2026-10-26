#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fail() { echo "workstation: $*" >&2; exit 1; }
usage() {
  cat <<'HELP'
Usage: ./install.sh [options]
  --profile core|desktop|full   Preset (interactive prompt when omitted)
  --mode integrate|standalone Default: integrate existing configuration
  --config-dir PATH           Existing configuration (default /etc/nixos)
  --existing-host NAME        Existing flake output (auto-select only if unique)
  --candidate PATH            Resume a prepared candidate (review/edit its workstation.nix)
  --output PATH               New, empty staging directory (default .workstation/TIMESTAMP)
  --gpu preserve|intel|amd|nvidia   Default preserve; hybrid: configure manually
  --without-cloud-tools       Full toolchains without Terraform/cloud packages
  --vietnamese --cloud-tools --docker   Explicit optional features
  --without-gnome --without-hyprland    Explicit desktop exclusions
  --hardware FILE --bootloader FILE --state-version VERSION  Standalone requirements
  --dry-run                   Inspect and print plan; write nothing, build nothing
  --prepare-only              Snapshot sources and generate candidate; no build or activation
  --non-interactive --profile PROFILE  Build only unless activation explicitly requested
  --activate test|switch      Activation requires a successful build and test
  --allow-activation          Required for non-interactive activation
  --confirm-tested           Non-interactive switch: affirm desktop/hardware were reviewed
  --help
Never edits /etc/nixos, partitions disks, changes passwords or reboots.
Back up secrets and personal data separately. Review the candidate before activation.
HELP
}
profile='' mode=integrate config_dir=/etc/nixos existing_host='' output='' gpu=preserve
prepare=false dry=false interactive=true activate='' allow=false confirmed=false
vietnamese=false cloud=auto docker=false gnome=true hyprland=true
hardware='' bootloader='' state_version='' candidate='' selection=false
value() { [[ $# -ge 2 && -n "$2" && "$2" != --* ]] || fail "Missing value for $1"; }
while (($#)); do
  case "$1" in
    --profile|--mode|--config-dir|--existing-host|--output|--gpu|--hardware|--bootloader|--state-version|--vietnamese|--cloud-tools|--without-cloud-tools|--docker|--without-gnome|--without-hyprland) selection=true ;;
  esac
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --profile|--mode|--config-dir|--existing-host|--output|--gpu|--activate|--hardware|--bootloader|--state-version|--candidate)
      value "$@"
      case "$1" in
        --profile) profile=$2 ;; --mode) mode=$2 ;; --config-dir) config_dir=$2 ;;
        --existing-host) existing_host=$2 ;; --output) output=$2 ;; --gpu) gpu=$2 ;;
        --activate) activate=$2 ;; --hardware) hardware=$2 ;; --bootloader) bootloader=$2 ;;
        --state-version) state_version=$2 ;; --candidate) candidate=$2 ;;
      esac; shift 2 ;;
    --prepare-only) prepare=true; shift ;; --dry-run) dry=true; shift ;;
    --non-interactive) interactive=false; shift ;; --allow-activation) allow=true; shift ;;
    --confirm-tested) confirmed=true; shift ;; --vietnamese) vietnamese=true; shift ;;
    --cloud-tools) cloud=true; shift ;; --without-cloud-tools) cloud=false; shift ;; --docker) docker=true; shift ;;
    --without-gnome) gnome=false; shift ;; --without-hyprland) hyprland=false; shift ;;
    *) fail "Unknown option: $1 (see --help)" ;;
  esac
done
case "$profile" in ''|core|desktop|full) ;; *) fail 'Invalid profile' ;; esac
case "$mode" in integrate|standalone) ;; *) fail 'Invalid mode' ;; esac
case "$gpu" in preserve|intel|amd|nvidia) ;; *) fail 'Unsupported GPU selection; hybrid needs manual PCI bus IDs (docs/configuration.md)' ;; esac
case "$activate" in ''|test|switch) ;; *) fail 'Invalid activation mode' ;; esac
[[ -z "$candidate" || "$selection" == false ]] || fail 'With --candidate, edit its workstation.nix instead of passing new profile/hardware options'
[[ "$interactive" == true || -n "$profile" || -n "$candidate" ]] || fail '--non-interactive requires --profile'
[[ "$interactive" == true || -z "$activate" || "$allow" == true ]] || fail 'Non-interactive activation requires --allow-activation'
[[ "$interactive" == true || "$activate" != switch || "$confirmed" == true ]] || fail 'Non-interactive switch requires --confirm-tested'
[[ -f /etc/NIXOS ]] || fail 'This installer requires an existing NixOS system'
[[ "$EUID" != 0 ]] || fail 'Run as a normal user; sudo is used only for explicit activation'
case "$(uname -m)" in x86_64) ;; *) fail 'Installer supports x86_64 only; other architectures require manual evaluation' ;; esac
for cmd in nix python3 tar realpath hostname id; do command -v "$cmd" >/dev/null || fail "Missing required tool: $cmd"; done
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 12) else 1)' || fail 'Python 3.12+ is required; enter the pinned environment with nix develop'
if [[ -n "$candidate" ]]; then
  output=$(realpath -e "$candidate")
  [[ -f "$output/flake.nix" && -f "$output/workstation.nix" ]] || fail 'Candidate must contain flake.nix and workstation.nix'
  echo "Using reviewed candidate: $output"
  [[ "$dry" == false && "$prepare" == false ]] || exit 0
else
  bash "$ROOT/scripts/detect.sh"
  if [[ -z "$profile" && "$dry" == true ]]; then profile=desktop; fi
  if [[ -z "$profile" ]]; then
    read -r -p 'Profile [core/desktop/full] (desktop): ' profile
    profile=${profile:-desktop}
    case "$profile" in core|desktop|full) ;; *) fail 'Invalid profile' ;; esac
  fi
  if [[ "$interactive" == true && "$dry" == false ]]; then
    read -r -p 'Optional features: comma-separated vietnamese,cloud,docker (empty keeps defaults): ' features
    IFS=, read -r -a selected <<< "$features"
    for feature in "${selected[@]}"; do
      case "$feature" in '' ) ;; vietnamese) vietnamese=true ;; cloud) cloud=true ;; docker) docker=true ;; *) fail "Unknown feature $feature" ;; esac
    done
  fi
  config_dir=$(realpath -e "$config_dir")
  if [[ "$mode" == integrate ]]; then
    [[ -f "$config_dir/flake.nix" || -f "$config_dir/configuration.nix" ]] || fail 'Missing flake.nix or configuration.nix'
    if [[ -f "$config_dir/flake.nix" ]]; then
      [[ -f "$config_dir/flake.lock" ]] || fail 'Existing flake needs a lock file; pin it explicitly before integration'
      if [[ "$dry" == false ]]; then
        hosts=$(nix eval --json --no-write-lock-file "path:$config_dir#nixosConfigurations" --apply builtins.attrNames)
        existing_host=$(python3 -c 'import json,sys; h=json.loads(sys.argv[1]); requested=sys.argv[2]; print(requested if requested in h else h[0] if not requested and len(h)==1 else "")' "$hosts" "$existing_host")
        [[ -n "$existing_host" ]] || fail 'Select a valid existing output with --existing-host (multiple outputs or invalid name)'
      fi
    fi
  else
    [[ -f "$hardware" && -f "$bootloader" ]] || fail 'Standalone requires --hardware and --bootloader files'
    [[ "$state_version" =~ ^[0-9]{2}\.[0-9]{2}$ ]] || fail 'Standalone requires --state-version, e.g. 25.11'
  fi
  printf 'Plan: %s; profile=%s; GPU=%s; existing=%s#%s\n' "$mode" "$profile" "$gpu" "$config_dir" "$existing_host"
  echo 'Candidate adds modules to a snapshot; original host, accounts, filesystems and bootloader remain defined by your source.'
  echo 'Review display-manager/audio conflicts and unfree licenses. No conflicts are force-overridden.'
  [[ "$dry" == false ]] || exit 0
  output=${output:-"$ROOT/.workstation/$(date -u +%Y%m%dT%H%M%S)-$$"}
  [[ ! -e "$output" ]] || fail 'Output already exists; choose a fresh directory'
  umask 077
  mkdir -p -- "$output"
  output=$(realpath "$output")
  export ROOT profile mode config_dir existing_host output gpu vietnamese cloud docker gnome hyprland hardware bootloader state_version
  python3 "$ROOT/scripts/prepare.py"
  echo "Prepared: $output"
  echo 'Backup: existing/ (source snapshot; excludes Git, results, staging and common credential files).'
  echo 'Recovery: boot a previous generation, or sudo nixos-rebuild switch --rollback. See docs/rollback.md.'
  [[ "$prepare" == false ]] || exit 0
fi
if ! bash "$ROOT/scripts/validate.sh" "$output"; then
  fail "Candidate validation/build failed. No activation was attempted. Review $output and retry with --candidate $output"
fi
[[ -f "$output/candidate/bin/switch-to-configuration" ]] || fail 'Build produced no activatable candidate'
echo 'Planned system changes:'
nix store diff-closures /run/current-system "$output/candidate"
if [[ "$interactive" == true && -z "$activate" ]]; then
  read -r -p 'Review the candidate and diff above. Type test to activate temporarily (empty stops): ' activate
  [[ "$activate" == test ]] || { echo 'Built only. No system changes applied.'; exit 0; }
fi
[[ -n "$activate" ]] || { echo 'Build passed. No system changes applied.'; exit 0; }
effective=$(nix eval --json --no-write-lock-file "path:$output#nixosConfigurations.workstation.config.workstation" --apply 'w: { profile = w.profile; gnome = w.desktop.gnome.enable; hyprland = w.desktop.hyprland.enable; }')
profile=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["profile"])' "$effective")
gnome=$(python3 -c 'import json,sys; print(str(json.loads(sys.argv[1])["gnome"]).lower())' "$effective")
hyprland=$(python3 -c 'import json,sys; print(str(json.loads(sys.argv[1])["hyprland"]).lower())' "$effective")
# shellcheck disable=SC2016 # ${name} is Nix attribute interpolation.
accounts=$(nix eval --json --no-write-lock-file "path:$output#nixosConfigurations.workstation.config.users.users" --apply 'users: builtins.filter (name: users.${name}.isNormalUser) (builtins.attrNames users)')
python3 -c 'import json,sys; sys.exit(0 if sys.argv[2] in json.loads(sys.argv[1]) else 1)' "$accounts" "$(id -un)" || fail 'The candidate does not declare your normal login account; add your existing account settings before activation'
for cmd in sudo nixos-rebuild systemctl; do command -v "$cmd" >/dev/null || fail "Missing activation tool: $cmd"; done
if [[ "$interactive" == true ]]; then
  read -r -p 'Type ACTIVATE to confirm reviewed desktop/service changes and temporary activation: ' answer
  [[ "$answer" == ACTIVATE ]] || fail 'Activation cancelled'
fi
previous=$(readlink -f /run/current-system)
printf '%s\n' "$previous" > "$output/previous-system"
sudo nixos-rebuild test --flake "path:$output#workstation" --no-write-lock-file
[[ "$(readlink -f /run/current-system)" == "$(readlink -f "$output/candidate")" ]] || fail 'Test did not activate expected system; see recovery instructions'
if [[ "$profile" != core && "$gnome" == true ]]; then
  systemctl is-active --quiet display-manager.service || fail 'Display manager is not active; restore previous generation (docs/rollback.md)'
fi
echo 'Temporary activation verified. Check login, GNOME, Hyprland, networking and GPU on real hardware.'
if [[ "$interactive" == true ]]; then
  read -r -p 'After checking the desktop, type SWITCH to persist (empty leaves test active): ' answer
  [[ "$answer" == SWITCH ]] && activate=switch || activate='test'
fi
if [[ "$activate" == switch ]]; then
  sudo nixos-rebuild switch --flake "path:$output#workstation" --no-write-lock-file
  [[ "$(readlink -f /nix/var/nix/profiles/system)" == "$(readlink -f "$output/candidate")" ]] || fail 'Persistent generation verification failed'
  echo 'Persistent generation verified. Keep this candidate directory for future rebuilds.'
fi
if [[ "$profile" != core && "$hyprland" == true ]]; then
  echo 'Run end4-setup as your desktop user when ready; existing dotfiles are preserved until then.'
fi

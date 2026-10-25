#!/usr/bin/env bash
# Run only against isolated XDG trees, never a real home configuration.
set -euo pipefail
[[ $# == 2 ]] || { echo 'Usage: end4-setup.sh SETUP_BINARY ROLLBACK_BINARY' >&2; exit 2; }
setup=$1 rollback=$2
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export XDG_CONFIG_HOME="$scratch/config" XDG_STATE_HOME="$scratch/state"
mkdir -p "$XDG_CONFIG_HOME/hypr" "$XDG_CONFIG_HOME/quickshell"
printf 'original-hypr\n' > "$XDG_CONFIG_HOME/hypr/sentinel"
printf 'original-qs\n' > "$XDG_CONFIG_HOME/quickshell/sentinel"
printf 'unrelated\n' > "$XDG_CONFIG_HOME/keep"
"$setup" --check
"$setup"
[[ -s "$XDG_CONFIG_HOME/hypr/custom/keybinds.lua" ]]
[[ -s "$XDG_CONFIG_HOME/quickshell/end4-pC/modules/ii/lock/LockVisual.qml" ]]
[[ -L "$XDG_STATE_HOME/end4-nixos/current-backup" ]]
"$rollback"
[[ "$(cat "$XDG_CONFIG_HOME/hypr/sentinel")" == original-hypr ]]
[[ "$(cat "$XDG_CONFIG_HOME/quickshell/sentinel")" == original-qs ]]
[[ "$(cat "$XDG_CONFIG_HOME/keep")" == unrelated ]]
# A failure after directory exchange must restore both old directories.
touch "$XDG_CONFIG_HOME/illogical-impulse.blocked"
rmdir "$XDG_CONFIG_HOME/illogical-impulse"
mv "$XDG_CONFIG_HOME/illogical-impulse.blocked" "$XDG_CONFIG_HOME/illogical-impulse"
if "$setup"; then echo 'Unexpected setup success with conflicting settings file' >&2; exit 1; fi
[[ "$(cat "$XDG_CONFIG_HOME/hypr/sentinel")" == original-hypr ]]
[[ "$(cat "$XDG_CONFIG_HOME/quickshell/sentinel")" == original-qs ]]
# Refuse a symlink conflict without touching its target or unrelated data.
mv "$XDG_CONFIG_HOME/hypr" "$scratch/managed-hypr"
ln -s "$scratch/managed-hypr" "$XDG_CONFIG_HOME/hypr"
if "$setup"; then echo 'Unexpected setup success with symlink conflict' >&2; exit 1; fi
[[ "$(cat "$scratch/managed-hypr/sentinel")" == original-hypr ]]
[[ "$(cat "$XDG_CONFIG_HOME/keep")" == unrelated ]]
echo 'Packaged end4 setup/rollback integration tests passed'

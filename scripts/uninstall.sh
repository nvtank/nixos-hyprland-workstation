#!/usr/bin/env bash
set -euo pipefail
cat <<'HELP'
This helper removes no files or user data.
For a staged installation: rebuild your original configuration to remove the
workstation additions, or boot the previous generation. Persistent rollback:
  sudo nixos-rebuild switch --rollback
For a manually integrated host: remove its workstation module import and options,
then build, test and switch your original host. Keep its hardware and account settings.
For user dotfiles: run end4-rollback as your desktop user. It restores only hypr
and quickshell and preserves the replaced trees in a separate recovery directory.
Keep source snapshots and backups until recovery has been verified.
HELP

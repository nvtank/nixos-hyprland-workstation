#!/usr/bin/env bash
# Compatibility helper; activation is always explicit.
set -euo pipefail
echo 'Cốc Cốc is optional. Set workstation.applications.coccoc.enable = true in your host.'
echo 'Allow its unfree license, then build and test using a reviewed WORKSTATION_FLAKE.'
exec bash "$(dirname -- "${BASH_SOURCE[0]}")/scripts/workstation" help

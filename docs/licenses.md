# Licenses and attribution

Original code and documentation contributed to this project by nvtank are
licensed under **GPL-3.0-only**, as provided in the root LICENSE. GPL version 3
is chosen for original work to fit the existing GPLv3 end4 ecosystem. This does
not change third-party copyrights or grant rights to proprietary packages.

The pinned end4-pC and dots-hyprland source trees each contain GPLv3 LICENSE
texts. They are fetched through the flake rather than relicensed or vendored by
this refactor. Their embedded fonts, widget shapes and other assets may have
additional notices; those source trees retain them. Custom lock QML and Lua
integrate with these projects. Inspect the relevant pinned upstream source when
distributing a combined desktop artifact.

Hyprland, Quickshell, NixOS/Nixpkgs and all other dependencies retain their own
licenses and copyright notices. Nixpkgs package metadata provides per-package
license information; a project-level license does not override it. Cốc Cốc,
NVIDIA drivers, Terraform and other selected packages may have nonfree or
source-available terms that require explicit acceptance.

The Btop palette derives from [Catppuccin/btop](https://github.com/catppuccin/btop).
Retain the theme project's upstream copyright and license notice when redistributing
its theme files; the root project license does not supersede that notice. Existing user Bat theme
files are not bundled or relicensed. Repository screenshots and diagrams are
preserved, with embedded third-party branding and desktop content retaining
applicable rights. Review asset provenance before republishing them separately.

Upstreams:

- https://github.com/hyprwm/Hyprland
- https://github.com/quickshell-mirror/quickshell
- https://github.com/end-4/dots-hyprland
- https://github.com/pctrade/end4-pC
- https://github.com/NixOS/nixpkgs
- https://github.com/catppuccin/btop

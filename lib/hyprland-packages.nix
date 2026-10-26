{
  lib,
  pkgs,
  workstationInputs,
}:
let
  hyprland = import ./hyprland-package.nix { inherit lib pkgs workstationInputs; };
in
{
  inherit hyprland;
  # The share-picker wrapper also depends on Hyprland. Replace that reference
  # too, otherwise a cold evaluation still reaches the unpatched package.
  portal =
    workstationInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland.override
      {
        inherit hyprland;
      };
}

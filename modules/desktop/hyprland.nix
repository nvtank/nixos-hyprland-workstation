{
  lib,
  pkgs,
  workstationInputs,
  ...
}:
let
  desktopPackages = import ../../lib/hyprland-packages.nix { inherit lib pkgs workstationInputs; };
in
{
  programs.hyprland = {
    enable = true;
    package = desktopPackages.hyprland;
    portalPackage = desktopPackages.portal;
    withUWSM = false;
  };
  services.displayManager.defaultSession = lib.mkDefault "hyprland";
}

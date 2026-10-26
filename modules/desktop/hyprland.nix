{
  lib,
  pkgs,
  workstationInputs,
  ...
}:
{
  programs.hyprland = {
    enable = true;
    package = import ../../lib/hyprland-package.nix { inherit lib pkgs workstationInputs; };
    portalPackage =
      workstationInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    withUWSM = false;
  };
  services.displayManager.defaultSession = lib.mkDefault "hyprland";
}

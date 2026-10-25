{
  lib,
  pkgs,
  workstationInputs,
  ...
}:
{
  programs.hyprland = {
    enable = true;
    package = workstationInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      workstationInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    withUWSM = false;
  };
  services.displayManager.defaultSession = lib.mkDefault "hyprland";
}

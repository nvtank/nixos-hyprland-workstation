{ config, pkgs, ... }:

{
  # Desktop UI
  services.xserver.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Font + icon + cursor (system-wide, chọn trong KDE Settings)
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  environment.systemPackages = with pkgs; [
    papirus-icon-theme
    bibata-cursors
  ];
}

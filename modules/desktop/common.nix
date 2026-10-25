{ lib, pkgs, ... }: {
  hardware.graphics.enable = true;
  services.pipewire = {
    enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
  };
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  environment.systemPackages = with pkgs; [
    firefox
    papirus-icon-theme
    bibata-cursors
    blueman
  ];
  fonts.packages = [ pkgs.noto-fonts-cjk-sans ];
}

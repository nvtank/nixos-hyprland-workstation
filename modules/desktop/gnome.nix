{ lib, ... }: {
  services.xserver.enable = true;
  services.displayManager.gdm.enable = lib.mkDefault true;
  services.desktopManager.gnome.enable = true;
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;
}

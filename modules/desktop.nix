{ config, pkgs, ... }:

{
  # server
  services.xserver.enable = true;

  # GNOME + GDM
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # GNOME
  programs.dconf.enable = true;

  # Âm thanh (PipeWire)
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  services.pulseaudio.enable = false;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Flatpak
  services.flatpak.enable = true;

  # Firewall
  networking.firewall.enable = true;
}

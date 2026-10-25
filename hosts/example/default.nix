# Evaluation fixture. Supply real hardware and bootloader settings for installation.
{ lib, ... }: {
  networking.hostName = "hoang-laptop";
  workstation = {
    enable = true;
    profile = "desktop";
    hardware.gpu = "amd";
  };
  users.users.hoang = {
    isNormalUser = true;
    home = "/home/hoang";
  };
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };
  boot.loader.grub.enable = false;
  boot.isContainer = true;
}

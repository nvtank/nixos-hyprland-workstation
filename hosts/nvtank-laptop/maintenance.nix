{ config, pkgs, ... }:

{
  # Giữ ít generations để menu boot không phình
  boot.loader.systemd-boot.configurationLimit = 10;

  # SSD TRIM (nếu bạn dùng SSD/NVMe)
  services.fstrim.enable = true;

  # ZRAM (giảm swap ra disk, mượt hơn khi thiếu RAM)
  zramSwap.enable = true;

  # Nix: tự dọn rác + tối ưu store
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # Auto-upgrade (flake)
  system.autoUpgrade = {
    enable = true;
    flake = "/etc/nixos#nixos";
    dates = "weekly";
    randomizedDelaySec = "45min";
    allowReboot = false; # true nếu bạn muốn tự reboot
  };
}

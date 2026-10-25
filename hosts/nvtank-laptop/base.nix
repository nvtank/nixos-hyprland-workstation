{
  config,
  pkgs,
  lib,
  ...
}:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Ho_Chi_Minh";

  i18n.supportedLocales = lib.mkForce [
    "en_US.UTF-8/UTF-8"
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      AlwaysPairable = true;
      PairableTimeout = 0;
    };
  };

  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    bluez
    kdePackages.bluedevil
  ];
}

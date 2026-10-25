{ lib, ... }: {
  workstation.enable = lib.mkDefault true;
  workstation.profile = lib.mkDefault "desktop";
}

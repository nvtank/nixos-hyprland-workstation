{ pkgs, ... }:

{
  users.users.nvtank = {
    isNormalUser = true;
    description = "nvtank";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "i2c"
    ];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = true;
}

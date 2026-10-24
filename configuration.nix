{ config, pkgs, unstablePkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/common.nix
    ./modules/base.nix
    ./modules/user.nix
    ./modules/vietnamese.nix
    ./modules/terminal.nix
    ./modules/shell.nix
    ./modules/ui.nix
    ./modules/desktop.nix
    ./modules/end4-hyprland.nix
    ./modules/packages.nix
    ./modules/dev.nix
    ./modules/maintenance.nix
    ./modules/coccoc.nix
  ];

  # Cho phép cài package unfree như spotify, google-chrome, kiro, nvidia...
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "nixos";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # GPU NVIDIA
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;

    # Driver NVIDIA proprietary thường ổn định hơn cho desktop/gaming/dev
    open = false;

    nvidiaSettings = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # GUI GNOME
  services.xserver.enable = true;

  services.desktopManager.gnome = {
    enable = true;
    extraGSettingsOverrides = ''
    '';
  };

  services.gnome.gnome-keyring.enable = true;

  # Docker
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker_29;
  };

  users.users.nvtank.extraGroups = [ "docker" ];
  # ZSH được cấu hình đầy đủ trong modules/shell.nix

  # Hỗ trợ chạy một số binary Linux ngoài NixOS
  programs.nix-ld.enable = true;

  # services.mongodb = {
  #   enable = true;
  #   package = pkgs.mongodb-ce;
  # };

  # Packages
  environment.systemPackages = with pkgs; [
    # Browser / desktop apps
    firefox
    zotero

    # Kiro AI IDE + CLI
    kiro

    # Basic tools
    wget
    curl
    git
    jq
    appimage-run
    unzip
    gnumake
    gcc
    pkg-config

    # Terminal / CLI tools
    awscli2
    ssm-session-manager-plugin
    terraform
    kubectl
    kubernetes-helm
    eksctl
    k9s

    # GNOME customization
    gnomeExtensions.user-themes
    gnome-tweaks
    sassc
    # Docker
    docker-compose

    # Dev libraries
    stdenv.cc.cc.lib
    zlib
    openssl

    # Database / backend tools
    postgresql
  ];

  system.stateVersion = "25.11";
}

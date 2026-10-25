{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    nodejs_22
    pnpm
    python3
    python3Packages.pip
    python3Packages.virtualenv
    jdk17
    maven
    gradle
    go
    gopls
    gcc
    gdb
    cmake
    ninja
    clang-tools
    neovim
    pkg-config
    gnumake
  ];
}

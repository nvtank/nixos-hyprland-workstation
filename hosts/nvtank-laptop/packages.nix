{
  pkgs,
  unstablePkgs,
  inputs,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    vscode # Using stable version to avoid build issues

    libreoffice-fresh
    git
    vim
    neovim
    wget
    curl
    htop
    tree
    unzip

    # Web
    nodejs_20
    pnpm

    # Python
    python3
    python3Packages.pip
    python3Packages.virtualenv

    # Java
    jdk17
    maven
    gradle

    # C/C++
    gcc
    gdb
    cmake
    ninja
    clang-tools

    # Go
    go
    gopls

    zip
    fastfetch
    appimage-run
    inputs.antigravity.packages.${pkgs.stdenv.hostPlatform.system}.default

    # AI CLI tools
    unstablePkgs.codex
  ];
}

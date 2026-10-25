{ pkgs, ... }: {

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  programs.git.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
  ];
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    jq
    unzip
    tree
  ];
}

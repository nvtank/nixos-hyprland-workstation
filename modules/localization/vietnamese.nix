{ pkgs, ... }:

{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-bamboo
      qt6Packages.fcitx5-unikey
      qt6Packages.fcitx5-configtool
    ];
  };
}

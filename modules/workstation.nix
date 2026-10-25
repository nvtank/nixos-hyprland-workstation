{
  config,
  lib,
  pkgs,
  workstationInputs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    mkMerge
    ;
  cfg = config.workstation;
  desktop = cfg.profile != "core";
  full = cfg.profile == "full";
  graphical = desktop || cfg.desktop.gnome.enable || cfg.desktop.hyprland.enable;
  conditional =
    enabled: path: args:
    mkIf enabled (import path args);
in
{
  imports = [ ./hardware/graphics.nix ];
  options.workstation = {
    enable = mkEnableOption "the reusable workstation";
    profile = mkOption {
      type = types.enum [
        "core"
        "desktop"
        "full"
      ];
      default = "desktop";
      description = "Package and desktop preset. Features can be overridden individually.";
    };
    desktop = {
      gnome.enable = mkOption {
        type = types.bool;
        default = desktop;
        description = "GNOME and GDM fallback. Review existing display managers before enabling.";
      };
      hyprland.enable = mkOption {
        type = types.bool;
        default = desktop;
        description = "Pinned Hyprland session.";
      };
      end4.enable = mkOption {
        type = types.bool;
        default = cfg.desktop.hyprland.enable;
        description = "Pinned end4-pC, Quickshell and explicit user setup helpers.";
      };
      vietnamese.enable = mkEnableOption "Vietnamese Fcitx5 input";
    };
    development = {
      enable = mkOption {
        type = types.bool;
        default = full;
        description = "Language toolchains and development utilities.";
      };
      cloudTools.enable = mkOption {
        type = types.bool;
        default = full;
        description = "AWS, Terraform and Kubernetes tools (some require allowUnfree).";
      };
      docker.enable = mkEnableOption "Docker (membership in docker grants root-equivalent access; add groups yourself)";
    };
    applications = {
      coccoc.enable = mkEnableOption "the proprietary x86_64 Cốc Cốc browser";
      router9.enable = mkEnableOption "the 9Router container service";
      router9.image = mkOption {
        type = types.str;
        default = "";
        description = "Explicit ghcr.io/decolua/9router@sha256 digest; no mutable tag is accepted by the public module.";
      };
    };
    maintenance.enable = mkEnableOption "weekly store optimisation (does not prune generations)";
  };
  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.desktop.end4.enable || cfg.desktop.hyprland.enable;
          message = "end4 requires workstation.desktop.hyprland.enable.";
        }
        {
          assertion = !cfg.applications.coccoc.enable || pkgs.stdenv.hostPlatform.system == "x86_64-linux";
          message = "Cốc Cốc supports x86_64-linux only.";
        }
        {
          assertion =
            !cfg.applications.router9.enable
            ||
              builtins.match "ghcr.io/decolua/9router@sha256:[0-9a-f]{64}" cfg.applications.router9.image != null;
          message = "9Router requires an explicitly reviewed immutable image digest.";
        }
        {
          assertion = !cfg.applications.router9.enable || cfg.development.docker.enable;
          message = "9Router requires explicit workstation.development.docker.enable.";
        }
      ];

    }
    (conditional true ./core/default.nix { inherit pkgs; })
    (conditional true ./core/commands.nix { inherit pkgs; })
    (conditional true ./shell/default.nix { inherit config lib pkgs; })
    (conditional cfg.desktop.gnome.enable ./desktop/gnome.nix { inherit lib; })
    (conditional (cfg.desktop.hyprland.enable && !cfg.desktop.end4.enable) ./desktop/hyprland.nix {
      inherit lib pkgs workstationInputs;
    })
    (conditional cfg.desktop.end4.enable ./desktop/end4.nix {
      inherit
        config
        lib
        pkgs
        workstationInputs
        ;
    })
    (conditional graphical ./desktop/common.nix { inherit config lib pkgs; })
    (conditional graphical ./desktop/terminal.nix { inherit config pkgs; })
    (conditional cfg.desktop.vietnamese.enable ./localization/vietnamese.nix { inherit pkgs; })
    (conditional cfg.development.enable ./development/default.nix { inherit pkgs; })
    (conditional cfg.development.cloudTools.enable ./development/cloud.nix { inherit pkgs; })
    (conditional cfg.applications.coccoc.enable ./coccoc.nix { inherit pkgs; })
    (conditional cfg.applications.router9.enable ./9router.nix { inherit config lib pkgs; })
    (mkIf cfg.development.docker.enable { virtualisation.docker.enable = true; })
    (conditional cfg.maintenance.enable ./maintenance/default.nix { })
  ]);
}

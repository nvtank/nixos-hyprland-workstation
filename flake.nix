{
  description = "Reusable NixOS workstation with GNOME, Hyprland and end4-pC";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    antigravity.url = "github:jacopone/antigravity-nix";

    # Pinned desktop stack for the optional end4 Hyprland session.  Keeping
    # these separate from nixpkgs lets GNOME remain on the stable system set.
    hyprland.url = "github:hyprwm/Hyprland/v0.55.0";
    quickshell = {
      # Includes the PipeWire default-sink lifetime fix from quickshell#568.
      url = "github:quickshell-mirror/quickshell/13fe9b0d98028361344b7422b1ebe238d1d29d02";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    illogical-impulse = {
      url = "github:end-4/dots-hyprland/aed4d1ec63f584905c28d2a678db5845579fdafc";
      flake = false;
    };
    end4-pc = {
      url = "github:pctrade/end4-pC";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      workstationModule = {
        _module.args.workstationInputs = inputs;
        imports = [ ./modules/workstation.nix ];
      };
      personal = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          workstationInputs = inputs;
          unstablePkgs = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };
        modules = [
          ./configuration.nix
          ./modules/core/commands.nix
        ];
      };
      example =
        profile:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            workstationModule
            ./hosts/example
            {
              workstation.profile = nixpkgs.lib.mkForce profile;
              nixpkgs.config.allowUnfree = true;
            }
          ];
        };
      desktopTool =
        name:
        nixpkgs.lib.findFirst (
          p: (p.pname or p.name) == name
        ) (throw "Missing desktop helper: ${name}") fixtures.desktop.config.environment.systemPackages;
      fixtures = builtins.listToAttrs (
        map
          (profile: {
            name = profile;
            value = example profile;
          })
          [
            "core"
            "desktop"
            "full"
          ]
      );
    in
    {
      nixosModules = {
        default = workstationModule;
        workstation = workstationModule;
        core = {
          imports = [
            workstationModule
            ./profiles/core.nix
          ];
        };
        desktop = {
          imports = [
            workstationModule
            ./profiles/desktop.nix
          ];
        };
        full = {
          imports = [
            workstationModule
            ./profiles/full.nix
          ];
        };
      };
      nixosConfigurations = fixtures // {
        nixos = personal; # Original rebuild commands remain valid.
        nvtank-laptop = personal; # Output name deliberately differs from hostName.
        example = fixtures.desktop;
      };
      formatter.${system} = pkgs.nixfmt-rfc-style;
      checks.${system} =
        builtins.mapAttrs
          (
            name: host:
            pkgs.runCommand "evaluate-${name}"
              { drv = builtins.unsafeDiscardStringContext host.config.system.build.toplevel.drvPath; }
              ''
                printf '%s\n' "$drv" > "$out"
              ''
          )
          (
            fixtures
            // {
              inherit personal;
              example = fixtures.desktop;
            }
          )
        // {
          end4-setup = pkgs.runCommand "end4-setup-integration" { nativeBuildInputs = [ pkgs.bash ]; } ''
            bash ${./tests/end4-setup.sh} ${desktopTool "end4-setup"}/bin/end4-setup ${desktopTool "end4-rollback"}/bin/end4-rollback
            touch "$out"
          '';
          portability = import ./tests/portability.nix { inherit pkgs nixpkgs workstationModule; };
          scripts =
            pkgs.runCommand "workstation-scripts"
              {
                nativeBuildInputs = [
                  pkgs.bash
                  pkgs.python3
                  pkgs.shellcheck
                  pkgs.hostname
                ];
              }
              ''
                cp -r ${self} source
                chmod -R u+w source
                cd source
                bash tests/installer.sh
                bash tests/installer-flow.sh
                python3 tests/end4-rollback.py
                shellcheck install.sh scripts/*.sh scripts/workstation install-coccoc.sh tests/*.sh
                touch "$out"
              '';
        };
    };
}

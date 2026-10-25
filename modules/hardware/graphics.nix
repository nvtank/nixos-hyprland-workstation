{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.workstation;
  gpu = cfg.hardware.gpu;
  nvidia = builtins.elem gpu [
    "nvidia"
    "hybrid-intel-nvidia"
    "hybrid-amd-nvidia"
  ];
  hybrid = builtins.elem gpu [
    "hybrid-intel-nvidia"
    "hybrid-amd-nvidia"
  ];
in
{
  options.workstation.hardware = {
    gpu = lib.mkOption {
      type = lib.types.enum [
        "preserve"
        "intel"
        "amd"
        "nvidia"
        "hybrid-intel-nvidia"
        "hybrid-amd-nvidia"
      ];
      default = "preserve";
      description = "Explicit driver choice; preserve leaves current drivers untouched. Hybrid profiles use PRIME offload.";
    };
    nvidiaBusId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "NVIDIA PCI bus ID, e.g. PCI:1:0:0; required for hybrid.";
    };
    integratedBusId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Intel/AMD PCI bus ID; required for hybrid.";
    };
  };
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !hybrid || (cfg.hardware.nvidiaBusId != "" && cfg.hardware.integratedBusId != "");
            message = "Hybrid graphics requires both explicit PRIME PCI bus IDs. Detection never chooses these for you.";
          }
          {
            assertion = !nvidia || pkgs.stdenv.hostPlatform.system == "x86_64-linux";
            message = "This project's NVIDIA profiles are validated for x86_64-linux only.";
          }
        ];
      }
      (lib.mkIf (gpu != "preserve") { hardware.graphics.enable = true; })
      (lib.mkIf (gpu == "amd") { services.xserver.videoDrivers = [ "amdgpu" ]; })
      (lib.mkIf nvidia {
        services.xserver.videoDrivers = [ "nvidia" ];
        hardware.nvidia = {
          modesetting.enable = true;
          open = lib.mkDefault false;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          prime = lib.mkIf hybrid (
            {
              offload.enable = true;
              offload.enableOffloadCmd = true;
              nvidiaBusId = cfg.hardware.nvidiaBusId;
            }
            // (
              if gpu == "hybrid-intel-nvidia" then
                { intelBusId = cfg.hardware.integratedBusId; }
              else
                { amdgpuBusId = cfg.hardware.integratedBusId; }
            )
          );
        };
      })
    ]
  );
}

{
  pkgs,
  nixpkgs,
  workstationModule,
}:
let
  make =
    profile: extra:
    nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        workstationModule
        ../hosts/example
        {
          workstation.profile = nixpkgs.lib.mkForce profile;
          nixpkgs.config.allowUnfree = true;
        }
        extra
      ];
    };
  desktop = (make "desktop" { }).config;
  core = (make "core" { }).config;
  full = (make "full" { }).config;
  other =
    (make "core" {
      networking.hostName = nixpkgs.lib.mkForce "another-host";
      users.users.alice = {
        isNormalUser = true;
        home = "/srv/alice";
      };
    }).config;
  disabled = (make "desktop" { workstation.enable = nixpkgs.lib.mkForce false; }).config;
  invalid =
    (make "desktop" { workstation.hardware.gpu = nixpkgs.lib.mkForce "hybrid-intel-nvidia"; }).config;
  gpuConfig =
    gpu:
    (make "core" {
      workstation.hardware = {
        gpu = nixpkgs.lib.mkForce gpu;
        integratedBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    }).config;
  invalidEnd4 = (make "core" { workstation.desktop.end4.enable = true; }).config;
  invalidRouter = (make "core" { workstation.applications.router9.enable = true; }).config;
  ok = c: builtins.all (a: a.assertion) c.assertions;
in
assert ok desktop && ok core && ok full;
assert desktop.networking.hostName == "hoang-laptop";
assert desktop.users.users.hoang.home == "/home/hoang";
assert !(desktop.users.users ? nvtank);
assert !(builtins.elem "nvidia" desktop.services.xserver.videoDrivers);
assert !(desktop.boot.loader.systemd-boot.enable);
assert desktop.fileSystems."/".device == "none";
assert desktop.services.desktopManager.gnome.enable;
assert desktop.services.displayManager.gdm.enable;
assert desktop.programs.hyprland.enable;
assert !(desktop.systemd.user.services ? fcitx5-daemon);
assert !core.programs.hyprland.enable && !core.services.desktopManager.gnome.enable;
assert !core.virtualisation.docker.enable && !full.virtualisation.docker.enable;
assert !core.system.autoUpgrade.enable;
assert full.workstation.development.cloudTools.enable;
assert other.networking.hostName == "another-host" && other.users.users.alice.home == "/srv/alice";
assert !disabled.programs.hyprland.enable;
assert !ok invalid;
assert builtins.all (gpu: ok (gpuConfig gpu)) [
  "preserve"
  "intel"
  "amd"
  "nvidia"
  "hybrid-intel-nvidia"
  "hybrid-amd-nvidia"
];
assert (gpuConfig "hybrid-intel-nvidia").hardware.nvidia.prime.intelBusId == "PCI:0:2:0";
assert (gpuConfig "hybrid-amd-nvidia").hardware.nvidia.prime.amdgpuBusId == "PCI:0:2:0";
assert !ok invalidEnd4 && !ok invalidRouter;
assert !(builtins.tryEval (make "invalid-profile" { }).config.workstation.profile).success;
assert
  !(builtins.tryEval
    (make "core" { workstation.hardware.gpu = nixpkgs.lib.mkForce "invalid-gpu"; })
    .config.workstation.hardware.gpu
  ).success;
pkgs.runCommand "workstation-portability" { } ''touch "$out"''

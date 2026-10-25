{ pkgs, ... }: {
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "workstation";
      runtimeInputs = with pkgs; [
        coreutils
        git
        nix
      ];
      text = builtins.readFile ../../scripts/workstation;
    })
  ];
}

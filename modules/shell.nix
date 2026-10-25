# Compatibility import. New configurations should import nixosModules.workstation.
{ ... }: { imports = [ ./shell/default.nix ]; }

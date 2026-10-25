# Compatibility import. New configurations should import nixosModules.workstation.
{ ... }: { imports = [ ./desktop/end4.nix ]; }

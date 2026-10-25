# Compatibility import. New configurations should import nixosModules.workstation.
{ ... }: { imports = [ ./desktop/ui.nix ]; }

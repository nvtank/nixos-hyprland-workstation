# Compatibility import. New configurations should import nixosModules.workstation.
{ ... }: { imports = [ ./desktop/terminal.nix ]; }

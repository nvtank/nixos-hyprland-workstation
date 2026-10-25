# Compatibility import. New configurations should import nixosModules.workstation.
{ ... }: { imports = [ ./localization/vietnamese.nix ]; }

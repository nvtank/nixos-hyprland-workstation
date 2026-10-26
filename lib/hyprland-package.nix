# Preserve the pinned package/source while avoiding an evaluation-time read from
# fileset.toSource. On a cold Nix 2.35 store that path may not exist yet.
{
  lib,
  pkgs,
  workstationInputs,
}:
let
  upstream = workstationInputs.hyprland;
  version = lib.trim (builtins.readFile (upstream + "/VERSION"));
in
upstream.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.overrideAttrs (old: {
  env = old.env // {
    GIT_TAG = "v${version}";
  };
})

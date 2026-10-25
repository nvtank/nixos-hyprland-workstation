# Cốc Cốc (optional, x86_64 only)

The public workstation does not install Cốc Cốc by default. In your host set:

```nix
workstation.applications.coccoc.enable = true;
```

Explicitly permit the browser's unfree license in your Nixpkgs policy, then
build and test your own flake before switching. See
[configuration](configuration.md) and [installation](installation.md).
`install-coccoc.sh` is a compatibility help command and no longer activates a
system automatically. The personal laptop retains its existing browser import.

The derivation retains version `152.0.7977.124-1`, its existing amd64 `.deb` URL
and fixed source hash. Availability and runtime sandbox/graphics behavior still
need validation against the upstream binary. Do not suppress missing required
libraries to force a build. The optional Qt dependencies in the original
packaging remain documented in the derivation.

To update, review the vendor release, change version and source hash explicitly,
and test the build/browser. To remove, disable the option, build/test/switch;
personal browser profile data is not deleted. Vendor: https://coccoc.com.

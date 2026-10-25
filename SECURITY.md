# Security policy

Do not disclose credentials, exploit details or private machine data in public
issues. Use the repository's private vulnerability reporting channel when enabled:
https://github.com/nvtank/nixos-hyprland-workstation/security/advisories/new

If that channel is unavailable, use a private contact method published on
https://github.com/nvtank. If no private route is available, open a minimal issue
requesting a confidential reporting channel without vulnerability details. The
maintainer should enable GitHub private vulnerability reporting before launch.
There is no published response-time guarantee or paid support commitment.

Include affected revision/profile, reproduction steps, impact and proposed
mitigations, with secrets redacted. Coordinate disclosure with the maintainer.
Report upstream vulnerabilities to their respective maintainers as appropriate.

Security fixes target the maintained repository state; old pins are not a
promise of current security patches. Inputs are intentionally pinned for
reproducibility, so updating vulnerable packages requires an explicit tested
lock change. Optional proprietary binaries and containers have separate upstream
lifecycles. The personal 9Router `latest` configuration remains a legacy exception;
public use requires an explicit immutable image digest.

Nix store contents are public. Keep plaintext credentials out of Nix modules,
installer snapshots and command-line arguments. Use an appropriate secret manager
and separate encrypted personal-data backups.

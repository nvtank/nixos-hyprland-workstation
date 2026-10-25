# Troubleshooting

Start with `workstation doctor`, the actual failing command output and your
candidate path. Do not delete the old configuration or update all inputs as a
first response. [Recovery procedures](rollback.md) remain available from a TTY.

| Problem | Useful checks and next step |
|---|---|
| Nix command unavailable / flakes disabled | Confirm NixOS and enable `nix-command flakes` in your existing config; rebuild that config first |
| Several existing outputs | Pass `--existing-host NAME`; the output need not equal your hostname |
| Missing import or absolute path | Inspect candidate `existing/`; copy required local modules explicitly; preserve real hardware files |
| Existing flake uses local path dependencies | Review/copy those dependencies and their lock references manually; automatic relocation is not guaranteed |
| GDM/SDDM conflict | Keep a working manager; explicitly review disabling the new GDM or migrating the old manager in the candidate |
| PulseAudio/PipeWire conflict | Review your current audio policy; do not force away working services blindly |
| Unfree package error | Approve only the chosen package licenses in your host; Full includes Terraform |
| `end4-setup` reports symlink conflict | Home Manager/stow or another tool owns the tree; back it up and reconcile ownership manually before setup |
| Upstream patch/staging failure | Old live configs remain; inspect exact pinned source paths and errors; do not run setup as root |
| No end4 rollback backup | Confirm XDG paths and backup directory; command refuses incomplete data; manual recovery may be necessary |
| Hyprland fails or black screen | Select GNOME in GDM; inspect `journalctl -b`, GPU drivers, and `hyprctl configerrors` in a valid session |
| NVIDIA/hybrid external display fails | Keep prior driver/PRIME routing; inspect PCI IDs and driver/kernel support; revert the explicit GPU preset |
| Quickshell fails | Run `qs --version`, inspect `qs --help`, launch `qs --no-duplicate -c end4-pC` from a terminal in Hyprland and capture stderr |
| Missing QML module | Use the project-provided wrapped `qs`; inspect Qt/QML imports against the pinned revision |
| Duplicate panel | Stop old user-launched shell instances, log out and back in; inspect autostart entries |
| Vietnamese input missing | Enable the option, check `fcitx5-remote -n` and `systemctl --user status fcitx5-daemon`; log in again |
| Screen recording unavailable | Run the helper in a working Wayland session with a valid XDG_RUNTIME_DIR; check its state log and capture tools |
| Source URL unavailable / hash mismatch | Keep locks unchanged; verify pinned upstream availability and report revision/hash; do not invent a replacement hash |
| Build fails | No installer activation follows; retain logs and fix the candidate, not the original source |

Collect `nix --version`, selected output/profile, GPU PCI IDs (when relevant),
`journalctl -b -u display-manager`, `journalctl --user -b`, `hyprctl configerrors`
and precise build errors. Redact usernames, tokens, private paths and screen
contents where appropriate. File general issues in the repository; follow
[SECURITY.md](../SECURITY.md) for sensitive reports.

The personal host retains optional apps with external network sources and a
legacy 9Router `latest` image. Their availability is separate from successful
Nix evaluation. Public 9Router requires an explicit immutable digest and binds
port 3001 to loopback. Existing host services may still have their own network
exposure; review them independently.

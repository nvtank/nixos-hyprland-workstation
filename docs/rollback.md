# Rollback and recovery

These procedures restore different things. Keep them separate.

| Operation | Restores | Does not restore |
|---|---|---|
| Rebuild a pinned flake | Declared software and system configuration | Historical mutable dotfiles or documents |
| Previous NixOS generation | Prior system closure and activation settings | General user data; arbitrary service database migrations |
| `end4-rollback` | Last backed-up `hypr` and `quickshell` directories | NixOS generation, wallpaper settings outside these trees, documents |
| Independent personal backup | Files actually included in that backup | Files/services never backed up |

## Before activation

Keep an older boot generation and the original host source. The installer copies
source files before building and records `previous-system` before activation.
A prepared directory alone has no system effects. Do not garbage-collect your
last known-good generation during migration. The owner's old 7-day automatic GC
policy remains in the personal host; review its retention before migration.

## Temporary activation failed

`nixos-rebuild test` leaves the default boot generation unchanged. Reboot into
the previous generation, or, from a working TTY/session, restore the closure
recorded by the installer:

```bash
previous=$(cat /absolute/path/to/candidate/previous-system)
# Inspect the printed /nix/store/...-nixos-system-... path before running it.
printf '%s\n' "$previous"
sudo "$previous/bin/switch-to-configuration" test
```

Do not execute a path from an untrusted candidate. If graphical login fails,
press Ctrl+Alt+F3, sign in normally and restore there. GDM's session chooser lets
you select GNOME when Hyprland is broken. With a different display manager, use
its session selection mechanism.

## Persistent switch failed

Choose an earlier generation at boot, or run from a functioning session:

```bash
sudo nixos-rebuild switch --rollback
```

Rebuilding the original configuration also removes the workstation additions:

```bash
sudo nixos-rebuild test --flake /path/to/original#YOUR_OUTPUT
# Verify recovery, then persist explicitly.
sudo nixos-rebuild switch --flake /path/to/original#YOUR_OUTPUT
```

For non-flake hosts use your original `nixos-rebuild` workflow. Inspect the actual
profile generation and boot configuration if there has been more than one switch;
`--rollback` selects a prior generation, not an arbitrary known-good label.

## User desktop rollback

Run as the desktop user, preferably from GNOME or a TTY after logging out of
Hyprland:

```bash
end4-rollback
```

The original supported interface takes no backup argument. The command resolves
`$XDG_STATE_HOME/end4-nixos/current-backup` (default
`~/.local/state/end4-nixos/current-backup`) and requires a backup within its own
`backups/` directory. A historical misplaced pointer is accepted only if it
resolves inside that same backup root. Missing/incomplete/unsafe archives cause
a refusal before replacing either live tree.

Current live trees are moved into a new `before-rollback-*` backup. Restored
content comes from the original pre-switch directories or validated archives.
A target originally absent becomes absent again; the displaced live tree is
still kept. No documents or unrelated config directories are deleted.
The pointer is removed after success; a second rollback fails safely unless
there is another explicit setup backup. Advanced recovery can inspect the
printed backup path and manually copy a selected directory while logged out.

## Removing the project

`scripts/uninstall.sh` prints recovery guidance and deletes nothing. Remove a
manually added workstation import and options from your own host, then build,
test and switch. A staged installation can return to the original host source
or a previous generation. Keep backups and any persistent Docker data until you
have verified recovery; uninstalling a module does not restore personal data.

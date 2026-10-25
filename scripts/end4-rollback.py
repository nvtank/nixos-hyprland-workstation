#!/usr/bin/env python3
"""Restore the two end4 configuration trees; never erase the current trees."""
import fcntl
import os
from pathlib import Path
import shutil
import sys
import tarfile
import tempfile


def restore(config, state):
    config, state = Path(config), Path(state)
    if not config.is_absolute() or config == Path('/') or config == Path.home():
        raise ValueError('Unsafe XDG_CONFIG_HOME')
    backup = (state / 'current-backup').resolve(strict=True)
    # Compatibility with the old setup's misplaced pointer, but keep backups confined.
    if backup.parent != (state / 'backups').resolve() or not backup.is_dir():
        raise ValueError('Backup must be an existing directory under end4-nixos/backups')
    absent = (backup / 'absent').read_text().splitlines() if (backup / 'absent').is_file() else []
    config.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.end4-restore.', dir=config) as tmp:
        staging = Path(tmp)
        for target in ('hypr', 'quickshell'):
            saved = backup / (target + '.pre-switch')
            archive = backup / (target + '.tar.gz')
            if saved.is_dir() and not saved.is_symlink():
                shutil.copytree(saved, staging / target, symlinks=True)
            elif archive.is_file():
                with tarfile.open(archive, 'r:gz') as tar:
                    for member in tar.getmembers():
                        path = Path(member.name)
                        if path.is_absolute() or '..' in path.parts or not path.parts or path.parts[0] != target:
                            raise ValueError('Unexpected path in backup archive')
                    tar.extractall(staging, filter='data')
            elif target not in absent:
                raise ValueError(f'Incomplete backup: missing {target}')
        # All restoration data is validated before touching either live tree.
        recovery = Path(tempfile.mkdtemp(prefix='before-rollback-', dir=state / 'backups'))
        moved, installed = [], []
        try:
            for target in ('hypr', 'quickshell'):
                live = config / target
                if live.exists() or live.is_symlink():
                    live.rename(recovery / target)
                    moved.append(target)
                if (staging / target).exists():
                    (staging / target).rename(live)
                    installed.append(target)
        except BaseException:
            for target in reversed(installed):
                (config / target).rename(staging / target)
            for target in reversed(moved):
                (recovery / target).rename(config / target)
            raise
    (state / 'current-backup').unlink()
    print(f'Restored {backup}. Previous live configs preserved at {recovery}.')
    print('Log out before restarting Quickshell. This does not roll back NixOS or personal data.')


def main():
    if len(sys.argv) > 1:
        if sys.argv[1:] in (['--help'], ['-h']):
            print('Usage: end4-rollback (restores the most recent end4-setup backup)')
            return
        raise ValueError('end4-rollback takes no arguments')
    if os.geteuid() == 0:
        raise ValueError('Run end4-rollback as the desktop user, never root')
    config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config')))
    state_base = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state')))
    state = state_base / 'end4-nixos'
    state.mkdir(parents=True, exist_ok=True)
    with (state / 'lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        # Repair the pointer location used by historical end4-setup versions.
        old = state_base / 'current-backup'
        if not (state / 'current-backup').exists() and old.is_symlink():
            backup = old.resolve(strict=True)
            if backup.parent == (state / 'backups').resolve():
                (state / 'current-backup').symlink_to(backup)
        restore(config, state)


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, tarfile.TarError) as error:
        print(f'end4-rollback: {error}; no unrelated files were removed.', file=sys.stderr)
        sys.exit(1)

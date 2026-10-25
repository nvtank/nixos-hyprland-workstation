#!/usr/bin/env python3
import importlib.util
from pathlib import Path
import tempfile
import tarfile
import io
spec = importlib.util.spec_from_file_location('rollback', 'scripts/end4-rollback.py')
rollback = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rollback)
with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    config = root / 'config'
    state = root / 'state'
    backup = state / 'backups' / 'stamp'
    backup.mkdir(parents=True)
    config.mkdir()
    (config / 'unrelated').write_text('keep')
    (config / 'hypr').mkdir()
    (config / 'hypr/live').write_text('new')
    (backup / 'hypr.pre-switch').mkdir()
    (backup / 'hypr.pre-switch/old').write_text('old')
    (backup / 'absent').write_text('quickshell\n')
    (state / 'current-backup').symlink_to(backup)
    rollback.restore(config, state)
    assert (config / 'hypr/old').read_text() == 'old'
    assert (config / 'unrelated').read_text() == 'keep'
    assert list((state / 'backups').glob('before-rollback-*/hypr/live'))
    assert not (state / 'current-backup').exists()
    # Incomplete and malicious archives must leave live data intact.
    (state / 'current-backup').symlink_to(backup)
    (backup / 'hypr.pre-switch/old').unlink()
    (backup / 'hypr.pre-switch').rmdir()
    for malicious in [False, True]:
        if malicious:
            with tarfile.open(backup / 'hypr.tar.gz', 'w:gz') as tar:
                info = tarfile.TarInfo('../unrelated')
                info.size = 4
                tar.addfile(info, io.BytesIO(b'evil'))
        try:
            rollback.restore(config, state)
            raise AssertionError('Unsafe rollback accepted')
        except ValueError:
            pass
        assert (config / 'hypr/old').read_text() == 'old'
        assert (config / 'unrelated').read_text() == 'keep'
print('end4 rollback tests passed')

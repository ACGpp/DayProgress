#!/usr/bin/env python3
"""Compare scene-wide observation with isolated labels; never launches the installed app."""
import os
import pathlib
import platform
import subprocess
import time

root = pathlib.Path(__file__).resolve().parents[2]
out = root / '.build-cache' / 'memory-probe'
out.mkdir(parents=True, exist_ok=True)
for variant in ('legacy', 'isolated'):
    binary = out / variant
    args = ['swiftc', '-O', '-swift-version', '5', '-parse-as-library',
            '-target', f'{platform.machine()}-apple-macos13.0',
            '-module-cache-path', str(root / '.build-cache/modules')]
    if variant == 'legacy':
        args += ['-D', 'LEGACY_SCENE']
    args += [str(root / p) for p in ('Sources/DayClock.swift', 'Sources/Localization.swift',
                                    'Sources/MenuBarLabel.swift', 'Sources/DayRing.swift',
                                    'Sources/LoginItem.swift', 'Tools/MemoryProbe/main.swift')]
    if variant == 'legacy':
        old = out / 'LegacyPopoverView.swift'
        old.write_text(subprocess.check_output(['git', 'show', '6f38beb:Sources/PopoverView.swift'],
                                              cwd=root, text=True))
        args += [str(old)]
    else:
        args += [str(root / 'Sources/PopoverView.swift')]
    subprocess.run(args + ['-o', str(binary)], check=True)
    ready = out / f'{variant}.ready'
    ready.unlink(missing_ok=True)
    log = out / f'{variant}.log'
    with log.open('w') as stream:
        proc = subprocess.Popen([str(binary)], env={**os.environ, 'PROBE_READY': str(ready)},
                                stdout=stream, stderr=stream)
        try:
            deadline = time.monotonic() + 90
            while not ready.exists():
                if proc.poll() is not None:
                    raise RuntimeError(f'{variant} exited ({proc.returncode}): {log.read_text()}')
                if time.monotonic() > deadline:
                    raise TimeoutError(variant)
                time.sleep(0.25)
            for tool in (['vmmap', '-summary'], ['heap', '-sortBySize']):
                result = subprocess.run(tool + [str(proc.pid)], capture_output=True, text=True, timeout=45)
                (out / f'{variant}-{tool[0]}.txt').write_text(result.stdout + result.stderr)
                if result.returncode:
                    raise RuntimeError(f'{tool[0]} failed: {result.returncode}')
            print(f'{variant}: 1200 ticks, reports in {out}', flush=True)
        finally:
            if proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait()

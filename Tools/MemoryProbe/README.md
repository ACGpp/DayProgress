# DayProgress memory probe

Run `python3 Tools/MemoryProbe/run.py` on a logged-in macOS desktop. Two temporary settings windows appear sequentially. The probe compares 1,200 accelerated updates of the original settings observation path with the optimized path, captures `vmmap`/`heap`, and exits its own processes. It does not launch or modify the installed app.

Results: `.build-cache/memory-probe/`. Requires Swift, Git history containing commit `6f38beb`, Python 3, `vmmap`, and `heap`. See `docs/memory-performance.md` for interpretation and limitations. Do not run concurrently with another copy of this probe.

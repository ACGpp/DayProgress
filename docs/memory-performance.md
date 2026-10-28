# Memory regression investigation and validation

## Finding (2026-10-28)

Installed DayProgress 1.2.1 (4), running since October 18 on macOS 26.3.1 / Apple M5:

- Physical footprint: 584.6 MB (peak 593.5 MB).
- Default malloc zone: 527.3 MB allocated, about 4.64 million allocations, approximately 5% fragmentation.
- Heap inspection: 635,162 Observation registrar dictionaries, 635,162 key-path dictionaries and related sets; Observation/SwiftUI tracking collections accounted for roughly 470 MB.
- CoreAnimation and IOAccelerator graphics regions were only a few MB. Blur textures were not the dominant retained allocation.
- A three-second sample caught an idle event loop, not the previously observed CPU bursts.

The installed binary is not byte-identical to the repository build. The relevant clock/scene code is unchanged between v1.2.1 and the starting commit 6f38beb; the starting commit also includes the upcoming 1.2.2 display-setting UI.

## Changes

1. The App/Scene no longer observes the global clock. The menu label owns a small display model which publishes only changed percent/caption values, including accessibility text.
2. The settings page observes a projection of settings and timezone labels rather than every tick. Timezone offset changes (including DST) still refresh the picker. The main page retains the existing ten-second progress cadence.
3. Date formatters are reused and reconfigured on locale/timezone changes.
4. Floating panels are created on demand. Hiding releases their content/hosting/blur views and removes the window-specific observer; restoring recreates the panel from persisted geometry. Blur views only exist in glass mode.
5. Wake, system-clock and system-timezone notifications refresh the clock immediately.

This retains macOS 13 compatibility, appearance options, precision and timing semantics. There is no new dependency or forced periodic restart.

## Automated checks

Run `./test.sh` on a Mac with Xcode command-line tools. It compiles assertions-enabled test executables into `.build-cache/tests` and uses isolated UserDefaults suites.

Checks include:

- Progress, completion, precision, timezone and localization.
- Unchanged menu output does not publish; changed percent/caption does.
- Display model subscriptions do not keep the model alive.
- Settings ignore ordinary clock ticks but respond to configuration and DST offset changes.
- Main-page updates still occur each tick.
- 100 show/hide and glass/dark cycles release content and visual-effect views; panel geometry is recreated.

Panel tests briefly create accessory windows. CI runs these checks before packaging. `./build.sh` produces an optimized arm64 app locally without installing it; CI retains the existing universal release build.

## Reproducible allocation probe

Run `python3 Tools/MemoryProbe/run.py` from the repository on a logged-in Mac desktop. It compiles two isolated executables with the production macOS 13 deployment target, opens a settings window and advances a synthetic clock by ten seconds at 20 ms intervals for 1,200 updates. It does not restart the installed app or use its preference domain. Both executions use the current DayClock, so this is a comparison of observation paths, not a complete old/new release benchmark.

The legacy variant uses the original scene subscription and PopoverView from commit 6f38beb. The isolated variant uses the new label/settings observers. Both use custom-day mode with start/end pickers. After updates stop, the driver records vmmap and heap output, then terminates only its own child process. Reports are under `.build-cache/memory-probe`. Git history, the macOS profiling tools, and their local access permissions are required.

Measured with the production deployment target:

| Metric after 1,200 updates | Legacy path | Isolated path |
| --- | ---: | ---: |
| Physical footprint | 57.3 MB | 43.2 MB |
| Peak footprint | 57.4 MB | 44.3 MB |
| Registrar observation dictionary instances | 15,001 | 21 |
| Observation tracking-ID dictionary bytes | 1,032,192 | 1,568 |
| SwiftUI observation-entry dictionary bytes | 802,816 | 1,344 |

A menu-only probe did not reproduce the large accumulation; the settings controls were necessary in this reproduction. These results support the settings invalidation fix, not a claim that changing the Scene alone fixes the issue.

One exploratory run compiled with the compiler's default (newer) deployment target terminated with an AppKit constraint-update exception. Its result was discarded. The recorded pair and the regression tests use the application's actual macOS 13 target and completed successfully. Treat newer deployment-target compatibility as unverified rather than silently changing that build setting.

## Remaining acceptance work

- The 584.6 MB installed process was deliberately left running; these changes have not been installed into /Applications.
- The 43.2 MB result is an isolated settings probe, not a promise for the full app with all UI surfaces.
- 24-hour memory plateau, five-minute idle CPU/wakeup averages, sleep/resume and physical multi-display/Spaces interaction still require a full-app acceptance run. The existing targets (120 MB floating-mode footprint, <=10 MB growth after warm-up over 24 hours, <1% average single-core idle CPU) are goals, not yet proven.
- Further rendering changes, full AppKit replacement, and slower refresh intervals should only follow new evidence. The current fix preserves rendering and timing semantics.

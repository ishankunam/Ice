# macOS 27 validation record

## Automated validation

- Source: `22a4fe1eaf9ae79227f65639e75ea20e43eb5a0f`.
- [Passing CI run](https://github.com/ishankunam/Ice/actions/runs/36383616570).
- Runner: `xcode-27`, image `macos27 20260921.0210.1`.
- Toolchain: Xcode 27.0 (`27A266a`), Swift 6.4, macOS 27.0 (`26A428`).
- Release build, all standalone regression programs, ARM64 assertion,
  stable bundle identifier, custom-update flag, resolved dependency check,
  and strict deep signature verification passed.
- The regression suite passed locally using Command Line Tools. After the
  final coordinate change, the 15 geometry assertions also passed locally.
- Downloaded archive SHA-256:
  `0ad8094e8c2e7eb39813a4cf7fd3de628580ce9559f164656ce98b866c51a000`.
- The downloaded checksum and application signature were verified locally.

## Installation and local interaction

The host is an Apple M2 Pro Mac running macOS 27.0 (`26A428`). Its external
displays are MSI G273 at 1920×1080 and DELL S2721QS at 1080×1920 logical points,
rotated 90 degrees. The original installed Ice is version 0.11.12.

The original application and preferences are backed up locally at
`build/backups/2026-09-28-original/`. That ignored directory is not pushed to
GitHub. Installation is pending action-time approval for the custom build.
The original application remains installed and was relaunched while that
approval is pending. No custom application has been launched on this host.

| Check | Local result |
| --- | --- |
| Original settings | Native menu-bar mode, scroll, automatic rehide enabled. |
| Install and launch custom build | Pending. |
| Button hide/show on MSI and Dell | Not performed. |
| Scroll hide/show on MSI and Dell | Not performed. |
| Smart rehide and open-menu exclusions | Not performed. |
| Clock, Wi-Fi, Control Center, application clicks | Not performed. |
| Rapid toggles and manual Command-dragging | Not performed. |
| Relaunch and preservation of item order/settings | Not performed. |
| Sleep/wake, display changes, fullscreen | Not performed. |
| Core features without Screen Recording | Not performed. |
| Older macOS and built-in notched display | Not performed. |

Passing CI does not substitute for these interaction checks.

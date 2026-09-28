# Roadmap to a public macOS 27 release

The next milestone is a locally validated build. Public release readiness
depends on live testing, broader beta coverage, and a signed distribution.
Passing CI alone does not establish that menu-bar interactions work.

This roadmap records future work. It does not authorize publication, enrolling
in a developer program, or changing the agreed Git workflow.

## Current position

| Area | Status |
| --- | --- |
| Implementation | Native overflow hiding, scroll-to-show, Smart rehide, display geometry validation, and stale-request cancellation are implemented. |
| Automated validation | The [latest checked CI run](https://github.com/ishankunam/Ice/actions/runs/36383945347) passed at `e60a243994edf9024461cc07a12847efa78353a1`. |
| Downloaded artifact | The application from `22a4fe1eaf9ae79227f65639e75ea20e43eb5a0f` passed local checksum and signature verification. The subsequent commit changes documentation only. |
| Live validation | The custom build has not been installed or tested on the target Mac. Installation approval is pending. |
| Distribution | CI produces an ARM64 ZIP. It uses ad-hoc signing with hardened runtime disabled. No public release has been published. |
| Recovery | The original app and preferences are backed up. Installation and rollback are documented. |

Evidence belongs in [VALIDATION-MACOS27.md](VALIDATION-MACOS27.md).
Installation and recovery instructions are in
[INSTALL-MACOS27.md](INSTALL-MACOS27.md).

## Release scope and Git workflow

The first public version should target Apple Silicon Macs on macOS 27.
Its supported workflow is Ice-button hide/show, scrolling in a visible menu
bar, and Smart auto-rehide using native overflow. Application menus remain
visible. Preserve the bundle identifier, preference keys, and item order.

Do not advertise complete Ice feature parity. Timed and focused-application
rehide, show-on-hover/click, item spacing, app-menu hiding, and search remain
outside this fix. List inherited features separately unless they are also tested.

Continue all work on `fix/macos27-menu-bar-hiding` in `ishankunam/Ice`.
Keep the fork's `main` unchanged as the default upstream baseline.
Use focused Conventional Commits with relevant regression tests in each fix.
Preserve inherited history and attribution. Do not create stacked branches,
merge into `main`, or open an upstream pull request under this roadmap.

Public release tags can identify validated commits on the feature branch.
Publishing from those commits does not require changing `main`.

## Milestone 1: Validate the fix on the target Mac

- [ ] Install the verified artifact after approval. Launch exactly one copy.
- [ ] Reauthorize Accessibility if required. Verify core behavior with Screen
  Recording disabled.
- [ ] Complete the local checklist below on the MSI G273 and rotated Dell S2721QS.
- [ ] Verify recovery when geometry or boundary alignment cannot be confirmed.
  Items must expand, and the Ice button must remain reachable.
- [ ] Confirm unsupported rehide modes are visibly unavailable.
- [ ] Verify rollback restores the original app and saved preferences.
- [ ] Record the exact source commit, macOS build, display arrangement,
  permissions, and each result in the validation record.
- [ ] Fix discovered failures with focused regression coverage and rerun the
  affected interaction checks using a fresh successful CI artifact.

**Exit criterion:** The agreed workflow works on both displays. There are no
unresolved failures involving inaccessible items, lost preferences, unexpected
reordering, or interrupted native menus. Unperformed checks remain explicit.

## Milestone 2: Test with a small external beta

- [ ] Recruit testers after local validation succeeds. Distribute the exact
  candidate build with its source commit and known limitations.
- [ ] Cover a built-in notched display, a single external display, mixed scaling,
  portrait displays, and different primary-display arrangements.
- [ ] Cover sparse and crowded menu bars with several third-party status items.
- [ ] Test fresh installation and upgrade from existing Ice preferences.
  Include denied, newly granted, and reauthorized Accessibility access.
- [ ] Test sleep/wake, display reconnection, fullscreen transitions, rapid
  toggling, native Command-dragging, and an ordinary daily-use session.
- [ ] Review inherited compatibility code as well as the new fixes, especially
  native input, cancellation, permission handling, and failure recovery.
- [ ] Collect reproducible reports with build, displays, reproduction steps,
  and expected versus observed behavior. Request logs or recordings only as needed.
- [ ] Convert reproducible defects into regression coverage where practical.

**Exit criterion:** The beta matrix has recorded results and no unresolved
blocking defects. Publish the tested configurations. Make no compatibility
claims for older macOS or additional architectures without testing them.

## Milestone 3: Prepare a signed release candidate

- [ ] Identify the release maintainer and obtain an appropriate Developer ID
  signing identity. Keep signing and notarization credentials out of Git.
- [ ] Add a protected release-signing path in CI. Keep ordinary branch builds
  usable without release credentials.
- [ ] Enable hardened runtime and resolve embedded framework and helper signing.
  The current `ENABLE_HARDENED_RUNTIME=NO` workaround cannot be the notarized
  release configuration.
- [ ] Sign the application and its nested executables correctly. Submit for
  notarization and staple the resulting ticket to the distributed application
  or disk image.
- [ ] Test the signed candidate again. Include a fresh browser download and
  first launch on a Mac that has not previously authorized the development build.
- [ ] Verify Gatekeeper acceptance, Accessibility onboarding, upgrade behavior,
  and rollback using the actual downloadable package.
- [ ] Give the candidate an identifiable version and source commit. Show that
  it is an unofficial fork in the app and release notes without changing the
  bundle identifier or silently resetting preferences.

Apple requires Developer ID signing and hardened runtime for notarization.
See [notarization requirements](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
and [Developer ID distribution](https://developer.apple.com/developer-id/).
Notarization checks distribution integrity and security requirements. It does
not replace functional testing.

**Exit criterion:** A user can download the candidate, move it to Applications,
launch it through the normal macOS flow, grant Accessibility, and use the
validated features without installing developer tools.

## Milestone 4: Publish and maintain the release

- [ ] Obtain approval to publish the release.
- [ ] Tag the exact validated feature-branch commit and publish a GitHub Release
  with a signed ZIP or DMG, SHA-256 checksum, and matching source.
- [ ] Provide a clear download link in this branch's README. Preserve upstream
  attribution and the project's license notices.
- [ ] Publish supported macOS versions and architectures, known limitations,
  installation, permission recovery, update, and rollback instructions.
- [ ] Keep upstream automatic updating disabled. Use documented manual updates
  initially so an upstream release cannot silently replace the fork's fixes.
- [ ] Identify where users report issues and who maintains subsequent builds.
- [ ] Define when a defective release should be withdrawn and how users obtain
  the previous verified build.

A dedicated automatic-update channel is a later improvement. It needs its own
signed update artifacts and upgrade testing before being enabled.

**Exit criterion:** An ordinary user has a stable download, an understandable
installation path, tested behavior, and a documented way to update or recover.

## Local validation checklist

Use the same build throughout a test run. Repeat steps 3–6 on each display.
Note any failures before changing settings or installing another build.

1. **Install.** Follow [the installation guide](INSTALL-MACOS27.md). Keep the
   original backup. Quit the old copy, install the verified artifact, and launch
   only `/Applications/Ice.app`. Grant Accessibility if requested.
2. **Configure.** Turn Use Ice Bar off, Show on scroll on, and Automatically
   rehide on with Smart selected. Leave Screen Recording disabled for this run.
   Close Ice's settings window before testing gestures or rehide.
3. **Button.** Toggle Ice at least five times. Items left of Ice should enter
   native « overflow and return when space permits. Ice, application menus,
   and items in the visible section must remain accessible.
4. **Scroll.** Scroll in both directions over a visible menu bar. One direction
   should show the hidden section and the other should hide it. Scrolling in
   an ordinary application window must not toggle Ice.
5. **Smart rehide and native menus.** Reveal items, then click a normal app or
   the Dock. Items should rehide after focus settles. Open and use a status-item
   menu, Wi-Fi, Control Center, and the clock. They must retain native behavior
   without premature closure. Ice's settings and active drags must suppress rehide.
6. **Rapid input and ordering.** Toggle rapidly, then stop and verify that the
   final state matches the last input. Command-drag one ordinary status item
   across Ice, release it, and verify the resulting section membership.
   Return the item to its original position.
7. **Lifecycle.** Relaunch Ice, sleep and wake the Mac, reconnect a display, and
   enter and leave fullscreen. Repeat button, scroll, and Smart rehide checks.
   Verify that settings and item order survive.
8. **Report.** Record pass/fail for each step and display, the build commit, and
   reproduction steps for any failure. Keep automated and manual results separate.

If a test fails, preserve the reproduction details and use the documented
rollback when needed. A passing test on one display does not count for both.

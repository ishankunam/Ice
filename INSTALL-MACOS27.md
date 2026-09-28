# Install and recover the custom macOS 27 build

Use the source in `ishankunam/Ice` on `fix/macos27-menu-bar-hiding`. The fork
preserves the changes and their attribution. GitHub Actions builds the app
from source because this Mac has Command Line Tools, rather than Xcode 27.

The branch starts at reviewed compatibility commit
`c3df598f36100b0500fd159a1cfd9ac5d2dc2525` from
[upstream PR #997](https://github.com/jordanbaird/Ice/pull/997).
Review new work against that commit. The fork's default `main` stays at
`11edd39115f3f43a83ae114b5348df6a0e1741cf`.
All implementation commits and the workflow live on the single feature branch.

## Obtain and verify an artifact

1. Open the [branch's workflow runs](https://github.com/ishankunam/Ice/actions/workflows/macos27.yml).
   Select a successful run for the intended feature-branch commit.
2. Download the `Ice-macos27-arm64-<commit>` artifact. Extract its contents into
   an empty directory. Keep the validation records beside the downloaded zip.
3. In that directory, verify and unpack the application:

   ```sh
   shasum -a 256 -c SHA256SUMS
   cat build-info.txt
   ditto -x -k Ice-macos27-arm64.zip unpacked
   codesign --verify --deep --strict --verbose=2 unpacked/Ice.app
   lipo -archs unpacked/Ice.app/Contents/MacOS/Ice
   /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' unpacked/Ice.app/Contents/Info.plist
   /usr/libexec/PlistBuddy -c 'Print :IceDisableUpstreamUpdates' unpacked/Ice.app/Contents/Info.plist
   ```

   The architecture must be `arm64`, the bundle identifier must be
   `com.jordanbaird.Ice`, and the custom-update flag must be `true`.
   Compare the first line of `build-info.txt` with the workflow run's commit.

The workflow uses `xcode-27`, Release configuration, the resolved package
versions, manual ad-hoc signing, and `ENABLE_HARDENED_RUNTIME=NO`.
It checks the signature and uploads the app, checksum, source commit, runner
versions, test results, and build logs. The app is not Developer ID notarized.
The hardened-runtime override is inherited from the compatibility build and
permits loading its embedded framework under an ad-hoc signature.

## Back up and install

Create a fresh backup directory for each installation. Never overwrite the
original backup when installing a newer custom build.

```sh
ice_backup="$HOME/lab/ice/build/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$ice_backup"
defaults export com.jordanbaird.Ice "$ice_backup/preferences.plist"
ditto /Applications/Ice.app "$ice_backup/Ice.app"
```

Quit Ice using its menu. Replace `/Applications/Ice.app` with the verified
`unpacked/Ice.app` in Finder, then launch that installed copy once. Do not run
the archived copy or the copy in the download directory at the same time.

If macOS requests Accessibility again, authorize `/Applications/Ice.app` in
System Settings → Privacy & Security → Accessibility. If the old permission
entry does not recognize the replacement, remove that Ice entry and add the
installed application again. Relaunch Ice after granting access.

Screen Recording is optional for item thumbnails. Native hiding, scrolling,
and Smart rehide use Accessibility and passive event monitors. Keep
"Use Ice Bar" off to use native overflow. Enable "Show on scroll" and choose
"Smart" under "Automatically rehide". Application menus remain visible.

The custom build preserves the bundle identifier, preference keys, and saved
item positions. It does not start Sparkle or modify the original update
preferences. Install future custom builds manually from this branch.

## Roll back

1. Quit the custom Ice application.
2. Move the custom `/Applications/Ice.app` into a separate recovery directory.
3. Copy the original backup's `Ice.app` back into `/Applications`.
4. Restore the preferences while Ice is stopped:

   ```sh
   defaults import com.jordanbaird.Ice /absolute/path/to/backup/preferences.plist
   ```

5. Launch `/Applications/Ice.app` once. Reauthorize Accessibility if requested.

The original app's macOS 27 hiding limitation returns after rollback.
The preserved update preferences take effect in the original build again.

## Validation

Run all focused tests locally with `bash Scripts/test-macos27.sh`.
Run the complete app build on an Xcode 27 installation with
`bash Scripts/build-macos27.sh`, or push to the feature branch to run CI.
Tests cover native boundary alignment, global display coordinates, visibility
origins, stale request cancellation, scroll thresholds, Smart rehide
exclusions, and the custom update policy.

Automated geometry tests include a 1920×1080 MSI layout and a 1080×1920 portrait
Dell layout with a negative origin. These tests do not establish hardware
interaction success. Record hardware results separately in
[the validation record](VALIDATION-MACOS27.md).

Timed and focused-application rehide, show-on-hover/click, item spacing,
app-menu hiding, and search remain unavailable on macOS 27. Ice leaves items
expanded if it cannot verify a safe boundary or geometry. Native overflow can
also limit how many items fit even in the expanded state.

## Git history

Pushed commits are visible when selecting `fix/macos27-menu-bar-hiding` in the
repository's commit history. GitHub describes Insights → Commits as repository
commits over the past year, excluding merge commits. Insights → Contributors
counts eligible default-branch commits. Feature-branch work does not qualify
for that graph. Do not merge into `main` or change the default branch for a graph.

See GitHub's [commits graph documentation](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/analyzing-changes-to-a-repositorys-content)
and [contributors documentation](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-a-projects-contributors).

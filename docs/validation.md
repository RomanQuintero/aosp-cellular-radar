# Validation

## Recorded implementation validation

Before packaging, the feature passed:
- Android 17 Settings-only build: m Settings -j8.
- CellularRadarCellTest: 10 passed.
- CellularRadarFormatterTest: 6 passed.
- CellularRadarRepositoryTest: 9 passed.
- Total: 25 focused Robolectric tests passed.
- Resource XML parsing and git diff --check passed.

These results were checked against the existing local M2.1 build/test logs.
Publication preparation did not rebuild AOSP or rerun the feature tests.

## Local publication package validation

- Three standard git-format-patch files were generated from the exact Settings base.
- Patch paths were checked against an 11-file Cellular Radar allowlist.
- The full series was applied with apply-patches.sh in an isolated local checkout.
- The resulting complete Git tree equals the exported working-tree snapshot.
- All 11 contributed files match their original source bytes by SHA-256.
- The isolated checkout was clean after application, with no remotes.
- Patch checksums and git diff --check passed.
- Both shell scripts pass bash -n and --help checks.
- The application script rejects dirty/untracked work, unfinished Git operations,
  modified patch checksums, and an already-patched/wrong base.
- Launcher validation: Passed: fake-launch argument forwarding, unchanged HOME, existing-runtime refusal.
- The launcher rejects missing product images.
- Local Markdown links were checked; real screenshot files are intentionally pending.
- Original Settings HEAD, Git index bytes, working-tree status, contribution file
  hashes, and remote listing are unchanged from the pre-export state.

No actual Cuttlefish VM was started, no APK was deployed, and no screenshot was
created during packaging validation. The launcher was checked with a stub
executable rather than by changing the running Cuttlefish environment.

## Patch provenance

See [provenance.json](provenance.json) for exact commits and file hashes.
Patch 3 is a synthetic export of the uncommitted acquisition/presentation remainder;
its export commit was made in temporary storage, not in Settings. The package
contains no Git repository or remote; temporary validation repositories were
removed after checking.

## Manual review before any future publication

- Copy/capture real screenshots as described in [screenshots](screenshots/README.md).
- Review README wording and example simulated values.
- Review original commit author/email metadata and licensing notices in the patches.
- Run the portable launcher on the intended host when deliberately ready to boot;
  its sandbox setting follows the inspected WSL configuration.
- Keep a pinned full AOSP manifest if exact platform-wide reproduction is required.

This package remains local. Nothing was uploaded or published, and no GitHub
repository, authentication, API call, or remote modification was performed.

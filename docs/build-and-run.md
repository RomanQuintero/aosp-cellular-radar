# Build and run

These commands describe the source-checkout workflow used for this project.
They are instructions for a deliberate future run; packaging did not run repo
sync, rebuild Android, deploy an APK, or launch a VM.

## Environment and checkout

The validated environment is Ubuntu 24.04 under WSL2 with hardware virtualization,
a usable /dev/kvm, Git, Bash, repo, and the AOSP checkout's toolchains.
Cuttlefish host tools and complete bootable product images were already built.
A Settings-only build does not create the full image set or provision a new host.

The local manifest was initialized with android-latest-release; its default
project revision currently resolves to android17-release.

```bash
AOSP_ROOT="$HOME/aosp/android"
PACKAGE_DIR="$HOME/project-11-aosp-cellular-radar"
mkdir -p "$AOSP_ROOT"
cd "$AOSP_ROOT"
repo init -u https://android.googlesource.com/platform/manifest -b android-latest-release
repo sync -c -j12
```

Those are the checkout commands recorded locally. Adjust parallelism for host
resources. A moving branch is not an exact full-platform pin: the package pins
Settings' base commit, not all projects in the manifest. Preserve a full pinned
manifest separately if exact full-platform reproduction is needed.

## Apply the feature

Use a separate clean checkout/branch for review. Do not run this on the original
dirty development checkout. Inspect status and preserve changes before selecting
the base; no script automatically resets, cleans, or checks out a revision.

```bash
cd "$AOSP_ROOT"
git -C packages/apps/Settings status --short
git -C packages/apps/Settings switch -c cellular-radar-review \
    213829fb67f5e070029e0513a088f31bc8f5c1ed
bash "$PACKAGE_DIR/scripts/apply-patches.sh" "$AOSP_ROOT"
```

The script requires that exact base, a clean index/worktree, and no unfinished Git
operation. It checks patch SHA-256 hashes and applies all three patches with
git am --no-3way, creating local commits in the supplied target checkout. A failed
application is left for inspection; the script reports git am --continue/--abort
instead of silently overwriting or rolling back work. It does not add remotes,
contact a hosting provider, or push anything.

Patch 3 captures the remaining local acquisition/presentation changes through an
export-only synthetic commit. It is necessary: the two original commits alone
do not wire the complete diagnostic screen.

## Lunch, Settings build, and tests

```bash
cd "$AOSP_ROOT"
source build/envsetup.sh
lunch aosp_cf_x86_64_only_phone aosp_current userdebug
m Settings -j8

atest \
    SettingsRoboTests:com.android.settings.network.telephony.CellularRadarCellTest \
    SettingsRoboTests:com.android.settings.network.telephony.CellularRadarFormatterTest \
    SettingsRoboTests:com.android.settings.network.telephony.CellularRadarRepositoryTest \
    --no-metrics
```

Use the three-argument lunch form from this checkout. android-latest-release is
the checkout branch; it is not a valid lunch release name here. This configuration
reports Android 17, userdebug, and build ID CP2A.260605.016.

For a fresh checkout that has no bootable images or matching host tools yet,
build the selected product first after lunch:

```bash
m -j8
```

That is a first-time full-product prerequisite, not a packaging validation step.
Use m Settings -j8 for subsequent feature-only rebuilds. No full build was run
during publication preparation.

The built APK is:
`out/target/product/vsoc_x86_64_only/system_ext/priv-app/Settings/Settings.apk`.

The recorded implementation run passed m Settings -j8 and all 25 focused tests.
The existing build emits deprecation/compiler warnings; those were not treated
as evidence of a clean, warning-free platform build.

## Launch Cuttlefish

Ensure the complete source-built image set and matching host tools exist. Stop
any existing Cuttlefish instance deliberately before reusing its ports/resources.
The script does not stop VMs or overwrite an existing runtime directory.

```bash
test -r /dev/kvm && test -w /dev/kvm
export CVD_RUNTIME_DIR="$HOME/project-11-cuttlefish-runtime"
bash "$PACKAGE_DIR/scripts/launch-cuttlefish.sh" "$AOSP_ROOT"
```

The script uses the selected ANDROID_HOST_OUT/ANDROID_PRODUCT_OUT from lunch,
or defaults under the checkout's out directory. It reproduces the inspected
configuration: guest_swiftshader graphics, four CPUs, 4096 MB RAM, WebRTC,
the modem simulator, and --enable_sandbox=false.

Disabling Cuttlefish's sandbox was part of the working WSL configuration. This is
an environment-specific host setting, not a change to Android or the modem.
The portable script uses supported --instance_dir and --assembly_dir flags to
choose a fresh runtime directory without changing HOME. Its arguments were
checked locally with a stub executable; a fresh VM launch remains a manual check.

The current local setup exposes WebRTC at https://localhost:8443 and has an ADB
serial 0.0.0.0:6520. Discover your own endpoint rather than assuming that serial
on another host.

To stop the runtime deliberately after use:

```bash
CVD_CONFIG="$CVD_RUNTIME_DIR/cuttlefish/assembly/cuttlefish_config.json"
CUTTLEFISH_CONFIG_FILE="$CVD_CONFIG" "$ANDROID_HOST_OUT/bin/stop_cvd"
```

For a subsequent launch, select a new runtime directory or manage your previous
runtime manually. The wrapper refuses to overwrite one.

## Deploy only Settings when useful

On a running userdebug instance, use the matching source-built adb. Choose an
explicit serial if multiple devices are connected.

```bash
ADB="$AOSP_ROOT/out/host/linux-x86/bin/adb"
APK="$AOSP_ROOT/out/target/product/vsoc_x86_64_only/system_ext/priv-app/Settings/Settings.apk"
"$ADB" devices
"$ADB" shell pm path com.android.settings
"$ADB" root
"$ADB" wait-for-device
"$ADB" remount
```

If remount requests a reboot or a verification change, follow its output and
repeat remount after reconnecting. Once /system_ext is writable and Settings is
loaded from its system path:

```bash
"$ADB" push "$APK" /system_ext/priv-app/Settings/Settings.apk
"$ADB" shell chmod 0644 /system_ext/priv-app/Settings/Settings.apk
"$ADB" reboot
"$ADB" wait-for-device
```

If pm path reports a data-installed override, a system-image copy may not be the
active APK. For a matching platform-signed replacement, the alternative is:

```bash
"$ADB" install -r "$APK"
```

Deployment commands are documented, not executed during this packaging task.
On a device with multiple entries, add -s YOUR_SERIAL to every adb command.

Enable Location if required and open:
**Settings > Network & internet > Cellular Radar**.
Review refresh behavior, unavailable metrics, empty observed-cell output,
Location-off behavior, and leaving/reopening the page.

## Screenshots

Follow [the screenshot instructions](screenshots/README.md). Capture actual UI
after verifying the deployed APK; do not use a fabricated radar image or a stock
screenshot as evidence of this feature.

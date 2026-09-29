#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

usage() {
    printf 'Usage: %s [AOSP_ROOT]\n' "$0"
    printf 'Overrides: ANDROID_HOST_OUT, ANDROID_PRODUCT_OUT, CVD_RUNTIME_DIR\n'
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
if [[ "${1:-}" == "--help" ]]; then usage; exit 0; fi
[[ $# -le 1 ]] || { usage >&2; exit 2; }
root_arg="${1:-${ANDROID_BUILD_TOP:-}}"
[[ -n "$root_arg" ]] || fail "Pass AOSP_ROOT or source build/envsetup.sh and lunch first."
aosp_root="$(cd -- "$root_arg" && pwd -P)"
[[ -f "$aosp_root/build/envsetup.sh" ]] || fail "Not an AOSP checkout: $aosp_root"

host_out="${ANDROID_HOST_OUT:-$aosp_root/out/host/linux-x86}"
product_out="${ANDROID_PRODUCT_OUT:-$aosp_root/out/target/product/vsoc_x86_64_only}"
[[ -d "$host_out" && -d "$product_out" ]] || fail "Host tools or product output is missing."
host_out="$(cd -- "$host_out" && pwd -P)"
product_out="$(cd -- "$product_out" && pwd -P)"
[[ -x "$host_out/bin/launch_cvd" ]] || fail "Source-built launch_cvd is missing."
for image in boot.img super.img userdata.img; do
    [[ -f "$product_out/$image" ]] || fail "Missing bootable product image: $image"
done
[[ -r /dev/kvm && -w /dev/kvm ]] || fail "This user needs read/write access to /dev/kvm."
[[ -n "${HOME:-}" ]] || fail "HOME is not set."
runtime="${CVD_RUNTIME_DIR:-$HOME/project-11-cuttlefish-runtime}"
[[ "$runtime" == /* ]] || fail "CVD_RUNTIME_DIR must be an absolute path."
# Avoid overwriting an existing runtime. This script does not stop running VMs.
[[ ! -e "$runtime" && ! -L "$runtime" ]] ||
    fail "Runtime already exists: $runtime. Stop existing VMs and select a fresh directory."
mkdir -p -- "$runtime"
runtime="$(cd -- "$runtime" && pwd -P)"

export ANDROID_HOST_OUT="$host_out"
export ANDROID_PRODUCT_OUT="$product_out"
export PATH="$host_out/bin:$PATH"
export LD_LIBRARY_PATH="$host_out/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
printf 'Launching source-built Cuttlefish from %s\n' "$product_out"
printf 'Runtime: %s\n' "$runtime"
printf 'The validated WSL configuration disables the Cuttlefish sandbox.\n'
cd -- "$runtime"
exec "$host_out/bin/launch_cvd" \
    --daemon \
    --system_image_dir="$product_out" \
    --instance_dir="$runtime/cuttlefish" \
    --assembly_dir="$runtime/cuttlefish_assembly" \
    --enable_sandbox=false \
    --enable_modem_simulator=true \
    --gpu_mode=guest_swiftshader \
    --cpus=4 \
    --memory_mb=4096 \
    --start_webrtc=true

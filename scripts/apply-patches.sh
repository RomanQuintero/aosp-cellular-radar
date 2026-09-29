#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

usage() { printf 'Usage: %s AOSP_ROOT\n' "$0"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
if [[ "${1:-}" == "--help" ]]; then usage; exit 0; fi
[[ $# -eq 1 ]] || { usage >&2; exit 2; }
command -v git >/dev/null || fail "git is required."
command -v sha256sum >/dev/null || fail "sha256sum is required."

package_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
aosp_root="$(cd -- "$1" && pwd -P)"
settings="$aosp_root/packages/apps/Settings"
base="213829fb67f5e070029e0513a088f31bc8f5c1ed"
[[ -d "$settings" ]] || fail "Settings not found at $settings"
top="$(git -C "$settings" rev-parse --show-toplevel)"
[[ "$(cd -- "$top" && pwd -P)" == "$settings" ]] ||
    fail "Settings must be its own Git working tree."
[[ -z "$(git -C "$settings" status --porcelain=v1)" ]] ||
    fail "Settings has staged, unstaged, or untracked changes. Preserve them first."
for state in rebase-apply rebase-merge MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    state_path="$(git -C "$settings" rev-parse --path-format=absolute --git-path "$state")"
    [[ ! -e "$state_path" ]] || fail "An unfinished Git operation exists: $state"
done
actual="$(git -C "$settings" rev-parse HEAD)"
[[ "$actual" == "$base" ]] ||
    fail "Expected Settings base $base; found $actual. No reset or checkout was performed."
git -C "$settings" var GIT_COMMITTER_IDENT >/dev/null ||
    fail "Configure a local Git committer identity before using git am."
(cd -- "$package_dir" && sha256sum --check patches/SHA256SUMS)

patches=(
    "$package_dir/patches/0001-Settings-add-Cellular-Radar-entry.patch"
    "$package_dir/patches/0002-Settings-expand-Cellular-Radar-diagnostics.patch"
    "$package_dir/patches/0003-Settings-finish-Cellular-Radar-acquisition-and-prese.patch"
)
for patch in "${patches[@]}"; do
    [[ -f "$patch" ]] || fail "Missing patch: $patch"
done
printf 'Applying %d patches to %s\n' "${#patches[@]}" "$settings"
printf 'git am will create local commits in this target checkout.\n'
if ! git -C "$settings" am --no-3way -- "${patches[@]}"; then
    printf 'Patch application stopped. Inspect git status in %s.\n' "$settings" >&2
    printf 'After review, use git am --continue or git am --abort there.\n' >&2
    exit 1
fi
printf 'Cellular Radar patches applied successfully.\n'
git -C "$settings" log -3 --oneline

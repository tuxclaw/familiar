#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
OUT_DIR="$ROOT/tests/out"
WRITER="$ROOT/hypr/write.sh"

generate() {
  "$WRITER" --generate "$1" "$2"
}

test_symlink_output_refused() {
  local test_dir
  local target
  local output

  test_dir=$(mktemp -d -- "$OUT_DIR/.symlink-test.XXXXXX")
  target=$(mktemp)
  output="$test_dir/familiar.lua"
  printf '%s\n' 'outside-sentinel' > "$target"
  ln -s -- "$target" "$output"

  if generate gnome "$output" >/dev/null 2>&1; then
    printf 'symlink output was accepted: %s\n' "$output" >&2
    return 1
  fi
  grep -qx 'outside-sentinel' "$target"

  unlink -- "$output"
  rmdir -- "$test_dir"
  unlink -- "$target"
}

test_require_insert() {
  local test_dir config
  test_dir=$(mktemp -d -- "$OUT_DIR/.require-test.XXXXXX")
  config="$test_dir/hyprland.lua"
  printf '%s\n' 'require("hypr.variables")' 'require("hypr.looknfeel")' 'require("hypr.bindings")' > "$config"
  "$WRITER" --ensure-require "$config"
  [[ $(grep -Fc 'familiar:require' "$config") -eq 1 ]]
  [[ $(sed -n '2p' "$config") == 'require("hypr.looknfeel")' ]]
  [[ $(sed -n '3p' "$config") == 'require("hypr.familiar") -- familiar:require' ]]
  "$WRITER" --ensure-require "$config"
  [[ $(grep -Fc 'familiar:require' "$config") -eq 1 ]]
  rm -f -- "$config"
  rmdir -- "$test_dir"
}

test_symlink_config_refused() {
  local test_dir target config
  test_dir=$(mktemp -d -- "$OUT_DIR/.config-symlink-test.XXXXXX")
  target="$test_dir/target.lua"
  config="$test_dir/hyprland.lua"
  printf '%s\n' 'require("hypr.looknfeel")' > "$target"
  ln -s -- "$target" "$config"
  if "$WRITER" --ensure-require "$config" >/dev/null 2>&1; then
    printf 'symlink config was accepted: %s\n' "$config" >&2
    return 1
  fi
  ! grep -Fq 'familiar:require' "$target"
  rm -f -- "$config" "$target"
  rmdir -- "$test_dir"
}

test_apply_and_rollback() {
  local test_dir fake_home fake_bin config output
  test_dir=$(mktemp -d -- "$OUT_DIR/.apply-test.XXXXXX")
  fake_home="$test_dir/home"
  fake_bin="$test_dir/bin"
  config="$fake_home/.config/hypr/hyprland.lua"
  output="$fake_home/.config/hypr/familiar.lua"
  mkdir -p -- "${config%/*}" "$fake_bin"
  printf '%s\n' 'require("hypr.variables")' 'require("hypr.looknfeel")' 'require("hypr.bindings")' > "$config"
  printf '%s\n' '#!/usr/bin/env bash' 'if [[ ${1:-} == configerrors ]]; then printf "%s" "${FAKE_CONFIG_ERRORS:-}"; fi' > "$fake_bin/hyprctl"
  chmod +x "$fake_bin/hyprctl"

  HOME="$fake_home" PATH="$fake_bin:$PATH" "$WRITER" --apply gnome >/dev/null
  grep -Fq 'familiar:require' "$config"
  grep -Fq 'gaps_in = 8' "$output"
  cp -f -- "$output" "$test_dir/known-good.lua"

  if HOME="$fake_home" PATH="$fake_bin:$PATH" FAKE_CONFIG_ERRORS='synthetic error' "$WRITER" --apply plasma >/dev/null 2>&1; then
    printf 'writer accepted synthetic config errors\n' >&2
    return 1
  fi
  cmp -s "$test_dir/known-good.lua" "$output"
  cmp -s "$test_dir/known-good.lua" "$fake_home/.local/state/familiar/familiar.lua.prev"
  rm -rf -- "$test_dir"
}

if [[ ${1:-} == --profile ]]; then
  [[ $# -eq 4 && ${3:-} == --output ]] || {
    echo 'usage: tests/hypr.sh [--profile gnome|plasma|macos --output PATH]' >&2
    exit 2
  }
  generate "$2" "$4"
  exit 0
fi

[[ $# -eq 0 ]] || {
  echo 'usage: tests/hypr.sh [--profile gnome|plasma|macos --output PATH]' >&2
  exit 2
}

for profile in gnome plasma macos; do
  generate "$profile" "$OUT_DIR/familiar-$profile.lua"
done

test_symlink_output_refused
test_require_insert
test_symlink_config_refused
test_apply_and_rollback

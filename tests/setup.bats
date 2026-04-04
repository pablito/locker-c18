#!/usr/bin/env bats
# Tests for scripts/setup.sh

load 'helpers/mocks'

setup() {
  use_mocks
  export _ORIG_DIR="$PWD"
  cd "$BATS_TEST_TMPDIR"
  export HOME="$BATS_TEST_TMPDIR/home"
  export SHELL="/bin/bash"
  mkdir -p "$HOME"
}

teardown() {
  cd "$_ORIG_DIR"
}

# ---------------------------------------------------------------------------
# devbox guard
# ---------------------------------------------------------------------------

@test "setup.sh: exits non-zero when devbox is not on PATH" {
  # devbox is not in our mock bin dir
  run bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"
  [ "$status" -ne 0 ]
}

@test "setup.sh: prints helpful installation URL when devbox is missing" {
  run bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"
  [[ "$output" == *"jetify.com"* ]] || [[ "$output" == *"devbox"* ]]
}

@test "setup.sh: does not attempt curl install of devbox" {
  mock_cmd curl 0 ""
  run bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"
  # curl should not have been invoked for devbox
  [ ! -f "$BATS_TEST_TMPDIR/curl.args" ]
}

# ---------------------------------------------------------------------------
# direnv hook
# ---------------------------------------------------------------------------

@test "setup.sh: writes direnv hook to RC file matching \$SHELL" {
  mock_cmd devbox 0 ""
  mock_cmd direnv 0 ""

  run bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"

  local rc="$HOME/.bashrc"
  [ -f "$rc" ]
  grep -q 'direnv hook' "$rc"
}

@test "setup.sh: does not write duplicate direnv hook" {
  mock_cmd devbox 0 ""
  mock_cmd direnv 0 ""
  echo 'eval "$(direnv hook bash)"' > "$HOME/.bashrc"

  bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"

  local count
  count=$(grep -c 'direnv hook' "$HOME/.bashrc")
  [ "$count" -eq 1 ]
}

@test "setup.sh: installs direnv via apt when not present and apt is available" {
  mock_cmd devbox 0 ""
  mock_cmd apt-get 0 ""
  # direnv is NOT on PATH

  run bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"

  local args
  args=$(mock_args apt-get)
  [[ "$args" == *"direnv"* ]]
}

@test "setup.sh: installs direnv via brew when apt is unavailable" {
  # On apt-based systems apt-get is always present, so this path is only
  # reachable on macOS/Nix. Skip rather than fight the host environment.
  command -v apt-get &>/dev/null && skip "apt-get present — brew fallback not reachable on this host"
  mock_cmd devbox 0 ""
  mock_cmd brew 0 ""

  run bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"

  local args
  args=$(mock_args brew)
  [[ "$args" == *"direnv"* ]]
}

@test "setup.sh: exits with error when no package manager is available for direnv" {
  mock_cmd devbox 0 ""
  # No apt-get, no brew, no nix-env, no direnv

  run bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"package manager"* ]] || [[ "$output" == *"direnv"* ]]
}

# ---------------------------------------------------------------------------
# direnv allow
# ---------------------------------------------------------------------------

@test "setup.sh: runs direnv allow for the current directory" {
  mock_cmd devbox 0 ""
  mock_cmd direnv 0 ""

  bash "$BATS_TEST_DIRNAME/../scripts/setup.sh"

  local args
  args=$(mock_args direnv)
  [[ "$args" == *"allow"* ]]
}

#!/usr/bin/env bats
# Tests for scripts/_dotnet.sh
# The script is designed to be sourced, but we test observable side-effects
# by running it as a subprocess where possible.

load 'helpers/mocks'

setup() {
  use_mocks
  export DOTNET_DIR="$BATS_TEST_TMPDIR/.dotnet"
  mkdir -p "$DOTNET_DIR"
}

# ---------------------------------------------------------------------------
# DOTNET_INSTALL_SHA256 guard
# ---------------------------------------------------------------------------

@test "_dotnet.sh: exits non-zero when DOTNET_INSTALL_SHA256 is unset" {
  run env -i HOME="$HOME" PATH="$PATH" \
    bash "$BATS_TEST_DIRNAME/../scripts/_dotnet.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"DOTNET_INSTALL_SHA256"* ]]
}

@test "_dotnet.sh: does not silently skip verification — must fail, not warn" {
  run env -i HOME="$HOME" PATH="$PATH" \
    bash "$BATS_TEST_DIRNAME/../scripts/_dotnet.sh"
  [ "$status" -ne 0 ]
  # Must exit, not merely warn
  [[ "$output" != *"esecuzione senza verifica"* ]]
}

# ---------------------------------------------------------------------------
# dotnet version check
# ---------------------------------------------------------------------------

@test "_dotnet.sh: skips install when dotnet 8.x is already on PATH" {
  # Provide a fake dotnet 8.x binary
  mock_cmd dotnet 0 "8.0.100"
  mock_cmd curl 0 ""

  run env -i HOME="$HOME" PATH="$PATH" \
    DOTNET_INSTALL_SHA256="placeholder" \
    bash "$BATS_TEST_DIRNAME/../scripts/_dotnet.sh"

  # curl should never have been called (install skipped)
  [ ! -f "$BATS_TEST_TMPDIR/curl.args" ]
}

@test "_dotnet.sh: proceeds with install when dotnet 6.x is on PATH" {
  # Provide a fake dotnet that returns version 6
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat > "$BATS_TEST_TMPDIR/bin/dotnet" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then echo "6.0.400"; exit 0; fi
exit 0
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/dotnet"
  # curl will fail (no network), but we just need to see it was attempted
  mock_cmd curl 1 ""

  run env -i HOME="$HOME" PATH="$PATH" \
    DOTNET_INSTALL_SHA256="placeholder" \
    bash "$BATS_TEST_DIRNAME/../scripts/_dotnet.sh"

  # curl should have been invoked (install attempted)
  [ -f "$BATS_TEST_TMPDIR/curl.args" ]
}

@test "_dotnet.sh: proceeds with install when dotnet is not on PATH" {
  # No dotnet in PATH
  mock_cmd curl 1 ""

  run env -i HOME="$HOME" PATH="$PATH" \
    DOTNET_INSTALL_SHA256="placeholder" \
    bash "$BATS_TEST_DIRNAME/../scripts/_dotnet.sh"

  [ -f "$BATS_TEST_TMPDIR/curl.args" ]
}

# ---------------------------------------------------------------------------
# PATH exports
# ---------------------------------------------------------------------------

@test "_dotnet.sh: exports DOTNET_ROOT after sourcing" {
  mock_cmd dotnet 0 "8.0.100"

  # Source in a subshell and print the exported var
  run bash -c "
    export DOTNET_INSTALL_SHA256=placeholder
    source '$BATS_TEST_DIRNAME/../scripts/_dotnet.sh'
    echo \"DOTNET_ROOT=\$DOTNET_ROOT\"
  "
  [[ "$output" == *"DOTNET_ROOT="* ]]
  [[ "$output" != *"DOTNET_ROOT="$'\n' ]]  # must not be empty
}

@test "_dotnet.sh: PATH includes ~/.dotnet/tools after sourcing" {
  mock_cmd dotnet 0 "8.0.100"

  run bash -c "
    export DOTNET_INSTALL_SHA256=placeholder
    source '$BATS_TEST_DIRNAME/../scripts/_dotnet.sh'
    echo \"\$PATH\"
  "
  [[ "$output" == *".dotnet/tools"* ]]
}

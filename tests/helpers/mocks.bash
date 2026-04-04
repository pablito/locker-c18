#!/usr/bin/env bash
# Shared mock helpers for locker-c18 bats tests.
# Source this file in each .bats file's setup() function.

# Creates a mock executable at $BATS_TEST_TMPDIR/bin/<name> that records
# its arguments to <name>.args and exits with the given code.
#
# Usage: mock_cmd <name> <exit_code> [stdout_output]
mock_cmd() {
  local name="$1" exit_code="$2" output="${3:-}"
  local bin_dir="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin_dir"
  cat > "$bin_dir/$name" <<EOF
#!/usr/bin/env bash
echo "\$@" >> "$BATS_TEST_TMPDIR/${name}.args"
${output:+echo "$output"}
exit $exit_code
EOF
  chmod +x "$bin_dir/$name"
}

# Prepend the mock bin dir to PATH for this test.
# Also installs a passthrough sudo so scripts using `sudo <cmd>` resolve
# to whatever <cmd> mock is in the bin dir.
use_mocks() {
  local bin_dir="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin_dir"
  export PATH="$bin_dir:$PATH"
  # passthrough sudo: just exec the remaining args
  cat > "$bin_dir/sudo" <<'SUDO'
#!/usr/bin/env bash
exec "$@"
SUDO
  chmod +x "$bin_dir/sudo"
}

# Read recorded args for a mock command.
mock_args() {
  cat "$BATS_TEST_TMPDIR/${1}.args" 2>/dev/null || true
}

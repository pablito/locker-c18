#!/usr/bin/env bats
# Tests for scripts/reset.sh

load 'helpers/mocks'

setup() {
  use_mocks
  export _ORIG_DIR="$PWD"
  cd "$BATS_TEST_TMPDIR"
  # Copy scripts into the temp dir so reset.sh can find them relatively
  mkdir -p scripts
  cp "$BATS_TEST_DIRNAME/../scripts/reset.sh" scripts/
  cp "$BATS_TEST_DIRNAME/../scripts/_mcp.sh" scripts/
  # Mock uv so uv sync doesn't fail
  mock_cmd uv 0 ""
}

teardown() {
  cd "$_ORIG_DIR"
}

# ---------------------------------------------------------------------------
# .mcp.json lifecycle
# ---------------------------------------------------------------------------

@test "reset.sh: deletes existing .mcp.json" {
  echo '{"old": true}' > .mcp.json
  bash scripts/reset.sh
  # _mcp.sh will regenerate it, but the old content should be gone
  run jq -r '.old // "absent"' .mcp.json
  [ "$output" = "absent" ]
}

@test "reset.sh: regenerates .mcp.json after deleting it" {
  echo '{"old": true}' > .mcp.json
  bash scripts/reset.sh
  [ -f .mcp.json ]
  jq . .mcp.json > /dev/null  # valid JSON
}

@test "reset.sh: calls _mcp.sh via bash directly, not devbox shell" {
  # If reset.sh used 'devbox shell -- bash scripts/_mcp.sh', this would fail
  # because devbox is not available here. The fact that it succeeds proves
  # it calls bash directly.
  mock_cmd devbox 1 ""  # devbox would fail if called
  run bash scripts/reset.sh
  # Should succeed even though devbox fails
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# .venv cleanup
# ---------------------------------------------------------------------------

@test "reset.sh: removes .venv directory if it exists" {
  mkdir -p .venv/lib
  bash scripts/reset.sh
  [ ! -d .venv ]
}

@test "reset.sh: succeeds even when .venv does not exist" {
  [ ! -d .venv ]
  run bash scripts/reset.sh
  [ "$status" -eq 0 ]
}

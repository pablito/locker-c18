#!/usr/bin/env bats
# Tests for scripts/_mcp.sh

setup() {
  # Run each test in an isolated temp directory so .mcp.json doesn't leak
  export _ORIG_DIR="$PWD"
  cd "$BATS_TEST_TMPDIR"
}

teardown() {
  cd "$_ORIG_DIR"
}

# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------

@test "_mcp.sh: generates .mcp.json when it does not exist" {
  [ ! -f .mcp.json ]
  bash "$BATS_TEST_DIRNAME/../scripts/_mcp.sh"
  [ -f .mcp.json ]
}

@test "_mcp.sh: generated .mcp.json is valid JSON" {
  bash "$BATS_TEST_DIRNAME/../scripts/_mcp.sh"
  jq . .mcp.json > /dev/null
}

@test "_mcp.sh: .mcp.json uses '.' not absolute path for filesystem server" {
  bash "$BATS_TEST_DIRNAME/../scripts/_mcp.sh"
  local fs_path
  fs_path=$(jq -r '.mcpServers.filesystem.args[-1]' .mcp.json)
  [ "$fs_path" = "." ]
}

@test "_mcp.sh: .mcp.json uses '.' not absolute path for git server" {
  bash "$BATS_TEST_DIRNAME/../scripts/_mcp.sh"
  local repo_path
  repo_path=$(jq -r '.mcpServers.git.args[-1]' .mcp.json)
  [ "$repo_path" = "." ]
}

@test "_mcp.sh: .mcp.json does not contain hardcoded absolute paths" {
  bash "$BATS_TEST_DIRNAME/../scripts/_mcp.sh"
  # No path starting with / should appear as a server argument
  run jq -r '.. | strings | select(startswith("/"))' .mcp.json
  [ -z "$output" ]
}

# ---------------------------------------------------------------------------
# Idempotency
# ---------------------------------------------------------------------------

@test "_mcp.sh: does not overwrite existing .mcp.json" {
  echo '{"custom": true}' > .mcp.json
  bash "$BATS_TEST_DIRNAME/../scripts/_mcp.sh"
  run jq -r '.custom' .mcp.json
  [ "$output" = "true" ]
}

@test "_mcp.sh: exits cleanly when .mcp.json already exists" {
  echo '{}' > .mcp.json
  run bash "$BATS_TEST_DIRNAME/../scripts/_mcp.sh"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Server presence
# ---------------------------------------------------------------------------

@test "_mcp.sh: .mcp.json includes filesystem, git, fetch, memory servers" {
  bash "$BATS_TEST_DIRNAME/../scripts/_mcp.sh"
  run jq -r '.mcpServers | keys | sort | @csv' .mcp.json
  [[ "$output" == *"filesystem"* ]]
  [[ "$output" == *"fetch"* ]]
  [[ "$output" == *"git"* ]]
  [[ "$output" == *"memory"* ]]
}

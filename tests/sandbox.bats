#!/usr/bin/env bats
# Tests for scripts/sandbox.sh
# Covers security invariants added in the P0 fix session.

load 'helpers/mocks'

setup() {
  use_mocks
  # docker info must succeed (environment check passes)
  mock_cmd docker 0 ""
}

# ---------------------------------------------------------------------------
# AGENT_SANDBOX_IMAGE guard
# ---------------------------------------------------------------------------

@test "sandbox.sh: fails fast when AGENT_SANDBOX_IMAGE is unset" {
  run env -i HOME="$HOME" PATH="$PATH" bash "$BATS_TEST_DIRNAME/../scripts/sandbox.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"AGENT_SANDBOX_IMAGE must be set"* ]]
}

@test "sandbox.sh: accepts AGENT_SANDBOX_IMAGE when set" {
  # docker image inspect must succeed so the build step is skipped
  mock_cmd docker 0 ""
  # docker run will fail (no real daemon), but the guard should pass
  run env -i HOME="$HOME" PATH="$PATH" \
    AGENT_SANDBOX_IMAGE="test-image:latest" \
    bash "$BATS_TEST_DIRNAME/../scripts/sandbox.sh" echo hello
  # Guard itself should not produce the "must be set" error
  [[ "$output" != *"AGENT_SANDBOX_IMAGE must be set"* ]]
}

# ---------------------------------------------------------------------------
# Credential forwarding: only ANTHROPIC_API_KEY
# ---------------------------------------------------------------------------

@test "sandbox.sh: docker run receives ANTHROPIC_API_KEY flag" {
  mock_cmd docker 0 ""
  run env -i HOME="$HOME" PATH="$PATH" \
    AGENT_SANDBOX_IMAGE="test-image:latest" \
    ANTHROPIC_API_KEY="sk-test" \
    bash "$BATS_TEST_DIRNAME/../scripts/sandbox.sh" echo hello
  local args
  args=$(mock_args docker)
  [[ "$args" == *"-e ANTHROPIC_API_KEY"* ]] || [[ "$args" == *"-e"*"ANTHROPIC_API_KEY"* ]]
}

@test "sandbox.sh: docker run does NOT receive GITHUB_TOKEN flag" {
  mock_cmd docker 0 ""
  run env -i HOME="$HOME" PATH="$PATH" \
    AGENT_SANDBOX_IMAGE="test-image:latest" \
    GITHUB_TOKEN="ghp_test" \
    bash "$BATS_TEST_DIRNAME/../scripts/sandbox.sh" echo hello
  local args
  args=$(mock_args docker)
  [[ "$args" != *"GITHUB_TOKEN"* ]]
}

@test "sandbox.sh: docker run does NOT receive OPENAI_API_KEY flag" {
  mock_cmd docker 0 ""
  run env -i HOME="$HOME" PATH="$PATH" \
    AGENT_SANDBOX_IMAGE="test-image:latest" \
    OPENAI_API_KEY="sk-openai-test" \
    bash "$BATS_TEST_DIRNAME/../scripts/sandbox.sh" echo hello
  local args
  args=$(mock_args docker)
  [[ "$args" != *"OPENAI_API_KEY"* ]]
}

# ---------------------------------------------------------------------------
# Docker availability check
# ---------------------------------------------------------------------------

@test "sandbox.sh: exits when Docker is not available" {
  mock_cmd docker 1 ""  # docker info fails
  run env -i HOME="$HOME" PATH="$PATH" \
    AGENT_SANDBOX_IMAGE="test-image:latest" \
    bash "$BATS_TEST_DIRNAME/../scripts/sandbox.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Docker"* ]]
}

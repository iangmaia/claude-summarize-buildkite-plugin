#!/usr/bin/env bats

# shellcheck disable=SC2030,SC2031,SC2016 # Disable warnings for variable modifications in BATS subshells

setup() {
  load "${BATS_PLUGIN_PATH}/load.bash"

  # Common test variables
  export BUILDKITE_BUILD_ID='test-build-123'
  export BUILDKITE_JOB_ID='test-job-456'
  export BUILDKITE_PIPELINE_SLUG='test-pipeline'
}

teardown() {
  # Clean up environment variables
  unset BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY
  unset BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_BUILDKITE_API_TOKEN
  unset ANTHROPIC_API_KEY
  unset BUILDKITE_TOKEN_FOR_CLAUDE
  unset TEST_ENV_VAR
  unset EMPTY_ENV_VAR
}

@test "Environment hook exports API key when provided" {
  export BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY="sk-ant-test-key"

  # Source the environment hook
  source "$PWD"/hooks/environment

  # Check that the API key is exported
  [ "${BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY}" = "sk-ant-test-key" ]
}

@test "Environment hook handles empty API_KEY gracefully" {
  # Don't set API_KEY to test behavior
  unset BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY

  # Source the environment hook
  source "$PWD"/hooks/environment

  # API_KEY should not be set if not provided
  [ -z "${BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY:-}" ]
}

@test "Environment hook preserves literal values" {
  export BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY="literal-key-value"

  # Source the environment hook
  source "$PWD"/hooks/environment

  # Check that literal values are preserved
  [ "${BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY}" = "literal-key-value" ]
}

@test "Environment hook resolves a runtime API key reference" {
  export ANTHROPIC_API_KEY="sk-ant-runtime-key"
  export BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY='$ANTHROPIC_API_KEY'

  source "$PWD"/hooks/environment

  [ "${BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY}" = "sk-ant-runtime-key" ]
}

@test "Secret configuration does not evaluate shell expressions" {
  export BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY='$(printf unsafe)'

  source "$PWD"/hooks/environment

  [ "${BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY}" = '$(printf unsafe)' ]
}

@test "Missing runtime API key references resolve to an empty value" {
  export BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY='$MISSING_API_KEY'
  unset MISSING_API_KEY
  source "$PWD"/lib/plugin.bash

  [ -z "$(plugin_read_secret_config API_KEY ANTHROPIC_API_KEY)" ]
}

@test "Buildkite API token resolves a runtime environment reference" {
  export BUILDKITE_TOKEN_FOR_CLAUDE="buildkite-runtime-token"
  export BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_BUILDKITE_API_TOKEN='$BUILDKITE_TOKEN_FOR_CLAUDE'
  source "$PWD"/lib/plugin.bash

  [ "$(get_buildkite_api_token)" = "buildkite-runtime-token" ]
}

@test "Environment hook handles special characters in API key" {
  export BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY="sk-ant-key-with-special-chars_123"

  # Source the environment hook
  source "$PWD"/hooks/environment

  # Check that special characters are preserved
  [ "${BUILDKITE_PLUGIN_CLAUDE_SUMMARIZE_API_KEY}" = "sk-ant-key-with-special-chars_123" ]
}

@test "Plugin name and prefix are correct" {
  PLUGIN_NAME=$(grep -E '^name:' "./plugin.yml" | awk '{ $1=""; sub(/^ /,""); print }')

  source "$PWD"/lib/plugin.bash

  # Check that the name is correct in the YAML file
  [ "${PLUGIN_NAME}" = "Claude Summarize" ]

  # Check that the prefix is correct in the plugin script
  [ "${PLUGIN_PREFIX}" = "CLAUDE_SUMMARIZE" ]
}

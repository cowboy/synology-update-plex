#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}"/../update-plex.sh
}

@test 'process_args :: should print nothing by default' {
  run process_args
  [[ ! "$output" ]]
}

@test 'process_args :: should print help when --help is specified' {
  run process_args --help
  [[ "$output" =~ Usage ]]
}

@test 'process_args :: should print help when -h is specified' {
  run process_args -h
  [[ "$output" =~ Usage ]]
}

@test 'process_args :: should print help when -? is specified' {
  run process_args -?
  [[ "$output" =~ Usage ]]
}

@test 'process_args :: should not set plex_pass by default' {
  process_args
  [[ ! "$plex_pass" ]]
}

@test 'process_args :: should set plex_pass when --plex-pass is specified' {
  process_args --plex-pass
  [[ "$plex_pass" ]]
}

@test 'process_args :: should warn on unknown options' {
  run process_args --foo bar --baz >/dev/null 2>&1
  [[ "${lines[0]}" == "WARN: Unknown option (ignored): --foo" ]]
  [[ "${lines[1]}" == "WARN: Unknown option (ignored): bar" ]]
  [[ "${lines[2]}" == "WARN: Unknown option (ignored): --baz" ]]
}

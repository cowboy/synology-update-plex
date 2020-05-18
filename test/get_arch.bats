#!/usr/bin/env bats

setup() {
  load "${BATS_TEST_DIRNAME}"/../update-plex.sh
}

@test 'get_arch: should return the passed-in arch if not armv7' {
  run get_arch other_arch DS9001;     [[ "$output" == "other_arch" ]]
}

@test 'get_arch: should return the correct arch for the x18 series' {
  run get_arch armv7 RS3618xs;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS2818RP+;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS2418+;         [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS2418RP+;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS818+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS818RP+;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS3018xs;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS1618+;         [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS918+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS718+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS418;           [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS418play;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS418j;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS218+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS218;           [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS218play;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS218j;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS118;           [[ "$output" == "armv7hf_neon" ]]
}

@test 'get_arch: should return the correct arch for the x17 series' {
  run get_arch armv7 RS18017xs+;      [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS4017xs+;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS3617xs+;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS3617RPxs;      [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS3617xs;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS217;           [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS3617xs;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS1817+;         [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS1817;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS1517+;         [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS1517;          [[ "$output" == "armv7hf_neon" ]]
}

@test 'get_arch: should return the correct arch for the x16 series' {
  run get_arch armv7 RS18016xs+;      [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS2416+;         [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS2416RP+;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS816;           [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS916+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS716+II;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS716+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS416;           [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS416play;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS416j;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS416slim;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS216+II;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS216+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS216;           [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS216play;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS216j;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS216se;         [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS116;           [[ "$output" == "armv7hf_neon" ]]
}

@test 'get_arch: should return the correct arch for the x15 series' {
  run get_arch armv7 RS815+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS815RP+;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 RS815;           [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RC18015xs+;      [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS3615xs;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS2415+;         [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS2015xs;        [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS1815+;         [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS1515+;         [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS1515;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS715;           [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS415+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS415play;       [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS215+;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS215j;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS115;           [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS115j;          [[ "$output" == "armv7hf" ]]
}

@test 'get_arch: should return the correct arch for the x14 series' {
  run get_arch armv7 RS3614xs+;       [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS3614xs;        [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS3614RPxs;      [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS2414+;         [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS2414RP+;       [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS814+;          [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS814RP+;        [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS814;           [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS214;           [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS414;           [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS414j;          [[ "$output" == "armv7hf_neon" ]]
  run get_arch armv7 DS414slim;       [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS214+;          [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS214;           [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS214play;       [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS214se;         [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS114;           [[ "$output" == "armv7hf" ]]
}

@test 'get_arch: should return the correct arch for the x13 series' {
  run get_arch armv7 RS10613xs+;      [[ "$output" == "armv7hf" ]]
  run get_arch armv7 RS3413xs+;       [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS2413+;         [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS1813+;         [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS1513+;         [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS713+;          [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS413;           [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS413j;          [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS213+;          [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS213;           [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS213air;        [[ "$output" == "armv7hf" ]]
  run get_arch armv7 DS213j;          [[ "$output" == "armv7hf" ]]
}

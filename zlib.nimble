# nim-zlib
# Copyright (c) 2021-2023 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

mode = ScriptMode.Verbose

packageName   = "zlib"
version       = "0.1.0"
author        = "Status Research & Development GmbH"
description   = "zlib wrapper in nim"
license       = "Apache License 2.0"
skipDirs      = @["tests"]

requires "nim >= 1.6.0"
requires "stew >= 0.1.0"

# Helper functions
proc test(args, path: string) =
  if not dirExists "build":
    mkDir "build"
  exec "nim " & getEnv("TEST_LANG", "c") & " " & getEnv("NIMFLAGS") & " " & args &
    " --outdir:build -r -f --hints:off --warnings:off --skipParentCfg " & path

task test, "Run all tests":
  test "-d:debug", "tests/test_all"
  test "-d:release", "tests/test_all"
  test "--threads:on -d:release", "tests/test_all"
  if (NimMajor, NimMinor) > (1, 6):
    test "-d:debug", "tests/test_all"
    test "-d:release", "tests/test_all"
    test "--threads:on -d:release", "tests/test_all"

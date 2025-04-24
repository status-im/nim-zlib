# nim-zlib
# Copyright (c) 2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import
  std/[unittest, os],
  results,
  ../zlib/gzip

proc toBytes(s: string): seq[byte] =
  result = newSeq[byte](s.len)
  if s.len > 0:
    copyMem(result[0].addr, s[0].unsafeAddr, s.len)

suite "gzip test suite":
  const
    rawFolder = "tests" / "data"

  for path in walkDirRec(rawFolder):
    let parts = splitFile(path)
    test parts.name:
      let s = readFile(path)
      let cstr = string.gzip(s).get()
      let cbytes = seq[byte].gzip(s).get()
      check cbytes.len == cstr.len

      let dcstr  = string.ungzip(cbytes).get()
      let dcstr2 = string.ungzip(cstr).get()
      let dcbytes = seq[byte].ungzip(cbytes).get()
      let dcbytes2 = seq[byte].ungzip(cstr).get()
      check dcbytes2 == s.toBytes
      check dcbytes == s.toBytes
      check dcstr2 == s
      check dcstr == s

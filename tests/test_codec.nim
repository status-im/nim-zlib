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
  ../zlib/zlib_api

proc decompress[T: byte | char](data: openArray[T]): seq[byte] =
  var mz = ZStream(
    next_in: cast[ptr cuchar](data[0].unsafeAddr),
    avail_in: data.len.cuint
  )

  const windowBits = Z_DEFAULT_WINDOW_BITS
  doAssert(mz.inflateInit2(windowBits) == Z_OK)
  var res: seq[byte]
  var buf: array[0xFFFF, byte]

  while true:
    mz.next_out  = cast[ptr cuchar](buf[0].addr)
    mz.avail_out = buf.len.cuint
    let r = mz.inflate(Z_SYNC_FLUSH)
    let outSize = buf.len - mz.avail_out.int
    res.add toOpenArray(buf, 0, outSize-1)
    if r == Z_STREAM_END:
      break
    elif r == Z_OK:
      continue
    else:
      doAssert(false, "decompression error")

  doAssert(mz.inflateEnd() == Z_OK)
  return res

proc compress[T: byte | char](data: openArray[T]): seq[byte] =
  var mz = ZStream(
    next_in: if data.len == 0: nil else: cast[ptr cuchar](data[0].unsafeAddr),
    avail_in: data.len.cuint
  )

  const windowBits = Z_DEFAULT_WINDOW_BITS
  doAssert(mz.deflateInit2(
    level = Z_DEFAULT_LEVEL,
    meth  = Z_DEFLATED,
    windowBits,
    memLevel = Z_DEFAULT_MEM_LEVEL,
    strategy = Z_DEFAULT_STRATEGY) == Z_OK
  )

  let maxSize = mz.deflateBound(data.len.culong).int
  var res: seq[byte]
  var buf: array[0xFFFF, byte]

  while true:
    mz.next_out  = cast[ptr cuchar](buf[0].addr)
    mz.avail_out = buf.len.cuint
    let r = mz.deflate(Z_FINISH)
    let outSize = buf.len - mz.avail_out.int
    res.add toOpenArray(buf, 0, outSize-1)
    if r == Z_STREAM_END:
      break
    elif r == Z_OK:
      continue
    else:
      doAssert(false, "compression error")

  doAssert(mz.deflateEnd() == Z_OK)
  return res

proc toBytes(s: string): seq[byte] =
  result = newSeq[byte](s.len)
  if s.len > 0:
    copyMem(result[0].addr, s[0].unsafeAddr, s.len)

suite "codec test suite":
  const
    rawFolder = "tests" / "data"

  for path in walkDirRec(rawFolder):
    let parts = splitFile(path)
    test parts.name:
      let s = readFile(path).toBytes
      let c  = compress(s)
      let dc = decompress(c)
      check dc == s

# nim-zlib
# Copyright (c) 2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

{.push raises:[].}

import
  std/[os, strutils, streams, unittest],
  pkg/results,
  ../zlib/[gunzip_incremental, gzip]


proc nextLineWrapper(gz: GUnzipRef): Opt[string] =
  try:
    gz.nextLine().isErrOr:
      return ok(value)
  except CatchableError:
    discard
  err()

proc nextChunkWrapper(gz: GUnzipRef): Opt[string] =
  try:
    gz.nextChunk().isErrOr:
      return ok(value)
  except CatchableError:
    discard
  err()

func isTextFile(ext, data: string): bool =
  if ext in [".txt", ".html"]:
    return true
  if data.len < 3:
    return false
  if data[0] == '<' and data[1] == '!': # xml/http
    return true
  if data[0] == 'h' and data[1] == 't' and data[2] == 't': # list of urls
    return true
  # false


suite "Incremental guzip test suite":
  const
    rawFolder = "tests" / "data"

  for path in walkDirRec(rawFolder):
    let parts = splitFile(path)

    test parts.name:
      let
        inData = readFile(path)
        isText = parts.ext.isTextFile(inData)
        inStream = string.gzip(inData).get().newStringStream()

      defer: inStream.close()
      let gz = GUnzipRef.init(inStream).expect "valid gunzip descriptor"

      if isText:
        var outLines: seq[string]
        while true:
          let line = gz.nextLineWrapper().valueOr:
            check gz.lineStatusOk()
            break
          # Collect it without end-of-line marker
          outLines.add line

        # Get rid of end-of-line markers
        let inLines = inData.splitLines

        # Adjust for extra line feed
        if outLines.len + 1 == inLines.len and inLines[^1] == "":
          outLines.add ""

        check outLines == inLines

      else:
        var outData = ""
        while true:
          let data = gz.nextChunkWrapper().valueOr:
            check gz.atEnd()
            break
          outData &= data

        check outData == inData

# End

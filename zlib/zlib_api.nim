# nim-zlib
# Copyright (c) 2021 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import strutils
from os import quoteShell, DirSep, AltSep

const
  basePath = currentSourcePath.rsplit({DirSep, AltSep}, 1)[0]
  zlibPath = basePath & "/csources"

{.passC: "-I" & quoteShell(zlibPath).}
{.compile: zlibPath & "/adler32.c".}
{.compile: zlibPath & "/compress.c".}
{.compile: zlibPath & "/crc32.c".}
{.compile: zlibPath & "/deflate.c".}
{.compile: zlibPath & "/gzclose.c".}
{.compile: zlibPath & "/gzlib.c".}
{.compile: zlibPath & "/gzread.c".}
{.compile: zlibPath & "/gzwrite.c".}
{.compile: zlibPath & "/inffast.c".}
{.compile: zlibPath & "/inflate.c".}
{.compile: zlibPath & "/infback.c".}
{.compile: zlibPath & "/inftrees.c".}
{.compile: zlibPath & "/trees.c".}
{.compile: zlibPath & "/uncompr.c".}
{.compile: zlibPath & "/zutil.c".}

type
  ZError* {.size: sizeof(cint).} = enum
    Z_PARAM_ERROR   = -10000
    Z_VERSION_ERROR = -6
    Z_BUF_ERROR     = -5
    Z_MEM_ERROR     = -4
    Z_DATA_ERROR    = -3
    Z_STREAM_ERROR  = -2
    Z_ERRNO         = -1
    Z_OK            = 0
    Z_STREAM_END    = 1
    Z_NEED_DICT     = 2

  ZLevel* {.size: sizeof(cint).} = enum
    Z_DEFAULT_COMPRESSION  = -1
    Z_NO_COMPRESSION       = 0
    Z_BEST_SPEED           = 1
    Z_LEVEL_2              = 2
    Z_LEVEL_3              = 3
    Z_LEVEL_4              = 4
    Z_LEVEL_5              = 5
    Z_LEVEL_6              = 6
    Z_LEVEL_7              = 7
    Z_LEVEL_8              = 8
    Z_BEST_COMPRESSION     = 9
    Z_UBER_COMPRESSION     = 10

  ZMemLevel* {.size: sizeof(cint).} = enum
    Z_MEM_1 = 1
    Z_MEM_2 = 2
    Z_MEM_3 = 3
    Z_MEM_4 = 4
    Z_MEM_5 = 5
    Z_MEM_6 = 6
    Z_MEM_7 = 7
    Z_MEM_8 = 8
    Z_MEM_9 = 9

  ZMethod* {.size: sizeof(cint).} = enum
    Z_DEFLATED = 8

  ZWindowBits* {.size: sizeof(cint).} = enum
    Z_RAW_DEFLATE         = -15
    Z_RAW_WINDOW_BITS_14  = -14
    Z_RAW_WINDOW_BITS_13  = -13
    Z_RAW_WINDOW_BITS_12  = -12
    Z_RAW_WINDOW_BITS_11  = -11
    Z_RAW_WINDOW_BITS_10  = -10
    Z_RAW_WINDOW_BITS_9   = -9
    Z_RAW_WINDOW_BITS_8   = -8

    Z_WINDOW_BITS_8       = 8
    Z_WINDOW_BITS_9       = 9
    Z_WINDOW_BITS_10      = 10
    Z_WINDOW_BITS_11      = 11
    Z_WINDOW_BITS_12      = 12
    Z_WINDOW_BITS_13      = 13
    Z_WINDOW_BITS_14      = 14
    Z_WINDOW_BITS_15      = 15

  ZStrategy* {.size: sizeof(cint).} = enum
    Z_DEFAULT_STRATEGY = 0
    Z_FILTERED         = 1
    Z_HUFFMAN_ONLY     = 2
    Z_RLE              = 3
    Z_FIXED            = 4

  ZFlush* {.size: sizeof(cint).} = enum
    Z_NO_FLUSH      = 0
    Z_PARTIAL_FLUSH = 1
    Z_SYNC_FLUSH    = 2
    Z_FULL_FLUSH    = 3
    Z_FINISH        = 4
    Z_BLOCK         = 5

type
  AllocFunc* = proc(ud: pointer, items: cuint, size: cuint): pointer {.cdecl.}
  FreeFunc* = proc(ud: pointer, address: pointer){.cdecl.}

  ZStream* {.final, pure.} = object
    next_in*  : ptr cuchar
    avail_in* : cuint
    total_in* : culong
    next_out* : ptr cuchar
    avail_out*: cuint
    total_out*: culong

    msg*      : cstring
    state*    : pointer
    zalloc*   : AllocFunc
    zfree*    : FreeFunc
    opaque*   : pointer
    dataType* : cint
    adler*    : culong
    reserved* : culong

  GZHeader*{.final, pure.} = object # not defined yet (see zlib.h)

const
  ZLIB_VERSION = "1.2.11"
  Z_DEFAULT_MEM_LEVEL*   = Z_MEM_8
  Z_DEFAULT_WINDOW_BITS* = Z_WINDOW_BITS_15
  Z_DEFAULT_LEVEL*       = Z_LEVEL_6

proc zlibVersion*(): ptr char {.cdecl, importc: "zlibVersion".}

proc deflate*(zs: var ZStream, flush: ZFlush): ZError {.cdecl,
  importc: "deflate".}

proc deflateEnd*(zs: var ZStream): ZError {.cdecl,
  importc: "deflateEnd".}

proc deflateReset*(zs: var ZStream): ZError {.cdecl,
  importc: "deflateReset".}

proc deflateParams*(zs: var ZStream, level: ZLevel,
  strategy: ZStrategy): ZError {.cdecl,
    importc: "deflateParams".}

proc deflateInitu(zs: var ZStream, level: ZLevel, version: cstring,
  streamSize: cint): ZError {.cdecl, importc: "deflateInit_".}

proc deflateInit2u(zs: var ZStream, level: ZLevel, meth: ZMethod,
  windowBits: ZWindowBits, memLevel: ZMemLevel, strategy: ZStrategy,
  version: cstring, streamSize: cint): ZError {.cdecl,
  importc: "deflateInit2_".}

proc deflateInit*(zs: var ZStream, level: ZLevel): ZError =
  deflateInitu(zs, level, ZLIB_VERSION, sizeof(ZStream).cint)

proc deflateInit2*(zs: var ZStream, level: ZLevel,
  meth: ZMethod, windowBits: ZWindowBits,
  memLevel: ZMemLevel, strategy: ZStrategy): ZError =
  deflateInit2u(zs, level, meth, windowBits,
    memLevel, strategy, ZLIB_VERSION, sizeof(ZStream).cint)

proc deflateBound*(zs: var ZStream, sourceLen: culong): culong {.cdecl,
  importc: "deflateBound".}

proc inflate*(zs: var ZStream, flush: ZFlush): ZError {.cdecl,
  importc: "inflate".}

proc inflateEnd*(zs: var ZStream): ZError {.cdecl,
  importc: "inflateEnd".}

proc inflateInitu(zs: var ZStream,
  version: cstring, streamSize: cint): ZError {. cdecl,
    importc: "inflateInit_".}

proc inflateInit2u(zs: var ZStream, windowBits: ZWindowBits,
  version: cstring, streamSize: cint): ZError {.cdecl,
    importc: "inflateInit2_".}

proc inflateInit*(zs: var ZStream): ZError =
  inflateInitu(zs, ZLIB_VERSION, sizeof(ZStream).cint)

proc inflateInit2*(zs: var ZStream, windowBits: ZWindowBits): ZError =
  inflateInit2u(zs, windowBits, ZLIB_VERSION, sizeof(ZStream).cint)

proc inflateReset*(zs: var ZStream): ZError {.cdecl,
  importc: "inflateReset".}

proc inflateReset2*(zs: var ZStream,
  windowBits: ZWindowBits): ZError {.cdecl,
    importc: "inflateReset2".}

proc zError*(err: ZError): cstring {.cdecl, importc: "zError".}

proc crc32*(crc: culong, buf: ptr cuchar, length: cuint): culong {.cdecl,
  importc: "crc32".}

const
  Z_CRC32_INIT* = 0.culong

func crc32*[T: byte|char](input: openArray[T]): culong =
  let dataPtr = if input.len == 0:
                  nil
                else:
                  cast[ptr cuchar](input[0].unsafeAddr)
  crc32(Z_CRC32_INIT,
    dataPtr,
    input.len.cuint
  ).culong

proc deflateSetDictionary*(zs: var ZStream,
  dictionary: ptr cuchar, dictLength: cuint): ZError {.cdecl,
    importc: "deflateSetDictionary".}

proc deflateCopy*(dest: ZStream, source: var ZStream): ZError {.cdecl,
  importc: "deflateCopy".}

proc deflateTune*(zs: var ZStream, goodLength,
  maxLazy, niceLength, maxChain: cint): ZError {.cdecl,
    importc: "deflateTune".}

proc deflatePending*(zs: var ZStream,
  pending: var cuint, bits: var cint): ZError {.cdecl,
    importc: "deflatePending".}

proc deflatePrime*(zs: var ZStream, bits, value: cint): ZError {.cdecl,
  importc: "deflatePrime".}

proc deflateSetHeader*(zs: var ZStream,
  head: ptr GZHeader): ZError {.cdecl,
    importc: "deflateSetHeader".}

proc inflateSetDictionary*(zs: var ZStream,
  dictionary: ptr cuchar, dictLength: cuint): ZError {.cdecl,
    importc: "inflateSetDictionary".}

proc inflateGetDictionary*(zs: var ZStream,
  dictionary: ptr cuchar, dictLength: ptr cuint): ZError {.cdecl,
    importc: "inflateGetDictionary".}

proc inflateSync*(zs: var ZStream): ZError {.cdecl,
  importc: "inflateSync".}

proc inflateCopy*(dest: ZStream, source: var ZStream): ZError {.cdecl,
  importc: "inflateCopy".}

proc inflatePrime*(zs: var ZStream,
  bits: cint, value: cint): ZError {.cdecl,
    importc: "inflatePrime".}

proc inflateMark*(zs: var ZStream): ZError {.cdecl,
  importc: "inflateMark".}

proc inflateGetHeader*(zs: var ZStream, head: ptr GZHeader): ZError {.cdecl,
  importc: "inflateGetHeader".}

proc zlibCompileFlags*(): culong {.cdecl,
  importc: "zlibCompileFlags".}

proc compress*(dest: ptr cuchar, destLen: var culong,
  source: ptr cuchar, sourceLen: culong): ZError {.cdecl,
    importc: "compress".}

proc compress2*(dest: ptr cuchar, destLen: var culong,
  source: ptr cuchar, sourceLen: culong, level: cint): ZError {.cdecl,
    importc: "compress2".}

proc uncompress*(dest: ptr cuchar, destLen: var culong,
  source: ptr cuchar, sourceLen: culong): ZError {.cdecl,
    importc: "uncompress".}

proc compressBound*(sourceLen: culong): culong {.cdecl, importc.}

proc inflateSyncPoint*(z: var Zstream): ZError {.cdecl,
  importc: "inflateSyncPoint".}

proc getCrcTable*(): pointer {.cdecl, importc: "get_crc_table".}

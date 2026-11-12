# nim-zlib
# Copyright (c) 2021-2026 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import std/strutils
from std/os import quoteShell, DirSep, AltSep

const
  basePath = currentSourcePath.rsplit({DirSep, AltSep}, 1)[0]
  zlibPath = basePath & "/csources"

{.passc: "-I" & quoteShell(zlibPath) & " -DHAVE_UNISTD_H".}
{.compile: zlibPath & "/adler32.c".}
{.compile: zlibPath & "/compress.c".}
{.compile: zlibPath & "/crc32.c".}
{.compile: zlibPath & "/deflate.c".}
{.compile: zlibPath & "/gzclose.c".}
{.compile: zlibPath & "/gzlib.c".}
{.compile: zlibPath & "/gzread.c".}
{.compile: zlibPath & "/gzwrite.c".}
{.compile: zlibPath & "/infback.c".}
{.compile: zlibPath & "/inffast.c".}
{.compile: zlibPath & "/inflate.c".}
{.compile: zlibPath & "/inftrees.c".}
{.compile: zlibPath & "/trees.c".}
{.compile: zlibPath & "/uncompr.c".}
{.compile: zlibPath & "/zutil.c".}

type
  gzFile_s = object

  # zconf.h defines `z_off_t` as `off_t`, due to `HAVE_UNISTD_H`
  z_off_t {.importc: "off_t", header: "<sys/types.h>".} = clong



const
  ZLIB_VERSION* = "1.4"
  ZLIB_VERNUM* = 0x1400
  ZLIB_VER_MAJOR* = 1
  ZLIB_VER_MINOR* = 4
  ZLIB_VER_REVISION* = 0
  ZLIB_VER_SUBREVISION* = 0


type
  AllocFunc* = proc (opaque: pointer; items: cuint; size: cuint): pointer {.cdecl.}
  FreeFunc* = proc (opaque: pointer; address: pointer) {.cdecl.}
  ZStream* {.bycopy.} = object
    next_in*: ptr uint8
    avail_in*: cuint
    total_in*: culong
    next_out*: ptr uint8
    avail_out*: cuint
    total_out*: culong
    msg*: cstring
    state*: pointer
    zalloc*: AllocFunc
    zfree*: FreeFunc
    opaque*: pointer
    dataType*: cint
    adler*: culong
    reserved*: culong

  ZStreamp* = ptr ZStream


type
  GZHeader* {.bycopy.} = object
    text*: cint
    time*: culong
    xflags*: cint
    os*: cint
    extra*: ptr uint8
    extra_len*: cuint
    extra_max*: cuint
    name*: ptr uint8
    name_max*: cuint
    comment*: ptr uint8
    comm_max*: cuint
    hcrc*: cint
    done*: cint

  GZHeaderp* = ptr GZHeader


type
  ZFlush* {.size: sizeof(cint).} = enum
    Z_NO_FLUSH = 0, Z_PARTIAL_FLUSH = 1, Z_SYNC_FLUSH = 2, Z_FULL_FLUSH = 3, Z_FINISH = 4,
    Z_BLOCK = 5, Z_TREES = 6



type
  ZError* {.size: sizeof(cint).} = enum
    Z_VERSION_ERROR = -6, Z_BUF_ERROR = -5, Z_MEM_ERROR = -4, Z_DATA_ERROR = -3,
    Z_STREAM_ERROR = -2, Z_ERRNO = -1, Z_OK = 0, Z_STREAM_END = 1, Z_NEED_DICT = 2



type
  ZLevel* {.size: sizeof(cint).} = enum
    Z_DEFAULT_COMPRESSION = -1, Z_NO_COMPRESSION = 0, Z_BEST_SPEED = 1, Z_LEVEL_2 = 2,
    Z_LEVEL_3 = 3, Z_LEVEL_4 = 4, Z_LEVEL_5 = 5, Z_LEVEL_6 = 6, Z_LEVEL_7 = 7, Z_LEVEL_8 = 8,
    Z_BEST_COMPRESSION = 9



type
  ZStrategy* {.size: sizeof(cint).} = enum
    Z_DEFAULT_STRATEGY = 0, Z_FILTERED = 1, Z_HUFFMAN_ONLY = 2, Z_RLE = 3, Z_FIXED = 4



const
  Z_BINARY* = 0
  Z_TEXT* = 1
  Z_ASCII* = Z_TEXT
  Z_UNKNOWN* = 2


type
  ZMethod* {.size: sizeof(cint).} = enum
    Z_DEFLATED = 8



const
  Z_NULL* = 0


proc zlibVersion*(): cstring {.cdecl, importc: "zlibVersion".}

proc deflate*(zs: var ZStream; flush: ZFlush): ZError {.cdecl, importc: "deflate".}

proc deflateEnd*(zs: var ZStream): ZError {.cdecl, importc: "deflateEnd".}

proc inflate*(zs: var ZStream; flush: ZFlush): ZError {.cdecl, importc: "inflate".}

proc inflateEnd*(zs: var ZStream): ZError {.cdecl, importc: "inflateEnd".}

proc deflateSetDictionary*(zs: var ZStream; dictionary: ptr uint8; dictLength: cuint): ZError {.
    cdecl, importc: "deflateSetDictionary".}

proc deflateGetDictionary*(zs: var ZStream; dictionary: ptr uint8;
                          dictLength: ptr cuint): ZError {.cdecl,
    importc: "deflateGetDictionary".}

proc deflateCopy*(dest: var ZStream; source: var ZStream): ZError {.cdecl,
    importc: "deflateCopy".}

proc deflateReset*(zs: var ZStream): ZError {.cdecl, importc: "deflateReset".}

proc deflateParams*(zs: var ZStream; level: ZLevel; strategy: ZStrategy): ZError {.cdecl,
    importc: "deflateParams".}

proc deflateTune*(zs: var ZStream; good_length: cint; max_lazy: cint;
                 nice_length: cint; max_chain: cint): ZError {.cdecl,
    importc: "deflateTune".}

proc deflateBound*(zs: var ZStream; sourceLen: culong): culong {.cdecl,
    importc: "deflateBound".}
proc deflateBound_z*(zs: var ZStream; sourceLen: csize_t): csize_t {.cdecl,
    importc: "deflateBound_z".}

proc deflatePending*(zs: var ZStream; pending: var cuint; bits: var cint): ZError {.cdecl,
    importc: "deflatePending".}

proc deflateUsed*(zs: var ZStream; bits: var cint): ZError {.cdecl,
    importc: "deflateUsed".}

proc deflatePrime*(zs: var ZStream; bits: cint; value: cint): ZError {.cdecl,
    importc: "deflatePrime".}

proc deflateSetHeader*(zs: var ZStream; head: GZHeaderp): ZError {.cdecl,
    importc: "deflateSetHeader".}

proc inflateSetDictionary*(zs: var ZStream; dictionary: ptr uint8; dictLength: cuint): ZError {.
    cdecl, importc: "inflateSetDictionary".}

proc inflateGetDictionary*(zs: var ZStream; dictionary: ptr uint8;
                          dictLength: ptr cuint): ZError {.cdecl,
    importc: "inflateGetDictionary".}

proc inflateSync*(zs: var ZStream): ZError {.cdecl, importc: "inflateSync".}

proc inflateCopy*(dest: var ZStream; source: var ZStream): ZError {.cdecl,
    importc: "inflateCopy".}

proc inflateReset*(zs: var ZStream): ZError {.cdecl, importc: "inflateReset".}

proc inflateReset2*(zs: var ZStream; windowBits: cint): ZError {.cdecl,
    importc: "inflateReset2".}

proc inflatePrime*(zs: var ZStream; bits: cint; value: cint): ZError {.cdecl,
    importc: "inflatePrime".}

proc inflateMark*(zs: var ZStream): clong {.cdecl, importc: "inflateMark".}

proc inflateGetHeader*(zs: var ZStream; head: GZHeaderp): ZError {.cdecl,
    importc: "inflateGetHeader".}

type
  in_func* = proc (a1: pointer; a2: ptr ptr uint8): cuint {.cdecl.}
  out_func* = proc (a1: pointer; a2: ptr uint8; a3: cuint): cint {.cdecl.}

proc inflateBack*(zs: var ZStream; `in`: in_func; in_desc: pointer; `out`: out_func;
                 out_desc: pointer): ZError {.cdecl, importc: "inflateBack".}

proc inflateBackEnd*(zs: var ZStream): ZError {.cdecl, importc: "inflateBackEnd".}

proc zlibCompileFlags*(): culong {.cdecl, importc: "zlibCompileFlags".}

proc compress*(dest: ptr uint8; destLen: var culong; source: ptr uint8; sourceLen: culong): ZError {.
    cdecl, importc: "compress".}
proc compress_z*(dest: ptr uint8; destLen: var csize_t; source: ptr uint8;
                sourceLen: csize_t): ZError {.cdecl, importc: "compress_z".}

proc compress2*(dest: ptr uint8; destLen: var culong; source: ptr uint8; sourceLen: culong;
               level: ZLevel): ZError {.cdecl, importc: "compress2".}
proc compress2_z*(dest: ptr uint8; destLen: var csize_t; source: ptr uint8;
                 sourceLen: csize_t; level: ZLevel): ZError {.cdecl,
    importc: "compress2_z".}

proc compressBound*(sourceLen: culong): culong {.cdecl, importc: "compressBound".}
proc compressBound_z*(sourceLen: csize_t): csize_t {.cdecl,
    importc: "compressBound_z".}

proc uncompress*(dest: ptr uint8; destLen: var culong; source: ptr uint8; sourceLen: culong): ZError {.
    cdecl, importc: "uncompress".}
proc uncompress_z*(dest: ptr uint8; destLen: var csize_t; source: ptr uint8;
                  sourceLen: csize_t): ZError {.cdecl, importc: "uncompress_z".}

proc uncompress2*(dest: ptr uint8; destLen: var culong; source: ptr uint8;
                 sourceLen: ptr culong): ZError {.cdecl, importc: "uncompress2".}
proc uncompress2_z*(dest: ptr uint8; destLen: var csize_t; source: ptr uint8;
                   sourceLen: ptr csize_t): ZError {.cdecl, importc: "uncompress2_z".}

type
  gzFile* = ptr gzFile_s


proc gzdopen*(fd: cint; mode: cstring): gzFile {.cdecl, importc: "gzdopen".}

proc gzbuffer*(file: gzFile; size: cuint): cint {.cdecl, importc: "gzbuffer".}

proc gzsetparams*(file: gzFile; level: ZLevel; strategy: ZStrategy): cint {.cdecl,
    importc: "gzsetparams".}

proc gzread*(file: gzFile; buf: pointer; len: cuint): cint {.cdecl, importc: "gzread".}

proc gzfread*(buf: pointer; size: csize_t; nitems: csize_t; file: gzFile): csize_t {.
    cdecl, importc: "gzfread".}

proc gzwrite*(file: gzFile; buf: pointer; len: cuint): cint {.cdecl, importc: "gzwrite".}

proc gzfwrite*(buf: pointer; size: csize_t; nitems: csize_t; file: gzFile): csize_t {.
    cdecl, importc: "gzfwrite".}

proc gzprintf*(file: gzFile; format: cstring): cint {.varargs, cdecl,
    importc: "gzprintf".}

proc gzputs*(file: gzFile; s: cstring): cint {.cdecl, importc: "gzputs".}

proc gzgets*(file: gzFile; buf: cstring; len: cint): cstring {.cdecl, importc: "gzgets".}

proc gzputc*(file: gzFile; c: cint): cint {.cdecl, importc: "gzputc".}

proc gzgetc*(file: gzFile): cint {.cdecl, importc: "gzgetc".}

proc gzungetc*(c: cint; file: gzFile): cint {.cdecl, importc: "gzungetc".}

proc gzflush*(file: gzFile; flush: ZFlush): cint {.cdecl, importc: "gzflush".}

proc gzrewind*(file: gzFile): cint {.cdecl, importc: "gzrewind".}

proc gzeof*(file: gzFile): cint {.cdecl, importc: "gzeof".}

proc gzdirect*(file: gzFile): cint {.cdecl, importc: "gzdirect".}

proc gzclose*(file: gzFile): cint {.cdecl, importc: "gzclose".}

proc gzclose_r*(file: gzFile): cint {.cdecl, importc: "gzclose_r".}
proc gzclose_w*(file: gzFile): cint {.cdecl, importc: "gzclose_w".}

proc gzerror*(file: gzFile; errnum: ptr cint): cstring {.cdecl, importc: "gzerror".}

proc gzclearerr*(file: gzFile) {.cdecl, importc: "gzclearerr".}

proc adler32*(adler: culong; buf: ptr uint8; len: cuint): culong {.cdecl, importc: "adler32".}

proc adler32_z*(adler: culong; buf: ptr uint8; len: csize_t): culong {.cdecl,
    importc: "adler32_z".}

proc crc32*(crc: culong; buf: ptr uint8; len: cuint): culong {.cdecl, importc: "crc32".}

proc crc32_z*(crc: culong; buf: ptr uint8; len: csize_t): culong {.cdecl,
    importc: "crc32_z".}

proc crc32_combine_op*(crc1: culong; crc2: culong; op: culong): culong {.cdecl,
    importc: "crc32_combine_op".}

proc deflateInitImpl(zs: var ZStream; level: ZLevel; version: cstring; stream_size: cint): ZError {.
    cdecl, importc: "deflateInit_".}
proc inflateInitImpl(zs: var ZStream; version: cstring; stream_size: cint): ZError {.
    cdecl, importc: "inflateInit_".}
proc deflateInit2Impl(zs: var ZStream; level: ZLevel; meth: ZMethod; windowBits: cint;
                   memLevel: cint; strategy: ZStrategy; version: cstring; stream_size: cint): ZError {.
    cdecl, importc: "deflateInit2_".}
proc inflateInit2Impl(zs: var ZStream; windowBits: cint; version: cstring;
                   stream_size: cint): ZError {.cdecl, importc: "inflateInit2_".}
proc inflateBackInitImpl(zs: var ZStream; windowBits: cint; window: ptr uint8;
                      version: cstring; stream_size: cint): ZError {.cdecl,
    importc: "inflateBackInit_".}
template deflateInit*(zs, level: untyped): untyped =
  deflateInitImpl((zs), (level), ZLIB_VERSION,
               cast[cint](sizeof((ZStream))))

template inflateInit*(zs: untyped): untyped =
  inflateInitImpl((zs), ZLIB_VERSION, cast[cint](sizeof((ZStream))))

template deflateInit2*(zs, level, meth, windowBits, memLevel, strategy: untyped): untyped =
  deflateInit2Impl((zs), (level), (meth), (windowBits), (memLevel), (strategy),
                ZLIB_VERSION, cast[cint](sizeof((ZStream))))

template inflateInit2*(zs, windowBits: untyped): untyped =
  inflateInit2Impl((zs), (windowBits), ZLIB_VERSION,
                cast[cint](sizeof((ZStream))))

template inflateBackInit*(zs, windowBits, window: untyped): untyped =
  inflateBackInitImpl((zs), (windowBits), (window), ZLIB_VERSION,
                   cast[cint](sizeof((ZStream))))


proc gzopen*(a1: cstring; a2: cstring): gzFile {.cdecl, importc: "gzopen".}
proc gzseek*(a1: gzFile; a2: z_off_t; a3: cint): z_off_t {.cdecl, importc: "gzseek".}
proc gztell*(a1: gzFile): z_off_t {.cdecl, importc: "gztell".}
proc gzoffset*(a1: gzFile): z_off_t {.cdecl, importc: "gzoffset".}
proc adler32_combine*(a1: culong; a2: culong; a3: z_off_t): culong {.cdecl,
    importc: "adler32_combine".}
proc crc32_combine*(a1: culong; a2: culong; a3: z_off_t): culong {.cdecl,
    importc: "crc32_combine".}
proc crc32_combine_gen*(a1: z_off_t): culong {.cdecl, importc: "crc32_combine_gen".}

type
  ZMemLevel* = cint
  ZWindowBits* = cint

const
  Z_DEFAULT_LEVEL* = Z_DEFAULT_COMPRESSION
  Z_DEFAULT_MEM_LEVEL*: ZMemLevel = 8
  Z_DEFAULT_WINDOW_BITS*: ZWindowBits = 15
  Z_RAW_DEFLATE*: ZWindowBits = -15
  Z_CRC32_INIT* = 0.culong

func crc32*[T: byte|char](input: openArray[T]): culong =
  let dataPtr = if input.len == 0:
                  nil
                else:
                  cast[ptr uint8](input[0].addr)
  crc32(Z_CRC32_INIT,
    dataPtr,
    input.len.cuint
  ).culong

#!/usr/bin/env bash
# nim-zlib
# Copyright (c) 2026 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.
set -eu -o pipefail
cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")"

[[ $(c2nim -v) == "0.9.18" ]] || { echo "c2nim 0.9.18 required"; exit 1; }

mkdir -p gen
cp zlib/csources/zlib.h gen

# c2nim gets confused by the conditional sections - keep the default ones
unifdef -m -UZLIB_BUILD -UZ_PREFIX_SET -UZ_SOLO -UZ_LARGE64 -UZ_WANT64 -DSTDC \
  gen/zlib.h || [ $? -eq 1 ]  # Exit status 1: files changed

# - The constant groups, up to their comment, are typed enums (c2nim sorts them)
# - `zlib_version` calls `zlibVersion()`, and `internal_state` is opaque
# - c2nim gets confused by the attribute macros - drop them
# - Return codes are `ZError`, except for gz*
# - `gzFile_s` is opaque - its fields are only for the `gzgetc` macro
# - The undocumented functions are not part of the zlib API
# - `method` is a Nim keyword - spell it `meth`
sed -i.bak -E \
  -e '/^#define (Z_NO_FLUSH|Z_OK|Z_NO_COMPRESSION|Z_FILTERED|Z_DEFLATED) /,/^\/\*/{s/^#define (Z_[A-Z_]+) +\(?(-?[0-9]+)\)?$/\1 = \2,/;s/^\/\*/}; &/;}' \
  -e 's/^Z_NO_FLUSH /enum ZFlush { &/' \
  -e 's/^Z_OK /enum ZError { &/' \
  -e 's/^Z_NO_COMPRESSION /enum ZLevel { Z_LEVEL_2 = 2, Z_LEVEL_3 = 3, Z_LEVEL_4 = 4, Z_LEVEL_5 = 5, Z_LEVEL_6 = 6, Z_LEVEL_7 = 7, Z_LEVEL_8 = 8, &/' \
  -e 's/^Z_FILTERED /enum ZStrategy { &/' \
  -e 's/^Z_DEFLATED /enum ZMethod { &/' \
  -e '/^(#define zlib_version|struct internal_state;)/d' \
  -e 's/(ZEXTERN|ZEXPORTVA|ZEXPORT|FAR|z_const) +//g' \
  -e 's/^int( +(deflate|inflate|compress|uncompress))/ZError\1/' \
  -e '/^struct gzFile_s/,/\(gzgetc\)\(g\)/d' \
  -e '/undocumented functions/,/^$/d' \
  -e 's/method/meth/g' \
  gen/zlib.h
rm -f gen/zlib.h.bak  # Portable GNU/macOS `sed` needs backup

c2nim --strict --importc --skipinclude --cdecl --skipcomments --out:gen/zlib.nim gen/zlib.h

# Keep the established names and types
# - The stream is passed as `zs: var ZStream`
# - The `*Init_` helpers of the `*Init` templates are private, and cannot end
#   with `_` - use `Impl` instead
# - The zconf.h types are bound to their Nim equivalents
# - The enums have the size of `int`
# - The options are typed enums, and output parameters use `var`
sed -i.bak -E \
  -e 's/strm/zs/g' \
  -e 's/: z_streamp/: var z_stream/g' \
  -e 's/(construct)?z_stream/ZStream/g' \
  -e 's/alloc_func/AllocFunc/g' \
  -e 's/free_func/FreeFunc/g' \
  -e 's/gz_header/GZHeader/g' \
  -e 's/data_type/dataType/' \
  -e 's/_\*?\(/Impl(/g' \
  -e 's/Bytef|cuchar/uint8/g' \
  -e 's/uInt/cuint/g' \
  -e 's/uLongf?/culong/g' \
  -e 's/voidp[cf]?|ptr internal_state/pointer/g' \
  -e 's/z_size_t/csize_t/g' \
  -e 's/\* = enum/* {.size: sizeof(cint).} = enum/' \
  -e 's/flush: cint/flush: ZFlush/g' \
  -e 's/level: cint/level: ZLevel/g' \
  -e 's/meth: cint/meth: ZMethod/g' \
  -e 's/strategy: cint/strategy: ZStrategy/g' \
  -e 's/(destLen|pending|bits): ptr/\1: var/g' \
  gen/zlib.nim
rm -f gen/zlib.nim.bak  # Portable GNU/macOS `sed` needs backup

OUT=zlib/zlib_api.nim

cat > "$OUT" <<'EOF'
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
EOF

for f in zlib/csources/*.c; do
  echo "{.compile: zlibPath & \"/${f##*/}\".}" >> "$OUT"
done

cat >> "$OUT" <<'EOF'

type
  gzFile_s = object

  # zconf.h defines `z_off_t` as `off_t`, due to `HAVE_UNISTD_H`
  z_off_t {.importc: "off_t", header: "<sys/types.h>".} = clong

EOF

cat gen/zlib.nim >> "$OUT"

# The defaults of `deflateInit` are defined in zconf.h and zutil.h
MAX_WBITS=$(sed -n -E 's/^#  define MAX_WBITS +([0-9]+).*/\1/p' zlib/csources/zconf.h)
DEF_MEM_LEVEL=$(sed -n -E 's/^#  define DEF_MEM_LEVEL +([0-9]+)$/\1/p' zlib/csources/zutil.h)

cat >> "$OUT" <<EOF


type
  ZMemLevel* = cint
  ZWindowBits* = cint

const
  Z_DEFAULT_LEVEL* = Z_DEFAULT_COMPRESSION
  Z_DEFAULT_MEM_LEVEL*: ZMemLevel = ${DEF_MEM_LEVEL:?}
  Z_DEFAULT_WINDOW_BITS*: ZWindowBits = ${MAX_WBITS:?}
  Z_RAW_DEFLATE*: ZWindowBits = -${MAX_WBITS:?}
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
EOF

rm -rf gen

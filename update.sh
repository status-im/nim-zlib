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

git diff --exit-code -- . ':(exclude)update.sh' > /dev/null || { echo "Commit changes before updating!" ; exit 1 ; }

# https://github.com/madler/zlib/releases
VERSION="${1:-1.4}"

git -C zlib/csources fetch -q --tags origin
git -C zlib/csources checkout -q "v${VERSION}"

./regenerate.sh

! git diff --exit-code > /dev/null || { echo "This repository is already up to date" ; exit 0 ; }

git commit -a \
  -m "Bump csources to v${VERSION}" \
  -m "- https://github.com/madler/zlib/releases/tag/v${VERSION}"

echo "The repo has been updated with a commit recording the update."
echo "You can review the changes with 'git diff HEAD^' before pushing to a public repository."

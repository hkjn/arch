#!/bin/bash
#
# Creates arch image for ARMv7l based on latest release from
# http://archlinuxarm.org/os.
#
set -euo pipefail

SERVER=http://archlinuxarm.org/os
BINARY=ArchLinuxARM-utilite-latest.tar.gz
IMAGE=${IMAGE:-hkjn/armv7l-arch-base}
SIG=${BINARY}.sig
echo "Downloading $BINARY.."
curl -fsSL "$SERVER/$BINARY" -o $BINARY
echo "Downloading $SIG.."
curl -fsSL "$SERVER/$SIG" -o $SIG
# TODO(henrik): Verify (binary GPG?) .sig against static key fingerprint.
cat $BINARY | gunzip | docker import - $IMAGE
echo "Built $IMAGE successfully."

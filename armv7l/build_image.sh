#!/bin/bash
#
# Creates arch image for ARMv7l based on latest release from
# http://archlinuxarm.org/os.
#
#
set -euo pipefail

SERVER=https://archlinuxarm.org/os
BINARY=ArchLinuxARM-utilite-latest.tar.gz
IMAGE=${IMAGE:-hkjn/armv7l-arch-base}
SIG=${BINARY}.sig
KEY=2BDBE6A6
echo "Downloading $BINARY.."
curl -fsSL "$SERVER/$BINARY" -o $BINARY
echo "Downloading $SIG.."
curl -fsSL "$SERVER/$SIG" -o $SIG
gpg --keyserver pgp.mit.edu --recv $KEY
gpg --verify ArchLinuxARM-utilite-latest.tar.gz.sig
cat $BINARY | gunzip | docker import - $IMAGE
echo "Built $IMAGE successfully."

#!/bin/bash
#
# Builds a new archlinux.tar.gz filesystem within a Docker container.
#
set -euo pipefail

BASE=${BASE:-hkjn/armv7l-arch-base}
IMAGE=${IMAGE:-hkjn/arch-bootstrap}

# We need a base image with a functional Arch install for our CPU
# architecture to have an environment to build our image. See armv7l/
# directory for an example on how to build such a base image from a
# precompiled binary.
[[ $(docker images | grep $BASE | wc -l) -ne 0 ]] || {
	echo "No such BASE image: $BASE. Attempting to pull.." >&2
  docker pull $BASE
}

LOG_PREFIX="$(basename $0)"
LGRAY='\033[0;37m'
BCYAN='\033[1;36m'
NC='\033[0m'
log() {
	echo -e "${BCYAN}[$LOG_PREFIX]${NC} ${LGRAY}$@${NC}"
}

log "Building new archlinux.tar.xz from $BASE image.."
BUILD_DIR="$(mktemp -d)"
sed -e "s|{{BASE}}|${BASE}|g" bootstrap/Dockerfile.tmpl > $BUILD_DIR/Dockerfile
cp -r bootstrap/*.{conf,sh} $BUILD_DIR/
docker build -t $IMAGE $BUILD_DIR/
[ -e .bootstrap.cid ] && {
	log "Cleaning up old container.."
	docker rm $(cat .bootstrap.cid) 1>/dev/null || true
	rm .bootstrap.cid
}
log "Running bootstrap container.."
# TODO(hkjn): Add only specific capabilities needed, drop the rest.
docker run -it --name arch-bootstrap --privileged $IMAGE
[[ -e archlinux.tar.xz ]] && {
	# Keep the last built filesystem archive around so we can compare
	# changes to e.g. minimize size.
	log "Renaming existing archlinux.tar.xz as -last.."
	mv archlinux.tar.xz archlinux-last.tar.xz
}
log "Copying out archlinux.tar.xz from bootstrap container.."
docker cp arch-bootstrap:/archlinux.tar.xz .
# Clean up container and the bootstrap image.
docker rm $CID
log "All done."

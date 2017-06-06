#!/bin/bash
#
# Build the hkjn/arch Docker images.
#
NO_PUSH=${NO_PUSH:-""}
DOCKER_USER="hkjn"
DOCKER_IMAGE="arch"
ARCH="$(uname -m)"

[[ -e "archlinux.tar.xz" ]] || {
	echo "No archlinux.tar.xz. Run bootstrap.sh to create it." >&2
	exit 1
}

TAG="$DOCKER_USER/$DOCKER_IMAGE:$ARCH"
BUILD_DIR="$(mktemp -d)"
cp Dockerfile archlinux.tar.xz $BUILD_DIR/
echo "Building $IMAGE.."
docker build -t $IMAGE $BUILD_DIR/
[[ "$NO_PUSH" ]] || docker push $TAG

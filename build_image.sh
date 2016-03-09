#!/bin/bash
#
# Builds and pushes the docker image.
#
IMAGE=${IMAGE:-hkjn/$(uname -m)-arch}
NO_PUSH=${NO_PUSH:-""}
[ -e "archlinux.tar.xz" ] || {
	echo "No archlinux.tar.xz. Run bootstrap.sh to create it." >&2
	exit 1
}

# Copy over files we need to a new build context rather than having to
# send all of the pwd to the Docker daemon.
tmp="$(mktemp -d)"
cp Dockerfile $tmp/
cp archlinux.tar.xz $tmp/
echo "Building $IMAGE.."
docker build -t $IMAGE $tmp/ && [ "$NO_PUSH" ] || docker push $IMAGE

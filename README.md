# docker-archlinux

Minimal Arch Linux docker image with trustable, traceable &
inspectable origin.

Forked from https://github.com/l3iggs/docker-archlinux.

# Usage

If you have Docker installed and a functional Arch image for your CPU
architecture, you can build your own minimal image inside the base image:

## Clone this repo
```
git clone https://github.com/hkjn/docker-archlinux.git
```

## Build the Arch filesystem
Run `BASE=some-image ./bootstrap.sh` in the root of the repo to build
from `some-image` as a base. When the build finishes you'll have an
`archlinux.tar.xz` file, which is an archive of the root filesystem
that was built inside the bootstrap container.

## Build the image
Run the `./build_image.sh` script in the root of the repo. That's it!
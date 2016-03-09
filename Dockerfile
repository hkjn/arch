FROM scratch
MAINTAINER Henrik Jonsson <me@hkjn.me>
ADD archlinux.tar.xz /
ENTRYPOINT ["bash", "-c"]
#!/usr/bin/env bash
#
# Builds a minimal filesystem for Arch Linux.
#
# This script is meant to run inside an Arch container.
#
set -euo pipefail

LOG_PREFIX="$(basename $0)"
RED='\033[0;31m'
BRED='\033[1;31m'
HIRED='\033[0;101m'
LBLUE='\033[0;34m'
CYAN='\033[0;36m'
BCYAN='\033[1;36m'
LGRAY='\033[0;37m'
BIGRAY='\033[1;37m'
NC='\033[0m'
WHITE='\033[0;37m'
BIWHITE='\033[1;97m'
YELLOW='\033[4;33m'
UYELLOW='\033[4;33m'
BYELLOW='\033[1;33m'
log() {
	echo -e "${CYAN}[$LOG_PREFIX]${NC} ${WHITE}$@${NC}"
}
debug() {
	echo -e "${YELLOW}[$LOG_PREFIX]${NC} ${BIGRAY}$@${NC}"
}
warn() {
	echo -e "${UYELLOW}[$LOG_PREFIX]${NC} ${BYELLOW}$@${NC}" >&2
}
fatal() {
	echo -e "${HIRED}[$LOG_PREFIX] FATAL: $@${NC}" >&2
	exit 1
}

[ "$EUID" == 0 ] || {
	fatal "This script requires super-user powers; please run with sudo or as root."
}

[ -e /usr/lib/os-release ] || {
	fatal "Couldn't find OS name in /usr/lib/os-release."
}

source /usr/lib/os-release
[ "$ID" == "arch" ] || [ "$ID" == "archarm" ] || {
	warn "Untested host OS '$ID'."
	warn
	warn "This script is only known to work on 'arch' / 'archarm' (Arch Linux)."
}

log "Installing dependencies.."
# TODO(hkjn): Drop openresolv from here, should only be needed for the
# within-chroot install.
# TODO(hkjn): Add --needed to avoid reinstalling packages we may already have.
pacman --noconfirm -Syy base arch-install-scripts expect haveged openresolv

export LANG="en_US.UTF-8"

ROOTFS=$(mktemp -d ${TMPDIR:-/var/tmp}/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS

# packages to ignore for space savings

# TODO(hkjn): Fix cause of following (seemingly non-fatal) error message:
# error: failed to prepare transaction (could not satisfy dependencies)
# :: netctl: requires openresolv
# ==> ERROR: Failed to install packages to new root
# Dropped the following from PKGIGNORE:
#    openresolv

PKGIGNORE=(
    cryptsetup
    device-mapper
    dhcpcd
    iproute2
    jfsutils
    linux
    lvm2
    man-db
    man-pages
    mdadm
    netctl
    pciutils
    pcmciautils
    reiserfsprogs
    s-nail
    systemd-sysvcompat
    usbutils
    vi
    xfsprogs
)

IFS=','
PKGIGNORE="${PKGIGNORE[*]}"
unset IFS

log "Initializing pacman keyring.."

# We need haveged to be able to generate keys without running out of
# entropy, unfortunately.
# TODO: Look into mounting host's /dev/urandom or somesuch.
debug "Starting haveged for entropy generation.."
haveged
# TODO(hkjn): Just do this in the previous pacman run?
debug "Installing archlinux-keyring.."
pacman --noconfirm -S archlinux-keyring
debug "Initializing pacman's keyring.."
pacman-key --init
debug "Done initializing keyring, now populating archlinux"
pacman-key --populate archlinux
debug "Done populating archlinux keyring, now refreshing it"
# Workaround for https://bugs.archlinux.org/task/42798:
mkdir -p /root/.gnupg && touch /root/.gnupg/dirmngr_ldapservers.conf
pacman-key --refresh-keys

# TODO(hkjn): The following steps are only needed to avoid getting an
# interactive prompt about the key when pacstrap'ing later on.
debug "Manually importing Arch Linux ARM Build System <builder@archlinuxarm.org> GPG key"
BUILDER_KEY=68B3537F39A313B3E574D06777193F152BDBE6A6
pacman-key --recv-keys $BUILDER_KEY
pacman-key --lsign-key $BUILDER_KEY

debug "Done setting up keys"

log "Installing packages to new root.."
pacstrap -C /etc/pacman_chroot.conf -c -d $ROOTFS base haveged --ignore $PKGIGNORE

debug "Removing /usr/share/man/* inside chroot.."
arch-chroot $ROOTFS /bin/sh -c 'rm -r /usr/share/man/*'

debug "Setting timezone to UTC in chroot.."
arch-chroot $ROOTFS /bin/sh -c "ln -s /usr/share/zoneinfo/UTC /etc/localtime"

debug "Generating locales in chroot.."
echo 'en_US.UTF-8 UTF-8' > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen

# Since udev doesn't work in our container, we have to rebuild /dev.
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

log "Creating archlinux.tar.xz archive.."
# TODO(hkjn): Try ignoring the following socket file to avoid tar
# complaining about "socket ignored":
# --exclude ./etc/pacman.d/gnupg/S.gpg-agent
tar --totals --checkpoint=1000 --numeric-owner --xattrs --acls -C $ROOTFS -c . -af archlinux.tar.xz
debug "Cleaning up $ROOTFS.."
rm -rf $ROOTFS
debug "Moving archlinux.tar.xz to /.."
mv archlinux.tar.xz /
log "Created Arch install at /archlinux.tar.xz inside the container."

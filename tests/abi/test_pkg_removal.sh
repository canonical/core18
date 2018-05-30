#!/bin/bash
#
# Ideally we would test here against an ABI database and ensure nothing
# is removed/changed in a way to break the core. As a simpler approximation
# of this we just check here that no packages got changed since we last
# run this.
#

set -e

if [ "$(dpkg --print-architecture)" != "amd64" ]; then
    echo "only testing on amd64 for now"
    exit 0
fi

DIFF=$(comm -1 -3 \
         <(tail -n +6 prime/usr/share/snappy/dpkg.list|awk '{print $2}'|sort) \
         <(cat <<EOF
adduser
apparmor
apt
base-files
base-passwd
bash
bsdutils
bzip2
ca-certificates
coreutils
dash
dbus
debconf
debianutils
diffutils
distro-info-data
dpkg
e2fsprogs
fdisk
findutils
gcc-8-base:amd64
gpgv
grep
gzip
hostname
init-system-helpers
iproute2
kmod
libacl1:amd64
libapparmor1:amd64
libapt-pkg5.0:amd64
libargon2-0:amd64
libattr1:amd64
libaudit1:amd64
libaudit-common
libblkid1:amd64
libbsd0:amd64
libbz2-1.0:amd64
libc6:amd64
libcap2:amd64
libcap-ng0:amd64
libc-bin
libcom-err2:amd64
libcryptsetup12:amd64
libdb5.3:amd64
libdbus-1-3:amd64
libdebconfclient0:amd64
libdevmapper1.02.1:amd64
libedit2:amd64
libelf1:amd64
libexpat1:amd64
libext2fs2:amd64
libfdisk1:amd64
libffi6:amd64
libgcc1:amd64
libgcrypt20:amd64
libglib2.0-0:amd64
libgmp10:amd64
libgnutls30:amd64
libgpg-error0:amd64
libgssapi-krb5-2:amd64
libhogweed4:amd64
libidn11:amd64
libidn2-0:amd64
libip4tc0:amd64
libjson-c3:amd64
libk5crypto3:amd64
libkeyutils1:amd64
libkmod2:amd64
libkrb5-3:amd64
libkrb5support0:amd64
liblz4-1:amd64
liblzma5:amd64
liblzo2-2:amd64
libmnl0:amd64
libmount1:amd64
libmpdec2:amd64
libncurses5:amd64
libncursesw5:amd64
libnettle6:amd64
libnss-extrausers
libp11-kit0:amd64
libpam0g:amd64
libpam-modules:amd64
libpam-modules-bin
libpam-runtime
libpcre3:amd64
libprocps6:amd64
libpython3.6-minimal:amd64
libpython3.6-stdlib:amd64
libpython3-stdlib:amd64
libreadline7:amd64
libseccomp2:amd64
libselinux1:amd64
libsemanage1:amd64
libsemanage-common
libsepol1:amd64
libsmartcols1:amd64
libsqlite3-0:amd64
libss2:amd64
libssl1.0.0:amd64
libssl1.1:amd64
libstdc++6:amd64
libsystemd0:amd64
libtasn1-6:amd64
libtinfo5:amd64
libudev1:amd64
libunistring2:amd64
libuuid1:amd64
libwrap0:amd64
libyaml-0-2:amd64
libzstd1:amd64
login
lsb-base
mawk
mime-support
mount
multiarch-support
ncurses-base
ncurses-bin
netplan.io
openssh-client
openssh-server
openssh-sftp-server
openssl
passwd
perl-base
procps
python3
python3.6
python3.6-minimal
python3-minimal
python3-yaml
readline-common
sed
sensible-utils
squashfs-tools
sudo
systemd
sysvinit-utils
tar
tzdata
ubuntu-keyring
ucf
udev
util-linux
zlib1g:amd64
EOF
        ))

if [ -n "$DIFF" ]; then
    echo "Error! The following packages are missing from the system:"
    echo "$DIFF"
    echo "If that is intentional, please update the package list in the"
    echo "test_pkg_removal.sh test."
    exit 1
fi

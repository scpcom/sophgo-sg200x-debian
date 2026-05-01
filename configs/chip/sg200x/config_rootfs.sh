#!/bin/sh
#
set -ex

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LC_ALL=C LANGUAGE=C LANG=C

/var/lib/dpkg/info/base-passwd.preinst install || true
/var/lib/dpkg/info/sgml-base.preinst install || true

mkdir -p /etc/sgml
mount proc -t proc /proc
mount -B sys /sys
mount -B run /run
mount -B dev /dev
#mount devpts -t devpts /dev/pts
dpkg --configure -a

for p in libnetplan1 netplan-generator python3-netplan networkd-dispatcher systemd-resolved ; do
  if dpkg -s $p | grep -q '^Version: ' ; then
    apt-get remove -y --purge $p
  fi
done

apt-get update || true
apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes -y chrony

unset DEBIAN_FRONTEND DEBCONF_NONINTERACTIVE_SEEN


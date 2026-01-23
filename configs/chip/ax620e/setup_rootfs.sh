#!/bin/sh
#
set -ex

GITREF=$(cat /tmp/install/gitref)
BOARD=$(cat /tmp/install/board)
CHIP_VENDOR=$(cat /tmp/install/chip_vendor)
VARIANT=$(cat /tmp/install/variant)
HOSTNAME=$(cat /tmp/install/hostname)
STORAGETYPE=$(cat /tmp/install/storage)


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

unset DEBIAN_FRONTEND DEBCONF_NONINTERACTIVE_SEEN

#
# Change root password
#
password=rv
if echo "$VARIANT" | grep -q "kvm" ; then
  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
  password=sipeed
fi
usermod --password "$(echo $password | openssl passwd -1 -stdin)" root

#
# Add a new user debian and its passwd is `rv`
#
mkdir -p /home/debian
useradd --password dummy \
    -G cdrom,floppy,sudo,audio,dip,video,plugdev \
    --home-dir /home/debian --shell /bin/bash debian || true
chown debian:debian /home/debian
# Set debian password
password=rv
if echo "$VARIANT" | grep -q "kvm" ; then
  password=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 12)
fi
usermod --password "$(echo $password | openssl passwd -1 -stdin)" debian || true

# Set up fstab
cat > /etc/fstab <<EOF
# <file system> <mount point>   <type>  <options>                 <dump>  <pass>
/dev/root       /               auto    defaults                  1       1
EOF

if [ "$STORAGETYPE" = "sd" ]; then
  cat >> /etc/fstab <<EOF
/dev/mmcblk0p1  /boot           auto    defaults                  1       2
EOF
fi

if [ "$STORAGETYPE" = "emmc" ]; then
cat > /etc/fstab <<EOF
# <file system>	<mount pt>	<type>	<options>	<dump>	<pass>
/dev/root	/		ext4	rw,noatime,nodiratime,errors=remount-ro	0	1
proc		/proc		proc	defaults	0	0
devpts		/dev/pts	devpts	defaults,gid=5,mode=620,ptmxmode=0666	0	0
tmpfs		/dev/shm	tmpfs	mode=1777,nosuid,nodev	0	0
tmpfs		/tmp		tmpfs	mode=1777,nosuid,nodev	0	0
tmpfs		/run		tmpfs	mode=0755,nosuid,nodev	0	0
sysfs		/sys		sysfs	defaults	0	0
/dev/mmcblk0p16	/boot	vfat	defaults,umask=000,utf8=true	0	0
EOF
fi

rm -f /etc/network/interfaces.d/end0

if ! grep -q eth0 /etc/network/interfaces ; then
  echo '' >> /etc/network/interfaces
  echo 'allow-hotplug eth0' >> /etc/network/interfaces
  echo 'iface eth0 inet dhcp' >> /etc/network/interfaces
fi

if [ ! -e /etc/rc.local ]; then
  echo "#!/bin/bash" > /etc/rc.local
  chmod ugo+rx /etc/rc.local
fi


#regenerate SSH keys on first boot
cat > /etc/systemd/system/finalize-image.service <<EOF
[Unit]
Description=Finalize the Image
Before=ssh.service

[Service]
Type=oneshot
ExecStartPre=-/usr/sbin/parted -s -f /dev/mmcblk0 resizepart 2 100%
ExecStartPre=-/usr/sbin/resize2fs /dev/mmcblk0p2
ExecStartPre=-/bin/dd if=/dev/hwrng of=/dev/urandom count=1 bs=4096
ExecStartPre=-/bin/sh -c "/bin/rm -f -v /etc/ssh/ssh_host_*_key*"
ExecStart=/usr/bin/ssh-keygen -A -v
ExecStartPost=/bin/systemctl disable finalize-image

[Install]
WantedBy=multi-user.target
EOF

if [ "$STORAGETYPE" = "emmc" ]; then
sed -i -e 's|ExecStartPre=-/usr/sbin/parted -s -f /dev/mmcblk0 resizepart 2 100%|ExecStartPre=-/usr/sbin/parted -s -f /dev/mmcblk0 resizepart 17 100%|' /etc/systemd/system/finalize-image.service
sed -i s/mmcblk0p2/mmcblk0p17/g /etc/systemd/system/finalize-image.service
sed -i /parted/d /etc/systemd/system/finalize-image.service
fi
#if echo "$VARIANT" | grep -q "kvm" ; then
#sed -i 's|resizepart 2 100%|resizepart 2 25%|g' /etc/systemd/system/finalize-image.service
#fi

cat /etc/systemd/system/finalize-image.service

apt install --allow-downgrades -y -f /tmp/install/*.deb


# change device tree
echo "===== ln -s dtb files ====="
file_prefix="/usr/lib/linux-image-*"

file_path=$(ls -d $file_prefix || true)

if [ ! -z "$file_path" ]; then

if [ -e "$file_path" ]; then
  echo "File found: $file_path"
  lib_dir=$file_path
else
  echo "File not found: $file_path"
fi

kernel_image=${lib_dir##*/}

# set default dtb file, please verify your board version
mkdir -p /boot/fdt/${kernel_image}/${CHIP_VENDOR}

cp ${lib_dir}/${CHIP_VENDOR}/*.dtb /boot/fdt/${kernel_image}/${CHIP_VENDOR}/


cat /boot/extlinux/extlinux.conf

#doing this dance, as in the chroot, / and /boot are same filesystem, so u-boot-update doesn't setup correctly
if grep -q '^U_BOOT_FDT_DIR' /etc/default/u-boot ; then
  sed -i -e "s|U_BOOT_FDT_DIR=\".*\"|U_BOOT_FDT_DIR=\"/usr/lib/linux-image-\"|" /etc/default/u-boot
else
  echo "U_BOOT_FDT_DIR=\"/usr/lib/linux-image-\"" >> /etc/default/u-boot
fi
u-boot-update
if [ "$STORAGETYPE" = "sd" ]; then
  sed -i -e 's|fdtdir /usr/lib/|fdtdir /fdt/|' /boot/extlinux/extlinux.conf
  sed -i -e 's|linux /boot/|linux /|' /boot/extlinux/extlinux.conf
  sed -i -e "s|U_BOOT_FDT_DIR=\".*\"|U_BOOT_FDT_DIR=\"/fdt/linux-image-\"|" /etc/default/u-boot
else 
  sed -i -e 's|fdtdir /usr/lib/|fdtdir /boot/fdt/|' /boot/extlinux/extlinux.conf
fi

cat /boot/extlinux/extlinux.conf

fi

echo ${BOARD}-${VARIANT}_${STORAGETYPE}-${GITREF}.img > /boot/ver

# Set hostname
cat /tmp/install/hostname > /etc/hostname

# 
cat >> /etc/hosts << EOF
127.0.0.1      ${HOSTNAME} 
EOF

[ ! -e /usr/bin/run-parts ] || sed -i 's|(run-parts |(/usr/bin/run-parts |g' /etc/profile

# 
# Enable system services
#
systemctl enable finalize-image.service

# Update source list 

rm -rf /etc/apt/sources.list.d/multistrap-debian.list

#apt-key add /tmp/install/public-key.asc
gpg --dearmor /tmp/install/public-key.asc
cp /tmp/install/public-key.asc.gpg /etc/apt/trusted.gpg.d/scpcom-packages.gpg

cat > /etc/apt/sources.list < /tmp/install/deb_sources

mkdir -p /etc/apt/sources.list.d

cat > /etc/apt/sources.list.d/scpcom-packages.list <<EOG
deb https://scpcom.github.io/deb stable sg200x ${BOARD}-${VARIANT}
EOG

cat >> /etc/systemd/journald.conf <<EOJ
RuntimeMaxUse=16M
RuntimeMaxFileSize=2M
EOJ

apt-get update
export DEBIAN_FRONTEND=noninteractive ; apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes -y chrony


#
# Clean apt cache on the system
#
apt-get clean


rm -rf /var/cache/*
find /var/lib/apt/lists -type f -not -name '*.gpg' -print0 | xargs -0 rm -f
find /var/log -type f -print0 | xargs -0 truncate --size=0

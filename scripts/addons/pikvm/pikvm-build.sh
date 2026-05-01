#!/bin/bash -e
usepip=true
[ -e /usr/local/bin/python3 ] || usepip=false

pkgmntr="Sipeed <support@sipeed.com>"

apt-get update || true

if [ $usepip = false ] ; then
  apt-get install -y python3-setuptools python3-pip python3-build python3-wheel
else
  pip install build
fi

apt-get install -y autogen autoconf libtool build-essential \
 libevent-dev libjpeg-dev libbsd-dev \
 libgpiod-dev libsystemd-dev \
 libasound2-dev libspeex-dev libspeexdsp-dev libopus-dev \
 libglib2.0-dev libjansson-dev \
 libconfig-dev libwebsockets-dev libnice-dev libsrtp2-dev libssl-dev

apt-get install -y git


if [ ! -e janus-gateway-stamp ]; then
  cd janus-gateway

bash -e ../janus-gateway-build.sh

. ../pikvm-packages/packages/janus-gateway-pikvm/PKGBUILD

JANUS_GATEWAY_VERSION=$(cat package.json | grep '"version": ".*"' | cut -d ':' -f 2- | cut -d '"' -f 2)
pkgver=${JANUS_GATEWAY_VERSION}

mkdir out/DEBIAN

cat <<EOF > out/DEBIAN/control 
Package: $pkgname
Version: $pkgver-$pkgrel
Architecture: ${DEB_ARCH}
Maintainer: $pkgmntr
Description: $pkgdesc
EOF

dpkg-deb -b out ../${pkgname}_${pkgver}-${pkgrel}_${DEB_ARCH}.deb
[ -e /usr/include/janus/plugins/plugin.h ] || dpkg -i ../${pkgname}_${pkgver}-${pkgrel}_${DEB_ARCH}.deb

  cd ..
  touch janus-gateway-stamp
fi


if [ ! -e ustreamer-stamp ]; then
  apt-get install -y libdrm-dev \
    libasound2-dev libopus-dev libspeexdsp-dev libjpeg-dev \
    libevent-dev libbsd-dev libgpiod-dev libsystemd-dev

  cd ustreamer

bash -e ../ustreamer-build.sh

for d in out/usr/local/lib/python3.1? ; do
  b=$(basename $d)
  #mv out/usr/local/lib/${b}/dist-packages out/usr/local/lib/${b}/site-packages
done

mkdir -p out/usr/local/
mv out/usr/share out/usr/local/
rsync -avpPxH out/usr/bin/ out/usr/local/bin/
rsync -avpPxH out/usr/lib/ out/usr/local/lib/

. ../pikvm-packages/packages/ustreamer/PKGBUILD

USTREAMER_VERSION=$(cat .bumpversion.cfg | grep '^current_version = ' | cut -d '=' -f 2- | tr -d ' ')
pkgver=${USTREAMER_VERSION}

mkdir out/DEBIAN

cat <<EOF > out/DEBIAN/control 
Package: $pkgname
Version: $pkgver-$pkgrel
Architecture: ${DEB_ARCH}
Maintainer: $pkgmntr
Description: $pkgdesc
EOF

dpkg-deb -b out ../${pkgname}_${pkgver}-${pkgrel}_${DEB_ARCH}.deb
[ -e /usr/bin/ustreamer ] || dpkg -i ../${pkgname}_${pkgver}-${pkgrel}_${DEB_ARCH}.deb

  cd ..
  touch ustreamer-stamp
fi


if [ ! -e kvmd-stamp ]; then
  apt-get install -y \
	libxkbcommon-dev \
	libgpiod-dev \
	libfreetype-dev \
	libldap-dev \
	libsasl2-dev \
	v4l-utils \
	nginx \
	openssl \
	sudo \
	iptables \
	iproute2 \
	dnsmasq \
	ipmitool \
	certbot \
 \
	systemd \
 \
	zstd \
 \
	openssl \
 \
	dos2unix \
	parted \
	e2fsprogs \
	openssh-server \
 \
	dosfstools \
 \
	procps \
 \
	hostapd

  if [ $usepip = false ] ; then
    apt-get install -y \
	python3-yaml \
	python3-ruamel.yaml \
	python3-aiohttp \
	python3-aiofiles \
	python3-passlib \
	python3-pyotp \
	python3-qrcode \
	python3-serial \
	python3-spidev \
	python3-setproctitle \
	python3-psutil \
	python3-netifaces \
	python3-systemd \
	python3-dbus \
	python3-pygments \
	python3-pyghmi \
	python3-pam \
	python3-pil \
	python3-xlib \
	python3-hidapi \
	python3-six \
	python3-pyrad \
	python3-ldap \
	python3-mako \
	python3-luma.core \
	python3-luma.oled \
	python3-usb \
	python3-pyudev \
	python3-evdev
  else
    cat <<\EOF > kvmd_requirements.txt
aiohttp
psutil
aiofiles
hidapi
mako
netifaces
passlib
pillow
pyghmi
pygments
setproctitle
six
spidev
systemd-python
xlib
pyyaml
pyotp
qrcode
dbus-python
evdev
pyusb
ruamel.yaml
pyserial
pyserial-asyncio
python-pam
pyrad
python-ldap
pyudev
luma.core
luma.oled
EOF

    pip install -r kvmd_requirements.txt
  fi

  partialpip=false
  if [ $usepip = false ] ; then
    apt-get install -y \
	python3-async-lru \
	python3-dbus-next \
	python3-zstandard || partialpip=true
  else
    partialpip=true
  fi

  if [ $partialpip = true ]; then
    pip install async_lru
    pip install dbus-next
    pip install zstandard
  fi


  cd kvmd

bash -e ../kvmd-build.sh

for d in out/usr/local/lib/python3.1? ; do
  b=$(basename $d)
  #mv out/usr/local/lib/${b}/dist-packages out/usr/local/lib/${b}/site-packages
done

mv out/usr/local/bin/kvmd* out/usr/bin/
rsync -avpPxH out/usr/local/lib/ out/usr/lib/

. ../pikvm-packages/packages/kvmd/PKGBUILD

pkgname=kvmd
KVMD_VERSION=$(cat .bumpversion.cfg | grep '^current_version = ' | cut -d '=' -f 2- | tr -d ' ')
pkgver=${KVMD_VERSION}

mkdir out/DEBIAN

cat <<EOF > out/DEBIAN/control 
Package: $pkgname
Version: $pkgver-$pkgrel
Architecture: ${DEB_ARCH}
Maintainer: $pkgmntr
Description: $pkgdesc
EOF

cat <<EOF > out/DEBIAN/conffiles
/etc/kvmd/ipmipasswd
/etc/kvmd/meta.yaml
/etc/kvmd/totp.secret
/etc/kvmd/web.css
/etc/kvmd/htpasswd
/etc/kvmd/vncpasswd
/etc/kvmd/override.yaml
EOF

dpkg-deb -b out ../${pkgname}_${pkgver}-${pkgrel}_${DEB_ARCH}.deb
[ -e /usr/bin/kvmd-bootconfig ] || dpkg -i ../${pkgname}_${pkgver}-${pkgrel}_${DEB_ARCH}.deb

  cd ..
  touch kvmd-stamp
fi


if [ ! -e kvmd-webterm-stamp ]; then
  cd pikvm-packages/
  cd packages/kvmd-webterm/

bash -e ../../../kvmd-webterm-build.sh

. ./PKGBUILD

KVMD_WEBTERM_VERSION=$(grep '^pkgver=' PKGBUILD | cut -d '=' -f 2)
pkgver=${KVMD_WEBTERM_VERSION}

mkdir out/DEBIAN

cat <<EOF > out/DEBIAN/control 
Package: $pkgname
Version: $pkgver-$pkgrel
Architecture: ${DEB_ARCH}
Maintainer: $pkgmntr
Description: $pkgdesc
EOF

dpkg-deb -b out ../${pkgname}_${pkgver}-${pkgrel}_${DEB_ARCH}.deb
[ -e /usr/share/kvmd/extras/webterm/manifest.yaml ] || dpkg -i ../${pkgname}_${pkgver}-${pkgrel}_${DEB_ARCH}.deb

  cd ../..
  cd ..
  touch kvmd-webterm-stamp
fi


dpkg -r kvmd-webterm || true
dpkg -r kvmd || true
dpkg -r ustreamer || true
dpkg -r janus-gateway-pikvm || true

mkdir out
rsync -avpPxH janus-gateway/out/ out/
rsync -avpPxH ustreamer/out/ out/
rsync -avpPxH kvmd/out/ out/
rsync -avpPxH pikvm-packages/packages/kvmd-webterm/out/ out/
rm -rf out/DEBIAN/

echo OK

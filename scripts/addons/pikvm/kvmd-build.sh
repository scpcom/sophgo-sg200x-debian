#!/bin/bash -e
srcdir=$(pwd)
pkgdir=$srcdir/out

. $srcdir/../pikvm-packages/packages/kvmd/PKGBUILD

[ -e "kvmd-$pkgver" ] || ln -s . "kvmd-$pkgver"

package_kvmd
package_kvmd-platform-v2-hdmiusb-rpi4

echo OK

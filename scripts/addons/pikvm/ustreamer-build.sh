#!/bin/bash -e
srcdir=$(pwd)
pkgdir=$srcdir/out

. $srcdir/../pikvm-packages/packages/ustreamer/PKGBUILD

[ -e $pkgname ] || ln -s . $pkgname

build
package

echo OK

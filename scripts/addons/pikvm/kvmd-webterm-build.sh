#!/bin/bash -e
srcdir=$(pwd)
pkgdir=$srcdir/out

. $srcdir/PKGBUILD

package

echo OK

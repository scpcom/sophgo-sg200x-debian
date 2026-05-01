#!/bin/bash -e
srcdir=$(pwd)
pkgdir=$srcdir/out

. $srcdir/../pikvm-packages/packages/janus-gateway-pikvm/PKGBUILD

[ -e "janus-gateway-$_commit" ] || ln -s . "janus-gateway-$_commit"

[ -e ../0001-js.patch ] || cp $srcdir/../pikvm-packages/packages/janus-gateway-pikvm/0001-js.patch ../0001-js.patch
[ -e ../adapter-latest.js ] || cp $srcdir/html/demos/adapter.js ../adapter-latest.js

build
package

echo OK

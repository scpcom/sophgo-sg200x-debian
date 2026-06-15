#!/bin/sh -e
cleanuphosttools=false
cleanupramdisk=false

[ -e host-tools ] || cleanuphosttools=true
[ -e ramdisk ] || cleanupramdisk=true

scriptdir=$(dirname $0) ; pushd $scriptdir >/dev/null ; scriptdir=$(pwd) ; popd >/dev/null

#for f in ./scripts/replace-all-*toolchains.sh ; do
#  $f
#done

tcver=6.3 ./scripts/replace-all-linaro-toolchains.sh
tcver=7.5 ./scripts/replace-all-linaro-toolchains.sh
tcver=9.2 ./scripts/replace-all-arm-a-toolchains.sh
tcver=10.3 ./scripts/replace-all-arm-a-toolchains.sh
tcver=11.3.rel1 ./scripts/replace-all-arm-toolchains.sh
tcver=12.2.rel1 ./scripts/replace-all-arm-toolchains.sh
tcver=2.6.1 ./scripts/replace-all-thead-toolchains.sh
tcver=2.10.2 ./scripts/replace-all-thead-toolchains.sh

[ $cleanuphosttools = false ] || rm -rf host-tools
[ $cleanupramdisk = false ] || rm -rf ramdisk

d=git-archive
[ ! -e ../$d ] || d=../$d
[ -e $d ] || mkdir $d
t=$d/toolchain/

for f in scripts/*.tar.* ; do
  e=`dirname $f`
  b=`basename $f`
  v=none
  d=none
  if echo $b | grep -q -E '^riscv64-' ; then
    d=
    v=
  elif echo $b | grep -q -E '^arm-gnu-toolchain-' ; then
    v=$(echo $b | cut -d '-' -f 4)
    d=arm/gnu/${v}/binrel/
  elif echo $b | grep -q -E '^gcc-arm-' ; then
    v=$(echo $b | cut -d '-' -f 3-4)
    d=arm/gnu-a/${v}/binrel/
  elif echo $b | grep -q -E '^gcc-linaro-' ; then
    v=$(echo $b | cut -d '-' -f 3 | cut -d '.' -f 1-2)-$(echo $b | cut -d '-' -f 4)
    a=$(echo $b | rev | cut -d '_' -f 1 | rev | sed s/'\.tar\..*'/''/g)
    d=linaro/${v}/${a}/
  elif echo $b | grep -q -E '^sysroot-glibc-linaro-' ; then
    v=$(echo $b | cut -d '-' -f 5)
    a=$(echo $b | cut -d '-' -f 6- | sed s/'\.tar\..*'/''/g)
    for g in $e/gcc-linaro-*-${v}-*_${a}.tar.* ; do
      [ -e $f ] || continue
      c=`basename $g`
      v=$(echo $c | cut -d '-' -f 3 | cut -d '.' -f 1-2)-$(echo $c | cut -d '-' -f 4)
    done
    d=linaro/${v}/${a}/
  fi
  echo "$d ($b)"
  mkdir -p ${t}${d}
  cp -p $f ${t}${d}
done

get_gnu()
{
  u=$1
  s=$(dirname $(echo $u | cut -d / -f 4-))
  rel_file=$(basename $u)
  rel_set=gnu-$(basename $u | sed s/'\.tar\..z$'/''/g)
  #rel_set=$(echo $s | tr / -)
  rel_sha256=${scriptdir}/${rel_set}.sha256
  ! echo $u | grep -q github.com || s=$(dirname $(echo $u | cut -d / -f 5)/$(echo $u | cut -d / -f 7-))
  ! echo $u | grep -q cdn.kernel.org || s=$(dirname $(echo $u | cut -d / -f 5)/$(echo $u | cut -d / -f 7-))
  mkdir -p ${t}gnu/$s
  pushd ${t}gnu/$s >/dev/null
  wget -q -N $u || sha256sum -c $rel_sha256
  [ -e $rel_sha256 -o ! -e ${rel_file} ] || echo "WARNING: $rel_sha256 not found, generating it."
  [ -e $rel_sha256 -o ! -e ${rel_file} ] || sha256sum ${rel_file} > $rel_sha256
  sha256sum -c $rel_sha256
  popd >/dev/null
}

get_gnu https://ftpmirror.gnu.org/binutils/binutils-2.43.1.tar.xz
get_gnu https://ftpmirror.gnu.org/bison/bison-3.8.2.tar.xz
get_gnu https://ftpmirror.gnu.org/gawk/gawk-5.3.1.tar.xz
get_gnu https://ftpmirror.gnu.org/gcc/gcc-13.4.0/gcc-13.4.0.tar.xz
get_gnu https://ftpmirror.gnu.org/gmp/gmp-6.3.0.tar.xz
get_gnu https://ftpmirror.gnu.org/mpc/mpc-1.3.1.tar.gz

get_gnu http://www.mpfr.org/mpfr-4.1.1/mpfr-4.1.1.tar.xz

get_gnu https://github.com/bminor/glibc/archive/2.41-70-g1502c248d58cb99a203731707987a4342926e830/glibc-2.41-70-g1502c248d58cb99a203731707987a4342926e830.tar.gz

get_gnu https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.44.tar.xz

echo OK

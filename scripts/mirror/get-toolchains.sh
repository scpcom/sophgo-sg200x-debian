#!/bin/sh -e
cleanuphosttools=false
cleanupramdisk=false

[ -e host-tools ] || cleanuphosttools=true
[ -e ramdisk ] || cleanupramdisk=true

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

echo OK

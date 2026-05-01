#!/bin/bash -e
d=`dirname $0`
cd $d ; d=`pwd` ; cd - > /dev/null

tcurl=$1
[ "X${tcurl}" = "X" ] && tcurl=https://developer.arm.com/-/media/Files/downloads/gnu

[ "X${tcver}" != "X" ] || tcver=12.2.rel1
[ "X${tcdat}" != "X" -o "X${tcver}" != "X12.2.rel1" ] || tcdat=2022.12

harch=`uname -m`

gcver=${tcver}
lcver=2.35
gctgts="arm-none-linux-gnueabihf
aarch64-none-linux-gnu
aarch64-none-elf"

tcset=arm-gnu-toolchain-${gcver}-${harch}

cd $d
for gctgt in $gctgts ; do
  gctar=arm-gnu-toolchain-${gcver}-${harch}-${gctgt}.tar.xz
  srtar=none
  if [ ! -e ${gctar} ]; then
    wget -N ${tcurl}/${tcver}/binrel/${gctar}
  fi
  #rttar=runtime-arm-gnu-toolchain-${gcver}-${gctgt}.tar.xz
  if echo ${gctgt} | grep -q linux ; then
    srtar=sysroot-glibc-arm-${lcver}-${tcdat}-${gctgt}.tar.xz
    if [ ! -e ${srtar} ]; then
      wget -N ${tcurl}/${tcver}/binrel/${srtar} || true
    fi
  fi
  if [ -e ${tcset}.sha256 ]; then
    gcsum=`sha256sum ${gctar} | cut -d ' ' -f 1`
    if [ "X${gcsum}" = "X" ] ; then
      echo "failed to get sha256 for ${gctar}"
    elif grep -q '^'${gcsum}' .*'${gctar}'$' ${tcset}.sha256 ; then
      echo "${gcsum} ${gctar} OK"
    else
      echo "${gcsum} ${gctar} WRONG CHECKSUM"
      exit 1
    fi
  else
    echo "no sha256 file for ${gctar}"
  fi
  if [ -e ${tcset}.sha256 -a "${srtar}" != "none" ]; then
    srsum=`sha256sum ${srtar} | cut -d ' ' -f 1`
    if [ "X${srsum}" = "X" ] ; then
      echo "failed to get sha256 for ${srtar}"
    elif grep -q '^'${srsum}' .*'${srtar}'$' ${tcset}.sha256 ; then
      echo "${srsum} ${srtar} OK"
    else
      echo "${srsum} ${srtar} WRONG CHECKSUM"
      exit 1
    fi
  elif [ "${srtar}" != "none" ]; then
    echo "no sha256 file for ${srtar}"
  fi
done
cd ..

mkdir -p host-tools

cd host-tools/
rm -rf gcc/gcc-arm-*/
mkdir -p gcc
cd gcc
for gctgt in $gctgts ; do
  gctar=arm-gnu-toolchain-${gcver}-${harch}-${gctgt}.tar.xz
  tar xJf ${d}/${gctar}
done
cd ../..

mkdir -p ramdisk

cd ramdisk/
rm -rf sysroot/sysroot*-arm-*
mkdir -p sysroot
cd sysroot
for gctgt in $gctgts ; do
  if echo ${gctgt} | grep -q linux ; then
    srtar=sysroot-glibc-arm-${lcver}-${tcdat}-${gctgt}.tar.xz
    if [ -e ${srtar} ]; then
      tar xJf ${d}/${srtar}
    fi
  fi
done
cd ../..

echo OK

#!/bin/sh -e
[ "X$GIT_SOURCE_HOST" != "X" ] || GIT_SOURCE_HOST=github.com
[ "X$GIT_SOURCE_USER" != "X" ] || GIT_SOURCE_USER=scpcom
[ "X$GIT_TARGET_USER" != "X" ] || GIT_TARGET_USER=$GIT_SOURCE_USER

if [ "X$GIT_TARGET_HOST" = "X" ]; then
  if [ "$GIT_TARGET_USER" = "$GIT_SOURCE_USER" ]; then
    echo "Please set GIT_TARGET_HOST and/or GIT_TARGET_USER."
    exit 1
  else
    GIT_TARGET_HOST=$GIT_SOURCE_HOST
  fi
fi

checkoutbranches=true
pushtags=true
while [ "$#" -gt 0 ]; do
	case "$1" in
	--no-checkout)
		checkoutbranches=false
		shift
		;;
	--no-tags)
		pushtags=false
		shift
		;;
	*)
		break
		;;
	esac
done

do_pull_push() {
  x=$1
  u=$2
  s=$3
  git checkout $x
  git remote set-url origin $u
  git pull --ff-only --tags origin
  git remote set-url origin $s
  git push -u origin $x || git push --ff-only origin
}

do_push_tags() {
  git tag -l $1 | while read t ; do git push origin $t ; done
}

d=git-archive
[ ! -e ../$d ] || d=../$d
[ -e $d ] || mkdir $d

echo $d
cd $d

for f in */.git ; do
  d=$(dirname $f)
  #echo $d
  cd $d
  u=$(git remote get-url origin | sed s/'\.git$'/''/g).git
  s=$u
  s=$(echo $s | sed 's|https://'$GIT_SOURCE_HOST'/|git@'$GIT_SOURCE_HOST':|g')
  s=$(echo $s | sed 's|git@'$GIT_SOURCE_HOST'|git@'$GIT_TARGET_HOST'|g')
  s=$(echo $s | sed 's|:'$GIT_SOURCE_USER'/|:'$GIT_TARGET_USER'/|g')
  u=$s
  u=$(echo $u | sed 's|:'$GIT_TARGET_USER'/|:'$GIT_SOURCE_USER'/|g')
  u=$(echo $u | sed 's|git@'$GIT_TARGET_HOST'|git@'$GIT_SOURCE_HOST'|g')
  u=$(echo $u | sed 's|git@'$GIT_SOURCE_HOST':|https://'$GIT_SOURCE_HOST'/|g')
  b=$(git branch | grep -E '^\*' | grep -m1 -v detached | tr -d ' *')
  [ "$b" != "X" ] || b=$(git branch | grep -m1 -v detached | tr -d ' *')
  echo "$d: $s $b"
  if [ $checkoutbranches = false ]; then
     do_pull_push $b $u $s
  elif echo $d | grep -q -E '^LicheeRV-Nano-Build' ; then
    for x in develop main middleware-maix_mmf nanokvm ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^LicheeSG-Nano-Build' ; then
    for x in develop main ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^build$' ; then
    for x in licheervnano-cvisdk licheervnano ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^buildroot$' ; then
    for x in nanokvm-2025.02 licheervnano-2025.02 licheervnano-2023.11 ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^buildroot-dl$|^dl$' ; then
    for x in main maixcdk licheesgnano ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^cvi_rtsp$' ; then
    for x in licheervnano-cvisdk cv18xx-v4.2.x master ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^fsbl$' ; then
    for x in licheervnano-cvisdk licheervnano ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^u-boot$' ; then
    for x in licheervnano-cvisdk-2021.10 nanokvmpro-2020.04 licheervnano-2021.10 ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^kernel$|^linux' ; then
    for x in licheervnano-merged-5.10.y nanokvmpro-4.19.y licheervnano-cvisdk-5.10.y licheervnano-5.10.y ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^maixcdk-dl-pkgs$' ; then
    for x in main full ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^middleware$' ; then
    for x in maix_mmf-cvisdk licheervnano ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^opencv$' ; then
    for x in 3rd 3rd-4.5 4.x ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^ade$' ; then
    for x in 3rd-4.5 master ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^opensbi$' ; then
    for x in licheervnano-cvisdk-1.2 licheervnano-0.9 ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^openssl$' ; then
    for x in 3rd OpenSSL_1_1_1-stable openssl-3.0 ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^osdrv$' ; then
    for x in licheervnano-cvisdk licheervnano ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^ramdisk$' ; then
    for x in licheesgnano licheervnano ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^tdl_sdk$' ; then
    for x in licheervnano-cvisdk licheervnano-v1.x licheervnano-v2.x licheervnano-master v0 v1 v2 master ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^json-c$' ; then
    for x in 3rd cvi ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^miniz$' ; then
    for x in 3rd cvi ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^pyca-cryptography$' ; then
    for x in 2.4.x 38.0.x main ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^ustreamer$' ; then
    for x in nanokvmpro kvm_vision ax_video ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^berkeley-testfloat-3$' ; then
    for x in master qemu ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^riscv-gcc$' ; then
    for x in xuantie-gcc-10.2.0 xuantie-gcc-10.4.0 ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^riscv-gnu-toolchain$' ; then
    for x in  xuantie-gnu-toolchain-v2.6.x  xuantie-gnu-toolchain-v2.8.x xuantie-gnu-toolchain-v2.10.x ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^sophgo-sg200x-debian$' ; then
    for x in debian ubuntu ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  else
    do_pull_push $b $u $s
  fi

  if [ $pushtags = false ] ; then
    true
  elif echo $d | grep -q -E '^sophgo-sg200x-debian$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^buildroot$' ; then
    do_push_tags '20*'
  elif echo $d | grep -q -E '^json$' ; then
    do_push_tags 'v3.1?.*'
  elif echo $d | grep -q -E '^json-c$' ; then
    do_push_tags 'json-c-*'
  elif echo $d | grep -q -E '^miniz$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^ade' ; then
    do_push_tags 'v0\.*'
  elif echo $d | grep -q -E '^cvi_pinmux|^duo-pinmux$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^capstone$' ; then
    do_push_tags '5.0*'
  elif echo $d | grep -q -E '^curl' ; then
    do_push_tags 'curl-8_2*'
  elif echo $d | grep -q -E '^dtc$' ; then
    do_push_tags 'v[0-9]\.*'
  elif echo $d | grep -q -E '^edk2$' ; then
    do_push_tags 'edk2-stable2020*'
 elif echo $d | grep -q -E '^ffmpeg$' ; then
    do_push_tags 'n4.4*'
  elif echo $d | grep -q -E '^flatbuffers|^glog$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^harfbuzz$' ; then
    do_push_tags '8.*'
  elif echo $d | grep -q -E '^kernel$|^linux' ; then
    do_push_tags 'v4.19*'
    do_push_tags 'v5.10*'
  elif echo $d | grep -q -E '^krb5$' ; then
    do_push_tags 'krb5-1.17*'
  elif echo $d | grep -q -E '^eigen|^libeigen$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^ipmitool$' ; then
    do_push_tags 'IPMITOOL_1*'
  elif echo $d | grep -q -E '^janus-gateway$' ; then
    do_push_tags 'v1.*'
  elif echo $d | grep -q -E '^kaldi-native-fbank$' ; then
    do_push_tags 'v1.20*'
    do_push_tags 'v1.21*'
  elif echo $d | grep -q -E '^kissfft$' ; then
    do_push_tags '131*'
  elif echo $d | grep -q -E '^kvmd$' ; then
    do_push_tags 'v4.1??'
    do_push_tags 'nanokvm_pro_1.*'
  elif echo $d | grep -q -E '^libdatachannel$' ; then
    do_push_tags 'v0.2?.*'
  elif echo $d | grep -q -E '^libjuice$' ; then
    do_push_tags 'v1.7.*'
  elif echo $d | grep -q -E '^libsrtp$' ; then
    do_push_tags 'v2.7.*'
  elif echo $d | grep -q -E '^libslirp$' ; then
    do_push_tags 'v4.*'
  elif echo $d | grep -q -E '^libwebsockets$' ; then
    do_push_tags 'v4\.*'
  elif echo $d | grep -q -E '^LicheeSG-Nano-Build$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^marisa-trie$' ; then
    do_push_tags 'v0.*'
  elif echo $d | grep -q -E '^maixcam-skeleton$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^meson$' ; then
    do_push_tags '0.55*'
  elif echo $d | grep -q -E '^NanoKVM' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^nanokvm-skeleton$' ; then
    do_push_tags 'v2.*'
  elif echo $d | grep -q -E '^nanomsg$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^opencc$' ; then
    do_push_tags 'ver.1.1.*'
  elif echo $d | grep -q -E '^opencv$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^opensbi$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^openssl$' ; then
    do_push_tags 'OpenSSL_1_1_*'
    do_push_tags 'openssl-3.0\.*'
  elif echo $d | grep -q -E '^overlayfs-tools$' ; then
    do_push_tags 'v20*'
  elif echo $d | grep -q -E '^plog$' ; then
    do_push_tags '1\.1\.*'
  elif echo $d | grep -q -E '^pyca-cryptography' ; then
    do_push_tags '2.3*'
    do_push_tags '2.4*'
    do_push_tags '38.0.*'
  elif echo $d | grep -q -E '^quirc$' ; then
    do_push_tags 'v1.*'
  elif echo $d | grep -q -E '^rapidjson$' ; then
    do_push_tags 'v1.*'
  elif echo $d | grep -q -E '^riscv-gnu-toolchain$' ; then
    do_push_tags 'riscv*-10.?.*'
  elif echo $d | grep -q -E '^rtc-tools' ; then
    do_push_tags '2022*'
  elif echo $d | grep -q -E '^sqlite$' ; then
    do_push_tags 'version-3\.*'
  elif echo $d | grep -q -E '^tdl_sdk' ; then
    do_push_tags 'v1\.*'
    do_push_tags 'v2\.*'
  elif echo $d | grep -q -E '^tinyalsa' ; then
    do_push_tags 'v1\.*'
    do_push_tags '1\.1\.*'
    do_push_tags 'v2\.*'
  elif echo $d | grep -q -E '^u-boot$' ; then
    do_push_tags 'v20*'
  elif echo $d | grep -q -E '^uchardet$' ; then
    do_push_tags 'v0.0.*'
  elif echo $d | grep -q -E '^usrsctp' ; then
    do_push_tags 'v0\.9\.*'
  elif echo $d | grep -q -E '^ustreamer$' ; then
    do_push_tags 'v6.*'
  elif echo $d | grep -q -E '^uv$' ; then
    do_push_tags 'v1.4?.*'
  elif echo $d | grep -q -E '^zlib$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^zram-config$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^zxing-cpp$' ; then
    do_push_tags 'v2\.?\.*'
  fi

  cd - > /dev/null
done

echo OK

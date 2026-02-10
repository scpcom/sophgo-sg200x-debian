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
  elif echo $d | grep -q -E '^u-boot$' ; then
    for x in licheervnano-cvisdk-2021.10 nanokvmpro-2020.04 ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^kernel$|^linux' ; then
    for x in licheervnano-merged-5.10.y nanokvmpro-4.19.y ; do
      do_pull_push $x $u $s
    done
    git checkout $b
  elif echo $d | grep -q -E '^opencv$' ; then
    for x in 3rd 4.x ; do
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
  elif echo $d | grep -q -E '^cvi_pinmux|^duo-pinmux$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^flatbuffers|^glog$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^kernel$|^linux' ; then
    do_push_tags 'v4.19*'
    do_push_tags 'v5.10*'
  elif echo $d | grep -q -E '^krb5$' ; then
    do_push_tags 'krb5-1.17*'
  elif echo $d | grep -q -E '^eigen|^libeigen$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^libwebsockets$' ; then
    do_push_tags 'v4\.*'
  elif echo $d | grep -q -E '^LicheeSG-Nano-Build$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^maixcam-skeleton$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^NanoKVM' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^nanokvm-skeleton$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^nanomsg$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^opencv$' ; then
    do_push_tags '[0-9]\.*'
  elif echo $d | grep -q -E '^opensbi$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^openssl$' ; then
    do_push_tags 'OpenSSL_1_1_*'
  elif echo $d | grep -q -E '^overlayfs-tools$' ; then
    do_push_tags 'v20*'
  elif echo $d | grep -q -E '^sqlite$' ; then
    do_push_tags 'version-3\.*'
  elif echo $d | grep -q -E '^u-boot$' ; then
    do_push_tags 'v20*'
  elif echo $d | grep -q -E '^uv$' ; then
    do_push_tags 'v1.4?.*'
  elif echo $d | grep -q -E '^zlib$' ; then
    do_push_tags 'v*'
  elif echo $d | grep -q -E '^zram-config$' ; then
    do_push_tags 'v*'
  fi

  cd - > /dev/null
done

echo OK

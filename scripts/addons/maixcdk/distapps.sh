#!/bin/sh
m=`dirname $0`
t=${m}/dist
rm -rf ${t}/maixapp/
mkdir -p ${t}
t=${t}/maixapp
mkdir ${t}
mkdir ${t}/apps
mkdir ${t}/lib
mkdir ${t}/tmp
l=${t}/lib
t=${t}/apps
echo "projects:"
for d in $m/projects/app_* ; do
  a=`dirname $d`
  b=`basename $d | cut -d '_' -f 2-`
  r=${a}/apps/${b}
  if [ -e ${d}/dist/${b}_release/${b} -a ! -e ${r}/${b} ]; then
    r=${d}/dist/${b}_release
  fi
  if [ -e ${r}/${b} ]; then
    echo $b
    mkdir ${t}/${b}
    rsync -avpPxH ${r}/ ${t}/${b}/
    chmod +x ${t}/${b}/${b}
    if [ -d ${t}/${b}/dl_lib ]; then
      rsync -avpPxH ${r}/dl_lib/ ${l}/
      rm -rf ${t}/${b}/dl_lib/
      ln -s ../../lib ${t}/${b}/dl_lib
    fi
  fi
done
echo "examples:"
for d in $m/examples/* ; do
  b=`basename $d`
  if [  -e ${d}/dist/${b}_release/${b} ]; then
    echo $b
    mkdir ${t}/${b}
    rsync -avpPxH ${d}/dist/${b}_release/ ${t}/${b}/
    chmod +x ${t}/${b}/${b}
    if [ -d ${t}/${b}/dl_lib ]; then
      rsync -avpPxH ${d}/dist/${b}_release/dl_lib/ ${l}/
      rm -rf ${t}/${b}/dl_lib/
      ln -s ../../lib ${t}/${b}/dl_lib
   fi
  fi
done

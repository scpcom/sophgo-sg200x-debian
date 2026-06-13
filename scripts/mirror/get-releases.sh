#!/bin/sh -e
d=git-archive
[ ! -e ../$d ] || d=../$d
[ -e $d ] || mkdir $d
r=$d/releases/

scriptdir=$(dirname $0) ; pushd $scriptdir >/dev/null ; scriptdir=$(pwd) ; popd >/dev/null

get_pip()
{
  repo=$1
  tag=$2

   if release=$(curl -fqs https://pypi.org/pypi/${repo}/json | jq -r '.releases."'${tag}'"')
    then
      #tag="$(echo "$release" | jq -r '.tag_name')"
      rel_set=$(echo ${repo} | tr / -)-releases-${tag}
      gen_sha256="${r}/pythonhosted"/${repo}-${tag}.sha256
      rel_sha256=${scriptdir}/../addons/python3-${repo}/${repo}-${tag}.sha256
      rel_files="$(echo "$release" | jq -r '.[] | select(.filename | match(".tar.gz$|none-any.whl$")) | .url')"
      echo "Parsing repo $repo at $tag"
      rm -f $gen_sha256
      for rel_file in $rel_files ; do
      if [ -n "$rel_file" ]
      then
        rel_hash=$(echo "$release" | jq -r '.[] | select(.url | match("^'$rel_file'$")) | .digests.sha256')
        rel_name=$(echo "$release" | jq -r '.[] | select(.url | match("^'$rel_file'$")) | .filename')
        echo "Getting ${rel_file}"
        mkdir -p "${r}/pythonhosted"
        echo "$rel_hash  $rel_name" >> $gen_sha256
        pushd "${r}/pythonhosted" >/dev/null
        wget -q -N "${rel_file}"
        popd >/dev/null
      fi
      done
      pushd "${r}/pythonhosted" >/dev/null
      [ -e $rel_sha256 ] || echo "WARNING: $rel_sha256 not found, using hashes from json."
      [ -e $rel_sha256 ] || rel_sha256=${repo}-${tag}.sha256
      sha256sum -c $rel_sha256
      popd >/dev/null
   fi
}

get_rel()
{
  repo=$1
  tag=$2

   if release=$(curl -fqs https://api.github.com/repos/${repo}/releases | jq -r '.[] | select(.tag_name | match("^'${tag}'$"))')
    then
      tag="$(echo "$release" | jq -r '.tag_name')"
      rel_set=$(echo ${repo} | tr / -)-releases-${tag}
      rel_sha256=${scriptdir}/${rel_set}.sha256
      rel_files="$(echo "$release" | jq -r '.assets[] | .name')"
      echo "Parsing repo $repo at $tag"
      for rel_file in $rel_files ; do
      if [ -n "$rel_file" ]
      then
        echo "Getting ${rel_file}"
        mkdir -p "${r}/${repo}/releases/download/${tag}"
        pushd "${r}/${repo}/releases/download/${tag}" >/dev/null
        wget -q -N "https://github.com/${repo}/releases/download/${tag}/${rel_file}"
        popd >/dev/null
      fi
      done
      pushd "${r}/${repo}/releases/download/${tag}" >/dev/null
      sha256sum -c $rel_sha256
      popd >/dev/null
   fi
}

get_tag()
{
  repo=$1
  tag=$2

   if true
    then
      rel_set=$(echo ${repo} | tr / -)-releases-${tag}
      rel_sha256=${scriptdir}/${rel_set}.sha256
      rel_files="${tag}.tar.gz ${tag}.zip"
      rel_dir=${tag}
      echo ${tag} | grep -q -E '^[0-9a-z][0-9a-z][0-9a-z][0-9a-z][0-9a-z]*$' || rel_dir=refs/tags
      echo "Parsing repo $repo at $tag"
      for rel_file in $rel_files ; do
      if [ -n "$rel_file" ]
      then
        echo "Getting ${rel_file}"
        mkdir -p "${r}/${repo}/archive/${rel_dir}"
        pushd "${r}/${repo}/archive" >/dev/null
        wget -q -N "https://github.com/${repo}/archive/${rel_file}"
        rm -f ${rel_dir}/${rel_file}
        if [ "${rel_dir}" = "refs/tags" ]
        then
          ln -s ../../${rel_file} ${rel_dir}/${rel_file}
        else
          ln -s ../${rel_file} ${rel_dir}/${rel_file}
        fi
        popd >/dev/null
      fi
      done
      pushd "${r}/${repo}/archive" >/dev/null
      [ -e $rel_sha256 ] || echo "WARNING: $rel_sha256 not found, generating it."
      [ -e $rel_sha256 ] || sha256sum *.tar.gz *.zip > $rel_sha256
      sha256sum -c $rel_sha256
      popd >/dev/null
   fi
}

for f in scripts/addons/python3-*/addon.mk ; do
  d=`dirname $f`
  a=`basename $d`
  b=`echo $a | cut -d '-' -f 2-`
  v=`echo $a | tr a-z- A-Z_`_VERSION
  t=$(grep '^'$v $f | cut -d '=' -f 2- | tr -d '\t ')
  [ "X$t" = "X" ] || get_pip $b $t
done

get_tag abseil/abseil-cpp 20240722.0
get_tag abseil/abseil-cpp 20250814.0
get_tag eigen-mirror/eigen 1d8b82b0740839c0de7f1242a3585e3390ff5f33
get_tag google/re2 2024-07-02
get_tag google/googletest v1.17.0
get_tag nlohmann/json v3.11.3
get_tag protocolbuffers/protobuf v21.12
get_tag HowardHinnant/date v3.0.1
get_tag boostorg/mp11 boost-1.82.0
get_tag pytorch/cpuinfo 403d652dca4c1046e8145950b1c0997a9f748b57
get_tag pytorch/cpuinfo 8a1772a0c5c447df2d18edf33ec4603a8c9c04a6
get_tag microsoft/GSL v4.0.0
get_tag microsoft/GSL v4.2.1
get_tag dcleblanc/SafeInt 3.0.28
get_tag google/flatbuffers v23.5.26
get_tag onnx/onnx v1.17.0
get_tag onnx/onnx v1.21.0

get_tag scpcom/ade v0.1.1f-gcc-13
get_tag opencv/ade v0.1.1f
get_tag opencv/ade v0.1.2a
get_tag opencv/ade v0.1.2b
get_tag opencv/ade v0.1.2c
get_tag opencv/ade v0.1.2d
get_tag opencv/ade v0.1.2e
get_tag opencv/opencv 4.5.0
get_tag opencv/opencv 4.6.0
get_tag opencv/opencv 4.7.0
get_tag opencv/opencv 4.8.0
get_tag opencv/opencv 4.9.0
get_tag opencv/opencv 4.10.0
get_tag opencv/opencv 4.11.0

get_rel sipeed/MaixCDK v0.0.0

echo OK

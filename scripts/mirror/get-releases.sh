#!/bin/sh -e
d=git-archive
[ ! -e ../$d ] || d=../$d
[ -e $d ] || mkdir $d
r=$d/releases/

scriptdir=$(dirname $0) ; pushd $scriptdir ; scriptdir=$(pwd) ; popd >/dev/null

repo=sipeed/MaixCDK
tag=v0.0.0

   if release=$(curl -fqs https://api.github.com/repos/sipeed/MaixCDK/releases | jq -r '.[] | select(.tag_name | match("^'${tag}'$"))')
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

echo OK

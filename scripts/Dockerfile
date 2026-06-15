FROM debian:trixie AS builder

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y eatmydata \
    && eatmydata apt-get install -y --no-install-recommends \
        qemu-user-static mtools sbuild-debian-developer-setup \
        binfmt-support gdisk kpartx sbuild \
        parted ca-certificates dh-make \
        autoconf automake autotools-dev bc \
        build-essential cpio curl sudo \
        dosfstools e2fsprogs fdisk flex gawk  \
        git gperf kmod libexpat-dev \
        libgmp-dev liblzma-dev libmpc-dev libmpfr-dev libncurses-dev libssl-dev \
        libtool mmdebstrap openssl parted tcl \
        patchutils python3 python3-dev  \
        python-is-python3 python3-jinja2 pkg-config xxd \
        python3-setuptools python3-yaml swig gnupg \
        systemd-container texinfo zlib1g-dev wget arch-test \
        genimage joe lz4 lzip mc unzip zip zstd \
        fakeroot git kernel-wedge quilt ccache cmake flex bison \
        libssl-dev dh-exec jq rsync u-boot-tools libelf-dev patchelf bc




FROM builder AS build_image
WORKDIR /builder
ADD scripts/ /builder/

CMD ["/bin/bash"]

#!/bin/sh -e
[ "X$GIT_SOURCE_HOST" != "X" ] || GIT_SOURCE_HOST=github.com
[ "X$GIT_SOURCE_USER" != "X" ] || GIT_SOURCE_USER=scpcom

clonesecondary=false
clonetoolchain=false
while [ "$#" -gt 0 ]; do
	case "$1" in
	--no-secondary)
		clonesecondary=false
		shift
		;;
	--secondary)
		clonesecondary=true
		shift
		;;
	--no-toolchain)
		clonetoolchain=false
		shift
		;;
	--toolchain)
		clonetoolchain=true
		shift
		;;
	*)
		break
		;;
	esac
done

git_clone() {
  d=$4
  [ "X$d" != "X" ] || d=$(echo $3 | rev | cut -d / -f 1 | rev | sed s/'\.git$'/''/g)
  if [ ! -e $d ]; then
    echo "$3 $2"
    git clone $1 $2 $3 $d
  fi
}

git_subclone() {
  d=$(echo $1 | rev | cut -d / -f 1 | rev)
  git_clone $3 $4 $2 $d
}

d=git-archive
[ ! -e ../$d ] || d=../$d
[ -e $d ] || mkdir $d

echo $d
cd $d

git_clone -b develop https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/LicheeSG-Nano-Build.git # tpusdk
git_subclone build https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-build -b licheervnano-cvisdk
git_subclone cnpy https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/cnpy -b tpu
git_subclone cvi_rtsp https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/cvi_rtsp -b licheervnano-cvisdk
git_subclone cvibuilder https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/cvibuilder -b master
git_subclone cvikernel https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/cvikernel -b master
git_subclone cvimath https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/cvimath -b licheervnano-cvisdk
git_subclone cviruntime https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/cviruntime -b licheervnano-cvisdk
git_subclone flatbuffers https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/flatbuffers -b licheervnano-cvisdk
git_subclone ive https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-ive -b master
git_subclone tdl_sdk https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-tdl_sdk -b licheervnano-cvisdk
git_subclone freertos https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/FreeRTOS -b licheervnano
git_subclone freertos-kernel https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/FreeRTOS-Kernel -b licheervnano
git_subclone freertos-posix https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/Lab-Project-FreeRTOS-POSIX -b licheervnano
git_subclone freertos-partner https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/FreeRTOS-Kernel-Partner-Supported-Ports -b main
git_subclone freertos-community https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/FreeRTOS-Kernel-Community-Supported-Ports -b main
git_subclone isp_tuning https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-isp_tuning -b sg200x-dev
git_subclone ramdisk https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-ramdisk -b licheesgnano
git_clone -b maix_mmf-cvisdk https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-middleware.git middleware
git_subclone component/isp https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-SensorSupportList -b licheervnano-cvisdk
git_subclone sample/test_mmf/media_server-1.0.x https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ireader -b maixcdk
git_subclone sample/kvm_stream https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/streameye -b kvm_stream
#git_subclone modules/bin/cvi_json-c https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/json-c -b cvi
#git_subclone modules/bin/cvi_miniz https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/miniz -b cvi
git_subclone 3rdparty/alsa_lib/alsa_lib https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/alsa-lib -b 3rd
git_subclone 3rdparty/live/live555 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/live555 -b sg200x-dev
git_subclone 3rdparty/json-c/json-c https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/json-c -b 3rd
git_subclone 3rdparty/miniz/miniz https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/miniz -b 3rd
git_subclone 3rdparty/zlib/zlib https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/zlib -b 3rd
git_subclone 3rdparty/opencv/opencv https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/opencv -b 3rd
git_subclone 3rdparty/opencv4.5/ade https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ade -b 3rd-4.5
#git_subclone 3rdparty/flatbuffers/flatbuffers https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/flatbuffers -b licheervnano-cvisdk
git_subclone 3rdparty/nanomsg/nanomsg https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/nanomsg -b 3rd
git_subclone 3rdparty/uv/uv https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/libuv -b 3rd
git_subclone 3rdparty/openssl/openssl https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/openssl -b 3rd
git_subclone 3rdparty/libwebsockets/libwebsockets https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/libwebsockets -b 3rd
git_subclone 3rdparty/sqlite/sqlite https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sqlite -b 3rd
git_subclone 3rdparty/glog/glog https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/glog -b 3rd
git_subclone 3rdparty/ffmpeg/ffmpeg https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/FFmpeg -b 3rd
git_subclone 3rdparty/curl/curl https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/curl -b 3rd
#git_clone -b maixcdk https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ireader media_server-1.0.x
git_subclone media-server https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ireader-media-server -b maixcdk
git_subclone avcodec https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ireader-avcodec -b maixcdk
git_subclone sdk https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ireader-sdk -b maixcdk
#git_clone -b 3rd https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/openssl openssl
git_subclone boringssl https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/boringssl -b main
git_subclone pyca-cryptography https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/pyca-cryptography -b main
git_subclone krb5 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/krb5 -b krb5-1.17
git_subclone gost-engine https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/gost-engine -b master
git_subclone wycheproof https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/wycheproof -b main

git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/stb.git stb-src
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/googletest.git googletest-src
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/eigen.git libeigen-src

git_clone -b licheervnano-cvisdk https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-fsbl fsbl

git_clone -b nanokvm-2025.02 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/buildroot.git buildroot
git_clone -b licheervnano-cvisdk-1.2 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/opensbi opensbi
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/cvi-pinmux cvi_pinmux
git_clone -b licheervnano-cvisdk https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-osdrv.git osdrv
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/aic8800-sdio-firmware aic8800-sdio-firmware
git_clone -b licheervnano-merged-5.10.y https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/linux.git kernel
git_clone -b licheervnano-cvisdk-2021.10 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/u-boot u-boot

git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/zram-config zram-config
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/overlayfs-tools overlayfs-tools

git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/MaixCDK MaixCDK
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/MaixPy MaixPy
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/NanoKVM NanoKVM
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/NanoKVM-Pro NanoKVM-Pro

git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/buildroot-dl dl
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/maixcdk-dl-pkgs
git_clone -b latest https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/maixcam-skeleton
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/nanokvm-server-vendor
git_clone -b latest https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/nanokvm-skeleton
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/nanokvm-web-modules
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/nanokvm-pro-server-vendor
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/nanokvm-pro-web-modules

git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/libdatachannel
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/libjuice
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/libsrtp
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/plog
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/usrsctp
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/zxing-cpp

git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/harfbuzz
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/marisa-trie
git_clone -b 3rd https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/onnxruntime
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/OpenCC opencc
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/quirc
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/rapidjson
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/uchardet

git_subclone cmake/external/onnx https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/onnx -b main
git_subclone cmake/external/libprotobuf-mutator https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/libprotobuf-mutator -b master
git_subclone cmake/external/emsdk https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/emsdk -b main

git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/tinyalsa

git_clone -b nanokvmpro https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/kvmd
git_clone -b nanokvmpro https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/janus-gateway
git_clone -b nanokvmpro https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ustreamer
git_clone -b nanokvmpro https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/pikvm-packages

git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/duo-pinmux
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ax620e-bsp-build
git_clone -b nanokvmpro https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/axerabin axerabin

git_clone -b debian https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-sg200x-debian sophgo-sg200x-debian
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/scpcom.github.io site

git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/lcdtest lcdtest
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/tpudemo-sg200x tpudemo-sg200x
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/uvc-gadget uvc-gadget

git_clone -b develop https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/json json
git_clone -b cvi https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/kissfft kissfft
git_clone -b cvi https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/kaldi-native-fbank kaldi-native-fbank

git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/ipmitool ipmitool
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/rtc-tools rtc-tools

# not required for build
if [ $clonesecondary != false ]; then
git_clone -b develop https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/LicheeRV-Nano-Build.git
#git_clone -b master https://github.com/sophgo/host-tools host-tools
git_clone -b licheervnano https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/sophgo-oss oss
git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/maix_ax620e_sdk maix_ax620e_sdk
git_subclone maix_ax620e_msp https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/maix_ax620e_sdk_msp.git -b main
git_subclone maix_ax620e_kernel https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/maix_ax620e_sdk_kernel.git -b main
fi

if [ $clonetoolchain != false ]; then
git_clone -b xuantie-gnu-toolchain-v2.10.x https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/riscv-gnu-toolchain riscv-gnu-toolchain
git_clone -b xuantie-binutils-gdb-2.35 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/riscv-binutils-gdb riscv-binutils-gdb
git_clone -b xuantie-gcc-10.4.0 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/riscv-gcc riscv-gcc
git_clone -b riscv-glibc-2.33-thead https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/riscv-glibc riscv-glibc
git_clone -b riscv-dejagnu-1.6 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/riscv-dejagnu riscv-dejagnu
git_clone -b xuantie-newlib-3.2.0 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/riscv-newlib riscv-newlib
git_clone -b xuantie-qemu-6.1.0 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/qemu qemu

git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/berkeley-softfloat-3 berkeley-softfloat-3
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/berkeley-testfloat-3 berkeley-testfloat-3
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/cmocka cmocka
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/oniguruma oniguruma
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/brotli brotli
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/esaxx esaxx
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/libdivsufsort libdivsufsort

git_clone -b main https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/dtc dtc
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/edk2 edk2
git_clone -b v5 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/capstone capstone
git_clone -b 0.55 https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/meson meson
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/keycodemapdb keycodemapdb
git_clone -b master https://$GIT_SOURCE_HOST/$GIT_SOURCE_USER/libslirp libslirp
fi

echo OK

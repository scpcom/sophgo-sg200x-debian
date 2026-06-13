ifneq ("$(findstring maixcdk,$(IMAGE_ADDITIONS))","")
BSPFILTER += "maixcdk"
endif

MAIXCDK_GIT_REF = d9741a207552b6e1a38eb247cf4bf62fd5df987d
MAIXCDK_DLPKGS_GIT_REF = a7e320a6bb28ce2b9c4cd2d3f64d7713c9f9a3fc

MAIXCDK_SAMPLE ?= stream_rtsp_demo

MAIXCDK_BUILD_DIR = $(BUILDDIR)/MaixCDK

MAIXCDK_TOOLCHAIN_URL ?= $(shell echo $(TOOLCHAIN_URL) | sed 's|/arm/.*|/arm/gnu|g')

ifeq ($(DEB_ARCH),riscv64)
MAIXCDK_LIB_TARGET = riscv64-linux-gnu
else ifeq ($(DEB_ARCH),arm64)
MAIXCDK_LIB_TARGET = aarch64-linux-gnu
else ifeq ($(DEB_ARCH),armhf)
MAIXCDK_LIB_TARGET = arm-linux-gnueabihf
else
$(error $(red)DEB_ARCH is invalid$(reset))
endif

ifeq ($(DEB_ARCH),armhf)
MAIXCDK_BUILD_ONNXRUNTIME_FROM_SOURCE ?= y
else
MAIXCDK_BUILD_ONNXRUNTIME_FROM_SOURCE ?= n
endif

ifneq ($(SDK_TARGET_LDFLAGS),)
MAIXCDK_TARGET_LDFLAGS = $(SDK_TARGET_LDFLAGS)
else
MAIXCDK_TARGET_LDFLAGS = ""
endif

ifneq ("$(CHIP_FAMILY)","sg200x")
# ax620e
MAIXCDK_PLATFORM ?= maixcam2

# we only need ustreamer customized branch from pikvm to build maixcam_lib
MAIXCAMLIB_BUILD_DIR = $(PIKVM_BUILD_DIR)/ustreamer
MAIXCAMLIB_OUT_DIR = $(MAIXCAMLIB_BUILD_DIR)/maixcam_lib
MS_ASR_OUT_DIR = $(MAIXCAMLIB_BUILD_DIR)/ms_asr

ifneq ("$(findstring pikvm,$(IMAGE_ADDITIONS))","")
MAIXCAMLIB_DEPENDS = $(BUILDDIR)/pikvm-stamp
else
MAIXCAMLIB_DEPENDS = $(BUILDDIR)/pikvm-prepare-stamp
endif

MAIXCAMLIB_DEPENDS += $(BUILDDIR)/alsa_lib-stamp $(BUILDDIR)/openssl-stamp $(BUILDDIR)/ffmpeg-stamp

ifeq ($(MAIXCDK_BUILD_ONNXRUNTIME_FROM_SOURCE),y)
MAIXCAMLIB_DEPENDS += $(BUILDDIR)/onnxruntime-stamp
endif

$(BUILDDIR)/maixcamlib-stamp: $(MAIXCAMLIB_DEPENDS)
	@# rebuild maixcam_lib with cross compile toolchain
	@rsync -avpPxH /rootfs/usr/lib/$(MAIXCDK_LIB_TARGET)/libsamplerate.so* $(MIDDLEWARE_OUT_DIR)/lib/
	@rsync -avpPxH /rootfs/usr/lib/$(MAIXCDK_LIB_TARGET)/libtinyalsa.* $(MIDDLEWARE_OUT_DIR)/lib/
	@cd $(MAIXCAMLIB_BUILD_DIR) && rm -rf maixcam_lib/build maixcam_lib/*.so*
	@cd $(MAIXCAMLIB_BUILD_DIR) && PATH="$(SDK_CROSS_COMPILE_PATH)/bin:$$PATH" make -C maixcam_lib CC=$(SDK_CROSS_COMPILE_PREFIX)gcc CXX=$(SDK_CROSS_COMPILE_PREFIX)g++ CFLAGS="-O3 -I$(MIDDLEWARE_OUT_DIR)/include" LDFLAGS="-L$(MIDDLEWARE_OUT_DIR)/lib"
	@touch $@

$(BUILDDIR)/msasr-stamp: $(BUILDDIR)/maixcamlib-stamp
	@# rebuild ms_asr with cross compile toolchain
	@cd $(MAIXCAMLIB_BUILD_DIR) && rm -rf ms_asr/build ms_asr/*.so*
	@cd $(MAIXCAMLIB_BUILD_DIR) && PATH="$(SDK_CROSS_COMPILE_PATH)/bin:$$PATH" make -C ms_asr CC=$(SDK_CROSS_COMPILE_PREFIX)gcc CXX=$(SDK_CROSS_COMPILE_PREFIX)g++ CFLAGS="-O3 -I$(MIDDLEWARE_OUT_DIR)/include" LDFLAGS="-L$(MIDDLEWARE_OUT_DIR)/lib"
	@touch $@

else
# sg200x
MAIXCDK_PLATFORM ?= maixcam

MAIXCAMLIB_BUILD_DIR = $(BUILDDIR)/middleware/sample/test_mmf
MAIXCAMLIB_OUT_DIR = $(MAIXCAMLIB_BUILD_DIR)/maixcam_lib/release.linux
MS_ASR_OUT_DIR = $(MAIXCAMLIB_BUILD_DIR)/ms_asr/release.linux
MEDIA_SERVER_BUILD_DIR = $(MAIXCAMLIB_BUILD_DIR)/media_server-1.0.x

MAIXCAMLIB_DEPENDS = $(BUILDDIR)/middleware-package-stamp $(BUILDDIR)/tpusdk-package-stamp

ifeq ($(MAIXCDK_BUILD_ONNXRUNTIME_FROM_SOURCE),y)
MAIXCAMLIB_DEPENDS += $(BUILDDIR)/onnxruntime-stamp
endif

$(BUILDDIR)/maixcamlib-stamp: $(MAIXCAMLIB_DEPENDS)
	@touch $@

$(BUILDDIR)/msasr-stamp: $(BUILDDIR)/maixcamlib-stamp
	@touch $@
endif

$(BUILDDIR)/maixcdk-prepare-checkout-stamp: $(BUILDDIR)/maixcamlib-stamp $(BUILDDIR)/msasr-stamp $(BUILDDIR)/python3-maixtool-stamp
	@cd $(BUILDDIR) && git clone --shallow-since=2024-08-18 $(GIT_USER_URL)/MaixCDK
	@cd $(MAIXCDK_BUILD_DIR)/ && git checkout $(MAIXCDK_GIT_REF)
	@cd $(MAIXCDK_BUILD_DIR)/dl && git clone -b full --depth 1 $(GIT_USER_URL)/maixcdk-dl-pkgs pkgs
	@cd $(MAIXCDK_BUILD_DIR)/dl/pkgs && git checkout $(MAIXCDK_DLPKGS_GIT_REF)
	@touch $@

$(BUILDDIR)/maixcdk-prepare-patch-stamp: $(BUILDDIR)/maixcdk-prepare-checkout-stamp
	@$(foreach file, $(wildcard /configs/common/patches/maixcdk/*.patch), cd $(MAIXCDK_BUILD_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/maixcdk/*.patch), cd $(MAIXCDK_BUILD_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/maixcdk/*.patch), cd $(MAIXCDK_BUILD_DIR) && git apply --ignore-whitespace $(file);)
	@# use maixcam_lib built from source
	@rsync -avpPxH $(MAIXCAMLIB_OUT_DIR)/libmaixcam_lib.so $(MAIXCDK_BUILD_DIR)/components/maixcam_lib/lib_$(MAIXCDK_PLATFORM)/
	@# use alsa_lib built from source
	@if [ -e $(SDK_OSS_TARBALL_DIR)/alsa_lib.tar.gz ]; then \
		rm -rf $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/include/ && \
		rm -rf $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/lib/ && \
		mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/alsa_lib && \
		tar -C $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/alsa_lib -xzf $(SDK_OSS_TARBALL_DIR)/alsa_lib.tar.gz && \
		sed -i 's|list(APPEND ADD_INCLUDE "include"|list(APPEND ADD_INCLUDE "alsa_lib/include"|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/CMakeLists.txt && \
		sed -i 's|set(alsa_lib_include_dir "include")|set(alsa_lib_include_dir "alsa_lib/include")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/CMakeLists.txt && \
		sed -i 's|set(alsa_lib_dir "lib")|set(alsa_lib_dir "alsa_lib/lib")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/CMakeLists.txt && \
		sed -i 's|$${alsa_lib_dir}/$(MAIXCDK_PLATFORM)|$${alsa_lib_dir}|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/CMakeLists.txt && \
		sed -i 's|lib/$(MAIXCDK_PLATFORM)|alsa_lib/lib|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/CMakeLists.txt && \
		rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/alsa_lib/component.py ; \
	fi
	@# build libdatachannel from source
	@sed -i 's|CONFIG_LIBDATACHANNEL_COMPILE_FROM_SOURCE|1|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/CMakeLists.txt
	@sed -i 's|if .CONFIG_LIBDATACHANNEL_COMPILE_FROM_SOURCE. not in confs|if 0|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/component.py
	@sed -i 's|"$${srcs_path}/include" "$${srcs_path}/src"|"$${srcs_path}/include" "$${srcs_path}/include/rtc" "$${srcs_path}/src"|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/CMakeLists.txt
	@rm -rf $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/lib/$(MAIXCDK_PLATFORM)
	@# use ffmpeg build from source
	@# --enable-swscale must be set on oss ffmpeg
	@# todo: enable avdevice/avfilter/avresample/postproc instead of removing it from CMakeLists.txt
	@if [ -e $(SDK_OSS_TARBALL_DIR)/ffmpeg.tar.gz ]; then \
		mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/ffmpeg && \
		tar -C $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/ffmpeg -xzf $(SDK_OSS_TARBALL_DIR)/ffmpeg.tar.gz && \
		sed -i 's|set(src_path "$${ffmpeg_unzip_path}/ffmpeg_$(MAIXCDK_PLATFORM)_libs_n$${ffmpeg_version_str}")|set(src_path "ffmpeg")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/CMakeLists.txt && \
		sed -i 's|set(src_path "$${ffmpeg_unzip_path}/ffmpeg")|set(src_path "ffmpeg")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/CMakeLists.txt && \
		for l in avdevice avfilter avresample postproc ; do \
			[ -e $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/ffmpeg/lib/lib$${l}.so ] || sed -i /lib$${l}.so/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/CMakeLists.txt ; \
		done && \
		rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/component.py ; \
	fi
	@if [ -e $(SDK_OSS_TARBALL_DIR)/ffmpeg.tar.gz -a -e $(SDK_OSS_TARBALL_DIR)/zlib.tar.gz ]; then \
		tar -C $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/ffmpeg --wildcards -xzf $(SDK_OSS_TARBALL_DIR)/zlib.tar.gz 'lib/libz.so*' && \
		sed -i 's|                                $${src_path}/lib/libswscale.so|                                $${src_path}/lib/libswscale.so\n                                $${src_path}/lib/libz.so|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/CMakeLists.txt ; \
	fi
	@# build harfbuzz from source
	@sed -i s/'confs.get("CONFIG_COMPONENTS_COMPILE_FROM_SOURCE", None)'/'1'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/component.py
	@sed -i s/CONFIG_COMPONENTS_COMPILE_FROM_SOURCE/1/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/CMakeLists.txt
	@# use msp libs from sdk
	@sed -i 's|set(msp_glibc_path ".*")|set(msp_glibc_path "$(MIDDLEWARE_OUT_DIR)")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/maixcam2_msp/CMakeLists.txt
	@sed -i 's|$${msp_local_path}/out/.*_glibc/include|$(MIDDLEWARE_OUT_DIR)/include|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/maixcam2_msp/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/maixcam2_msp/component.py
	@# disable ARM_MATH_DSP on ARM 32 bit
	@[ "$(DEB_ARCH)" != "armhf" ] || sed -i s/'#define ARM_MATH_DSP'/'#define BROKEN_ARM_MATH_DSP'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/omv/omv/ports/common/arm_math_types.h
	@# use maixcam2 onnxruntime on ARM 64 bit
	@[ "$(DEB_ARCH)" != "arm64" -o "$(MAIXCDK_BUILD_ONNXRUNTIME_FROM_SOURCE)" = "y" ] || \
		sed -i 's|maixcam_onnxruntime_v$${onnxruntime_version_str}|maixcam2_onnxruntime_v$${onnxruntime_version_str}|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/CMakeLists.txt && \
		sed -i 's|maixcam_onnxruntime_v{version}|maixcam2_onnxruntime_v{version}|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/component.py && \
		sed -i 's|sg2002_onnxruntime_v{version}|maixcam2_onnxruntime_v{version}|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/component.py
	@# use onnxruntime build from source
	@if [ -e $(SDK_OSS_TARBALL_DIR)/onnxruntime.tar.gz ]; then \
		mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/onnxruntime && \
		tar -C $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/onnxruntime -xzf $(SDK_OSS_TARBALL_DIR)/onnxruntime.tar.gz && \
		sed -i 's|set(src_path "$${onnxruntime_unzip_path}/$(MAIXCDK_PLATFORM)_onnxruntime_v$${onnxruntime_version_str}")|set(src_path "onnxruntime")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/CMakeLists.txt && \
		rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/component.py ; \
	fi
	@# build opencv from source
	@sed -i s/'confs.get("CONFIG_COMPONENTS_COMPILE_FROM_SOURCE", None)'/'1'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@sed -i s/CONFIG_COMPONENTS_COMPILE_FROM_SOURCE/1/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/CMakeLists.txt
	@# use openssl built from source
	@if [ -e $(SDK_OSS_TARBALL_DIR)/openssl3.0.tar.gz ]; then \
		rm -rf $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/include/ && \
		rm -rf $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/so/ && \
		mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/openssl && \
		tar -C $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/openssl -xzf $(SDK_OSS_TARBALL_DIR)/openssl3.0.tar.gz && \
		sed -i 's|list(APPEND ADD_INCLUDE "include"|list(APPEND ADD_INCLUDE "openssl/include"|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/CMakeLists.txt && \
		sed -i 's|so/$(MAIXCDK_PLATFORM)|openssl/lib|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/CMakeLists.txt && \
		rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/component.py ; \
	fi
	@# update download urls if required
	@[ ! -e $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/component.py ] || sed -i 's|https://github.com/sipeed/MaixCDK/releases|'$(GIT_RELEASES_URL)'/sipeed/MaixCDK/releases|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/component.py
	@sed -i 's|https://github.com/sipeed/MaixCDK/releases|'$(GIT_RELEASES_URL)'/sipeed/MaixCDK/releases|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@[ ! -e $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/component.py ] || sed -i 's|https://github.com/sipeed/MaixCDK/releases|'$(GIT_RELEASES_URL)'/sipeed/MaixCDK/releases|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/component.py
	@sed -i 's|https://github.com/opencv/ade/archive|$(GIT_RELEASES_URL)/opencv/ade/archive|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@sed -i 's|https://github.com/opencv/opencv/archive|$(GIT_RELEASES_URL)/opencv/opencv/archive|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@[ "X$(MAIXCDK_TOOLCHAIN_URL)" = "X" ] || sed -i 's|https://developer.arm.com/-/media/Files/downloads/gnu|$(MAIXCDK_TOOLCHAIN_URL)|g' $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@# use cross compile toolchain
	@sed -i s/'^    url: .*'/'    url:'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i s/'^    sha256sum: .*'/'    sha256sum:'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i s/'^    filename: .*'/'    filename:'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i s/'^    path: .*'/'    path:'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i 's|^    bin_path: .*|    bin_path: '$(SDK_CROSS_COMPILE_PATH)/bin'|g' $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i 's|^    prefix: .*|    prefix: '$(SDK_CROSS_COMPILE_PREFIX)'|g' $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i 's|^    c_flags: .*|    c_flags: $(MAIXCDK_TARGET_LDFLAGS)|g' $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i 's|^    cxx_flags: .*|    cxx_flags: $(MAIXCDK_TARGET_LDFLAGS)|g' $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@touch $@

$(BUILDDIR)/maixcdk-prepare-ax620e-stamp: $(BUILDDIR)/maixcdk-prepare-patch-stamp
	@# use ms_asr built from source on ARM 32 bit
	@[ "$(DEB_ARCH)" != "armhf" ] || rsync -avpPxH $(MS_ASR_OUT_DIR)/libms_asr_*.so $(MAIXCDK_BUILD_DIR)/components/nn/lib/
	@# disable onnxruntime on ARM 32 bit
	@[ "$(DEB_ARCH)" != "armhf" -o "$(MAIXCDK_BUILD_ONNXRUNTIME_FROM_SOURCE)" = "y" ] || sed -i /'list(APPEND ADD_DYNAMIC_LIB "$${src_path}.lib.libonnxruntime.so.1")'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/CMakeLists.txt
	@touch $@

$(BUILDDIR)/maixcdk-prepare-sg200x-stamp: $(BUILDDIR)/maixcdk-prepare-patch-stamp
	# use cvi_tpu built from source
	@mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/cvi_tpu_lib
	@rsync -avpPxH $(BUILDDIR)/tpusdk/install/soc_$(TPUSDK_BOARD_LINK)/tpu_$(SDK_VER)/cvitek_tpu_sdk/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/cvi_tpu_lib/
	@sed -i s/lib_musl/lib/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/CMakeLists.txt
	@sed -i s/lib_glibc/lib/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/component.py
	# use media_server built from source
	@mkdir -pv $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/media_server/
	@for i in $(MEDIA_SERVER_BUILD_DIR)/*/*/include ; do \
		d=$$(dirname $$i) ; \
		b=$$(basename $$d) ; \
		d=$$(dirname $$d) ; \
		a=$$(basename $$d) ; \
		mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/media_server/include/$$a/$$b ; \
		rsync -avpPxH $(MEDIA_SERVER_BUILD_DIR)/$$a/$$b/include/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/media_server/include/$$a/$$b/include/ ; \
	done
	@mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/media_server/include/sdk/
	@rsync -avpPxH $(MEDIA_SERVER_BUILD_DIR)/sdk/include/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/media_server/include/sdk/include/
	@mkdir -pv $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/media_server/lib/
	@rsync -avpPxH $(MEDIA_SERVER_BUILD_DIR)/*/*/release.linux/lib*.a $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/media_server/lib/
	@sed -i 's|$${media_server_unzip_path}/media_server-$${media_server_version_str}|media_server|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/media_server/component.py
	@# disable __ARM_ARCH on arm64
	@[ "$(DEB_ARCH)" != "arm64" ] || sed -i s/'ADD_DEFINITIONS_PRIVATE -DPLATFORM_MAIXCAM=1'/'ADD_DEFINITIONS_PRIVATE -D__ARM_ARCH=0 -DPLATFORM_MAIXCAM=1'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/omv/CMakeLists.txt
	@# use middleware libs from sdk
	@sed -i 's|$${middleware_src_path}/v2/lib|$(MIDDLEWARE_OUT_DIR)/lib|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i 's|$${middleware_src_path}/v2/include|$(MIDDLEWARE_OUT_DIR)/include|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i 's|$${middleware_src_path}/v2/uapi|$(MIDDLEWARE_OUT_DIR)/include/linux|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@# small changes related to weekly rls 2024.10.14
	@sed -i /'$${mmf_lib_dir}.3rd.libcli.so'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i s/'libdnvqe.so'/'libcvi_dnvqe.so'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i 's|$${mmf_lib_dir}/libcvi_dnvqe.so|\$${mmf_lib_dir}/libcvi_dnvqe.so $${mmf_lib_dir}/libcvi_ssp2.so|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i /'$${mmf_lib_dir}.libjson-c.so.5'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i 's|^list.APPEND ADD_INCLUDE $${middleware_include_dir}.|list(APPEND ADD_INCLUDE $${middleware_include_dir})\n\nlist(APPEND ADD_DEFINITIONS -D__$(SDK_CHIP)__)|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i /'#include "cvi_comm_ao.h"'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/sophgo-middleware/v2/sample/common/sample_comm.h
	@sed -i s/stSnsGc02m1_Obj/stSnsGc02m1b_Obj/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/sophgo-middleware/v2/component/isp/sensor/sg200x/gcore_gc02m1/gc02m1_cmos.c
	@sed -i s/stSnsGc02m1_Obj/stSnsGc02m1b_Obj/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/sophgo-middleware/v2/sample/common/sample_common_sensor.c
	@sed -i s/'#include "mipi_tx.h"'/'#include "cvi_mipi_tx.h"'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/sophgo-middleware/v2/sample/common/sample_common_vo.c
	@# use ms_asr built from source
	@rsync -avpPxH $(MS_ASR_OUT_DIR)/libms_asr_*.so $(MAIXCDK_BUILD_DIR)/components/nn/lib/
	@# add -ldl for glibc cross compile toolchain
	@[ "X$(findstring musl,$(SDK_VER))" != "X" ] || sed -i s/'-mabi=lp64d$$'/'-mabi=lp64d -ldl'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@touch $@

$(BUILDDIR)/maixcdk-compile-one-example-stamp: $(BUILDDIR)/maixcdk-prepare-$(CHIP_FAMILY)-stamp
	@cd $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/ && maixcdk build -p $(MAIXCDK_PLATFORM)
	@# build brotli only once
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/build/brotli_install/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/brotli/brotli_$(MAIXCDK_PLATFORM)/
	@sed -i 's|$${install_dir}|$${CMAKE_CURRENT_LIST_DIR}/brotli_$(MAIXCDK_PLATFORM)|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/brotli/CMakeLists.txt
	@sed -i 's|$${brotli_install_dir}|$${CMAKE_CURRENT_LIST_DIR}/brotli_$(MAIXCDK_PLATFORM)|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/brotli/CMakeLists.txt
	@sed -i 's|set(brotli_compile_cmd COMMAND .*)|set(brotli_compile_cmd COMMAND true)|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/brotli/CMakeLists.txt
	@sed -i /'list(APPEND ADD_FILE_DEPENDS .*)'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/brotli/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/brotli/component.py
	@# build datachannel only once
	@mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/include
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/dl/extracted/libdatachannel_srcs/libdatachannel-*/include/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/include/
	@mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/lib/$(MAIXCDK_PLATFORM)
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/build/datachannel/libdatachannel.so* $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/lib/$(MAIXCDK_PLATFORM)/
	@cd $(MAIXCDK_BUILD_DIR) && git restore components/3rd_party/datachannel/CMakeLists.txt
	@# build freetype only once
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/build/freetype_install/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/freetype/freetype_$(MAIXCDK_PLATFORM)/
	@sed -i 's|$${freetype_install_dir}|$${CMAKE_CURRENT_LIST_DIR}/freetype_$(MAIXCDK_PLATFORM)|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/freetype/CMakeLists.txt
	@sed -i 's|set(freetype_compile_cmd COMMAND .*)|set(freetype_compile_cmd COMMAND true)|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/freetype/CMakeLists.txt
	@sed -i /'DEPENDS brotli'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/freetype/CMakeLists.txt
	@sed -i /'list(APPEND ADD_FILE_DEPENDS .*)'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/freetype/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/freetype/component.py
	@# build harfbuzz only once
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/build/harfbuzz_install/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/harfbuzz_$(MAIXCDK_PLATFORM)/
	@cd $(MAIXCDK_BUILD_DIR) && git restore components/3rd_party/harfbuzz/CMakeLists.txt
	@sed -i 's|CONFIG_TOOLCHAIN_PATH MATCHES "musl"|1|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/CMakeLists.txt
	@sed -i 's|set(harfbuzz_lib_dir "$${DL_EXTRACTED_PATH}/harfbuzz/harfbuzz_.*_v8.2.1")|set(harfbuzz_lib_dir "$${CMAKE_CURRENT_LIST_DIR}/harfbuzz_$(MAIXCDK_PLATFORM)")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/CMakeLists.txt
	@sed -i 's|set(harfbuzz_lib_dir "$${DL_EXTRACTED_PATH}/harfbuzz/harfbuzz_.*_$${version_str}")|set(harfbuzz_lib_dir "$${CMAKE_CURRENT_LIST_DIR}/harfbuzz_$(MAIXCDK_PLATFORM)")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/component.py
	@# build opencv only once
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/build/opencv4_install/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/opencv4_lib_$(MAIXCDK_PLATFORM)/
	@cd $(MAIXCDK_BUILD_DIR) && git restore components/3rd_party/opencv/CMakeLists.txt
	@sed -i 's|set(opencv_lib_dir "$${DL_EXTRACTED_PATH}/opencv/opencv4/opencv4_lib_.*_$${version_str}")|set(opencv_lib_dir "$${CMAKE_CURRENT_LIST_DIR}/opencv4_lib_$(MAIXCDK_PLATFORM)")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/CMakeLists.txt
	@sed -i 's|$${opencv_lib_dir}/dl_lib|$${opencv_lib_dir}/lib|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@touch $@

$(BUILDDIR)/maixcdk-compile-stamp: $(BUILDDIR)/maixcdk-compile-one-example-stamp
	@cd $(MAIXCDK_BUILD_DIR)/projects/ && bash build_all.sh $(MAIXCDK_PLATFORM)
	@touch $@

$(BUILDDIR)/maixcdk-compile-all-examples-stamp: $(BUILDDIR)/maixcdk-compile-stamp
	@touch $(MAIXCDK_BUILD_DIR)/stamps/maixcdk-example.done
	@touch $(MAIXCDK_BUILD_DIR)/stamps/camera_onvif_server.done
	@cd $(MAIXCDK_BUILD_DIR)/test/test_examples/ && bash test_cases.sh $(MAIXCDK_PLATFORM)
	@touch $@

$(BUILDDIR)/maixcdk-distapps-stamp: $(BUILDDIR)/maixcdk-compile-stamp
	@cp -p addons/maixcdk/distapps.sh $(MAIXCDK_BUILD_DIR)/
	@cd $(MAIXCDK_BUILD_DIR)/ && chmod +x distapps.sh
	@cd $(MAIXCDK_BUILD_DIR)/ && ./distapps.sh
	@mkdir -p $(MAIXCDK_BUILD_DIR)/dist/usr/lib
	@touch $@

$(BUILDDIR)/maixcdk-distlibs-stamp: $(BUILDDIR)/maixcdk-distapps-stamp
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/build/opencv4_install/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/ || \
		rsync -avpPxH $(MAIXCDK_BUILD_DIR)/dl/extracted/opencv/opencv4/opencv4_*/dl_lib/ $(MAIXCDK_BUILD_DIR)/dist/usr/lib/
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/ffmpeg/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/ || \
		rsync -avpPxH $(MAIXCDK_BUILD_DIR)/dl/extracted/ffmpeg_srcs/ffmpeg_*/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/
	@touch $@

$(BUILDDIR)/maixcdk-distlibs-ax620e-stamp: $(BUILDDIR)/maixcdk-distlibs-stamp
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/onnxruntime/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/ || \
		rsync -avpPxH $(MAIXCDK_BUILD_DIR)/dl/extracted/onnxruntime_srcs/$(MAIXCDK_PLATFORM)_onnxruntime_*/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/
	@touch $@

$(BUILDDIR)/maixcdk-distlibs-sg200x-stamp: $(BUILDDIR)/maixcdk-distlibs-stamp
	@touch $@

$(BUILDDIR)/maixcdk-stamp: $(BUILDDIR)/maixcdk-compile-stamp $(BUILDDIR)/maixcdk-distapps-stamp $(BUILDDIR)/maixcdk-distlibs-$(CHIP_FAMILY)-stamp
	@rsync -avpPxH $(MAIXCAMLIB_OUT_DIR)/libmaixcam_lib.so $(MAIXCDK_BUILD_DIR)/dist/maixapp/lib/
	@cd $(MAIXCDK_BUILD_DIR)/ && rm -rf dl/extracted examples/*/build examples/*/dist projects/*/build projects/*/dist
	@cd $(MAIXCDK_BUILD_DIR)/ && [ "$(GIT_REF)" = "develop" ] || rm -rf dl
	@touch $@

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

$(BUILDDIR)/maixcamlib-stamp: $(MAIXCAMLIB_DEPENDS)
	@# rebuild maixcam_lib with cross compile toolchain
	@rsync -avpPxH /rootfs/usr/lib/$(MAIXCDK_LIB_TARGET)/libsamplerate.so* /rootfs$(MIDDLEWARE_TARGET_DIR)/lib/
	@rsync -avpPxH /rootfs/usr/lib/$(MAIXCDK_LIB_TARGET)/libtinyalsa.* /rootfs$(MIDDLEWARE_TARGET_DIR)/lib/
	@cd $(MAIXCAMLIB_BUILD_DIR) && rm -rf maixcam_lib/build maixcam_lib/*.so*
	@cd $(MAIXCAMLIB_BUILD_DIR) && PATH="$(SDK_CROSS_COMPILE_PATH)/bin:$$PATH" make -C maixcam_lib CC=$(SDK_CROSS_COMPILE_PREFIX)gcc CXX=$(SDK_CROSS_COMPILE_PREFIX)g++ CFLAGS="-O3 -I/rootfs$(MIDDLEWARE_TARGET_DIR)/include" LDFLAGS="-L/rootfs$(MIDDLEWARE_TARGET_DIR)/lib"
	@touch $@

else
# sg200x
MAIXCDK_PLATFORM ?= maixcam

MAIXCDK_OSS_TARBALL_DIR = $(BUILDDIR)/tpusdk/oss/oss_release_tarball/$(TPUSDK_VER)

MAIXCAMLIB_BUILD_DIR = $(BUILDDIR)/middleware/sample/test_mmf
MAIXCAMLIB_OUT_DIR = $(MAIXCAMLIB_BUILD_DIR)/maixcam_lib/release.linux
MS_ASR_OUT_DIR = $(MAIXCAMLIB_BUILD_DIR)/ms_asr/release.linux

MAIXCAMLIB_DEPENDS = $(BUILDDIR)/middleware-package-stamp $(BUILDDIR)/tpusdk-package-stamp

$(BUILDDIR)/maixcamlib-stamp: $(MAIXCAMLIB_DEPENDS)
	@touch $@
endif

$(BUILDDIR)/maixtool-stamp:
	@# install maixtool on host
	@apt-get install -y python3-flask python3-netifaces python3-pillow python3-yaml python3-progress python3-qrcode python3-requests python3-pip python3-setuptools
	@pip install --break-system-packages maixtool
	@touch $@

$(BUILDDIR)/maixcdk-prepare-checkout-stamp: $(BUILDDIR)/maixcamlib-stamp $(BUILDDIR)/maixtool-stamp
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
	@# build libdatachannel from source
	@sed -i 's|CONFIG_LIBDATACHANNEL_COMPILE_FROM_SOURCE|1|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/CMakeLists.txt
	@sed -i 's|if .CONFIG_LIBDATACHANNEL_COMPILE_FROM_SOURCE. not in confs|if 0|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/component.py
	@sed -i 's|"$${srcs_path}/include" "$${srcs_path}/src"|"$${srcs_path}/include" "$${srcs_path}/include/rtc" "$${srcs_path}/src"|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/CMakeLists.txt
	@rm -rf $(MAIXCDK_BUILD_DIR)/components/3rd_party/datachannel/lib/$(MAIXCDK_PLATFORM)
	@# build harfbuzz from source
	@sed -i s/'confs.get("CONFIG_COMPONENTS_COMPILE_FROM_SOURCE", None)'/'1'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/component.py
	@sed -i s/CONFIG_COMPONENTS_COMPILE_FROM_SOURCE/1/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/harfbuzz/CMakeLists.txt
	@# use msp libs from rootfs
	@sed -i 's|set(msp_glibc_path ".*")|set(msp_glibc_path "/rootfs$(MIDDLEWARE_TARGET_DIR)")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/maixcam2_msp/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/maixcam2_msp/component.py
	@# update download urls if required
	@[ ! -e $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/component.py ] || sed -i 's|https://github.com/sipeed/MaixCDK/releases|'$(GIT_RELEASES_URL)'/sipeed/MaixCDK/releases|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/component.py
	@sed -i 's|https://github.com/sipeed/MaixCDK/releases|'$(GIT_RELEASES_URL)'/sipeed/MaixCDK/releases|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@sed -i 's|https://github.com/sipeed/MaixCDK/releases|'$(GIT_RELEASES_URL)'/sipeed/MaixCDK/releases|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/onnxruntime/component.py
	@sed -i 's|https://github.com/opencv/ade/archive|$(GIT_RELEASES_URL)/opencv/ade/archive|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@sed -i 's|https://github.com/opencv/opencv/archive|$(GIT_RELEASES_URL)/opencv/opencv/archive|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@[ "X$(MAIXCDK_TOOLCHAIN_URL)" = "X" ] || sed -i 's|https://developer.arm.com/-/media/Files/downloads/gnu|$(MAIXCDK_TOOLCHAIN_URL)|g' $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@touch $@

$(BUILDDIR)/maixcdk-prepare-ax620e-stamp: $(BUILDDIR)/maixcdk-prepare-patch-stamp
	@touch $@

$(BUILDDIR)/maixcdk-prepare-sg200x-stamp: $(BUILDDIR)/maixcdk-prepare-patch-stamp
	# use cvi_tpu built from source
	@mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/cvi_tpu_lib
	@rsync -avpPxH $(BUILDDIR)/tpusdk/install/soc_$(TPUSDK_BOARD_LINK)/tpu_$(TPUSDK_VER)/cvitek_tpu_sdk/ $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/cvi_tpu_lib/
	@sed -i s/lib_musl/lib/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/CMakeLists.txt
	@sed -i s/lib_glibc/lib/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/CMakeLists.txt
	@rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/cvi_tpu/component.py
	@# use ffmpeg build from source
	@# --enable-swscale must be set on oss ffmpeg
	@# todo: enable avdevice/avfilter/avresample/postproc or remove it from CMakeLists.txt
	@if [ -e $(MAIXCDK_OSS_TARBALL_DIR)/ffmpeg.tar.gz ]; then \
		mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/ffmpeg && \
		tar -C $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/ffmpeg -xzf $(MAIXCDK_OSS_TARBALL_DIR)/ffmpeg.tar.gz && \
		sed -i 's|set(src_path "$${ffmpeg_unzip_path}/ffmpeg")|set(src_path "ffmpeg")|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/CMakeLists.txt && \
		rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/FFmpeg/component.py ; \
	fi
	@# use middleware libs from rootfs
	@sed -i 's|$${middleware_src_path}/v2/lib|/rootfs$(MIDDLEWARE_TARGET_DIR)/lib|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i /'$${mmf_lib_dir}.3rd.libcli.so'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i s/'libdnvqe.so'/'libcvi_dnvqe.so'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i 's|$${mmf_lib_dir}/libcvi_dnvqe.so|\$${mmf_lib_dir}/libcvi_dnvqe.so $${mmf_lib_dir}/libcvi_ssp2.so|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@sed -i /'$${mmf_lib_dir}.libjson-c.so.5'/d $(MAIXCDK_BUILD_DIR)/components/3rd_party/sophgo-middleware/CMakeLists.txt
	@# use ms_asr built from source
	@rsync -avpPxH $(MS_ASR_OUT_DIR)/libms_asr_*.so $(MAIXCDK_BUILD_DIR)/components/nn/lib/
	@# use openssl built from source
	@if [ -e $(MAIXCDK_OSS_TARBALL_DIR)/openssl3.0.tar.gz ]; then \
		rm -rf $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/include/ && \
		rm -rf $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/so/ && \
		mkdir -p $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/openssl && \
		tar -C $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/openssl -xzf $(MAIXCDK_OSS_TARBALL_DIR)/openssl3.0.tar.gz && \
		sed -i 's|list(APPEND ADD_INCLUDE "include"|list(APPEND ADD_INCLUDE "openssl/include"|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/CMakeLists.txt && \
		sed -i 's|so/$(MAIXCDK_PLATFORM)|openssl/lib|g' $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/CMakeLists.txt && \
		rm -f $(MAIXCDK_BUILD_DIR)/components/3rd_party/openssl/component.py ; \
	fi
	@# build opencv from source
	@sed -i s/'confs.get("CONFIG_COMPONENTS_COMPILE_FROM_SOURCE", None)'/'1'/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/component.py
	@sed -i s/CONFIG_COMPONENTS_COMPILE_FROM_SOURCE/1/g $(MAIXCDK_BUILD_DIR)/components/3rd_party/opencv/CMakeLists.txt
	@# use cross compile toolchain
	@sed -i s/'^    url: .*'/'    url:'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i s/'^    sha256sum: .*'/'    sha256sum:'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i s/'^    filename: .*'/'    filename:'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i s/'^    path: .*'/'    path:'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i 's|^    bin_path: .*|    bin_path: '$(SDK_CROSS_COMPILE_PATH)/bin'|g' $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i 's|^    prefix: .*|    prefix: '$(SDK_CROSS_COMPILE_PREFIX)'|g' $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@sed -i s/rv64imafdcv0p7xthead/rv64imafdc/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@[ "X$(findstring musl,$(SDK_VER))" != "X" ] || sed -i s/'-mabi=lp64d$$'/'-mabi=lp64d -ldl'/g $(MAIXCDK_BUILD_DIR)/platforms/$(MAIXCDK_PLATFORM).yaml
	@touch $@

$(BUILDDIR)/maixcdk-compile-stamp: $(BUILDDIR)/maixcdk-prepare-$(CHIP_FAMILY)-stamp
	@cd $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/ && maixcdk build -p $(MAIXCDK_PLATFORM)
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

$(BUILDDIR)/maixcdk-distlibs-ax620e-stamp: $(BUILDDIR)/maixcdk-distapps-stamp
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/dl/extracted/onnxruntime_srcs/$(MAIXCDK_PLATFORM)_onnxruntime_*/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/dl/extracted/opencv/opencv4/opencv4_*/dl_lib/ $(MAIXCDK_BUILD_DIR)/dist/usr/lib/
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/dl/extracted/ffmpeg_srcs/ffmpeg_*/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/
	@touch $@

$(BUILDDIR)/maixcdk-distlibs-sg200x-stamp: $(BUILDDIR)/maixcdk-distapps-stamp
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/examples/$(MAIXCDK_SAMPLE)/build/opencv4_install/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/
	@rsync -avpPxH $(MAIXCDK_BUILD_DIR)/dl/extracted/ffmpeg_srcs/ffmpeg*/lib/*.so* $(MAIXCDK_BUILD_DIR)/dist/usr/lib/
	@touch $@

$(BUILDDIR)/maixcdk-stamp: $(BUILDDIR)/maixcdk-compile-stamp $(BUILDDIR)/maixcdk-distapps-stamp $(BUILDDIR)/maixcdk-distlibs-$(CHIP_FAMILY)-stamp
	@rsync -avpPxH $(MAIXCAMLIB_OUT_DIR)/libmaixcam_lib.so $(MAIXCDK_BUILD_DIR)/dist/maixapp/lib/
	@cd $(MAIXCDK_BUILD_DIR)/ && rm -rf dl/extracted examples/*/build examples/*/dist projects/*/build projects/*/dist
	@cd $(MAIXCDK_BUILD_DIR)/ && [ "$(GIT_REF)" = "develop" ] || rm -rf dl
	@touch $@

SHELL = /bin/bash

ifneq ("$(CHIP_FAMILY)","sg200x")
# ax620e
FFMPEG_GIT_BRANCH = 3rd-6.1
FFMPEG_GIT_REF = e38092ef9395d7049f871ef4d5411eb410e283e0
else
# sg200x
FFMPEG_GIT_BRANCH = 3rd
FFMPEG_GIT_REF = ece322ebb362f09b268c54569c3c6815712a9c9d
endif

ifeq ($(SDK_VER), 32bit)
FFMPEG_ARCH = arm
FFMPEG_ARM_CPU_HAS_VFPV2 = y
FFMPEG_ARM_CPU_HAS_NEON = y
GCC_TARGET_CPU = cortex-a53
else ifeq ($(SDK_VER), 64bit)
FFMPEG_ARCH = aarch64
GCC_TARGET_CPU = cortex-a53
else ifeq ($(SDK_VER), glibc_riscv64)
FFMPEG_ARCH = riscv64
ifeq ($(findstring thead-c906,$(OPT_LEVEL)),thead-c906)
GCC_TARGET_CPU = thead-c906
else
GCC_TARGET_CPU = c906fdv
endif
else ifeq ($(SDK_VER), musl_riscv64)
FFMPEG_ARCH = riscv64
ifeq ($(findstring thead-c906,$(OPT_LEVEL)),thead-c906)
GCC_TARGET_CPU = thead-c906
else
GCC_TARGET_CPU = c906fdv
endif
else
$(error $(red)SDK_VER is invalid$(reset))
endif

FFMPEG_CFLAGS = $(filter-out -std=gnu11, $(SDK_TARGET_CFLAGS)) -g0 -I$(BUILDDIR)/zlib/output/usr/local/include -L$(BUILDDIR)/zlib/output/usr/local/lib -I$(BUILDDIR)/openssl3.0/output/usr/local/include -L$(BUILDDIR)/openssl3.0/output/usr/local/lib
FFMPEG_CXXFLAGS = $(filter-out -std=gnu++11, $(SDK_TARGET_CXXFLAGS)) -g0 -I$(BUILDDIR)/zlib/output/usr/local/include -L$(BUILDDIR)/zlib/output/usr/local/lib -I$(BUILDDIR)/openssl3.0/output/usr/local/include -L$(BUILDDIR)/openssl3.0/output/usr/local/lib

FFMPEG_CMAKE_ENV = \
	CROSS_COMPILE=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX) \
	CC=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)gcc CFLAGS="$(FFMPEG_CFLAGS)" \
	CXX=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)g++ CXXFLAGS="$(FFMPEG_CXXFLAGS)" \
	LDFLAGS="$(FFMPEG_CFLAGS)"

FFMPEG_CONF_OPTS = \
	--enable-cross-compile \
	--cross-prefix=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX) \
	--sysroot=$(SYSROOT) \
	--arch="$(FFMPEG_ARCH)" \
	--target-os="linux" \
	--disable-stripping \
	--enable-debug=0 \
	--enable-static \
	--enable-shared \
	--prefix=/usr/local \
	--enable-avfilter \
	--disable-version3 \
	--enable-logging \
	--enable-optimizations \
	--disable-extra-warnings \
	--enable-avdevice \
	--enable-avcodec \
	--enable-avformat \
	--enable-network \
	--disable-gray \
	--enable-swscale-alpha \
	--disable-small \
	--disable-crystalhd \
	--disable-dxva2 \
	--enable-runtime-cpudetect \
	--disable-hardcoded-tables \
	--disable-mipsdsp \
	--disable-mipsdspr2 \
	--disable-msa \
	--enable-hwaccels \
	--disable-cuda \
	--disable-cuvid \
	--disable-nvenc \
	--disable-avisynth \
	--disable-frei0r \
	--disable-libopencore-amrnb \
	--disable-libopencore-amrwb \
	--disable-libdc1394 \
	--disable-libgsm \
	--disable-libilbc \
	--disable-libvo-amrwbenc \
	--disable-symver \
	--enable-doc \
	--enable-manpages \
	--disable-htmlpages \
	--disable-podpages \
	--disable-txtpages \
	--enable-gpl \
	--enable-nonfree \
	--enable-ffmpeg \
	--disable-ffplay \
	--disable-libv4l2 \
	--enable-ffprobe \
	--disable-libxcb \
	--disable-postproc \
	--enable-swscale \
	--enable-indevs \
	--disable-alsa \
	--enable-outdevs \
	--enable-pthreads \
	--enable-zlib \
	--disable-bzlib \
	--disable-libfdk-aac \
	--disable-libcdio \
	--disable-gnutls \
	--enable-openssl \
	--disable-libdrm \
	--disable-libopenh264 \
	--disable-vaapi \
	--disable-vdpau \
	--disable-mmal \
	--disable-omx \
	--disable-omx-rpi \
	--disable-libopencv \
	--disable-libopus \
	--disable-libvpx \
	--disable-libass \
	--disable-libbluray \
	--disable-libmfx \
	--disable-librtmp \
	--disable-libmp3lame \
	--disable-libmodplug \
	--disable-libspeex \
	--disable-libtheora \
	--disable-iconv \
	--disable-libfreetype \
	--disable-fontconfig \
	--disable-libopenjpeg \
	--disable-libx264 \
	--disable-libx265 \
	--disable-libdav1d \
	--disable-x86asm \
	--disable-mmx \
	--disable-sse \
	--disable-sse2 \
	--disable-sse3 \
	--disable-ssse3 \
	--disable-sse4 \
	--disable-sse42 \
	--disable-avx \
	--disable-avx2 \
	--disable-armv6 \
	--disable-armv6t2

ifeq ($(FFMPEG_GIT_BRANCH),3rd)
FFMPEG_CONF_OPTS += \
	--enable-dct \
	--enable-fft \
	--enable-mdct \
	--enable-rdft \
	--disable-avresample \
	--disable-libwavpack
endif

ifeq ($(FFMPEG_ARM_CPU_HAS_VFPV2),y)
FFMPEG_CONF_OPTS += --enable-vfp
else
FFMPEG_CONF_OPTS += --disable-vfp
endif
ifeq ($(FFMPEG_ARM_CPU_HAS_NEON),y)
FFMPEG_CONF_OPTS += --enable-neon
else ifeq ($(FFMPEG_ARCH),aarch64)
FFMPEG_CONF_OPTS += --enable-neon
else
FFMPEG_CONF_OPTS += --disable-neon
endif

FFMPEG_CONF_OPTS += \
	--disable-altivec \
	--extra-libs=-latomic \
	--enable-pic \
	--cpu="$(GCC_TARGET_CPU)"

$(BUILDDIR)/ffmpeg-prepare-stamp:
	@mkdir -p $(BUILDDIR)/ffmpeg/
	@cd $(BUILDDIR)/ffmpeg/ && git clone $(GIT_CLONE_OPTS) -b $(FFMPEG_GIT_BRANCH) $(GIT_USER_URL)/ffmpeg
	@cd $(BUILDDIR)/ffmpeg/ffmpeg/ && git checkout $(FFMPEG_GIT_REF)
	@touch $@

#$(BUILDDIR)/opencv-stamp
$(BUILDDIR)/ffmpeg-stamp: $(BUILDDIR)/ffmpeg-prepare-stamp $(BUILDDIR)/openssl-stamp
	@mkdir -p $(SDK_OSS_TARBALL_DIR)
	@mkdir -p $(BUILDDIR)/ffmpeg/output
	@cd $(BUILDDIR)/ffmpeg/ffmpeg ; sed -i s/'std=c11'/'std=gnu11'/g ./configure
	@cd $(BUILDDIR)/ffmpeg/ffmpeg ; $(FFMPEG_CMAKE_ENV) DESTDIR=$(BUILDDIR)/ffmpeg/output ./configure $(FFMPEG_CONF_OPTS)
	@cd $(BUILDDIR)/ffmpeg/ffmpeg ; $(FFMPEG_CMAKE_ENV) DESTDIR=$(BUILDDIR)/ffmpeg/output make ARCH=$(FFMPEG_ARCH) install
	@tar -C $(BUILDDIR)/ffmpeg/output/usr/local -czf $(SDK_OSS_TARBALL_DIR)/ffmpeg.tar.gz bin include lib share
	@touch $@

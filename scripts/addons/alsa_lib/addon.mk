SHELL = /bin/bash

ALSA_LIB_GIT_REF = 785fd327ada6fc1778a2bb21176cb66705eb6b33

ALSA_LIB_CONF_ENV = \
	CROSS_COMPILE=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX) \
	CC=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)gcc CFLAGS="$(ALSA_LIB_CFLAGS)" \
	CXX=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)g++ CXXFLAGS="$(ALSA_LIB_CXXFLAGS)" \
	LDFLAGS="$(ALSA_LIB_CFLAGS) -lm"

ALSA_LIB_PREFIX=/usr

ifeq ($(SDK_VER), 32bit)
ALSA_LIB_TARGET = arm-linux-gnueabihf
else ifeq ($(SDK_VER), 64bit)
ALSA_LIB_TARGET = aarch64-linux-gnu
else ifeq ($(SDK_VER), glibc_riscv64)
ALSA_LIB_TARGET = riscv64-unknown-linux-gnu
else ifeq ($(SDK_VER), musl_riscv64)
ALSA_LIB_TARGET = riscv64-unknown-linux-musl
else
$(error $(red)SDK_VER is invalid$(reset))
endif

ALSA_LIB_CONF_OPTS = \
	--enable-cross-compile \
	--target=$(ALSA_LIB_TARGET) \
	--host=$(ALSA_LIB_TARGET)

ALSA_LIB_CONF_OPTS += \
	--with-alsa-devdir="/dev/snd" \
	--with-pcm-plugins="all" \
	--with-ctl-plugins="all"

ALSA_LIB_CONF_OPTS += --enable-static=no

ALSA_LIB_CONF_OPTS += --disable-python

$(BUILDDIR)/alsa_lib-prepare-stamp:
	@mkdir -p $(BUILDDIR)/alsa_lib/
	@cd $(BUILDDIR)/alsa_lib/ && git clone $(GIT_CLONE_OPTS) -b 3rd $(GIT_USER_URL)/alsa-lib alsa_lib
	@cd $(BUILDDIR)/alsa_lib/alsa_lib/ && git checkout $(ALSA_LIB_GIT_REF)
	@touch $@

$(BUILDDIR)/alsa_lib-stamp: $(BUILDDIR)/alsa_lib-prepare-stamp
	@mkdir -p $(SDK_OSS_TARBALL_DIR)
	@mkdir -p $(BUILDDIR)/alsa_lib/output
	@cd $(BUILDDIR)/alsa_lib/alsa_lib ; $(ALSA_LIB_CONF_ENV) autoreconf -fi
	@#cd $(BUILDDIR)/alsa_lib/alsa_lib ; sed -i s/'std=c11'/'std=gnu11'/g ./configure
	@cd $(BUILDDIR)/alsa_lib/alsa_lib ; $(ALSA_LIB_CONF_ENV) DESTDIR=$(BUILDDIR)/alsa_lib/output ./configure $(ALSA_LIB_CONF_OPTS)
	@cd $(BUILDDIR)/alsa_lib/alsa_lib ; $(ALSA_LIB_CONF_ENV) DESTDIR=$(BUILDDIR)/alsa_lib/output make ARCH=$(ALSA_LIB_ARCH) install
	@tar -C $(BUILDDIR)/alsa_lib/output$(ALSA_LIB_PREFIX) -czf $(SDK_OSS_TARBALL_DIR)/alsa_lib.tar.gz include lib share
	@touch $@

SHELL = /bin/bash

SED ?= $(shell which sed || type -p sed) -i -e

OPENSSL_3_0_GIT_REF = c3cc0f1386b0544383a61244a4beeb762b67498f

ifeq ($(SDK_VER), 32bit)
OPENSSL_3_0_TARGET_ARCH = linux-armv4
else ifeq ($(SDK_VER), 64bit)
OPENSSL_3_0_TARGET_ARCH = linux-aarch64
else ifeq ($(SDK_VER), glibc_riscv64)
OPENSSL_3_0_TARGET_ARCH = linux64-riscv64
else ifeq ($(SDK_VER), musl_riscv64)
OPENSSL_3_0_TARGET_ARCH = linux64-riscv64
else
$(error $(red)SDK_VER is invalid$(reset))
endif

OPENSSL_3_0_CFLAGS = $(SDK_TARGET_CFLAGS) -g0

ifeq ($(SDK_VER), musl_riscv64)
OPENSSL_3_0_CFLAGS += -DOPENSSL_NO_ASYNC
endif

OPENSSL_3_0_CFLAGS += -I$(BUILDDIR)/zlib/output/usr/local/include -L$(BUILDDIR)/zlib/output/usr/local/lib

OPENSSL_3_0_CMAKE_ENV = \
	CROSS_COMPILE=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)

OPENSSL_3_0_BUILD_DIR = $(BUILDDIR)/openssl3.0/openssl

$(BUILDDIR)/openssl-prepare-stamp:
	@mkdir -p $(BUILDDIR)/openssl3.0/
	@cd $(BUILDDIR)/openssl3.0/ && git clone $(GIT_CLONE_OPTS) -b 3rd-3.0 $(GIT_USER_URL)/openssl
	@cd $(BUILDDIR)/openssl3.0/openssl/ && git checkout $(OPENSSL_3_0_GIT_REF)
	@#cd $(BUILDDIR)/openssl3.0/openssl && git submodule set-url boringssl $(GIT_USER_URL)/boringssl
	@cd $(BUILDDIR)/openssl3.0/openssl && git submodule set-url krb5 $(GIT_USER_URL)/krb5
	@cd $(BUILDDIR)/openssl3.0/openssl && git submodule set-url pyca-cryptography $(GIT_USER_URL)/pyca-cryptography
	@cd $(BUILDDIR)/openssl3.0/openssl && git submodule set-url gost-engine $(GIT_USER_URL)/gost-engine
	@cd $(BUILDDIR)/openssl3.0/openssl && git submodule set-url wycheproof $(GIT_USER_URL)/wycheproof
	@cd $(BUILDDIR)/openssl3.0/openssl && git submodule update --init --depth=1
	@touch $@

$(BUILDDIR)/openssl-stamp: $(BUILDDIR)/openssl-prepare-stamp $(BUILDDIR)/zlib-stamp
	@mkdir -p $(SDK_OSS_TARBALL_DIR)
	@mkdir -p $(BUILDDIR)/openssl3.0/output
	(cd $(OPENSSL_3_0_BUILD_DIR); \
		$(OPENSSL_3_0_CMAKE_ENV) \
		DESTDIR=$(BUILDDIR)/openssl3.0/output \
		./Configure \
			$(OPENSSL_3_0_TARGET_ARCH) \
			--prefix=/usr/local \
			--openssldir=/usr/local/ssl \
			-latomic \
			-lpthread threads \
			shared \
			no-rc5 \
			enable-camellia \
			no-tests \
			no-fuzz-libfuzzer \
			no-fuzz-afl \
			no-afalgeng \
			zlib-dynamic \
	)
	$(SED) "s#-march=[-a-z0-9] ##" -e "s#-mcpu=[-a-z0-9] ##g" $(OPENSSL_3_0_BUILD_DIR)/Makefile
	$(SED) "s#-O[0-9sg]#$(OPENSSL_3_0_CFLAGS)#" $(OPENSSL_3_0_BUILD_DIR)/Makefile
	$(SED) "s# build_tests##" $(OPENSSL_3_0_BUILD_DIR)/Makefile
	@cd $(OPENSSL_3_0_BUILD_DIR) ; $(OPENSSL_3_0_CMAKE_ENV) make DESTDIR=$(BUILDDIR)/openssl3.0/output install
	@tar -C $(BUILDDIR)/openssl3.0/output/usr/local -czf $(SDK_OSS_TARBALL_DIR)/openssl3.0.tar.gz bin include lib share ssl
	@touch $@

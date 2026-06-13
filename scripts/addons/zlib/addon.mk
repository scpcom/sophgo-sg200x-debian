SHELL = /bin/bash

ZLIB_GIT_REF = 071f069df44826d48215d5184a7a407fdc1a267a

ZLIB_CMAKE_ENV = \
	CROSS_COMPILE=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX) \
	CC=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)gcc CFLAGS="$(SDK_TARGET_CFLAGS) -g0" \
	CXX=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)g++ CXXFLAGS="$(SDK_TARGET_CXXFLAGS) -g0"

$(BUILDDIR)/zlib-prepare-stamp:
	@mkdir -p $(BUILDDIR)/zlib/
	@cd $(BUILDDIR)/zlib/ && git clone $(GIT_CLONE_OPTS) -b 3rd $(GIT_USER_URL)/zlib
	@cd $(BUILDDIR)/zlib/zlib/ && git checkout $(ZLIB_GIT_REF)
	@touch $@

$(BUILDDIR)/zlib-stamp: $(BUILDDIR)/zlib-prepare-stamp
	@mkdir -p $(SDK_OSS_TARBALL_DIR)
	@mkdir -p $(BUILDDIR)/zlib/output
	@cd $(BUILDDIR)/zlib/zlib ; $(ZLIB_CMAKE_ENV) DESTDIR=$(BUILDDIR)/zlib/output ./configure
	@cd $(BUILDDIR)/zlib/zlib ; $(ZLIB_CMAKE_ENV) DESTDIR=$(BUILDDIR)/zlib/output make install
	@tar -C $(BUILDDIR)/zlib/output/usr/local -czf $(SDK_OSS_TARBALL_DIR)/zlib.tar.gz include lib share
	@touch $@

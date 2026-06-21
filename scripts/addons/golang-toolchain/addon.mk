ifneq ("$(findstring golang-toolchain,$(IMAGE_ADDITIONS))","")
BSPFILTER += "golang-toolchain"
endif

GOLANG_TOOLCHAIN_XDG_HOME_DIR = $(BUILDDIR)/golang-toolchain
GOLANG_TOOLCHAIN_XDG_CACHE_DIR = $(GOLANG_TOOLCHAIN_XDG_HOME_DIR)/.cache
GOLANG_TOOLCHAIN_XDG_CONFIG_DIR = $(GOLANG_TOOLCHAIN_XDG_HOME_DIR)/.config
GOLANG_TOOLCHAIN_XDG_DATA_DIR = $(GOLANG_TOOLCHAIN_XDG_HOME_DIR)/.local/share

GOLANG_HOST_ARCH ?= amd64
GOLANG_TOOLCHAIN_URL ?= $(shell echo $(TOOLCHAIN_URL) | sed 's|/arm/.*|/golang.org|g' | sed 's|/linaro/.*|/golang.org|g')

ifeq ($(GOLANG_HOST_ARCH),riscv64)
GOLANG_TOOLCHAIN_SHA256 = 82cfe15a11d65090cdcdfec6e1ebb54cc89398c1059d9948f483c378bb0864de
else ifeq ($(GOLANG_HOST_ARCH),arm64)
GOLANG_TOOLCHAIN_SHA256 = 46bb31df41009439c8333aa223dacde912c8fa7cf6dd0ab338e5efa17b790471
else
GOLANG_TOOLCHAIN_SHA256 = 39ad33636fa17d737bac55a2971239ce8bc0c9e5fb600012a630c3875813a767
endif
GOLANG_TOOLCHAIN_VERSION = 1.24.0

GOLANG_TOOLCHAIN_CACHE = $(GOLANG_TOOLCHAIN_XDG_HOME_DIR)/go/pkg/mod/cache/download
GOLANG_TOOLCHAIN_DL_DIR = $(BUILDDIR)/golang-toolchain
GOLANG_TOOLCHAIN_FILE = v0.0.1-go$(GOLANG_TOOLCHAIN_VERSION).linux-$(GOLANG_HOST_ARCH)

ifeq ($(DEB_ARCH),arm64)
GOLANG_TARGET_ARCH ?= arm64
else
GOLANG_TARGET_ARCH ?= arm
endif

GOLANG_TOOLCHAIN_GO_ENV = \
	GOCACHE=$(GOLANG_TOOLCHAIN_XDG_CACHE_DIR)/go-build \
	GOENV=$(GOLANG_TOOLCHAIN_XDG_CONFIG_DIR)/go/env \
	GOMODCACHE=$(GOLANG_TOOLCHAIN_XDG_HOME_DIR)/go/pkg/mod \
	GOPATH=$(GOLANG_TOOLCHAIN_XDG_HOME_DIR)/go

$(BUILDDIR)/golang-toolchain-stamp:
	@if [ "X$(GOLANG_TOOLCHAIN_URL)" != "X" ]; then \
		mkdir -p $(GOLANG_TOOLCHAIN_DL_DIR) && \
		cd $(GOLANG_TOOLCHAIN_DL_DIR) && \
		wget -N $(GOLANG_TOOLCHAIN_URL)/toolchain/@v/$(GOLANG_TOOLCHAIN_FILE).zip || \
		rm -f $(GOLANG_TOOLCHAIN_FILE).zip ; \
	fi
	@if [ -e $(GOLANG_TOOLCHAIN_DL_DIR)/$(GOLANG_TOOLCHAIN_FILE).zip ]; then \
		cd $(GOLANG_TOOLCHAIN_DL_DIR) && \
		if [ "`sha256sum "$(GOLANG_TOOLCHAIN_FILE).zip" | cut -d ' ' -f 1`" != "$(GOLANG_TOOLCHAIN_SHA256)" ]; then \
			echo "$(GOLANG_TOOLCHAIN_FILE).zip: checksum mismatch!" ; \
			rm -f $(GOLANG_TOOLCHAIN_FILE).zip ; \
		fi ; \
	fi
	@if [ -e $(GOLANG_TOOLCHAIN_DL_DIR)/$(GOLANG_TOOLCHAIN_FILE).zip ]; then \
		cd $(GOLANG_TOOLCHAIN_DL_DIR) && \
		mkdir -p $(GOLANG_TOOLCHAIN_CACHE)/golang.org/toolchain/\@v && \
		cp $(GOLANG_TOOLCHAIN_FILE).zip $(GOLANG_TOOLCHAIN_CACHE)/golang.org/toolchain/\@v/ && \
		touch $(GOLANG_TOOLCHAIN_CACHE)/$(GOLANG_TOOLCHAIN_FILE).lock && \
		wget -N $(GOLANG_TOOLCHAIN_URL)/toolchain/@v/$(GOLANG_TOOLCHAIN_FILE)-sumdb.zip || \
		rm -f $(GOLANG_TOOLCHAIN_FILE)-sumdb.zip ; \
	fi
	@if [ -e $(GOLANG_TOOLCHAIN_DL_DIR)/$(GOLANG_TOOLCHAIN_FILE)-sumdb.zip -a \
	    ! -e $(GOLANG_TOOLCHAIN_CACHE)/sumdb/sum.golang.org ]; then \
		cd $(GOLANG_TOOLCHAIN_DL_DIR) && \
		mkdir -p $(GOLANG_TOOLCHAIN_CACHE)/sumdb/sum.golang.org && \
		unzip -d $(GOLANG_TOOLCHAIN_CACHE)/sumdb/sum.golang.org $(GOLANG_TOOLCHAIN_FILE)-sumdb.zip lookup/golang.org/toolchain\@$(GOLANG_TOOLCHAIN_FILE) 'tile/*' ; \
	fi
	@touch $@

ifneq ("$(findstring libwebsockets,$(IMAGE_ADDITIONS))","")
BSPFILTER += "libwebsockets"
endif

LIBWEBSOCKETS_VERSION = 4.0.20
LIBWEBSOCKETS_BUILD = 2ubuntu1

LIBWEBSOCKETS_BASE_URL = https://ports.ubuntu.com/ubuntu-ports/pool/universe/libw/libwebsockets

LIBWEBSOCKETS_DL_DIR = $(BUILDDIR)/libwebsockets

$(BUILDDIR)/libwebsockets-prepare-stamp:
	@mkdir -p $(LIBWEBSOCKETS_DL_DIR)
	@cd $(LIBWEBSOCKETS_DL_DIR) && wget -N $(LIBWEBSOCKETS_BASE_URL)/libwebsockets_$(LIBWEBSOCKETS_VERSION)-$(LIBWEBSOCKETS_BUILD).debian.tar.xz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libwebsockets_$(LIBWEBSOCKETS_VERSION)-$(LIBWEBSOCKETS_BUILD).debian.tar.xz
	@cd $(LIBWEBSOCKETS_DL_DIR) && wget -N $(LIBWEBSOCKETS_BASE_URL)/libwebsockets_$(LIBWEBSOCKETS_VERSION)-$(LIBWEBSOCKETS_BUILD).dsc || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libwebsockets_$(LIBWEBSOCKETS_VERSION)-$(LIBWEBSOCKETS_BUILD).dsc
	@cd $(LIBWEBSOCKETS_DL_DIR) && wget -N $(LIBWEBSOCKETS_BASE_URL)/libwebsockets_$(LIBWEBSOCKETS_VERSION).orig.tar.gz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libwebsockets_$(LIBWEBSOCKETS_VERSION).orig.tar.gz
	@mkdir /rootfs/root/source-websockets && \
		cp -p $(LIBWEBSOCKETS_DL_DIR)/libwebsockets_* /rootfs/root/source-websockets/ && \
		cp /configs/chip/ax620e/patches/libwebsockets/0001-openssl-server-enum-vs-int-disagreement.patch /rootfs/root/source-websockets/ && \
		echo OK
	@cd /rootfs/root/source-websockets/ && \
		tar xzf libwebsockets_$(LIBWEBSOCKETS_VERSION).orig.tar.gz && \
		cd libwebsockets-$(LIBWEBSOCKETS_VERSION)/ && \
		tar xJf ../libwebsockets_$(LIBWEBSOCKETS_VERSION)-$(LIBWEBSOCKETS_BUILD).debian.tar.xz && \
		cp -p ../0001-openssl-server-enum-vs-int-disagreement.patch debian/patches/ && \
		echo "0001-openssl-server-enum-vs-int-disagreement.patch" >> debian/patches/series && \
		echo OK
	@touch $@

$(BUILDDIR)/libwebsockets-stamp: $(BUILDDIR)/libwebsockets-prepare-stamp
	@#chroot /rootfs apt-get update || true
	@chroot /rootfs apt-get install -y cmake debhelper libcap-dev libev-dev libssl-dev libuv1-dev openssl zlib1g-dev
	@chroot /rootfs bash -c 'cd /root/source-websockets/libwebsockets-$(LIBWEBSOCKETS_VERSION)/ && dpkg-buildpackage'
	@rm -rf /rootfs/root/source-websockets/libwebsockets-$(LIBWEBSOCKETS_VERSION)/
	@cp -p /rootfs/root/source-websockets/libwebsockets16_$(LIBWEBSOCKETS_VERSION)-$(LIBWEBSOCKETS_BUILD)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp -p /rootfs/root/source-websockets/libwebsockets16_$(LIBWEBSOCKETS_VERSION)-$(LIBWEBSOCKETS_BUILD)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf /rootfs/root/source-websockets/
	@touch $@

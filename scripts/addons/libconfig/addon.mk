ifneq ("$(findstring libconfig,$(IMAGE_ADDITIONS))","")
BSPFILTER += "libconfig"
DEV_PACKAGES += " texinfo"
endif

LIBCONFIG_VERSION = 1.5
LIBCONFIG_BUILD = 0.4build1

LIBCONFIG_BASE_URL = https://ports.ubuntu.com/ubuntu-ports/pool/universe/libc/libconfig

LIBCONFIG_DL_DIR = $(BUILDDIR)/libconfig

$(BUILDDIR)/libconfig-prepare-stamp:
	@mkdir -p $(LIBCONFIG_DL_DIR)
	@cd $(LIBCONFIG_DL_DIR) && wget -N $(LIBCONFIG_BASE_URL)/libconfig_$(LIBCONFIG_VERSION)-$(LIBCONFIG_BUILD).debian.tar.xz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libconfig_$(LIBCONFIG_VERSION)-$(LIBCONFIG_BUILD).debian.tar.xz
	@cd $(LIBCONFIG_DL_DIR) && wget -N $(LIBCONFIG_BASE_URL)/libconfig_$(LIBCONFIG_VERSION)-$(LIBCONFIG_BUILD).dsc || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libconfig_$(LIBCONFIG_VERSION)-$(LIBCONFIG_BUILD).dsc
	@cd $(LIBCONFIG_DL_DIR) && wget -N $(LIBCONFIG_BASE_URL)/libconfig_$(LIBCONFIG_VERSION).orig.tar.gz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libconfig_$(LIBCONFIG_VERSION).orig.tar.gz
	@mkdir /rootfs/root/source-libconfig && \
		cp -p $(LIBCONFIG_DL_DIR)/libconfig_* /rootfs/root/source-libconfig/ && \
		echo OK
	@cd /rootfs/root/source-libconfig/ && \
		tar xzf libconfig_$(LIBCONFIG_VERSION).orig.tar.gz && \
		cd libconfig-$(LIBCONFIG_VERSION)/ && \
		tar xJf ../libconfig_$(LIBCONFIG_VERSION)-$(LIBCONFIG_BUILD).debian.tar.xz && \
		rm -f debian/libconfig*-dev.docs && \
		rm -f debian/libconfig-doc.doc-base && \
		rm -f debian/libconfig-doc.docs && \
		rm -f debian/libconfig9.info && \
		sed -i /'^Build-Depends-Indep:'/d debian/control && \
		sed -i /'.(MAKE) -C doc pdf'/d debian/rules && \
		echo OK
	@touch $@

$(BUILDDIR)/libconfig-stamp: $(BUILDDIR)/libconfig-prepare-stamp
	@#chroot /rootfs apt-get update || true
	@chroot /rootfs apt-get install -y debhelper texinfo
	@chroot /rootfs bash -c 'cd /root/source-libconfig/libconfig-$(LIBCONFIG_VERSION)/ && dpkg-buildpackage'
	@rm -rf /rootfs/root/source-libconfig/libconfig-$(LIBCONFIG_VERSION)/
	@cp -p /rootfs/root/source-libconfig/libconfig9_$(LIBCONFIG_VERSION)-$(LIBCONFIG_BUILD)_$(DEB_ARCH).deb /output/
	@cp -p /rootfs/root/source-libconfig/libconfig-dev_$(LIBCONFIG_VERSION)-$(LIBCONFIG_BUILD)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp -p /rootfs/root/source-libconfig/libconfig9_$(LIBCONFIG_VERSION)-$(LIBCONFIG_BUILD)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf /rootfs/root/source-libconfig/
	@touch $@

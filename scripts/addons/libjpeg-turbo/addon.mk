ifneq ("$(findstring libjpeg-turbo,$(IMAGE_ADDITIONS))","")
BSPFILTER += "libjpeg-turbo"
DEV_PACKAGES += " dh-autoreconf chrpath"
endif

LIBJPEG_TURBO_VERSION = 2.1.2
LIBJPEG_TURBO_BUILD = 0ubuntu1

LIBJPEG_TURBO_BASE_URL = https://ports.ubuntu.com/ubuntu-ports/pool/main/libj/libjpeg-turbo

LIBJPEG_TURBO_DL_DIR = $(BUILDDIR)/libjpeg-turbo

$(BUILDDIR)/libjpeg-turbo-prepare-stamp:
	@mkdir -p $(LIBJPEG_TURBO_DL_DIR)
	@cd $(LIBJPEG_TURBO_DL_DIR) && wget -N $(LIBJPEG_TURBO_BASE_URL)/libjpeg-turbo_$(LIBJPEG_TURBO_VERSION)-$(LIBJPEG_TURBO_BUILD).debian.tar.xz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libjpeg-turbo_$(LIBJPEG_TURBO_VERSION)-$(LIBJPEG_TURBO_BUILD).debian.tar.xz
	@cd $(LIBJPEG_TURBO_DL_DIR) && wget -N $(LIBJPEG_TURBO_BASE_URL)/libjpeg-turbo_$(LIBJPEG_TURBO_VERSION)-$(LIBJPEG_TURBO_BUILD).dsc || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libjpeg-turbo_$(LIBJPEG_TURBO_VERSION)-$(LIBJPEG_TURBO_BUILD).dsc
	@cd $(LIBJPEG_TURBO_DL_DIR) && wget -N $(LIBJPEG_TURBO_BASE_URL)/libjpeg-turbo_$(LIBJPEG_TURBO_VERSION).orig.tar.gz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libjpeg-turbo_$(LIBJPEG_TURBO_VERSION).orig.tar.gz
	@mkdir /rootfs/root/source-libjpeg-turbo && \
		cp -p $(LIBJPEG_TURBO_DL_DIR)/libjpeg-turbo_* /rootfs/root/source-libjpeg-turbo/ && \
		echo OK
	@cd /rootfs/root/source-libjpeg-turbo/ && \
		tar xzf libjpeg-turbo_$(LIBJPEG_TURBO_VERSION).orig.tar.gz && \
		cd libjpeg-turbo-$(LIBJPEG_TURBO_VERSION)/ && \
		tar xJf ../libjpeg-turbo_$(LIBJPEG_TURBO_VERSION)-$(LIBJPEG_TURBO_BUILD).debian.tar.xz && \
		sed -i s/'default-jdk, '/''/g debian/control && \
		sed -i s/' -DWITH_JAVA=1'/''/g debian/rules && \
		echo OK
	@touch $@

$(BUILDDIR)/libjpeg-turbo-stamp: $(BUILDDIR)/libjpeg-turbo-prepare-stamp
	@#chroot /rootfs apt-get update || true
	@chroot /rootfs apt-get install -y cmake debhelper dh-autoreconf chrpath
	@chroot /rootfs bash -c 'cd /root/source-libjpeg-turbo/libjpeg-turbo-$(LIBJPEG_TURBO_VERSION)/ && dpkg-buildpackage'
	@rm -rf /rootfs/root/source-libjpeg-turbo/libjpeg-turbo-$(LIBJPEG_TURBO_VERSION)/
	@cp -p /rootfs/root/source-libjpeg-turbo/libjpeg-turbo8_$(LIBJPEG_TURBO_VERSION)-$(LIBJPEG_TURBO_BUILD)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp -p /rootfs/root/source-libjpeg-turbo/libjpeg-turbo8_$(LIBJPEG_TURBO_VERSION)-$(LIBJPEG_TURBO_BUILD)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf /rootfs/root/source-libjpeg-turbo/
	@touch $@

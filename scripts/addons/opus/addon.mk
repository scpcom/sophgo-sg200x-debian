ifneq ("$(findstring opus,$(IMAGE_ADDITIONS))","")
BSPFILTER += "opus"
DEV_PACKAGES += " doxygen graphviz"
endif

OPUS_VERSION = 1.3.1
OPUS_BUILD = 0.1build2

OPUS_BASE_URL = https://ports.ubuntu.com/ubuntu-ports/pool/main/o/opus

OPUS_DL_DIR = $(BUILDDIR)/opus

$(BUILDDIR)/opus-prepare-stamp:
	@mkdir -p $(OPUS_DL_DIR)
	@cd $(OPUS_DL_DIR) && wget -N $(OPUS_BASE_URL)/opus_$(OPUS_VERSION)-$(OPUS_BUILD).diff.gz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/opus_$(OPUS_VERSION)-$(OPUS_BUILD).diff.gz
	@cd $(OPUS_DL_DIR) && wget -N $(OPUS_BASE_URL)/opus_$(OPUS_VERSION)-$(OPUS_BUILD).dsc || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/opus_$(OPUS_VERSION)-$(OPUS_BUILD).dsc
	@cd $(OPUS_DL_DIR) && wget -N $(OPUS_BASE_URL)/opus_$(OPUS_VERSION).orig.tar.gz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/opus_$(OPUS_VERSION).orig.tar.gz
	@mkdir /rootfs/root/source-opus && \
		cp -p $(OPUS_DL_DIR)/opus_* /rootfs/root/source-opus/ && \
		echo OK
	@cd /rootfs/root/source-opus/ && \
		tar xzf opus_$(OPUS_VERSION).orig.tar.gz && \
		cd opus-$(OPUS_VERSION)/ && \
		gzip -cd ../opus_$(OPUS_VERSION)-$(OPUS_BUILD).diff.gz | patch -p1 && \
		echo OK
	@touch $@

ifeq ($(NANOKVM_PRO_DEBS_FROM_SOURCE),y)
$(BUILDDIR)/opus-stamp: $(BUILDDIR)/opus-prepare-stamp
	@#chroot /rootfs apt-get update || true
	@chroot /rootfs apt-get install -y debhelper doxygen graphviz
	@chroot /rootfs bash -c 'cd /root/source-opus/opus-$(OPUS_VERSION)/ && dpkg-buildpackage'
	@rm -rf /rootfs/root/source-opus/opus-$(OPUS_VERSION)/
	@cp -p /rootfs/root/source-opus/libopus0_$(OPUS_VERSION)-$(OPUS_BUILD)_$(DEB_ARCH).deb /output/
	@cp -p /rootfs/root/source-opus/libopus-dev_$(OPUS_VERSION)-$(OPUS_BUILD)_$(DEB_ARCH).deb /output/
	@#mkdir -p /rootfs/tmp/install/
	@#cp -p /rootfs/root/source-opus/libopus0_$(OPUS_VERSION)-$(OPUS_BUILD)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@#rm -rf /rootfs/root/source-opus/
	@touch $@
else
$(BUILDDIR)/opus-stamp:
	@cd /output/ ; wget -N https://launchpadlibrarian.net/592830919/libopus0_$(OPUS_VERSION)-$(OPUS_BUILD)_$(DEB_ARCH).deb || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libopus0_$(OPUS_VERSION)-$(OPUS_BUILD)_$(DEB_ARCH).deb
	@cd /output/ ; wget -N https://launchpadlibrarian.net/592830918/libopus-dev_$(OPUS_VERSION)-$(OPUS_BUILD)_$(DEB_ARCH).deb || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/libopus-dev_$(OPUS_VERSION)-$(OPUS_BUILD)_$(DEB_ARCH).deb
	@touch $@
endif

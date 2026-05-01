ifneq ("$(findstring ttyd,$(IMAGE_ADDITIONS))","")
BSPFILTER += "ttyd"
PACKAGES += " libjson-c-dev"
endif

TTYD_VERSION = 1.6.3+20210924
TTYD_BUILD = 1build1

TTYD_BASE_URL = https://ports.ubuntu.com/ubuntu-ports/pool/universe/t/ttyd

TTYD_DL_DIR = $(BUILDDIR)/ttyd

$(BUILDDIR)/ttyd-prepare-stamp:
	@mkdir -p $(TTYD_DL_DIR)
	@cd $(TTYD_DL_DIR) && wget -N $(TTYD_BASE_URL)/ttyd_$(TTYD_VERSION)-$(TTYD_BUILD).debian.tar.xz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/ttyd_$(TTYD_VERSION)-$(TTYD_BUILD).debian.tar.xz
	@cd $(TTYD_DL_DIR) && wget -N $(TTYD_BASE_URL)/ttyd_$(TTYD_VERSION)-$(TTYD_BUILD).dsc || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/ttyd_$(TTYD_VERSION)-$(TTYD_BUILD).dsc
	@cd $(TTYD_DL_DIR) && wget -N $(TTYD_BASE_URL)/ttyd_$(TTYD_VERSION).orig.tar.xz || wget -N $(USER_SITE_URL)/deb/pool/$(CHIP_FAMILY)/ttyd_$(TTYD_VERSION).orig.tar.xz
	@mkdir /rootfs/root/source-ttyd && \
		cp -p $(TTYD_DL_DIR)/ttyd_* /rootfs/root/source-ttyd/ && \
		echo OK
	@cd /rootfs/root/source-ttyd/ && \
		tar xJf ttyd_$(TTYD_VERSION).orig.tar.xz && \
		cd ttyd-$(TTYD_VERSION)/ && \
		tar xJf ../ttyd_$(TTYD_VERSION)-$(TTYD_BUILD).debian.tar.xz && \
		echo OK
	@touch $@

$(BUILDDIR)/ttyd-stamp: $(BUILDDIR)/ttyd-prepare-stamp
	@#chroot /rootfs apt-get update || true
	@chroot /rootfs apt-get install -y cmake debhelper libjson-c-dev libwebsockets-dev zlib1g-dev
	@chroot /rootfs bash -c 'cd /root/source-ttyd/ttyd-$(TTYD_VERSION)/ && dpkg-buildpackage'
	@rm -rf /rootfs/root/source-ttyd/ttyd-$(TTYD_VERSION)/
	@cp -p /rootfs/root/source-ttyd/ttyd_$(TTYD_VERSION)-$(TTYD_BUILD)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp -p /rootfs/root/source-ttyd/ttyd_$(TTYD_VERSION)-$(TTYD_BUILD)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf /rootfs/root/source-ttyd/
	@touch $@

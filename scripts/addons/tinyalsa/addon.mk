ifneq ("$(findstring tinyalsa,$(IMAGE_ADDITIONS))","")
BSPFILTER += "tinyalsa"
DEV_PACKAGES += " doxygen"
endif

TINYALSA_VERSION = 2.0.0
TINYALSA_BUILD = 1

TINYALSA_GIT_REF = e43025bbf702eb7dd8edd48c1eb50530c60f1de8

TINYALSA_BUILD_DIR = /rootfs/root/source-tinyalsa

$(BUILDDIR)/tinyalsa-prepare-stamp:
	@mkdir -p $(TINYALSA_BUILD_DIR)/
	@cd $(TINYALSA_BUILD_DIR)/ && git clone -b master $(GIT_USER_URL)/tinyalsa tinyalsa-$(TINYALSA_VERSION)
	@cd $(TINYALSA_BUILD_DIR)/tinyalsa-$(TINYALSA_VERSION)/ && git checkout $(TINYALSA_GIT_REF)
	@cd $(TINYALSA_BUILD_DIR)/tinyalsa-$(TINYALSA_VERSION)/ && \
		sed -i s/'tinyalsa ($(TINYALSA_VERSION))'/'tinyalsa ($(TINYALSA_VERSION)-$(TINYALSA_BUILD))'/g debian/changelog && \
		sed -i s/'Package: libtinyalsa$$'/'Package: libtinyalsa2'/g debian/control && \
		sed -i s/'libtinyalsa '/'libtinyalsa2 '/g debian/control && \
		sed -i s/'libtinyalsa,'/'libtinyalsa2,'/g debian/control && \
		mv debian/libtinyalsa.dirs.in debian/libtinyalsa2.dirs.in && \
		mv debian/libtinyalsa.install.in debian/libtinyalsa2.install.in && \
		echo OK
	@touch $@

$(BUILDDIR)/tinyalsa-stamp: $(BUILDDIR)/tinyalsa-prepare-stamp
	@#chroot /rootfs apt-get update || true
	@chroot /rootfs apt-get install -y debhelper doxygen # graphviz
	@chroot /rootfs bash -c 'cd /root/source-tinyalsa/tinyalsa-$(TINYALSA_VERSION)/ && dpkg-buildpackage'
	@rm -rf /rootfs/root/source-tinyalsa/tinyalsa-$(TINYALSA_VERSION)/
	@cp -p /rootfs/root/source-tinyalsa/libtinyalsa2_$(TINYALSA_VERSION)-$(TINYALSA_BUILD)_$(DEB_ARCH).deb /output/
	@cp -p /rootfs/root/source-tinyalsa/libtinyalsa-dev_$(TINYALSA_VERSION)-$(TINYALSA_BUILD)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp -p /rootfs/root/source-tinyalsa/libtinyalsa2_$(TINYALSA_VERSION)-$(TINYALSA_BUILD)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@cp -p /rootfs/root/source-tinyalsa/libtinyalsa-dev_$(TINYALSA_VERSION)-$(TINYALSA_BUILD)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf /rootfs/root/source-tinyalsa/
	@touch $@

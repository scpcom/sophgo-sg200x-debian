ifneq ("$(findstring pikvm,$(IMAGE_ADDITIONS))","")
BSPFILTER += "pikvm"
endif

PIKVM_PACKAGES_GIT_REF = d660118d169e96075c33fb7ab90e0bc492c4064e
PIKVM_JANUS_GATEWAY_GIT_REF = c1435cf670d422648edab7dd5f188f09f9df7fd5
PIKVM_USTREAMER_GIT_REF = de6fe0399bee4974d240e24f35560e2afb194d69
PIKVM_KVMD_GIT_REF = 8cc43887b430c5a982093afe3d14bd8b602c5fc2

PIKVM_DEPENDS = $(BUILDDIR)/nanokvm-pro-package-prepare-stamp $(BUILDDIR)/python3-dev-install-stamp $(BUILDDIR)/tinyalsa-stamp

ifneq ("$(findstring libgpiod,$(IMAGE_ADDITIONS))","")
PIKVM_DEPENDS += $(BUILDDIR)/libgpiod-stamp
endif

PIKVM_BUILD_DIR = /rootfs/root/pikvm

$(BUILDDIR)/pikvm-prepare-stamp: $(PIKVM_DEPENDS)
	@echo "$(COLOUR_GREEN)Cloning pikvm for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(PIKVM_BUILD_DIR)/
	@cd $(PIKVM_BUILD_DIR)/ && git clone -b nanokvmpro $(GIT_USER_URL)/pikvm-packages
	@cd $(PIKVM_BUILD_DIR)/ && git clone -b nanokvmpro $(GIT_USER_URL)/janus-gateway
	@cd $(PIKVM_BUILD_DIR)/ && git clone -b ax_video $(GIT_USER_URL)/ustreamer
	@cd $(PIKVM_BUILD_DIR)/ && git clone -b nanokvmpro $(GIT_USER_URL)/kvmd
	@cd $(PIKVM_BUILD_DIR)/pikvm-packages/ && git checkout $(PIKVM_PACKAGES_GIT_REF)
	@cd $(PIKVM_BUILD_DIR)/janus-gateway/ && git checkout $(PIKVM_JANUS_GATEWAY_GIT_REF)
	@cd $(PIKVM_BUILD_DIR)/ustreamer/ && git checkout $(PIKVM_USTREAMER_GIT_REF)
	@cd $(PIKVM_BUILD_DIR)/kvmd/ && git checkout $(PIKVM_KVMD_GIT_REF)
	@cp -a addons/pikvm/*-build.sh $(PIKVM_BUILD_DIR)/
	@touch $@

$(BUILDDIR)/pikvm-stamp: $(BUILDDIR)/middleware-package-stamp $(BUILDDIR)/pikvm-prepare-stamp
	@echo "$(COLOUR_GREEN)Building pikvm for $(BOARD)$(END_COLOUR)"
	@#chroot /rootfs apt-get update || true
	@chroot /rootfs mount proc -t proc /proc
	@mkdir -pv /rootfs/kvmapp/server/dl_lib/
	@#rsync -avpPxH $(NANOKVM_PRO_PACKAGE_DIR)/kvmapp/server/dl_lib/ /rootfs/kvmapp/server/dl_lib/
	@rsync -avpPxH $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/opt/include/ /rootfs/opt/include/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/$(CHIP_VENDOR)-middleware-$(BOARD)_*.deb /rootfs/tmp/install/
	@chroot /rootfs bash -c 'dpkg -i /tmp/install/$(CHIP_VENDOR)-middleware-$(BOARD)_*.deb'
	@[ "$(findstring libgpiod,$(IMAGE_ADDITIONS))" = "" ] || chroot /rootfs bash -c 'dpkg -i /tmp/install/libgpiod3_$(LIBGPIOD_VERSION)-$(LIBGPIOD_BUILD)_$(DEB_ARCH).deb'
	@[ "$(findstring libgpiod,$(IMAGE_ADDITIONS))" = "" ] || chroot /rootfs bash -c 'dpkg -i /tmp/install/libgpiod-dev_$(LIBGPIOD_VERSION)-$(LIBGPIOD_BUILD)_$(DEB_ARCH).deb'
	@[ "$(findstring libgpiod,$(IMAGE_ADDITIONS))" = "" ] || chroot /rootfs bash -c 'dpkg -i /tmp/install/gpiod_$(LIBGPIOD_VERSION)-$(LIBGPIOD_BUILD)_$(DEB_ARCH).deb'
	@[ "$(findstring libgpiod,$(IMAGE_ADDITIONS))" = "" -a "$(findstring maixcam2-python3,$(IMAGE_ADDITIONS))" = "" ] || chroot /rootfs pip install gpiod==$(LIBGPIOD_VERSION)
	@[ "$(findstring tinyalsa,$(IMAGE_ADDITIONS))" = "" ] || chroot /rootfs bash -c 'dpkg -i /tmp/install/libtinyalsa2_$(TINYALSA_VERSION)-$(TINYALSA_BUILD)_$(DEB_ARCH).deb'
	@[ "$(findstring tinyalsa,$(IMAGE_ADDITIONS))" = "" ] || chroot /rootfs bash -c 'dpkg -i /tmp/install/libtinyalsa-dev_$(TINYALSA_VERSION)-$(TINYALSA_BUILD)_$(DEB_ARCH).deb'
	@chroot /rootfs apt-get install -y libgpiod-dev
	@chroot /rootfs bash -c 'cd /root/pikvm/ && DEB_ARCH=$(DEB_ARCH) bash -e pikvm-build.sh'
	@umount /rootfs/proc || true
	@rm -rf $(PIKVM_BUILD_DIR)/janus-gateway/
	@rm -rf $(PIKVM_BUILD_DIR)/ustreamer/*/build $(PIKVM_BUILD_DIR)/ustreamer/out
	@rm -rf $(PIKVM_BUILD_DIR)/kvmd/
	@#rm -rf $(PIKVM_BUILD_DIR)/pikvm-packages/
	@touch $@

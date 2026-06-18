ifneq ("$(findstring overlayfs-tools,$(IMAGE_ADDITIONS))$(findstring overlayfs-tools,$(PACKAGES))","")
BSPDEPENDS += overlayfs-tools
BSPFILTER += "overlayfs-tools"
endif

OVERLAYFS_TOOLS_VERSION = 2025.01

$(BUILDDIR)/overlayfs-tools-stamp: $(BUILDDIR)/buildroot-package-stamp
	@echo "$(COLOUR_GREEN)Packaging overlayfs-tools for $(BOARD)$(END_COLOUR)"
	@$(eval BV=$(shell cd $(BUILDDIR)/buildroot && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@mkdir -p $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)
	@cp -r /builder/deb/overlayfs-tools/* $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)/
	@mkdir -pv $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)/usr/bin/
	@cp -p $(BR_OUTPUT_DIR)/target/usr/bin/fsck.overlay $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)/usr/bin/
	@cp -p $(BR_OUTPUT_DIR)/target/usr/bin/overlay $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)/usr/bin/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(OVERLAYFS_TOOLS_VERSION)$(BV)/' $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)/DEBIAN/control
	@sed -i 's/Package: overlayfs-tools/Package: overlayfs-tools/' $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION) overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

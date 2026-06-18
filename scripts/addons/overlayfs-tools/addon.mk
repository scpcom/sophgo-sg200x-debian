ifneq ("$(findstring overlayfs-tools,$(IMAGE_ADDITIONS))$(findstring overlayfs-tools,$(PACKAGES))","")
BSPDEPENDS += overlayfs-tools
BSPFILTER += "overlayfs-tools"
endif

OVERLAYFS_TOOLS_VERSION = 2025.01

OVERLAYFS_TOOLS_PACKAGE_DIR = $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)

$(BUILDDIR)/overlayfs-tools-stamp: $(BUILDDIR)/buildroot-package-stamp
	@echo "$(COLOUR_GREEN)Packaging overlayfs-tools for $(BOARD)$(END_COLOUR)"
	@$(eval BV=$(shell cd $(BUILDDIR)/buildroot && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@mkdir -p $(OVERLAYFS_TOOLS_PACKAGE_DIR)
	@cp -r /builder/deb/overlayfs-tools/* $(OVERLAYFS_TOOLS_PACKAGE_DIR)/
	@mkdir -pv $(OVERLAYFS_TOOLS_PACKAGE_DIR)/usr/bin/
	@cp -p $(BR_OUTPUT_DIR)/target/usr/bin/fsck.overlay $(OVERLAYFS_TOOLS_PACKAGE_DIR)/usr/bin/
	@cp -p $(BR_OUTPUT_DIR)/target/usr/bin/overlay $(OVERLAYFS_TOOLS_PACKAGE_DIR)/usr/bin/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(OVERLAYFS_TOOLS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(OVERLAYFS_TOOLS_VERSION)$(BV)/' $(OVERLAYFS_TOOLS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: overlayfs-tools/Package: overlayfs-tools/' $(OVERLAYFS_TOOLS_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION) overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

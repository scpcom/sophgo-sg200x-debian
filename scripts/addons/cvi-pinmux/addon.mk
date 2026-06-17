ifneq ("$(findstring cvi-pinmux,$(IMAGE_ADDITIONS))$(findstring cvi-pinmux-$(CHIP),$(PACKAGES))","")
BSPDEPENDS += cvi-pinmux-$(CHIP)
BSPFILTER += "cvi-pinmux"
endif

CVI_PINMUX_VERSION = 1.0.0

CVI_PINMUX_PACKAGE_DIR = $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)

$(BUILDDIR)/cvi-pinmux-stamp: $(BUILDDIR)/buildroot-package-stamp
	@echo "$(COLOUR_GREEN)Packaging cvi-pinmux for $(BOARD)$(END_COLOUR)"
	@$(eval BV=$(shell cd $(BUILDDIR)/buildroot && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@mkdir -p $(CVI_PINMUX_PACKAGE_DIR)
	@cp -r /builder/deb/cvi-pinmux-cv181x/* $(CVI_PINMUX_PACKAGE_DIR)/
	@mkdir -pv $(CVI_PINMUX_PACKAGE_DIR)/usr/bin/
	@cp -p $(BR_OUTPUT_DIR)/target/usr/bin/cvi-pinmux $(CVI_PINMUX_PACKAGE_DIR)/usr/bin/cvi_pinmux
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(CVI_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(CVI_PINMUX_VERSION)$(BV)/' $(CVI_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvi-pinmux-cv181x/Package: cvi-pinmux-cv181x/' $(CVI_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION) cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

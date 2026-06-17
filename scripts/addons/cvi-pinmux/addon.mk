ifneq ("$(findstring cvi-pinmux,$(IMAGE_ADDITIONS))$(findstring cvi-pinmux-$(CHIP),$(PACKAGES))","")
BSPDEPENDS += cvi-pinmux-$(CHIP)
BSPFILTER += "cvi-pinmux"
endif

CVI_PINMUX_VERSION = 1.0.0

$(BUILDDIR)/cvi-pinmux-stamp: $(BUILDDIR)/buildroot-package-stamp
	@echo "$(COLOUR_GREEN)Packaging cvi-pinmux for $(BOARD)$(END_COLOUR)"
	@$(eval BV=$(shell cd $(BUILDDIR)/buildroot && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@mkdir -p $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)
	@cp -r /builder/deb/cvi-pinmux-cv181x/* $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)/
	@mkdir -pv $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)/usr/bin/
	@cp -p $(BR_OUTPUT_DIR)/target/usr/bin/cvi-pinmux $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)/usr/bin/cvi_pinmux
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(CVI_PINMUX_VERSION)$(BV)/' $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)/DEBIAN/control
	@sed -i 's/Package: cvi-pinmux-cv181x/Package: cvi-pinmux-cv181x/' $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION) cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

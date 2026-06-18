DUO_PINMUX_VERSION = 1.0.0

$(BUILDDIR)/duo-pinmux-stamp: $(BUILDDIR)/buildroot-package-stamp
	@echo "$(COLOUR_GREEN)Packaging duo-pinmux for $(BOARD)$(END_COLOUR)"
	@$(eval BV=$(shell cd $(BUILDDIR)/buildroot && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@mkdir -p $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)
	@cp -r /builder/deb/duo-pinmux/* $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)/
	@mkdir -pv $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)/usr/bin/
	@cp -p $(BR_OUTPUT_DIR)/target/usr/bin/duo-pinmux $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)/usr/bin/duo-pinmux
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(DUO_PINMUX_VERSION)$(BV)/' $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)/DEBIAN/control
	@sed -i 's/Package: duo-pinmux/Package: duo-pinmux-$(BOARD)/' $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)/DEBIAN/control
	@if [ "$(BOARD)" = "duos" ]; then \
		sed -i 's/Duo256/DuoS/' $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)/DEBIAN/control ; \
	fi
	@cd $(BUILDDIR)/package/ && dpkg-deb --build duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION) duo-pinmux-$(BOARD)_$(DUO_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/duo-pinmux-$(BOARD)_$(DUO_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/duo-pinmux-$(BOARD)_$(DUO_PINMUX_VERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

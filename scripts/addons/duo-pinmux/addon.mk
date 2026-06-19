INSTALL ?= install

DUO_PINMUX_GIT_REF = 49a1d4ae2ccc18286e8c6dd60490189e8b85a9b8

DUO_PINMUX_VERSION = 1.0.0

DUO_PINMUX_BUILD_DIR = $(BUILDDIR)/duo-pinmux/duo-pinmux
DUO_PINMUX_PACKAGE_DIR = $(BUILDDIR)/package/duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION)

ifeq ($(BOARD),duos)
DUO_PINMUX_CHIP_DIR = duos
else
DUO_PINMUX_CHIP_DIR = duo256m
endif

$(BUILDDIR)/duo-pinmux-prepare-stamp:
	@mkdir -p $(BUILDDIR)/duo-pinmux/
	@cd $(BUILDDIR)/duo-pinmux/ && git clone --depth 1 -b main $(GIT_USER_URL)/duo-pinmux
	@cd $(BUILDDIR)/duo-pinmux/duo-pinmux/ && git checkout $(DUO_PINMUX_GIT_REF)
	@touch $@

$(BUILDDIR)/duo-pinmux-compile-stamp: $(BUILDDIR)/duo-pinmux-prepare-stamp
	$(DUO_PINMUX_MAKE_ENV) $(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)gcc $(SDK_TARGET_LDFLAGS) \
		$(DUO_PINMUX_BUILD_DIR)/$(DUO_PINMUX_CHIP_DIR)/*.c -o $(DUO_PINMUX_BUILD_DIR)/duo-pinmux
	@touch $@

$(BUILDDIR)/duo-pinmux-stamp: $(BUILDDIR)/duo-pinmux-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging duo-pinmux for $(BOARD)$(END_COLOUR)"
	@$(eval DPV=$(shell cd $(DUO_PINMUX_BUILD_DIR) && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@mkdir -p $(DUO_PINMUX_PACKAGE_DIR)
	@cp -r /builder/deb/duo-pinmux/* $(DUO_PINMUX_PACKAGE_DIR)/
	@mkdir -pv $(DUO_PINMUX_PACKAGE_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(DUO_PINMUX_BUILD_DIR)/duo-pinmux $(DUO_PINMUX_PACKAGE_DIR)/usr/bin/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(DUO_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(DUO_PINMUX_VERSION)$(DPV)/' $(DUO_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: duo-pinmux/Package: duo-pinmux-$(BOARD)/' $(DUO_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@if [ "$(BOARD)" = "duos" ]; then \
		sed -i 's/Duo256/DuoS/' $(DUO_PINMUX_PACKAGE_DIR)/DEBIAN/control ; \
	fi
	@cd $(BUILDDIR)/package/ && dpkg-deb --build duo-pinmux-$(BOARD)-$(DUO_PINMUX_VERSION) duo-pinmux-$(BOARD)_$(DUO_PINMUX_VERSION)$(DPV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/duo-pinmux-$(BOARD)_$(DUO_PINMUX_VERSION)$(DPV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/duo-pinmux-$(BOARD)_$(DUO_PINMUX_VERSION)$(DPV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

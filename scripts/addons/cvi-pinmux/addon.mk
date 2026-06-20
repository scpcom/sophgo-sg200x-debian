ifneq ("$(findstring cvi-pinmux,$(IMAGE_ADDITIONS))$(findstring cvi-pinmux-$(CHIP),$(PACKAGES))","")
BSPDEPENDS += cvi-pinmux-$(CHIP)
BSPFILTER += "cvi-pinmux"
endif

INSTALL ?= install

CVI_PINMUX_GIT_REF = 5b90da9f46fdc132e524f58f7f1bd96b028449c7

CVI_PINMUX_VERSION = 1.0.0

CVI_PINMUX_BUILD_DIR = $(BUILDDIR)/cvi-pinmux/cvi-pinmux
CVI_PINMUX_PACKAGE_DIR = $(BUILDDIR)/package/cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION)

CVI_PINMUX_CHIP_DIR ?= sg200x

$(BUILDDIR)/cvi-pinmux-prepare-stamp:
	@mkdir -p $(BUILDDIR)/cvi-pinmux/
	@cd $(BUILDDIR)/cvi-pinmux/ && git clone --depth 1 -b main $(GIT_USER_URL)/cvi-pinmux
	@cd $(BUILDDIR)/cvi-pinmux/cvi-pinmux/ && git checkout $(CVI_PINMUX_GIT_REF)
	@touch $@

$(BUILDDIR)/cvi-pinmux-compile-stamp: $(BUILDDIR)/cvi-pinmux-prepare-stamp
	rm -f $(CVI_PINMUX_BUILD_DIR)/*/cvi?pinmux
	[ -e $(CVI_PINMUX_BUILD_DIR)/sg200x ] || ln -s cv181x $(CVI_PINMUX_BUILD_DIR)/sg200x
	$(CVI_PINMUX_MAKE_ENV) $(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)gcc $(SDK_TARGET_LDFLAGS) \
		$(CVI_PINMUX_BUILD_DIR)/$(CVI_PINMUX_CHIP_DIR)/*.c -o $(CVI_PINMUX_BUILD_DIR)/cvi-pinmux
	@touch $@

$(BUILDDIR)/cvi-pinmux-stamp: $(BUILDDIR)/cvi-pinmux-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging cvi-pinmux for $(BOARD)$(END_COLOUR)"
	@$(eval CPV=$(shell cd $(CVI_PINMUX_BUILD_DIR) && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@mkdir -p $(CVI_PINMUX_PACKAGE_DIR)
	@cp -r /builder/deb/cvi-pinmux-cv181x/* $(CVI_PINMUX_PACKAGE_DIR)/
	@mkdir -pv $(CVI_PINMUX_PACKAGE_DIR)/usr/bin/
	$(INSTALL) -D -m 0755 $(CVI_PINMUX_BUILD_DIR)/cvi-pinmux $(CVI_PINMUX_PACKAGE_DIR)/usr/bin/
	@ln -s cvi-pinmux $(CVI_PINMUX_PACKAGE_DIR)/usr/bin/cvi_pinmux
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(CVI_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(CVI_PINMUX_VERSION)$(CPV)/' $(CVI_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvi-pinmux-cv181x/Package: cvi-pinmux-cv181x/' $(CVI_PINMUX_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build cvi-pinmux-cv181x-$(CVI_PINMUX_VERSION) cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(CPV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(CPV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/cvi-pinmux-cv181x_$(CVI_PINMUX_VERSION)$(CPV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

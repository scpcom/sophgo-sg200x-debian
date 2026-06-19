ifneq ("$(findstring overlayfs-tools,$(IMAGE_ADDITIONS))$(findstring overlayfs-tools,$(PACKAGES))","")
BSPDEPENDS += overlayfs-tools
BSPFILTER += "overlayfs-tools"
endif

OVERLAYFS_TOOLS_GIT_REF = 6e925bbbe747fbb58bc4a95a646907a2101741f6

OVERLAYFS_TOOLS_VERSION = 2025.01

OVERLAYFS_TOOLS_BUILD_DIR = $(BUILDDIR)/overlayfs-tools/overlayfs-tools
OVERLAYFS_TOOLS_OUTPUT_DIR = $(BUILDDIR)/overlayfs-tools/build
OVERLAYFS_TOOLS_PACKAGE_DIR = $(BUILDDIR)/package/overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION)

$(BUILDDIR)/overlayfs-tools-prepare-stamp:
	apt-get install -y meson
	@mkdir -p $(BUILDDIR)/overlayfs-tools/
	@cd $(BUILDDIR)/overlayfs-tools/ && git clone --depth 2 -b master $(GIT_USER_URL)/overlayfs-tools
	@cd $(BUILDDIR)/overlayfs-tools/overlayfs-tools/ && git checkout $(OVERLAYFS_TOOLS_GIT_REF)
	@touch $@

$(BUILDDIR)/overlayfs-tools-configure-stamp: $(BUILDDIR)/overlayfs-tools-prepare-stamp
	mkdir -p $(OVERLAYFS_TOOLS_OUTPUT_DIR)
	cat addons/overlayfs-tools/meson-cross-compilation.conf.in | \
		sed 's|{{SDK_SYSROOT}}|$(SDK_SYSROOT)|g' | \
		sed 's|{{SDK_CROSS_COMPILE_PATH}}|$(SDK_CROSS_COMPILE_PATH)|g' | \
		sed 's|{{SDK_CROSS_COMPILE_PREFIX}}|$(SDK_CROSS_COMPILE_PREFIX)|g' | \
		sed "s|{{SDK_MESON_LDFLAGS}}|$(SDK_MESON_LDFLAGS)|g" | \
		sed "s|{{SDK_MESON_CFLAGS}}|$(SDK_MESON_CFLAGS)|g" | \
		sed "s|{{SDK_MESON_CXXFLAGS}}|$(SDK_MESON_CXXFLAGS)|g" | \
		sed 's|{{SDK_MESON_ARCH}}|$(SDK_MESON_ARCH)|g' | \
		sed 's|{{SDK_MESON_CPU}}|$(SDK_MESON_CPU)|g' > $(OVERLAYFS_TOOLS_OUTPUT_DIR)/cross-compilation.conf
	PATH="$(SDK_CROSS_COMPILE_PATH)/bin:$(SDK_CROSS_COMPILE_PATH)/sbin:$$PATH" \
		meson setup --prefix=/usr --libdir=lib --default-library=shared --buildtype=release \
		--cross-file=$(OVERLAYFS_TOOLS_OUTPUT_DIR)/cross-compilation.conf \
		-Db_pie=false -Db_staticpic=true -Dstrip=false \
		$(OVERLAYFS_TOOLS_BUILD_DIR)/ $(OVERLAYFS_TOOLS_OUTPUT_DIR)
	@touch $@

$(BUILDDIR)/overlayfs-tools-compile-stamp: $(BUILDDIR)/overlayfs-tools-configure-stamp
	GIT_DIR=. \
	PATH="$(SDK_CROSS_COMPILE_PATH)/bin:$(SDK_CROSS_COMPILE_PATH)/sbin:$$PATH" \
		ninja \
		-C $(OVERLAYFS_TOOLS_OUTPUT_DIR)
	@touch $@

$(BUILDDIR)/overlayfs-tools-stamp: $(BUILDDIR)/overlayfs-tools-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging overlayfs-tools for $(BOARD)$(END_COLOUR)"
	@$(eval OTV=$(shell cd $(OVERLAYFS_TOOLS_BUILD_DIR) && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@mkdir -p $(OVERLAYFS_TOOLS_PACKAGE_DIR)
	@cp -r /builder/deb/overlayfs-tools/* $(OVERLAYFS_TOOLS_PACKAGE_DIR)/
	@mkdir -pv $(OVERLAYFS_TOOLS_PACKAGE_DIR)/usr/bin/
	@cp -p $(OVERLAYFS_TOOLS_OUTPUT_DIR)/fsck.overlay $(OVERLAYFS_TOOLS_PACKAGE_DIR)/usr/bin/
	@cp -p $(OVERLAYFS_TOOLS_OUTPUT_DIR)/overlay $(OVERLAYFS_TOOLS_PACKAGE_DIR)/usr/bin/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(OVERLAYFS_TOOLS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(OVERLAYFS_TOOLS_VERSION)$(OTV)/' $(OVERLAYFS_TOOLS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: overlayfs-tools/Package: overlayfs-tools/' $(OVERLAYFS_TOOLS_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build overlayfs-tools-$(OVERLAYFS_TOOLS_VERSION) overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(OTV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(OTV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/overlayfs-tools_$(OVERLAYFS_TOOLS_VERSION)$(OTV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

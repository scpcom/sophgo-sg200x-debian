FSBLVERSION=1.2.0
OSDRVVERSION=2024.11.20
MIDDLEWAREVERSION=2024.11.20

CROSS_COMPILE_64 = aarch64-none-linux-gnu-
CROSS_COMPILE_32 = arm-none-linux-gnueabihf-

CROSS_COMPILE_PATH_64 = /host-tools/gcc/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu
CROSS_COMPILE_PATH_32 = /host-tools/gcc/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-linux-gnueabihf

ifeq ($(SDK_VER),64bit)
SDK_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_64)
SDK_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_64)
else ifeq ($(SDK_VER),32bit)
SDK_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_32)
SDK_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_32)
else
$(error $(red)SDK_VER is invalid$(reset))
endif

ifeq ($(BOOT_CPU),aarch64)
SBL_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_64)
SBL_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_64)
else
SBL_CROSS_COMPILE_PATH = $(SDK_CROSS_COMPILE_PATH)
SBL_CROSS_COMPILE_PREFIX = $(SDK_CROSS_COMPILE_PREFIX)
endif
ifeq ($(KERNEL_ARCH),arm64)
SDK_CROSS_COMPILE_KERNEL="$(SBL_CROSS_COMPILE_PATH)/bin/$(SBL_CROSS_COMPILE_PREFIX)"
else
SDK_CROSS_COMPILE_KERNEL="$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)"
endif

BOARD_DTS ?= $(UBOOT_CHIP)_$(UBOOT_BOARD)
BOARD_EXT ?= $(BOARD)

BSP_OUTPUT_DIR=$(BUILDDIR)/bsp/build/$(BOARD_DTS)
BSP_INSTALL_DIR=$(BUILDDIR)/bsp/install/$(BOARD_DTS)

KERNEL_OUTPUT_DIR = $(BSP_OUTPUT_DIR)/linux

CHIP_VENDOR ?= axera

BR_BOARD = $(CHIP_VENDOR)_$(SDK_CHIP)_$(SDK_VER)
BR_DEFCONFIG = $(BR_BOARD)_defconfig
BR_DIR = $(BUILDDIR)/buildroot
BR_OUTPUT_DIR = $(BR_DIR)/output/$(BR_BOARD)

BUILDROOT_ENV = CROSS_COMPILE_KERNEL=$(patsubst "%",%,$(SDK_CROSS_COMPILE_PREFIX)) \
CROSS_COMPILE_SDK=$(patsubst "%",%,$(SDK_CROSS_COMPILE_PREFIX)) \
TARGET_OUTPUT_DIR=$(BR_OUTPUT_DIR)

FSBL_TARGETS = $(BUILDDIR)/fsbl-package-stamp

ifneq ("$(PANEL_TUNING_DEFAULT)","")
PANEL_CONFIG_DEFAULT = $(shell echo '$(PANEL_TUNING_DEFAULT)' | tr '[:lower:]' '[:upper:]')
FSBL_TARGETS += $(BUILDDIR)/fsbl-$(PANEL_TUNING_DEFAULT).package-stamp
#OSDRV_ENV += CONFIG_$(PANEL_CONFIG_DEFAULT)=y CONFIG_PANEL_TUNING_PARAM="$(PANEL_TUNING_DEFAULT)"
ifneq ("$(PANEL_TUNING_EXTRA)","")
FSBL_TARGETS += $(patsubst %,$(BUILDDIR)/fsbl-%.package-stamp,$(PANEL_TUNING_EXTRA))
endif
endif

MIDDLEWARE_OUT_DIR=$(BUILDDIR)/middleware/install/system/usr
MIDDLEWARE_TARGET_DIR=/opt

BSPDEPENDS = $(CHIP_VENDOR)-middleware-$(BOARD)\
 $(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)\
 $(CHIP_VENDOR)-bsp-$(BOARD)-$(VARIANT)\
 linux-headers-$(BOARD)-$(VARIANT)\
 linux-image-$(BOARD)-$(VARIANT)
BSPRECOMMENDS = $(CHIP_VENDOR)-fsbl-$(BOARD_EXT)
BSPFILTER =

AIC8800_TARGET_DIR ?= /opt/firmware

include $(wildcard /builder/addons/*/addon.mk)

SDK_OSS_TARBALL_DIR = $(BUILDDIR)/oss/oss_release_tarball/$(SDK_VER)

addon-targets = $(patsubst "%,$(BUILDDIR)/%-stamp,$(patsubst %",%,$(IMAGE_ADDITIONS)))
_PACKAGES = $(patsubst "%,%,$(patsubst %",%,$(PACKAGES)))
_DEV_PACKAGES = $(patsubst "%,%,$(patsubst %",%,$(DEV_PACKAGES)))

COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)

BSPDEPENDS += $(patsubst "%,%-$(BOARD),$(patsubst %",%,$(filter-out $(BSPFILTER),$(IMAGE_ADDITIONS))))
_BSPDEPENDS = $(subst $(SPACE),$(COMMA)$(SPACE),$(sort $(BSPDEPENDS)))
_BSPRECOMMENDS = $(subst $(SPACE),$(COMMA)$(SPACE),$(sort $(BSPRECOMMENDS)))

$(info $(blue)Board: $(BOARD_CFG)$(reset))
$(info $(blue)Variant: $(VARIANT)$(reset))
$(info $(blue)Storage: $(STORAGE_TYPE)$(reset))
$(info $(blue)Target: $(SDK_VER)$(reset))
$(info $(blue)ION Size: $(ION_SIZE)M$(reset))
$(info $(blue)Default Panel: $(PANEL_TUNING_DEFAULT)$(reset))
$(info $(blue)Image Addons: $(IMAGE_ADDITIONS)$(reset))
$(info $(blue)Packages: $(_PACKAGES)$(reset))
$(info $(blue)Development Packages: $(_DEV_PACKAGES)$(reset))

NPROCS := $(shell nproc)


define copy_ko_action
	@mkdir -p $(BUILDDIR)/osdrv/ko
	$(foreach kodir, $(KO_DIRS), find ${1}/lib/modules/*/kernel/$(kodir) -name '*.ko' -exec cp -f {} $(BUILDDIR)/osdrv/ko/ \; || true ;)
endef

$(BUILDDIR)/toolchain-prepare-patch-stamp:
	@echo "$(COLOUR_GREEN)Patching Toolchain for $(BOARD)$(END_COLOUR)"
	@[ "$(TOOLCHAIN_URL)" = "X" ] || sed -i 's|^tcurl=.*|tcurl=$(TOOLCHAIN_URL)|g' /builder/replace-all-arm-toolchains.sh
	@if [ "$(UBOOT_ARCH)" = "arm" ]; then \
		rm -rf /host-tools/gcc/riscv64-*/ && \
		cd / && tcver=11.3.rel1 /builder/replace-all-arm-toolchains.sh && \
		mv /ramdisk $(BUILDDIR)/ ; \
	fi
	@#cd / && /builder/fix-thead-glibc-toolchain.sh
	@touch $@

$(BUILDDIR)/linux-prepare-checkout-stamp: $(BUILDDIR)/bsp-prepare-checkout-stamp
	@echo "$(COLOUR_GREEN)Checking out Kernel for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@ln -s bsp/linux $(BUILDDIR)/kernel
	@touch $@

$(BUILDDIR)/linux-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/linux-prepare-checkout-stamp
	@echo "$(COLOUR_GREEN)Patching Kernel for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/linux/*.patch), cd $(BUILDDIR)/kernel && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/linux/*.patch), cd $(BUILDDIR)/kernel && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/linux/*.patch), cd $(BUILDDIR)/kernel && git apply --ignore-whitespace $(file);)
	@cp /configs/$(BOARD_CFG)/linux/defconfig $(BUILDDIR)/kernel/arch/$(KERNEL_ARCH)/configs/${BOARD}_defconfig
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)/*), cp $(file) $(BUILDDIR)/kernel/arch/$(KERNEL_ARCH)/boot/dts/$(CHIP_VENDOR)/;)
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)_$(UBOOT_ARCH)/*), cp $(file) $(BUILDDIR)/kernel/arch/$(KERNEL_ARCH)/boot/dts/$(CHIP_VENDOR)/;)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/dts/*), cp $(file) $(BUILDDIR)/kernel/arch/$(KERNEL_ARCH)/boot/dts/$(CHIP_VENDOR)/;)
	@touch $@

$(BUILDDIR)/linux-prepare-configure-stamp: $(BUILDDIR)/linux-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring Kernel for $(BOARD)$(END_COLOUR)"
	@touch $@

$(BUILDDIR)/linux-compile-stamp: $(BUILDDIR)/bsp-compile-stamp $(BUILDDIR)/linux-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building Kernel for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/bsp && ./scripts/build-linux.sh bindeb-pkg
	@cp $(BSP_OUTPUT_DIR)/*.deb /output/
	@touch $@

$(BUILDDIR)/linux-package-stamp: $(BUILDDIR)/linux-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging linux-headers-$(CHIP_FAMILY) for $(BOARD)$(END_COLOUR)"
	@$(eval KERNEL_DEB_TMP_IMAGE=$(KERNEL_OUTPUT_DIR)/debian/tmp)
	@$(eval KERNEL_DEB_TMP_HEADERS=$(KERNEL_OUTPUT_DIR)/debian/hdrtmp)
	@$(eval KERNEL_DEB_ARCH=$(shell grep -m1 '^Architecture: ' $(KERNEL_OUTPUT_DIR)/debian/control | cut -d ' ' -f 2))
	@$(eval LINUXMETAVERSION=$(shell basename $(KERNEL_DEB_TMP_HEADERS)/usr/share/doc/linux-headers-* | cut -d '-' -f 3-))
	@$(eval LINUX_HEADERS_META_DIR=$(BUILDDIR)/package/linux-headers-$(BOARD)-$(VARIANT)-$(LINUXMETAVERSION))
	@$(eval LINUX_IMAGE_META_DIR=$(BUILDDIR)/package/linux-image-$(BOARD)-$(VARIANT)-$(LINUXMETAVERSION))
	@mkdir -p $(LINUX_HEADERS_META_DIR)
	@cp -r /builder/deb/linux-image-sg200x/* $(LINUX_HEADERS_META_DIR)/
	@mkdir -pv $(LINUX_HEADERS_META_DIR)/usr/share/doc/linux-headers-$(BOARD)-$(VARIANT)/
	@cp -p $(KERNEL_DEB_TMP_HEADERS)/usr/share/doc/linux-headers-*/* $(LINUX_HEADERS_META_DIR)/usr/share/doc/linux-headers-$(BOARD)-$(VARIANT)/
	@sed -i 's/Architecture: riscv64/Architecture: $(KERNEL_DEB_ARCH)/' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(LINUXMETAVERSION)/' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@sed -i 's/Package: linux-image-sg200x/Package: linux-headers-$(BOARD)-$(VARIANT)/' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@sed -i 's/Depends: linux-image-.*/Depends: linux-headers-$(LINUXMETAVERSION)/' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@sed -i  '/Recommends: .*/d' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@sed -i 's/Provides: linux-image-.*/Provides: linux-headers-generic/' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(LINUX_HEADERS_META_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build linux-headers-$(BOARD)-$(VARIANT)-$(LINUXMETAVERSION) linux-headers-$(BOARD)-$(VARIANT)_$(LINUXMETAVERSION)_$(KERNEL_DEB_ARCH).deb
	@cp $(BUILDDIR)/package/linux-headers-$(BOARD)-$(VARIANT)_$(LINUXMETAVERSION)_$(KERNEL_DEB_ARCH).deb /output/
	@echo "$(COLOUR_GREEN)Packaging linux-image-$(CHIP_FAMILY) for $(BOARD)$(END_COLOUR)"
	@$(eval LINUXMETAVERSION=$(shell basename $(KERNEL_DEB_TMP_IMAGE)/usr/share/doc/linux-image-* | cut -d '-' -f 3-))
	@mkdir -p $(LINUX_IMAGE_META_DIR)
	@cp -r /builder/deb/linux-image-sg200x/* $(LINUX_IMAGE_META_DIR)/
	@mkdir -pv $(LINUX_IMAGE_META_DIR)/usr/share/doc/linux-image-$(BOARD)-$(VARIANT)/
	@cp -p $(KERNEL_DEB_TMP_IMAGE)/usr/share/doc/linux-image-*/* $(LINUX_IMAGE_META_DIR)/usr/share/doc/linux-image-$(BOARD)-$(VARIANT)/
	@sed -i 's/Architecture: riscv64/Architecture: $(KERNEL_DEB_ARCH)/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(LINUXMETAVERSION)/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@sed -i 's/Package: linux-image-sg200x/Package: linux-image-$(BOARD)-$(VARIANT)/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@sed -i 's/Depends: linux-image-.*/Depends: linux-image-$(LINUXMETAVERSION)/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@sed -i 's/Recommends: cvitek-osdrv-.*/Recommends: $(CHIP_VENDOR)-fsbl-$(BOARD_EXT), $(CHIP_VENDOR)-osdrv-$(LINUXMETAVERSION)/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@sed -i 's/linux-latest-modules-.*licheervnano,/linux-latest-modules-$(LINUXMETAVERSION),/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(LINUX_IMAGE_META_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build linux-image-$(BOARD)-$(VARIANT)-$(LINUXMETAVERSION) linux-image-$(BOARD)-$(VARIANT)_$(LINUXMETAVERSION)_$(KERNEL_DEB_ARCH).deb
	@cp $(BUILDDIR)/package/linux-image-$(BOARD)-$(VARIANT)_$(LINUXMETAVERSION)_$(KERNEL_DEB_ARCH).deb /output/
	@touch $@

linux: $(BUILDDIR)/linux-package-stamp

linux-clean:
	@rm -rf $(BUILDDIR)/kernel
	@rm -f $(BUILDDIR)/linux-*-stamp
	@rm -f $(BUILDDIR)/kernel/build/linux-*.deb


$(BUILDDIR)/osdrv-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out OSdrv for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@touch $@

$(BUILDDIR)/osdrv-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/osdrv-prepare-checkout-stamp $(BUILDDIR)/linux-compile-stamp
	@echo "$(COLOUR_GREEN)Patching OSdrv for $(BOARD)$(END_COLOUR)"
	$(call copy_ko_action, $(KERNEL_OUTPUT_DIR)/ko)
	@$(foreach file, $(wildcard /configs/common/patches/osdrv/*.patch), cd $(BUILDDIR)/osdrv && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/osdrv/*.patch), cd $(BUILDDIR)/osdrv && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/osdrv/*.patch), cd $(BUILDDIR)/osdrv && git apply --ignore-whitespace $(file);)
	@touch $@

$(BUILDDIR)/osdrv-prepare-configure-stamp: $(BUILDDIR)/osdrv-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring OSdrv for $(BOARD)$(END_COLOUR)"
	@touch $@

$(BUILDDIR)/osdrv-compile-stamp: $(BUILDDIR)/bsp-compile-stamp $(BUILDDIR)/osdrv-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building OSdrv for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)/osdrv/ko
	@cp -p $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/soc/ko/ax_*.ko $(BUILDDIR)/osdrv/ko/
	@touch $@

$(BUILDDIR)/osdrv-package-stamp: $(BUILDDIR)/osdrv-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging OSdrv for $(BOARD)$(END_COLOUR)"
	@$(eval KERNEL_DEB_TMP_IMAGE=$(KERNEL_OUTPUT_DIR)/debian/tmp)
	@$(eval KERNEL_DEB_TMP_HEADERS=$(KERNEL_OUTPUT_DIR)/debian/hdrtmp)
	@$(eval KERNEL_DEB_ARCH=$(shell grep -m1 '^Architecture: ' $(KERNEL_OUTPUT_DIR)/debian/control | cut -d ' ' -f 2))
	@$(eval KERNELRELEASE=$(shell basename $(KERNEL_DEB_TMP_HEADERS)/usr/share/doc/linux-headers-* | cut -d '-' -f 3-))
	@$(eval OSDRV_PACKAGE_DIR=$(BUILDDIR)/package/$(CHIP_VENDOR)-osdrv-$(KERNELRELEASE)-$(OSDRVVERSION))
	@$(eval OSDRV_META_DIR=$(BUILDDIR)/package/$(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)-$(KERNELRELEASE))
	@$(eval OSDRV_TARGET_DIR=/soc/ko)
	@mkdir -p $(OSDRV_PACKAGE_DIR)
	@cp -r /builder/deb/cvitek-osdrv/* $(OSDRV_PACKAGE_DIR)/
	@mkdir -pv $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/
	@cp -p $(BUILDDIR)/osdrv/ko/*.ko $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_clock_cooling.ko
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_pwm.ko
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_rtc.ko
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_saradc.ko
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_wdt.ko
	@sed -i 's/Architecture: riscv64/Architecture: $(KERNEL_DEB_ARCH)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(OSDRVVERSION)-$(KERNELRELEASE)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvitek-osdrv/Package: $(CHIP_VENDOR)-osdrv-$(KERNELRELEASE)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/RISC-V/$(ARCH_NAME)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(CHIP_VENDOR)-osdrv-$(KERNELRELEASE)-$(OSDRVVERSION) $(CHIP_VENDOR)-osdrv-$(KERNELRELEASE)_$(OSDRVVERSION)-$(KERNELRELEASE)_$(KERNEL_DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(CHIP_VENDOR)-osdrv-$(KERNELRELEASE)_$(OSDRVVERSION)-$(KERNELRELEASE)_$(KERNEL_DEB_ARCH).deb /output/
	@echo "$(COLOUR_GREEN)Packaging $(CHIP_VENDOR)-osdrv-$(CHIP) for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(OSDRV_META_DIR)
	@cp -r /builder/deb/linux-image-sg200x/* $(OSDRV_META_DIR)/
	@mkdir -pv $(OSDRV_META_DIR)/usr/share/doc/$(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)/
	@cp -p $(KERNEL_DEB_TMP_IMAGE)/usr/share/doc/linux-image-*/* $(OSDRV_META_DIR)/usr/share/doc/$(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)/
	@sed -i 's/Architecture: riscv64/Architecture: $(KERNEL_DEB_ARCH)/' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(OSDRVVERSION)-$(KERNELRELEASE)/' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i 's/Package: linux-image-sg200x/Package: $(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)/' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i 's/Depends: linux-image-.*/Depends: $(CHIP_VENDOR)-osdrv-$(KERNELRELEASE)/' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i 's/Recommends: cvitek-osdrv-.*/Recommends: linux-image-$(KERNELRELEASE)/' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i  '/Provides: .*/d' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i 's/Linux Image/OS drivers/' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(OSDRV_META_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(OSDRV_META_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)-$(KERNELRELEASE) $(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)_$(OSDRVVERSION)-$(KERNELRELEASE)_$(KERNEL_DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)_$(OSDRVVERSION)-$(KERNELRELEASE)_$(KERNEL_DEB_ARCH).deb /output/
	@touch $@

osdrv: $(BUILDDIR)/osdrv-package-stamp

osdrv-clean:
	@rm -rf $(BUILDDIR)/osdrv
	@rm -f $(BUILDDIR)/osdrv-*-stamp


$(BUILDDIR)/middleware-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out Middleware for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@touch $@

$(BUILDDIR)/middleware-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/middleware-prepare-checkout-stamp $(BUILDDIR)/osdrv-compile-stamp
	@echo "$(COLOUR_GREEN)Patching Middleware for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/middleware/*.patch), cd $(BUILDDIR)/middleware && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/middleware/*.patch), cd $(BUILDDIR)/middleware && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/middleware/*.patch), cd $(BUILDDIR)/middleware && git apply --ignore-whitespace $(file);)
	@touch $@

$(BUILDDIR)/middleware-prepare-configure-stamp: $(BUILDDIR)/middleware-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring Middleware for $(BOARD)$(END_COLOUR)"
	@touch $@

$(BUILDDIR)/middleware-compile-stamp: $(BUILDDIR)/middleware-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building Middleware for $(BOARD)$(END_COLOUR)"
	@mkdir -pv $(MIDDLEWARE_OUT_DIR)/lib/
	@cp -p $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/opt/lib/*.so* $(MIDDLEWARE_OUT_DIR)/lib/
	@rsync -avpPxH $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/opt/include/ $(BUILDDIR)/middleware/install/system/usr/include/
	@touch $@

$(BUILDDIR)/middleware-package-stamp: $(BUILDDIR)/middleware-compile-stamp
	@cd $(BUILDDIR)/bsp && [ "$(GIT_REF)" = "develop" ] || ./scripts/build-linux.sh clean
	@echo "$(COLOUR_GREEN)Packaging Middleware for $(BOARD)$(END_COLOUR)"
	@rm -rf $(BUILDDIR)/middleware/3rdparty/tmp/
	@$(eval MV=$(shell cd $(BUILDDIR)/middleware && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@$(eval MIDDLEWARE_PACKAGE_NAME=$(CHIP_VENDOR)-middleware-$(BOARD))
	@$(eval MIDDLEWARE_PACKAGE_DIR=$(BUILDDIR)/package/$(MIDDLEWARE_PACKAGE_NAME)-$(MIDDLEWAREVERSION))
	@mkdir -p $(MIDDLEWARE_PACKAGE_DIR)
	@cp -r /builder/deb/cvitek-middleware/* $(MIDDLEWARE_PACKAGE_DIR)/
	@mkdir -pv $(MIDDLEWARE_PACKAGE_DIR)$(MIDDLEWARE_TARGET_DIR)/
	@rsync -avpPxH $(MIDDLEWARE_OUT_DIR)/ $(MIDDLEWARE_PACKAGE_DIR)$(MIDDLEWARE_TARGET_DIR)/
	@rm -rf $(MIDDLEWARE_PACKAGE_DIR)$(MIDDLEWARE_TARGET_DIR)/include/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(MIDDLEWAREVERSION)$(MV)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvitek-middleware/Package: $(MIDDLEWARE_PACKAGE_NAME)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/RISC-V/$(ARCH_NAME)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(MIDDLEWARE_PACKAGE_NAME)-$(MIDDLEWAREVERSION) $(MIDDLEWARE_PACKAGE_NAME)_$(MIDDLEWAREVERSION)$(MV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(MIDDLEWARE_PACKAGE_NAME)_$(MIDDLEWAREVERSION)$(MV)_$(DEB_ARCH).deb /output/
	@$(eval MIDDLEWARE_DEV_PACKAGE_NAME=$(CHIP_VENDOR)-middleware-dev-$(BOARD))
	@$(eval MIDDLEWARE_DEV_PACKAGE_DIR=$(BUILDDIR)/package/$(MIDDLEWARE_DEV_PACKAGE_NAME)-$(MIDDLEWAREVERSION))
	@mkdir -p $(MIDDLEWARE_DEV_PACKAGE_DIR)
	@cp -r /builder/deb/cvitek-middleware/* $(MIDDLEWARE_DEV_PACKAGE_DIR)/
	@mkdir -pv $(MIDDLEWARE_DEV_PACKAGE_DIR)$(MIDDLEWARE_TARGET_DIR)/
	@rsync -avpPxH $(MIDDLEWARE_OUT_DIR)/include/ $(MIDDLEWARE_DEV_PACKAGE_DIR)$(MIDDLEWARE_TARGET_DIR)/include/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MIDDLEWARE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(MIDDLEWAREVERSION)$(MV)/' $(MIDDLEWARE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvitek-middleware/Package: $(MIDDLEWARE_DEV_PACKAGE_NAME)/' $(MIDDLEWARE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(MIDDLEWARE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(MIDDLEWARE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(MIDDLEWARE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/RISC-V/$(ARCH_NAME)/' $(MIDDLEWARE_DEV_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(MIDDLEWARE_DEV_PACKAGE_NAME)-$(MIDDLEWAREVERSION) $(MIDDLEWARE_DEV_PACKAGE_NAME)_$(MIDDLEWAREVERSION)$(MV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(MIDDLEWARE_DEV_PACKAGE_NAME)_$(MIDDLEWAREVERSION)$(MV)_$(DEB_ARCH).deb /output/
	@touch $@

middleware: $(BUILDDIR)/middleware-package-stamp

middleware-clean:
	@rm -rf $(BUILDDIR)/middleware
	@rm -f $(BUILDDIR)/middleware-*-stamp


$(BUILDDIR)/buildroot-prepare-clone-stamp:
	@echo "$(COLOUR_GREEN)Cloning Buildroot for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b nanokvm-2025.02 $(GIT_CLONE_OPTS) --recursive $(GIT_USER_URL)/buildroot.git $(BUILDDIR)/buildroot
	@touch $@

$(BUILDDIR)/buildroot-prepare-clone-dl-stamp: $(BUILDDIR)/buildroot-prepare-clone-stamp
	@echo "$(COLOUR_GREEN)Cloning Buildroot for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b main --depth=1 $(GIT_USER_URL)/buildroot-dl.git $(BR_DIR)/dl
	@cd $(BR_DIR)/dl && git checkout b953bc0
	@cd $(BR_DIR)/dl && [ "$(GIT_REF)" = "develop" ] || rm -rf .git
	@touch $@

$(BUILDDIR)/buildroot-prepare-checkout-stamp: $(BUILDDIR)/buildroot-prepare-clone-dl-stamp
	@echo "$(COLOUR_GREEN)Checking out Buildroot for $(BOARD)$(END_COLOUR)"
	@cd $(BR_DIR) && git checkout d109162
	@mkdir -p $(BUILDDIR)/ramdisk/tools
	@git clone -b main $(GIT_USER_URL)/cvi-pinmux $(BUILDDIR)/ramdisk/tools/cvi_pinmux
	@cd $(BUILDDIR)/ramdisk/tools/cvi_pinmux && git checkout 5b90da9
	@touch $@

$(BUILDDIR)/buildroot-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/buildroot-prepare-checkout-stamp $(BUILDDIR)/middleware-compile-stamp
	@echo "$(COLOUR_GREEN)Patching Buildroot for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/buildroot/*.patch), cd $(BR_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/buildroot/*.patch), cd $(BR_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/buildroot/*.patch), cd $(BR_DIR) && git apply --ignore-whitespace $(file);)
	@cp /configs/common/buildroot/$(ARCH)_defconfig $(BR_DIR)/configs/$(BR_DEFCONFIG)
	@echo 'BR2_TOOLCHAIN_EXTERNAL_PATH="'$(SDK_CROSS_COMPILE_PATH)'"' >> $(BR_DIR)/configs/$(BR_DEFCONFIG)
	@if [ "X$(findstring kvm,$(VARIANT))$(findstring maixapp,$(IMAGE_ADDITIONS))" = "X" ]; then \
		sed -i /BR2_CCACHE/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_CA_CERTIFICATES/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_LIBOPENSSL/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_LIBCURL/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_PYTHON/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_HOST_PYTHON/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_MAIX_CDK/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
	fi
	@if [ "X$(findstring maixapp,$(IMAGE_ADDITIONS))" = "X" ]; then \
		sed -i /BR2_PACKAGE_MPG123/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_LIBWEBSOCKETS/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_NANOMSG/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_WATCHDOG/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_OPENCV4/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_FFMPEG/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
	else \
		sed -i /BR2_PACKAGE_MAIX_CDK_ALL_DEPENDENCIES/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_MAIX_CDK_ALL_PROJECTS/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i s/'^BR2_PACKAGE_MAIX_CDK=y'/'BR2_PACKAGE_MAIX_CDK=y\nBR2_PACKAGE_MAIXCAM_SG200X=y'/g $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
	fi
	@if [ "X$(findstring kvm,$(VARIANT))" = "X" ]; then \
		sed -i /BR2_PACKAGE_NANOKVM/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
	fi
	@if [ "$(BOARD)" = "duos" ]; then \
		sed -i s/'BR2_PACKAGE_DUO_PINMUX_DUO256M=y'/'BR2_PACKAGE_DUO_PINMUX_DUOS=y'/g $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
	fi
	@mkdir -pv $(BUILDDIR)/buildroot/board/$(CHIP_VENDOR)/$(SDK_CHIP)/overlay/usr/share/fw_vcodec
	@mkdir -pv $(BUILDDIR)/ramdisk/tools/cvi_pinmux
	@touch $@

$(BUILDDIR)/buildroot-prepare-configure-stamp: $(BUILDDIR)/buildroot-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring Buildroot for $(BOARD)$(END_COLOUR)"
	@cd $(BR_DIR) && $(BUILDROOT_ENV) $(MAKE) $(BR_DEFCONFIG) BR2_TOOLCHAIN_EXTERNAL_PATH=$(SDK_CROSS_COMPILE_PATH)
	@touch $@

$(BUILDDIR)/buildroot-compile-stamp: $(BUILDDIR)/buildroot-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building Buildroot for $(BOARD)$(END_COLOUR)"
	@cd $(BR_DIR) && $(BUILDROOT_ENV) $(MAKE) -j$(NPROCS) source
	@cd $(BR_DIR) && $(BUILDROOT_ENV) $(MAKE) -j$(NPROCS)
	@touch $@

$(BUILDDIR)/buildroot-package-stamp: $(BUILDDIR)/buildroot-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging Buildroot for $(BOARD)$(END_COLOUR)"
	@rm -rf $(BR_OUTPUT_DIR)/build/*/*/
	@rm -f $(BR_OUTPUT_DIR)/build/*/*.a
	@rm -f $(BR_OUTPUT_DIR)/build/*/*.o
	@rm -f $(BR_OUTPUT_DIR)/build/*/*.so*
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BR_OUTPUT_DIR)/host/lib/go*/
	@rm -f $(BR_OUTPUT_DIR)/images/rootfs.tar*
	@touch $@

buildroot: $(BUILDDIR)/buildroot-package-stamp

buildroot-clean:
	@rm -rf $(BUILDDIR)/buildroot
	@rm -f $(BUILDDIR)/buildroot-*-stamp


define firmware_package_action
	@echo "$(COLOUR_GREEN)Packaging Firmware for $(BOARD) ${1}$(END_COLOUR)"
	@$(eval FIRMWAREVERSION=$(FSBLVERSION))
	@$(eval FV=$(shell cd $(BUILDDIR)/bsp && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@$(eval FIRMWARE_PACKAGE_NAME=$(CHIP_VENDOR)-firmware-$(BOARD_EXT)${2})
	@$(eval FIRMWARE_PACKAGE_DIR=$(BUILDDIR)/package/$(FIRMWARE_PACKAGE_NAME)-$(FIRMWAREVERSION))
	@$(eval PANEL_NAME_FIRMWARE=$(shell echo '${2}' | cut -d '-' -f 2- | tr '-' '_'))
	@mkdir -p $(FIRMWARE_PACKAGE_DIR)
	@cp -r /builder/deb/cvitek-fsbl/* $(FIRMWARE_PACKAGE_DIR)/
	@mkdir -p $(FIRMWARE_PACKAGE_DIR)/usr/lib/$(CHIP_VENDOR)-firmware/$(BOARD_EXT)${2}/
	@cp $(BSP_INSTALL_DIR)/uboot.bin $(FIRMWARE_PACKAGE_DIR)/usr/lib/$(CHIP_VENDOR)-firmware/$(BOARD_EXT)${2}/u-boot_signed.bin
	@cp $(BSP_INSTALL_DIR)/dtb.img $(FIRMWARE_PACKAGE_DIR)/usr/lib/$(CHIP_VENDOR)-firmware/$(BOARD_EXT)${2}/fdt_signed.dtb
	@cp $(BSP_INSTALL_DIR)/kernel.img $(FIRMWARE_PACKAGE_DIR)/usr/lib/$(CHIP_VENDOR)-firmware/$(BOARD_EXT)${2}/boot_signed.bin
	@sed -i 's|cvitek-fsbl/licheervnano|$(CHIP_VENDOR)-firmware/$(BOARD_EXT)${2}|g' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/postinst
	@[ "X$(PANEL_NAME_FIRMWARE)" = "X" ] || sed -i s/'^panel='/'panel='$(PANEL_NAME_FIRMWARE)/g $(FIRMWARE_PACKAGE_DIR)/DEBIAN/postinst
	@chmod ugo+rx $(FIRMWARE_PACKAGE_DIR)/DEBIAN/postinst
	@rm -f $(FIRMWARE_PACKAGE_DIR)/DEBIAN/postinst
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.1.0/Version: $(FIRMWAREVERSION)$(FV)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvitek-fsbl/Package: $(FIRMWARE_PACKAGE_NAME)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control
	@if [ "$(BOARD)" = "$(BOARD_EXT)" ]; then \
		sed -i '/Provides: .*/d' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control && \
		sed -i '/Replaces: .*/d' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control ; \
	else \
		sed -i 's/Provides: .*/Provides: $(CHIP_VENDOR)-firmware-$(BOARD)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control && \
		sed -i 's/Replaces: .*/Replaces: $(CHIP_VENDOR)-firmware-$(BOARD)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control ; \
	fi
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/RISC-V/$(ARCH_NAME)/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/First Stage Boot Loader/Firmware/' $(FIRMWARE_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(FIRMWARE_PACKAGE_NAME)-$(FIRMWAREVERSION) $(FIRMWARE_PACKAGE_NAME)_$(FIRMWAREVERSION)$(FV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(FIRMWARE_PACKAGE_NAME)_$(FIRMWAREVERSION)$(FV)_$(DEB_ARCH).deb /output/
	@touch $@
endef

$(BUILDDIR)/bsp-prepare-clone-stamp:
	@echo "$(COLOUR_GREEN)Cloning BSP for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b main $(GIT_CLONE_OPTS) --shallow-submodules $(GIT_USER_URL)/ax620e-bsp-build $(BUILDDIR)/bsp
	@touch $@

$(BUILDDIR)/bsp-prepare-checkout-stamp: $(BUILDDIR)/bsp-prepare-clone-stamp
	@echo "$(COLOUR_GREEN)Checking out BSP for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/bsp && git checkout 8222716
	@cd $(BUILDDIR)/bsp && git submodule set-url axerabin $(GIT_USER_URL)/axerabin
	@cd $(BUILDDIR)/bsp && git submodule set-url linux $(GIT_USER_URL)/linux
	@cd $(BUILDDIR)/bsp && git submodule set-url u-boot $(GIT_USER_URL)/u-boot
	@cd $(BUILDDIR)/bsp && git submodule update --init --recursive --depth=1
	@touch $@

$(BUILDDIR)/bsp-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/bsp-prepare-checkout-stamp $(BUILDDIR)/uboot-prepare-patch-stamp $(BUILDDIR)/linux-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Patching BSP for $(BOARD)$(END_COLOUR)"
	@$(eval BSP_ROOTFS_SOURCE_DIR=$(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs)
	@sed -i '/get-toolchain.sh/d' $(BUILDDIR)/bsp/build.sh
	@sed -i 's|^BOARD_DTS=.*|BOARD_DTS=$(BOARD_DTS)|g' $(BUILDDIR)/bsp/scripts/envsetup_pack.sh
	@sed -i s/'^BOARD_CHIP=.*'/'BOARD_CHIP='$(CHIP)/g $(BUILDDIR)/bsp/scripts/envsetup_pack.sh
	@sed -i s/'^BOARD_FAMILY=.*'/'BOARD_FAMILY='$(UBOOT_CHIP)/g $(BUILDDIR)/bsp/scripts/envsetup_pack.sh
	@sed -i s/'^KERNEL_ARCH=.*'/'KERNEL_ARCH='$(KERNEL_ARCH)/g $(BUILDDIR)/bsp/scripts/envsetup_pack.sh
	@sed -i 's|^CROSS_COMPILE_PATH=.*|CROSS_COMPILE_PATH=$(SBL_CROSS_COMPILE_PATH)|g' $(BUILDDIR)/bsp/scripts/envsetup_pack.sh
	@sed -i 's|^CROSS_COMPILE=.*|CROSS_COMPILE=$(SBL_CROSS_COMPILE_PREFIX)|g' $(BUILDDIR)/bsp/scripts/envsetup_pack.sh
	@if [ "X$(findstring kvm,$(VARIANT))" = "X" ]; then \
		sed -i /'devmem 0x10030028'/d $(BSP_ROOTFS_SOURCE_DIR)/etc/rc.local ; \
		sed -i s/'if ! systemctl is-active --quiet sysdev.service'/'if false'/g $(BSP_ROOTFS_SOURCE_DIR)/etc/rc.local ; \
		sed -i s/'systemctl enable --now sysdev.service'/'true # no sysdev.service'/g $(BSP_ROOTFS_SOURCE_DIR)/etc/rc.local ; \
		rm -f $(BSP_ROOTFS_SOURCE_DIR)/etc/systemd/system/sysdev.service ; \
		rm -f $(BSP_ROOTFS_SOURCE_DIR)/opt/scripts/sysdev.sh ; \
		sed -i s/'echo "nanokvm"'/'echo "$(BOARD)"'/g $(BSP_ROOTFS_SOURCE_DIR)/opt/scripts/usb-gadget.sh ; \
	else \
		sed -i /'cw2015_battery.ko'/d $(BSP_ROOTFS_SOURCE_DIR)/soc/scripts/auto_load_all_drv.sh ; \
		sed -i /'rtc-pcf8563.ko'/d $(BSP_ROOTFS_SOURCE_DIR)/soc/scripts/auto_load_all_drv.sh ; \
	fi
	@touch $@

$(BUILDDIR)/bsp-compile-stamp: $(BUILDDIR)/bsp-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Building BSP for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/bsp && ./build.sh
	@touch $@

$(BUILDDIR)/bsp-package-stamp: $(BUILDDIR)/bsp-compile-stamp
	@echo "$(COLOUR_GREEN)Installing BSP for $(BOARD)$(END_COLOUR)"
	@mkdir -p /rootfs/boot/
	@cp /configs/$(BOARD_CFG)/boot/configs /rootfs/boot/
	@sed -i s/'^maix_memory_cmm=.*'/'maix_memory_cmm=$(ION_SIZE)'/g /rootfs/boot/configs
	@echo "$(COLOUR_GREEN)Packaging BSP for $(BOARD)$(END_COLOUR)"
	@$(eval BSPRELEASE=$(shell cd $(BUILDDIR)/bsp && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@$(eval BSP_PACKAGE_DIR=$(BUILDDIR)/package/$(CHIP_VENDOR)-bsp-$(BOARD)-$(VARIANT))
	@mkdir -p $(BSP_PACKAGE_DIR)
	@cp -r /builder/deb/linux-image-sg200x/* $(BSP_PACKAGE_DIR)/
	@mkdir -pv $(BSP_PACKAGE_DIR)/etc/
	@cp -p -r $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/etc/* $(BSP_PACKAGE_DIR)/etc/
	@mv $(BSP_PACKAGE_DIR)/etc/rc.local $(BSP_PACKAGE_DIR)/etc/rc.local.$(CHIP_VENDOR)
	@mkdir -pv $(BSP_PACKAGE_DIR)/opt/scripts/
	@cp -p -r $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/opt/scripts/* $(BSP_PACKAGE_DIR)/opt/scripts/
	@mkdir -pv $(BSP_PACKAGE_DIR)/soc/scripts/
	@cp -p -r $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/soc/scripts/* $(BSP_PACKAGE_DIR)/soc/scripts/
	@mkdir -pv $(BSP_PACKAGE_DIR)/usr/
	@cp -p -r $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/usr/* $(BSP_PACKAGE_DIR)/usr/
	@rm -f $(BSP_PACKAGE_DIR)/usr/bin/fw_*env
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(OSDRVVERSION)$(BSPRELEASE)/' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: linux-image-sg200x/Package: $(CHIP_VENDOR)-bsp-$(BOARD)-$(VARIANT)/' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i  '/Depends: .*/d' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i  '/Recommends: .*/d' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i  '/Provides: .*/d' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Linux Image/BSP/' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(BSP_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(CHIP_VENDOR)-bsp-$(BOARD)-$(VARIANT) $(CHIP_VENDOR)-bsp-$(BOARD)-$(VARIANT)_$(OSDRVVERSION)$(BSPRELEASE)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(CHIP_VENDOR)-bsp-$(BOARD)-$(VARIANT)_$(OSDRVVERSION)$(BSPRELEASE)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/etc/
	@cp -p $(BUILDDIR)/bsp/axerabin/$(CHIP)/rootfs/etc/rc.local /rootfs/etc/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/$(CHIP_VENDOR)-bsp-*.deb /rootfs/tmp/install/
	@echo " wifi" >> /rootfs/tmp/install/systemd-enable
	$(call firmware_package_action,,)
	@cp /output/$(CHIP_VENDOR)-firmware-$(BOARD_EXT)_*.deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/uboot-prepare-checkout-stamp: $(BUILDDIR)/bsp-prepare-checkout-stamp
	@echo "$(COLOUR_GREEN)Checking out U-Boot for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@ln -s bsp/u-boot $(BUILDDIR)/u-boot
	@touch $@

$(BUILDDIR)/uboot-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/uboot-prepare-checkout-stamp
	@echo "$(COLOUR_GREEN)Patching U-Boot for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/u-boot/*.patch), cd $(BUILDDIR)/u-boot && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/u-boot/*.patch), cd $(BUILDDIR)/u-boot && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/u-boot/*.patch), cd $(BUILDDIR)/u-boot && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)/*), cp $(file) $(BUILDDIR)/u-boot/arch/$(UBOOT_ARCH)/dts/;)
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)_$(UBOOT_ARCH)/*), cp $(file) $(BUILDDIR)/u-boot/arch/$(UBOOT_ARCH)/dts/;)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/dts/*), cp $(file) $(BUILDDIR)/u-boot/arch/$(UBOOT_ARCH)/dts/;)
	@touch $@

define uboot_configure_action
	@echo "$(COLOUR_GREEN)Configuring U-Boot for $(BOARD) ${1}$(END_COLOUR)"
	@cp /configs/$(BOARD_CFG)/u-boot/defconfig $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig
	@touch $@
endef

define uboot_compile_action
	@echo "$(COLOUR_GREEN)Building U-Boot for $(BOARD) ${1}$(END_COLOUR)"
	@cd $(BUILDDIR)/bsp && ./scripts/build-u-boot.sh
	@touch $@
endef

$(BUILDDIR)/uboot-%.prepare-configure-stamp: $(BUILDDIR)/uboot-prepare-patch-stamp
	$(eval PANEL_TUNING_FSBL=$(patsubst uboot-%.prepare-configure-stamp,%,$(notdir $@)))
	$(eval PANEL_PACKAGE_FSBL=$(shell echo '$(PANEL_TUNING_FSBL)' | tr '[:upper:]_' '[:lower:]-' | sed s/'^mipi-panel-'/'-'/g))
	$(call uboot_configure_action,PANEL_TUNING_PARAM="$(PANEL_TUNING_FSBL)",$(PANEL_PACKAGE_FSBL))

$(BUILDDIR)/uboot-%.compile-stamp: $(BUILDDIR)/uboot-%.prepare-configure-stamp
	$(eval PANEL_TUNING_FSBL=$(patsubst uboot-%.compile-stamp,%,$(notdir $@)))
	$(call uboot_compile_action,PANEL_TUNING_PARAM="$(PANEL_TUNING_FSBL)")

$(BUILDDIR)/uboot-prepare-configure-stamp: $(BUILDDIR)/uboot-prepare-patch-stamp
	$(call uboot_configure_action,,)

$(BUILDDIR)/uboot-compile-stamp: $(BUILDDIR)/bsp-compile-stamp $(BUILDDIR)/uboot-prepare-configure-stamp
	$(call uboot_compile_action,)

uboot: $(BUILDDIR)/uboot-compile-stamp

uboot-clean:
	@rm -rf $(BUILDDIR)/u-boot
	@rm -f $(BUILDDIR)/uboot-*-stamp

$(BUILDDIR)/fsbl-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out FSBL for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@touch $@

$(BUILDDIR)/fsbl-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/fsbl-prepare-checkout-stamp
	@echo "$(COLOUR_GREEN)Patching FSBL for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/fsbl/*.patch), cd $(BUILDDIR)/fsbl && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/fsbl/*.patch), cd $(BUILDDIR)/fsbl && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/fsbl/*.patch), cd $(BUILDDIR)/fsbl && git apply --ignore-whitespace $(file);)
	@touch $@

define fsbl_compile_action
	@echo "$(COLOUR_GREEN)Building FSBL for $(BOARD) ${1}$(END_COLOUR)"
	@touch $@
endef

define fsbl_package_action
	@echo "$(COLOUR_GREEN)Packaging FSBL for $(BOARD) ${1}$(END_COLOUR)"
	@touch $@
endef

$(BUILDDIR)/fsbl-%.compile-stamp: $(BUILDDIR)/fsbl-prepare-patch-stamp $(BUILDDIR)/uboot-%.compile-stamp
	$(eval PANEL_TUNING_FSBL=$(patsubst fsbl-%.compile-stamp,%,$(notdir $@)))
	$(call fsbl_compile_action,PANEL_TUNING_PARAM="$(PANEL_TUNING_FSBL)")

$(BUILDDIR)/fsbl-%.package-stamp: $(BUILDDIR)/fsbl-%.compile-stamp
	$(eval PANEL_TUNING_FSBL=$(patsubst fsbl-%.package-stamp,%,$(notdir $@)))
	$(eval PANEL_PACKAGE_FSBL=$(shell echo '$(PANEL_TUNING_FSBL)' | tr '[:upper:]_' '[:lower:]-' | sed s/'^mipi-panel-'/'-'/g))
	$(call fsbl_package_action,PANEL_TUNING_PARAM="$(PANEL_TUNING_FSBL)",$(PANEL_PACKAGE_FSBL))

$(BUILDDIR)/fsbl-compile-stamp: $(BUILDDIR)/fsbl-prepare-patch-stamp $(BUILDDIR)/uboot-compile-stamp
	$(call fsbl_compile_action,)

$(BUILDDIR)/fsbl-package-stamp: $(BUILDDIR)/bsp-package-stamp $(BUILDDIR)/fsbl-compile-stamp
	$(call fsbl_package_action,,)
	@touch $@

fsbl: $(FSBL_TARGETS)

fsbl-clean:
	@rm -rf $(BUILDDIR)/fsbl
	@rm -rf $(BUILDDIR)/package/$(CHIP_VENDOR)-fsbl-*
	@rm -f $(BUILDDIR)/fsbl-*-stamp


$(BUILDDIR)/image-prepare-stamp: 
	@echo "$(COLOUR_GREEN)Preparing Image for $(BOARD)$(END_COLOUR)"
	@-mkdir $(BUILDDIR)
	@rm -rf /rootfs/
	@-rm $(addon-targets)
	@mkdir -p /rootfs/
	@[ "X$(DEB_PUBKEY)" = "X" ] || gpg --recv-key --keyserver $(DEB_KEYSERVER) $(DEB_PUBKEY) || true
	@[ "X$(DEB_PUBKEY)" = "X" ] || gpg --export $(DEB_PUBKEY) > /etc/apt/trusted.gpg.d/distro-archive-keyring.gpg
	@curl -v -L $(USER_SITE_URL)/scpcom-packages.asc -o $(BUILDDIR)/public-key.asc
	@mmdebstrap -v --architectures=$(DEB_ARCH) --include="$(_PACKAGES) $(_DEV_PACKAGES)" $(DEB_DISTRO) "/rootfs/" "deb $(DEB_URL)/ $(DEB_DISTRO) $(DEB_COMPONENTS)" "deb [signed-by=$(BUILDDIR)/public-key.asc] $(USER_SITE_URL)/deb stable $(CHIP_FAMILY) $(BOARD)-$(VARIANT)"
	@touch $@

$(BUILDDIR)/image-configure-stamp: $(BUILDDIR)/image-prepare-stamp $(BUILDDIR)/linux-package-stamp $(FSBL_TARGETS)
	@echo "$(COLOUR_GREEN)Configuring Image for $(BOARD)$(END_COLOUR)"
	@$(eval KERNEL_DEB_ARCH=$(shell grep -m1 '^Architecture: ' $(KERNEL_OUTPUT_DIR)/debian/control | cut -d ' ' -f 2))
	@mkdir -p /rootfs/tmp/install/
	@cp -p /etc/resolv.conf /rootfs/tmp/install/
	@cp -v /usr/bin/qemu-$(QEMU_ARCH)-static /rootfs/tmp/install/
	@cp -v /configs/chip/$(CHIP_FAMILY)/config_rootfs.sh /rootfs/tmp/install/
	@[ $(DEB_ARCH) = $(KERNEL_DEB_ARCH) ] || chroot /rootfs/ /tmp/install/qemu-$(QEMU_ARCH)-static /usr/bin/dpkg --add-architecture $(KERNEL_DEB_ARCH)
	@chroot /rootfs/ /tmp/install/qemu-$(QEMU_ARCH)-static /bin/sh /tmp/install/config_rootfs.sh
	@rm -f /rootfs/tmp/install/resolv.conf
	@umount /rootfs/proc || true
	@umount /rootfs/sys || true
	@umount /rootfs/run || true
	@umount /rootfs/dev || true
	@touch $@

$(BUILDDIR)/image-addons-stamp: $(BUILDDIR)/image-configure-stamp $(BUILDDIR)/osdrv-package-stamp $(BUILDDIR)/middleware-package-stamp $(addon-targets)
	@echo "$(COLOUR_GREEN)Packaging board-support-$(CHIP_FAMILY) for $(BOARD)$(END_COLOUR)"
	@$(eval KERNEL_DEB_ARCH=$(shell grep -m1 '^Architecture: ' $(KERNEL_OUTPUT_DIR)/debian/control | cut -d ' ' -f 2))
	@$(eval BOARD_SUPPORT_PACKAGE_DIR=$(BUILDDIR)/package/board-support-$(BOARD)-$(VARIANT)-$(BSPVERSION))
	@mkdir -p $(BOARD_SUPPORT_PACKAGE_DIR)
	@cp -r /builder/deb/board-support-sg200x/* $(BOARD_SUPPORT_PACKAGE_DIR)/
	@mkdir -pv $(BOARD_SUPPORT_PACKAGE_DIR)/usr/share/doc/board-support-$(BOARD)-$(VARIANT)/
	@echo "meta package" > $(BOARD_SUPPORT_PACKAGE_DIR)/usr/share/doc/board-support-$(BOARD)-$(VARIANT)/README
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(BSPVERSION)/' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: board-support-sg200x/Package: board-support-$(BOARD)-$(VARIANT)/' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Depends: .*/Depends: $(_BSPDEPENDS)/' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's|$(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)|$(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT):$(KERNEL_DEB_ARCH)|g' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's|linux-headers-$(BOARD)-$(VARIANT)|linux-headers-$(BOARD)-$(VARIANT):$(KERNEL_DEB_ARCH)|g' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's|linux-image-$(BOARD)-$(VARIANT)|linux-image-$(BOARD)-$(VARIANT):$(KERNEL_DEB_ARCH)|g' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Recommends: .*/Recommends: $(_BSPRECOMMENDS)/' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@[ "X$(findstring kvm,$(VARIANT))" = "X" ] || echo 'rm -f /etc/nginx/sites-enabled/default' >> $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/postinst
	@if [ -f /rootfs/tmp/install/systemd-enable ]; then \
		echo "systemctl enable `cat /rootfs/tmp/install/systemd-enable | tr -d '\n'`" >> $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/postinst ; \
	fi
	@chmod +x $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/postinst
	@cd $(BUILDDIR)/package/ && dpkg-deb --build board-support-$(BOARD)-$(VARIANT)-$(BSPVERSION) board-support-$(BOARD)-$(VARIANT)_$(BSPVERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/board-support-$(BOARD)-$(VARIANT)_$(BSPVERSION)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/board-support-$(BOARD)-$(VARIANT)*.deb /rootfs/tmp/install/
	@echo "$(COLOUR_GREEN)Copying Deb files for installation on $(BOARD)$(END_COLOUR)"
	#@cp /output/$(CHIP_VENDOR)-fsbl-$(BOARD_EXT)_*.deb /rootfs/tmp/install/
	@cp /output/$(CHIP_VENDOR)-osdrv-*.deb /rootfs/tmp/install/
	@cp /output/$(CHIP_VENDOR)-middleware-$(BOARD)_*.deb /rootfs/tmp/install/
	@cp /output/linux-image-*.deb /rootfs/tmp/install/
	@cp /output/linux-headers-*.deb /rootfs/tmp/install/
	@cp /output/linux-libc-dev*.deb /rootfs/tmp/install/
	@touch $@


$(BUILDDIR)/image-customize-stamp: $(BUILDDIR)/image-addons-stamp $(BUILDDIR)/image-configure-stamp
	@echo "$(COLOUR_GREEN)Customizing Image for $(BOARD)$(END_COLOUR)"
	@mkdir -p /rootfs/tmp/install/
	@echo $(GIT_REF) > /rootfs/tmp/install/gitref
	@echo $(BOARD) > /rootfs/tmp/install/hostname
	@echo $(BOARD) > /rootfs/tmp/install/board
	@echo $(CHIP_VENDOR) > /rootfs/tmp/install/chip_vendor
	@echo $(VARIANT) > /rootfs/tmp/install/variant
	@echo $(STORAGE_TYPE) > /rootfs/tmp/install/storage
	@echo "deb $(DEB_URL) $(DEB_DISTRO) $(DEB_COMPONENTS_FULL)" > /rootfs/tmp/install/deb_sources
	@echo "deb $(USER_SITE_URL)/deb stable $(CHIP_FAMILY) $(BOARD)-$(VARIANT)" > /rootfs/tmp/install/deb_user_sources
	@cp -v /usr/bin/qemu-$(QEMU_ARCH)-static /rootfs/tmp/install/
	@cp -v /configs/chip/$(CHIP_FAMILY)/setup_rootfs.sh /rootfs/tmp/install/
	@cp -v $(BUILDDIR)/public-key.asc /rootfs/tmp/install/
	@chroot /rootfs/ /tmp/install/qemu-$(QEMU_ARCH)-static /bin/sh /tmp/install/setup_rootfs.sh
	@rm -rf /rootfs/tmp/install/
	@umount /rootfs/proc || true 
	@umount /rootfs/sys || true 
	@umount /rootfs/run || true 
	@umount /rootfs/dev || true
	@touch $@

ifneq ("$(findstring kvm,$(VARIANT))","")
IMAGE_APP_VERSION ?= $(NANOKVM_PRO_VERSION)
else
MAIX_PY_VERSION ?= 4.12.4
IMAGE_APP_VERSION ?= $(MAIX_PY_VERSION)
endif

$(BUILDDIR)/image-dev-list-stamp: $(BUILDDIR)/image-customize-stamp $(BUILDDIR)/python3-dev-uninstall-stamp
	@echo "$(COLOUR_GREEN)Listing dev packages for $(BOARD)$(END_COLOUR)"
	@chroot /rootfs apt-get update || true
	@for p in libwebsockets-evlib-uv ; do \
		chroot /rootfs dpkg -s $$p | grep -q '^Version:' || continue ; \
		echo $$p >> $(BUILDDIR)/image-libs-$(BOARD) ; \
	done
	@for d in $(_PACKAGES) $(_DEV_PACKAGES) ; do \
		echo $$d | grep -q -E '^lib.*-dev$$' || continue ; \
		l=`echo $$d | sed s/'-dev$$'/''/g` ; \
		chroot /rootfs dpkg -s $$d | grep -q '^Version:' || continue ; \
		p=`chroot /rootfs dpkg -S $${l}.so.* 2>/dev/null | grep -v $$d | grep -m1 ':'$(DEB_ARCH)':' | cut -d ':' -f 1` ; \
		[ "$$p" != "" ] || l=`echo $$d | sed s/'-dev$$'/''/g | sed s/'[0-9]*$$'/''/g` ; \
		[ "$$p" != "" ] || p=`chroot /rootfs dpkg -S $${l}.so.* 2>/dev/null | grep -v $$d | grep -m1 ':'$(DEB_ARCH)':' | cut -d ':' -f 1` ; \
		[ "$$p" != "" ] || continue ; \
		chroot /rootfs dpkg -S $${l}.so.* 2>/dev/null | grep -v $$d | grep ':'$(DEB_ARCH)':' | cut -d ':' -f 1 | uniq | while read p ; do \
			echo $$p >> $(BUILDDIR)/image-libs-$(BOARD) ; \
		done && \
		echo $$d >> $(BUILDDIR)/image-dev-$(BOARD) ; \
	done
	@for d in $(_DEV_PACKAGES) ; do \
		chroot /rootfs dpkg -s $$d | grep -q '^Version:' || continue ; \
		echo $$d >> $(BUILDDIR)/image-dev-$(BOARD) ; \
	done
	@touch $@

$(BUILDDIR)/image-dev-uninstall-stamp: $(BUILDDIR)/image-dev-list-stamp
	@echo "$(COLOUR_GREEN)Uninstalling dev packages for $(BOARD)$(END_COLOUR)"
	@$(eval IMAGE_LIBS_DEPENDS=$(shell cat $(BUILDDIR)/image-libs-$(BOARD) | sort | uniq | tr '\n' ' '))
	@$(eval IMAGE_DEV_DEPENDS=$(shell cat $(BUILDDIR)/image-dev-$(BOARD) | sort | uniq | tr '\n' ' '))
	@chroot /rootfs mount proc -t proc /proc
	@chroot /rootfs apt-get install -y $(IMAGE_LIBS_DEPENDS)
	@chroot /rootfs apt-get remove --purge -y $(IMAGE_DEV_DEPENDS)
	@chroot /rootfs apt-get autoremove --purge -y
	@umount /rootfs/proc || true
	@chroot /rootfs apt-get clean
	@touch $@

$(BUILDDIR)/image-libs-package-stamp: $(BUILDDIR)/image-dev-uninstall-stamp
	@echo "$(COLOUR_GREEN)Packaging image-libs-$(CHIP_FAMILY) for $(BOARD)$(END_COLOUR)"
	@$(eval IMAGE_LIBS_PACKAGE_DIR=$(BUILDDIR)/package/image-libs-$(BOARD)-$(VARIANT)-$(BSPVERSION))
	@$(eval IMAGE_LIBS_DEPENDS=$(shell cat $(BUILDDIR)/image-libs-$(BOARD) | sort | uniq | tr '\n' ' '))
	@$(eval _IMAGE_LIBS_DEPENDS = $(subst $(SPACE),$(COMMA)$(SPACE),$(sort $(IMAGE_LIBS_DEPENDS))))
	@mkdir -p $(IMAGE_LIBS_PACKAGE_DIR)
	@cp -r /builder/deb/board-support-sg200x/* $(IMAGE_LIBS_PACKAGE_DIR)/
	@mkdir -pv $(IMAGE_LIBS_PACKAGE_DIR)/usr/share/doc/image-libs-$(BOARD)-$(VARIANT)/
	@echo "meta package" > $(IMAGE_LIBS_PACKAGE_DIR)/usr/share/doc/image-libs-$(BOARD)-$(VARIANT)/README
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(BSPVERSION)/' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: board-support-sg200x/Package: image-libs-$(BOARD)-$(VARIANT)/' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Depends: .*/Depends: $(_IMAGE_LIBS_DEPENDS)/' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@sed -i '/Recommends: .*/d' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Board support/Image libs/' $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/control
	@rm -f $(IMAGE_LIBS_PACKAGE_DIR)/DEBIAN/postinst
	@cd $(BUILDDIR)/package/ && dpkg-deb --build image-libs-$(BOARD)-$(VARIANT)-$(BSPVERSION) image-libs-$(BOARD)-$(VARIANT)_$(BSPVERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/image-libs-$(BOARD)-$(VARIANT)_$(BSPVERSION)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/image-libs-$(BOARD)-$(VARIANT)*.deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/image-dev-package-stamp: $(BUILDDIR)/image-dev-uninstall-stamp $(BUILDDIR)/image-libs-package-stamp
	@echo "$(COLOUR_GREEN)Packaging image-dev-$(CHIP_FAMILY) for $(BOARD)$(END_COLOUR)"
	@$(eval IMAGE_DEV_PACKAGE_DIR=$(BUILDDIR)/package/image-dev-$(BOARD)-$(VARIANT)-$(BSPVERSION))
	@$(eval IMAGE_DEV_DEPENDS=$(shell cat $(BUILDDIR)/image-dev-$(BOARD) | sort | uniq | tr '\n' ' '))
	@$(eval _IMAGE_DEV_DEPENDS = $(subst $(SPACE),$(COMMA)$(SPACE),$(sort $(IMAGE_DEV_DEPENDS))))
	@mkdir -p $(IMAGE_DEV_PACKAGE_DIR)
	@cp -r /builder/deb/board-support-sg200x/* $(IMAGE_DEV_PACKAGE_DIR)/
	@mkdir -pv $(IMAGE_DEV_PACKAGE_DIR)/usr/share/doc/image-dev-$(BOARD)-$(VARIANT)/
	@echo "meta package" > $(IMAGE_DEV_PACKAGE_DIR)/usr/share/doc/image-dev-$(BOARD)-$(VARIANT)/README
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(BSPVERSION)/' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: board-support-sg200x/Package: image-dev-$(BOARD)-$(VARIANT)/' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Depends: .*/Depends: $(_IMAGE_DEV_DEPENDS)/' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i '/Recommends: .*/d' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Board support/Image development/' $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/control
	@rm -f $(IMAGE_DEV_PACKAGE_DIR)/DEBIAN/postinst
	@cd $(BUILDDIR)/package/ && dpkg-deb --build image-dev-$(BOARD)-$(VARIANT)-$(BSPVERSION) image-dev-$(BOARD)-$(VARIANT)_$(BSPVERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/image-dev-$(BOARD)-$(VARIANT)_$(BSPVERSION)_$(DEB_ARCH).deb /output/
	@#mkdir -p /rootfs/tmp/install/
	@#cp /output/image-dev-$(BOARD)-$(VARIANT)*.deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/image-compile-stamp: $(BUILDDIR)/image-customize-stamp $(BUILDDIR)/image-dev-package-stamp
	@echo "$(COLOUR_GREEN)Compiling Image for $(BOARD)$(END_COLOUR)"
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BR_DIR)/dl
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BR_OUTPUT_DIR)/per-package
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BUILDDIR)/bsp/build/dl/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BUILDDIR)/bsp/toolchain/gcc-*/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BUILDDIR)/nanokvm-pro/NanoKVM-Pro/server/vendor/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BUILDDIR)/nanokvm-pro/NanoKVM-Pro/support/toolchains/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BUILDDIR)/nanokvm-pro/NanoKVM-Pro/web/node_modules
	@[ "$(GIT_REF)" = "develop" ] || rm -f /builder/gcc-*.tar.*
	@[ "$(GIT_REF)" = "develop" ] || rm -rf /host-tools/gcc/
	@rm -rf /tmp/genimage/
	@mkdir -p $(BUILDDIR)/input/
	@[ ! -e $(BSP_INSTALL_DIR)/$(STORAGE_TYPE).img ] || cp -p $(BSP_INSTALL_DIR)/$(STORAGE_TYPE).img $(BUILDDIR)/input/
	@cd $(BUILDDIR) && genimage --config /configs/chip/$(CHIP_FAMILY)/genimage_$(STORAGE_TYPE).cfg --tmppath /tmp/genimage --rootpath /rootfs/
	@rm -rf /tmp/genimage/
	@lz4 -9 -f $(BUILDDIR)/images/sdcard.img /output/$(BOARD)_$(STORAGE_TYPE).img.lz4
	@echo "$(COLOUR_GREEN)Image for $(BOARD) is $(BOARD)_$(STORAGE_TYPE).img$(END_COLOUR)"
	@if [ "$(STORAGE_TYPE)" = "emmc" ]; then \
		mkdir -p /tmp/rom/; \
		rm -f $(BUILDDIR)/images/boot.vfat ; \
		rm -f $(BUILDDIR)/images/root.ext4 ; \
		mkdir -p /tmp/rom/root/ ; \
		mv $(BUILDDIR)/images/sdcard.img /tmp/rom/root/$(BOARD)_$(GIT_REF).img; \
		mkdir -p /tmp/rom/boot/ ; \
		cp -p $(BSP_INSTALL_DIR)/atf.img /tmp/rom/boot/ ; \
		cp -p $(BSP_INSTALL_DIR)/boot.bin.tmp /tmp/rom/boot/boot.bin ; \
		cp -p $(BSP_INSTALL_DIR)/dtb.img /tmp/rom/boot/ ; \
		cp -p $(BSP_INSTALL_DIR)/kernel.img /tmp/rom/boot/ ; \
		cp -p $(BSP_INSTALL_DIR)/uboot.bin /tmp/rom/boot/ ; \
		touch /tmp/rom/boot/rec ; \
		cd $(BUILDDIR) && genimage --config /configs/chip/$(CHIP_FAMILY)/genimage_sdcard.cfg --tmppath /tmp/genimage --rootpath /tmp/rom/ ; \
		mv $(BUILDDIR)/images/sdcard.img $(BUILDDIR)/images/$(BOARD)_sdcard.img ; \
		echo "Image Version: $(GIT_REF)" > $(BUILDDIR)/images/README.md ; \
		echo "App Version: $(IMAGE_APP_VERSION)" >> $(BUILDDIR)/images/README.md ; \
		cd $(BUILDDIR)/images && zip /output/$(BOARD)_sdcard.zip $(BOARD)_sdcard.img README.md ; \
		echo "$(COLOUR_GREEN)Image for $(BOARD) is $(BOARD)_sdcard.zip$(END_COLOUR)"; \
	fi
	@touch $@

image: $(BUILDDIR)/image-compile-stamp

image-clean:
	@rm -rf /rootfs/
	@rm -f $(BUILDDIR)/image-*-stamp $(addon-targets)
	@rm -f /output/$(BOARD)_$(STORAGE_TYPE).img

image-clean-customize:
	@rm -f $(BUILDDIR)/image-customize-stamp

clean: uboot-clean linux-clean osdrv-clean middleware-clean fsbl-clean

.PHONY: image clean uboot linux osdrv middleware fsbl fsbl-clean uboot-clean linux-clean

FSBLVERSION=1.2.0
OSDRVVERSION=2024.11.20
MIDDLEWAREVERSION=2024.11.20

CROSS_COMPILE_64 = aarch64-none-linux-gnu-
CROSS_COMPILE_32 = arm-none-linux-gnueabihf-

CROSS_COMPILE_PATH_64 = /host-tools/gcc/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu
CROSS_COMPILE_PATH_32 = /host-tools/gcc/gcc-arm-9.2-2019.12-x86_64-arm-none-linux-gnueabihf

ifeq ($(SDK_VER),64bit)
SDK_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_64)
SDK_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_64)
else ifeq ($(SDK_VER),32bit)
SDK_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_32)
SDK_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_32)
else
$(error $(red)SDK_VER is invalid$(reset))
endif

ifeq ($(UBOOT_ARCH),arm)
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

BSPDEPENDS = $(CHIP_VENDOR)-middleware-$(BOARD)\
 $(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)\
 linux-headers-$(BOARD)-$(VARIANT)\
 linux-image-$(BOARD)-$(VARIANT)
BSPRECOMMENDS = $(CHIP_VENDOR)-fsbl-$(BOARD_EXT)
BSPFILTER =

AIC8800_TARGET_DIR ?= /opt/firmware

include $(wildcard /builder/addons/*/addon.mk)

addon-targets = $(patsubst "%,$(BUILDDIR)/%-stamp,$(patsubst %",%,$(IMAGE_ADDITIONS)))
_PACKAGES = $(patsubst "%,%,$(patsubst %",%,$(PACKAGES)))

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

NPROCS := $(shell nproc)


define copy_ko_action
	@mkdir -p $(BUILDDIR)/osdrv/ko
	$(foreach kodir, $(KO_DIRS), find ${1}/lib/modules/*/kernel/$(kodir) -name '*.ko' -exec cp -f {} $(BUILDDIR)/osdrv/ko/ \; || true ;)
endef

$(BUILDDIR)/toolchain-prepare-patch-stamp:
	@echo "$(COLOUR_GREEN)Patching Toolchain for $(BOARD)$(END_COLOUR)"
	@if [ "$(UBOOT_ARCH)" = "arm" ]; then \
		rm -rf /host-tools/gcc/riscv64-*/ ; \
		cd / && /builder/replace-all-arm-toolchains.sh ; \
		mv /ramdisk $(BUILDDIR)/ ; \
	else \
		mkdir -p /host-tools/gcc ; \
		wget -O - https://github.com/scpcom/riscv-gnu-toolchain/releases/download/riscv64-gcc-thead_20241206-10.4.0-x86_64/riscv64-linux-gcc-thead_20241206-10.4.0-x86_64.tar.gz | tar -C /host-tools/gcc -xz ; \
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
	@cp -p $(BUILDDIR)/bsp/axerabin/ax630c/rootfs/soc/ko/ax_*.ko $(BUILDDIR)/osdrv/ko/
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
	@mkdir -pv $(BUILDDIR)/middleware/install/system/lib/
	@cp -p $(BUILDDIR)/bsp/axerabin/ax630c/rootfs/opt/lib/*.so* $(BUILDDIR)/middleware/install/system/lib/
	@touch $@

$(BUILDDIR)/middleware-package-stamp: $(BUILDDIR)/middleware-compile-stamp
	@cd $(BUILDDIR)/bsp && [ "$(GIT_REF)" = "develop" ] || ./scripts/build-linux.sh clean
	@echo "$(COLOUR_GREEN)Packaging Middleware for $(BOARD)$(END_COLOUR)"
	@rm -rf $(BUILDDIR)/middleware/3rdparty/tmp/
	@$(eval MV=$(shell cd $(BUILDDIR)/middleware && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@$(eval MIDDLEWARE_PACKAGE_DIR=$(BUILDDIR)/package/$(CHIP_VENDOR)-middleware-$(BOARD)-$(MIDDLEWAREVERSION))
	@$(eval MIDDLEWARE_TARGET_DIR=/opt)
	@mkdir -p $(MIDDLEWARE_PACKAGE_DIR)
	@cp -r /builder/deb/cvitek-middleware/* $(MIDDLEWARE_PACKAGE_DIR)/
	@mkdir -pv $(MIDDLEWARE_PACKAGE_DIR)$(MIDDLEWARE_TARGET_DIR)/
	@rsync -avpPxH $(BUILDDIR)/middleware/install/system/ $(MIDDLEWARE_PACKAGE_DIR)$(MIDDLEWARE_TARGET_DIR)/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(MIDDLEWAREVERSION)$(MV)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvitek-middleware/Package: $(CHIP_VENDOR)-middleware-$(BOARD)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/RISC-V/$(ARCH_NAME)/' $(MIDDLEWARE_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(CHIP_VENDOR)-middleware-$(BOARD)-$(MIDDLEWAREVERSION) $(CHIP_VENDOR)-middleware-$(BOARD)_$(MIDDLEWAREVERSION)$(MV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(CHIP_VENDOR)-middleware-$(BOARD)_$(MIDDLEWAREVERSION)$(MV)_$(DEB_ARCH).deb /output/
	@touch $@

middleware: $(BUILDDIR)/middleware-package-stamp

middleware-clean:
	@rm -rf $(BUILDDIR)/middleware
	@rm -f $(BUILDDIR)/middleware-*-stamp


$(BUILDDIR)/buildroot-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out Buildroot for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b nanokvm-2025.02 $(GIT_CLONE_OPTS) --recursive https://github.com/scpcom/buildroot.git $(BUILDDIR)/buildroot
	@cd $(BR_DIR) && git checkout 1ef3acd
	@mkdir -p $(BUILDDIR)/ramdisk/tools
	@git clone -b main https://github.com/scpcom/cvi-pinmux $(BUILDDIR)/ramdisk/tools/cvi_pinmux
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


$(BUILDDIR)/bsp-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out BSP for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b main $(GIT_CLONE_OPTS) --recursive https://github.com/scpcom/ax620e-bsp-build $(BUILDDIR)/bsp
	@cd $(BUILDDIR)/bsp && git checkout 2352e03
	@touch $@

$(BUILDDIR)/bsp-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/bsp-prepare-checkout-stamp
	@echo "$(COLOUR_GREEN)Patching BSP for $(BOARD)$(END_COLOUR)"
	@sed -i '/get-toolchain.sh/d' $(BUILDDIR)/bsp/build.sh
	@sed -i 's|^CROSS_COMPILE_PATH=.*|CROSS_COMPILE_PATH=$(SBL_CROSS_COMPILE_PATH)|g' $(BUILDDIR)/bsp/scripts/envsetup_pack.sh
	@sed -i 's|^CROSS_COMPILE=.*|CROSS_COMPILE=$(SBL_CROSS_COMPILE_PREFIX)|g' $(BUILDDIR)/bsp/scripts/envsetup_pack.sh
	@sed -i 's|dtb EXTRA_CFLAGS|dtb BOARD=$(UBOOT_FAMILY) EXTRA_CFLAGS|g' $(BUILDDIR)/bsp/scripts/build-u-boot.sh
	@touch $@

$(BUILDDIR)/bsp-compile-stamp: $(BUILDDIR)/bsp-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Building BSP for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/bsp && ./build.sh
	@touch $@

$(BUILDDIR)/bsp-package-stamp: $(BUILDDIR)/bsp-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging BSP for $(BOARD)$(END_COLOUR)"
	@$(eval BSPRELEASE=$(shell cd $(BUILDDIR)/bsp && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@$(eval BSP_PACKAGE_DIR=$(BUILDDIR)/package/$(CHIP_VENDOR)-bsp-$(BOARD)-$(VARIANT))
	@mkdir -p $(BSP_PACKAGE_DIR)
	@cp -r /builder/deb/linux-image-sg200x/* $(BSP_PACKAGE_DIR)/
	@mkdir -pv $(BSP_PACKAGE_DIR)/etc/
	@cp -p -r $(BUILDDIR)/bsp/axerabin/ax630c/rootfs/etc/* $(BSP_PACKAGE_DIR)/etc/
	@mv $(BSP_PACKAGE_DIR)/etc/rc.local $(BSP_PACKAGE_DIR)/etc/rc.local.$(CHIP_VENDOR)
	@mkdir -pv $(BSP_PACKAGE_DIR)/opt/scripts/
	@cp -p -r $(BUILDDIR)/bsp/axerabin/ax630c/rootfs/opt/scripts/* $(BSP_PACKAGE_DIR)/opt/scripts/
	@mkdir -pv $(BSP_PACKAGE_DIR)/soc/scripts/
	@cp -p -r $(BUILDDIR)/bsp/axerabin/ax630c/rootfs/soc/scripts/* $(BSP_PACKAGE_DIR)/soc/scripts/
	@mkdir -pv $(BSP_PACKAGE_DIR)/usr/
	@cp -p -r $(BUILDDIR)/bsp/axerabin/ax630c/rootfs/usr/* $(BSP_PACKAGE_DIR)/usr/
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
	@cp -p $(BUILDDIR)/bsp/axerabin/ax630c/rootfs/etc/rc.local /rootfs/etc/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/$(CHIP_VENDOR)-bsp-*.deb /rootfs/tmp/install/
	@echo " wifi" >> /rootfs/tmp/install/systemd-enable
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
	@[ "X$(DEB_PUBKEY)" = "X" ] || gpg --recv-key --keyserver $(DEB_KEYSERVER) $(DEB_PUBKEY)
	@[ "X$(DEB_PUBKEY)" = "X" ] || gpg --export $(DEB_PUBKEY) > /etc/apt/trusted.gpg.d/distro-archive-keyring.gpg
	@curl -v -L https://scpcom.github.io/scpcom-packages.asc -o $(BUILDDIR)/public-key.asc
	@mmdebstrap -v --architectures=$(DEB_ARCH) --include="$(_PACKAGES)" $(DEB_DISTRO) "/rootfs/" "deb $(DEB_URL)/ $(DEB_DISTRO) $(DEB_COMPONENTS)" "deb [signed-by=$(BUILDDIR)/public-key.asc] https://scpcom.github.io/deb stable $(CHIP_FAMILY) $(BOARD)-$(VARIANT)"
	@touch $@

$(BUILDDIR)/image-addons-stamp: $(BUILDDIR)/image-prepare-stamp $(FSBL_TARGETS) $(BUILDDIR)/linux-package-stamp $(BUILDDIR)/osdrv-package-stamp $(BUILDDIR)/middleware-package-stamp $(addon-targets)
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
	#@sed -i 's|linux-image-$(BOARD)-$(VARIANT)|linux-image-$(BOARD)-$(VARIANT):$(KERNEL_DEB_ARCH)|g' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's|linux-image-$(BOARD)-$(VARIANT)|$(CHIP_VENDOR)-bsp-$(BOARD)-$(VARIANT):$(KERNEL_DEB_ARCH)|g' $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/control
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
	#@cp /output/linux-image-*.deb /rootfs/tmp/install/
	@cp /output/linux-headers-*.deb /rootfs/tmp/install/
	@cp /output/linux-libc-dev*.deb /rootfs/tmp/install/
	@touch $@


$(BUILDDIR)/image-customize-stamp: $(BUILDDIR)/image-addons-stamp $(BUILDDIR)/linux-package-stamp $(FSBL_TARGETS)
	@echo "$(COLOUR_GREEN)Customizing Image for $(BOARD)$(END_COLOUR)"
	@$(eval KERNEL_DEB_ARCH=$(shell grep -m1 '^Architecture: ' $(KERNEL_OUTPUT_DIR)/debian/control | cut -d ' ' -f 2))
	@mkdir -p /rootfs/tmp/install/
	@echo $(GIT_REF) > /rootfs/tmp/install/gitref
	@echo $(BOARD) > /rootfs/tmp/install/hostname
	@echo $(BOARD) > /rootfs/tmp/install/board
	@echo $(CHIP_VENDOR) > /rootfs/tmp/install/chip_vendor
	@echo $(VARIANT) > /rootfs/tmp/install/variant
	@echo $(STORAGE_TYPE) > /rootfs/tmp/install/storage
	@echo "deb $(DEB_URL) $(DEB_DISTRO) $(DEB_COMPONENTS_FULL)" > /rootfs/tmp/install/deb_sources
	@[ "$(DEB_DISTRO)" != "jammy" -o -e /rootfs/etc/resolv.conf-dist ] || mv /rootfs/etc/resolv.conf /rootfs/etc/resolv.conf-dist
	@[ "$(DEB_DISTRO)" != "jammy" ] || cp -p /etc/resolv.conf /rootfs/etc/
	@cp -v /usr/bin/qemu-$(QEMU_ARCH)-static /rootfs/tmp/install/
	@cp -v /configs/chip/$(CHIP_FAMILY)/setup_rootfs.sh /rootfs/tmp/install/
	@cp -v $(BUILDDIR)/public-key.asc /rootfs/tmp/install/
	@[ $(DEB_ARCH) = $(KERNEL_DEB_ARCH) ] || chroot /rootfs/ /tmp/install/qemu-$(QEMU_ARCH)-static /usr/bin/dpkg --add-architecture $(KERNEL_DEB_ARCH)
	@chroot /rootfs/ /tmp/install/qemu-$(QEMU_ARCH)-static /bin/sh /tmp/install/setup_rootfs.sh
	@rm -rf /rootfs/tmp/install/
	@umount /rootfs/proc || true 
	@umount /rootfs/sys || true 
	@umount /rootfs/run || true 
	@umount /rootfs/dev || true
	@mkdir -p /rootfs/kvmcomm/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/f_udisp_drv.ko /rootfs/kvmcomm/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/fbtft.ko /rootfs/kvmcomm/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/fb_jd9853.ko /rootfs/kvmcomm/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/gpio_keys.ko /rootfs/kvmcomm/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/lt6911_manage.ko /rootfs/kvmcomm/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/rotary_encoder.ko /rootfs/kvmcomm/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/aic8800_*.ko /rootfs/soc/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/hynitron_touch.ko /rootfs/soc/ko/
	@touch $@

$(BUILDDIR)/image-compile-stamp: $(BUILDDIR)/image-customize-stamp
	@echo "$(COLOUR_GREEN)Compiling Image for $(BOARD)$(END_COLOUR)"
	@$(eval NANOKVM_PRO_LATEST_VER=$(shell cat $(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json | jq -c '.version' | cut -d '"' -f 2))
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BR_DIR)/dl
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BR_OUTPUT_DIR)/per-package
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BUILDDIR)/bsp/build/dl/
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(BUILDDIR)/bsp/toolchain/gcc-*/
	@[ "$(GIT_REF)" = "develop" ] || rm -f /builder/gcc-*.tar.*
	@[ "$(GIT_REF)" = "develop" ] || rm -rf /host-tools/gcc/
	@rm -rf /tmp/genimage/
	@mkdir -p $(BUILDDIR)/input/
	@cp -p $(BSP_INSTALL_DIR)/$(STORAGE_TYPE).img $(BUILDDIR)/input/
	@cd $(BUILDDIR) && genimage --config /configs/chip/$(CHIP_FAMILY)/genimage_$(STORAGE_TYPE).cfg --tmppath /tmp/genimage --rootpath /rootfs/
	@rm -rf /tmp/genimage/
	@lz4 -9 -f $(BUILDDIR)/images/sdcard.img /output/$(BOARD)_$(STORAGE_TYPE).img.lz4
	@echo "$(COLOUR_GREEN)Image for $(BOARD) is $(BOARD)_$(STORAGE_TYPE).img$(END_COLOUR)"
	@if [ "$(STORAGE_TYPE)" = "emmc" ]; then \
		mkdir -p /tmp/rom/; \
		rm -f $(BUILDDIR)/images/boot.vfat ; \
		rm -f $(BUILDDIR)/images/root.ext4 ; \
		mv $(BUILDDIR)/images/sdcard.img /tmp/rom/$(BOARD)_$(GIT_REF).img; \
		mkdir -p /tmp/rom/boot/ ; \
		cp -p $(BSP_INSTALL_DIR)/atf.img /tmp/rom/boot/ ; \
		cp -p $(BSP_INSTALL_DIR)/boot.bin.tmp /tmp/rom/boot/boot.bin ; \
		cp -p $(BSP_INSTALL_DIR)/dtb.img /tmp/rom/boot/ ; \
		cp -p $(BSP_INSTALL_DIR)/kernel.img /tmp/rom/boot/ ; \
		cp -p $(BSP_INSTALL_DIR)/uboot.bin /tmp/rom/boot/ ; \
		touch /tmp/rom/boot/rec ; \
		cd $(BUILDDIR) && genimage --config /configs/chip/$(CHIP_FAMILY)/genimage_sd.cfg --tmppath /tmp/genimage --rootpath /tmp/rom/ ; \
		mv $(BUILDDIR)/images/sdcard.img $(BUILDDIR)/images/$(BOARD)_sdcard.img ; \
		echo "Image Version: $(GIT_REF)" > $(BUILDDIR)/images/README.md ; \
		echo "App Version: $(NANOKVM_PRO_LATEST_VER)" >> $(BUILDDIR)/images/README.md ; \
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

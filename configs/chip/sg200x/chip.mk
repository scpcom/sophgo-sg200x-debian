FSBLVERSION=1.2.0
OSDRVVERSION=2024.10.14
MIDDLEWAREVERSION=2024.10.14

PACKAGES += " gpiod"

IMAGE_ADDITIONS+="overlayfs-tools"

CROSS_COMPILE_64 = aarch64-none-linux-gnu-
CROSS_COMPILE_32 = arm-none-linux-gnueabihf-
CROSS_COMPILE_GLIBC_RISCV64 = riscv64-unknown-linux-gnu-
CROSS_COMPILE_MUSL_RISCV64 = riscv64-unknown-linux-musl-

CROSS_COMPILE_PATH_64 = /host-tools/gcc/arm-gnu-toolchain-11.3.rel1-x86_64-aarch64-none-linux-gnu
CROSS_COMPILE_PATH_32 = /host-tools/gcc/arm-gnu-toolchain-11.3.rel1-x86_64-arm-none-linux-gnueabihf
CROSS_COMPILE_PATH_GLIBC_RISCV64 = /host-tools/gcc/riscv64-linux-x86_64
CROSS_COMPILE_PATH_MUSL_RISCV64 = /host-tools/gcc/riscv64-linux-musl-x86_64

SDK_SYSROOT_64 = $(CROSS_COMPILE_PATH_64)/aarch64-none-linux-gnu/libc
SDK_SYSROOT_32 = $(CROSS_COMPILE_PATH_32)/arm-none-linux-gnueabihf/libc
SDK_SYSROOT_GLIBC_RISCV64 = $(CROSS_COMPILE_PATH_GLIBC_RISCV64)/sysroot
SDK_SYSROOT_MUSL_RISCV64 = $(CROSS_COMPILE_PATH_MUSL_RISCV64)/sysroot

SDK_TARGET_LDFLAGS_64 = -mcpu=cortex-a53
SDK_TARGET_LDFLAGS_32 = -march=armv7-a
SDK_TARGET_LDFLAGS_RISCV64 = -mcpu=c906fdv -march=rv64imafdcv0p7xthead -mcmodel=medany -mabi=lp64d

ifeq ($(SDK_VER),glibc_riscv64)
SDK_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_GLIBC_RISCV64)
SDK_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_GLIBC_RISCV64)
SDK_SYSROOT = $(SDK_SYSROOT_GLIBC_RISCV64)
SDK_TARGET_LDFLAGS = $(SDK_TARGET_LDFLAGS_RISCV64)
else ifeq ($(SDK_VER),musl_riscv64)
SDK_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_MUSL_RISCV64)
SDK_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_MUSL_RISCV64)
SDK_SYSROOT = $(SDK_SYSROOT_MUSL_RISCV64)
SDK_TARGET_LDFLAGS = $(SDK_TARGET_LDFLAGS_RISCV64)
else ifeq ($(SDK_VER),64bit)
SDK_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_64)
SDK_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_64)
SDK_SYSROOT = $(SDK_SYSROOT_64)
SDK_TARGET_LDFLAGS = $(SDK_TARGET_LDFLAGS_64)
else ifeq ($(SDK_VER),32bit)
SDK_CROSS_COMPILE_PATH = $(CROSS_COMPILE_PATH_32)
SDK_CROSS_COMPILE_PREFIX = $(CROSS_COMPILE_32)
SDK_SYSROOT = $(SDK_SYSROOT_32)
SDK_TARGET_LDFLAGS = $(SDK_TARGET_LDFLAGS_32)
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

BOARD_EXT ?= $(BOARD)

KERNEL_OUTPUT_DIR = $(BUILDDIR)/kernel/build/$(BOARD)-$(VARIANT)

CHIP_VENDOR ?= cvitek

UBOOT_MAKE_OPTS = ARCH=$(UBOOT_ARCH) \
BOARD=$(UBOOT_FAMILY) \
CONFIG_USE_DEFAULT_ENV=y \
STORAGE_TYPE=$(STORAGE_TYPE) \
CHIP=$(UBOOT_CHIP) \
CVIBOARD=$(UBOOT_BOARD) \
CROSS_COMPILE="$(SBL_CROSS_COMPILE_PATH)/bin/$(SBL_CROSS_COMPILE_PREFIX)"

KERNEL_MAKE_OPTS = ARCH=$(KERNEL_ARCH) \
CROSS_COMPILE="$(SDK_CROSS_COMPILE_KERNEL)" \
KDEB_SOURCENAME=linux-$(BOARD) \
LOCALVERSION=+$(BOARD_EXT)

OSDRV_ENV = CHIP_ARCH=$(SDK_CHIP) \
CVIARCH=$(SDK_CHIP) \
SDK_VER=$(SDK_VER) \
TPU_REL=$(TPU_REL) \
CROSS_COMPILE_64=$(CROSS_COMPILE_PATH_64)/bin/$(CROSS_COMPILE_64) \
CROSS_COMPILE_32=$(CROSS_COMPILE_PATH_32)/bin/$(CROSS_COMPILE_32) \
CROSS_COMPILE_GLIBC_RISCV64=$(CROSS_COMPILE_PATH_GLIBC_RISCV64)/bin/$(CROSS_COMPILE_GLIBC_RISCV64) \
CROSS_COMPILE_MUSL_RISCV64=$(CROSS_COMPILE_PATH_MUSL_RISCV64)/bin/$(CROSS_COMPILE_MUSL_RISCV64) \
CONFIG_ARCH=$(KERNEL_ARCH) \
CONFIG_CROSS_COMPILE_KERNEL="$(SDK_CROSS_COMPILE_KERNEL)" \
CONFIG_CP_EXT_WIRELESS=y

SENSOR_ENV = CONFIG_SENSOR_GCORE_GC2083=y \
CONFIG_SENSOR_GCORE_GC4653=y \
CONFIG_SENSOR_OV_OS04A10=y \
CONFIG_SENSOR_OV_OV2685=y \
CONFIG_SENSOR_OV_OV5647=y \
CONFIG_SENSOR_SMS_SC035GS=y \
CONFIG_SENSOR_LONTIUM_LT6911=y

BR_BOARD = $(CHIP_VENDOR)_$(SDK_CHIP)_$(SDK_VER)
BR_DEFCONFIG = $(BR_BOARD)_defconfig
BR_DIR = $(BUILDDIR)/buildroot
BR_OUTPUT_DIR = $(BR_DIR)/output/$(BR_BOARD)

BUILDROOT_ENV = CROSS_COMPILE_KERNEL=$(patsubst "%",%,$(SDK_CROSS_COMPILE_PREFIX)) \
CROSS_COMPILE_SDK=$(patsubst "%",%,$(SDK_CROSS_COMPILE_PREFIX)) \
TARGET_OUTPUT_DIR=$(BR_OUTPUT_DIR)

ifeq ($(findstring maixcdk,$(IMAGE_ADDITIONS)),)
BR_ENABLE_MAIXAPP = $(findstring maixapp,$(IMAGE_ADDITIONS))
endif

TOOLCHAIN_URL_ARM ?= $(shell echo $(TOOLCHAIN_URL) | sed 's|/arm/.*|/arm/gnu|g' | sed 's|/linaro|/arm/gnu|g')

FSBL_MAKE_OPTS = $(UBOOT_MAKE_OPTS) \
CHIP_ARCH=$(CHIP) \
BOOT_CPU=$(BOOT_CPU) \
DDR_CFG=$(DDR_CFG) \
RTOS_ENABLE_FREERTOS=y \
BLCP_2ND_PATH=$(BUILDDIR)/fsbl/blank.bin \
LOADER_2ND_PATH=$(BUILDDIR)/u-boot.bin

FSBL_TARGETS = $(BUILDDIR)/fsbl-package-stamp

ifneq ("$(PANEL_TUNING_DEFAULT)","")
PANEL_CONFIG_DEFAULT = $(shell echo '$(PANEL_TUNING_DEFAULT)' | tr '[:lower:]' '[:upper:]')
FSBL_TARGETS += $(BUILDDIR)/fsbl-$(PANEL_TUNING_DEFAULT).package-stamp
OSDRV_ENV += CONFIG_$(PANEL_CONFIG_DEFAULT)=y CONFIG_PANEL_TUNING_PARAM="$(PANEL_TUNING_DEFAULT)"
ifneq ("$(PANEL_TUNING_EXTRA)","")
FSBL_TARGETS += $(patsubst %,$(BUILDDIR)/fsbl-%.package-stamp,$(PANEL_TUNING_EXTRA))
endif
endif

MIDDLEWARE_ENV = $(OSDRV_ENV) $(SENSOR_ENV)

MIDDLEWARE_OUT_DIR=$(BUILDDIR)/middleware/install/system/usr
MIDDLEWARE_TARGET_DIR=/mnt/system/usr

BSPDEPENDS = $(CHIP_VENDOR)-middleware-$(BOARD)\
 $(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)\
 linux-headers-$(BOARD)-$(VARIANT)\
 linux-image-$(BOARD)-$(VARIANT)
BSPRECOMMENDS = $(CHIP_VENDOR)-fsbl-$(BOARD_EXT)
BSPFILTER =

include $(wildcard /builder/addons/*/addon.mk)

SDK_OSS_TARBALL_DIR = $(BUILDDIR)/tpusdk/oss/oss_release_tarball/$(SDK_VER)

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

$(info $(blue)Host Procs: $(NPROCS)$(reset))


define update_dts_action
	if [ "X$(findstring lichee,$(BOARD))" = "Xlichee" ]; then \
		sed -i 's|max-frequency = <50000000>;|max-frequency = <$(MMC_MAX_FREQUENCY)>;|g' ${1} ; \
		[ $(MMC_MAX_FREQUENCY) -ge 50000000 ] || sed -i /'sd-uhs-ddr50;'/d ${1} ; \
		[ $(MMC_MAX_FREQUENCY) -ge 100000000 ] || sed -i /'sd-uhs-sdr104;'/d ${1} ; \
	fi
endef

define copy_dts_action
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)/*), cp $(file) ${1}/;)
	@$(foreach file, $(wildcard /configs/common/dts/$(CHIP)_$(UBOOT_ARCH)/*), cp $(file) ${1}/;)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/dts/*), cp $(file) ${1}/;)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/dts/*.dts), $(call update_dts_action,${1}/$(notdir $(file)));)
endef

define copy_header_action
	@cp -r $(BUILDDIR)/osdrv/interdrv/include/chip/$(CHIP)/uapi/linux/* ${1}/linux/
	@cp -r $(BUILDDIR)/osdrv/interdrv/include/common/uapi/linux/* ${1}/linux/
	@cp $(BUILDDIR)/kernel/drivers/staging/android/uapi/ion.h ${1}/linux/
	@cp $(BUILDDIR)/kernel/drivers/staging/android/uapi/ion_cvitek.h ${1}/linux/
	@cp $(BUILDDIR)/kernel/include/uapi/linux/dma-buf.h ${1}/linux/
endef

define copy_ko_action
	@mkdir -p $(BUILDDIR)/osdrv/ko
	$(foreach kodir, $(KO_DIRS), find ${1}/lib/modules/*/kernel/$(kodir) -name '*.ko' -exec cp -f {} $(BUILDDIR)/osdrv/ko/ \; ;)
endef

$(BUILDDIR)/$(BOARD)-$(VARIANT)/memmap.py:
	@$(eval ISP_MEM_BASE_SIZE=$(shell expr $(ION_SIZE) - 4))
	@mkdir -p $(BUILDDIR)/$(BOARD)-$(VARIANT)
	@cp /configs/$(BOARD_CFG)/memmap.py $@
	@sed -i s/'ION_SIZE = .* . SIZE_1M'/'ION_SIZE = $(ION_SIZE) * SIZE_1M'/g $@
	@if [ $(ISP_MEM_BASE_SIZE) -le 0 ]; then \
		sed -i s/'H26X_BITSTREAM_SIZE = .* . SIZE_1M'/'H26X_BITSTREAM_SIZE = 0 * SIZE_1M'/g $@ ; \
		sed -i s/'ISP_MEM_BASE_SIZE = .* . SIZE_1M'/'ISP_MEM_BASE_SIZE = 0 * SIZE_1M'/g $@ ; \
		sed -i s/'BOOTLOGO_SIZE = .* . SIZE_1K'/'BOOTLOGO_SIZE = 0 * SIZE_1K'/g $@ ; \
	elif [ $(ISP_MEM_BASE_SIZE) -le 20 ]; then \
		sed -i s/'H26X_BITSTREAM_SIZE = .* . SIZE_1M'/'H26X_BITSTREAM_SIZE = 2 * SIZE_1M'/g $@ ; \
		sed -i s/'ISP_MEM_BASE_SIZE = .* . SIZE_1M'/'ISP_MEM_BASE_SIZE = $(ISP_MEM_BASE_SIZE) * SIZE_1M'/g $@ ; \
	fi

$(BUILDDIR)/$(BOARD)-$(VARIANT)/cvi_board_memmap.h: $(BUILDDIR)/$(BOARD)-$(VARIANT)/memmap.py
	@python3 /builder/python/mmap_conv.py --type h $(BUILDDIR)/$(BOARD)-$(VARIANT)/memmap.py $@

$(BUILDDIR)/toolchain-prepare-patch-stamp:
	@echo "$(COLOUR_GREEN)Patching Toolchain for $(BOARD)$(END_COLOUR)"
	@[ "$(TOOLCHAIN_URL)" = "X" ] || sed -i 's|^tcurl=.*|tcurl=$(TOOLCHAIN_URL)|g' /builder/replace-all-arm-toolchains.sh
	@[ "$(TOOLCHAIN_URL)" = "X" ] || sed -i 's|^tcurl=.*|tcurl=$(TOOLCHAIN_URL)|g' /builder/replace-all-thead-toolchains.sh
	@if [ "$(UBOOT_ARCH)" = "arm" ]; then \
		rm -rf /host-tools/gcc/riscv64-*/ && \
		cd / && tcver=11.3.rel1 /builder/replace-all-arm-toolchains.sh && \
		mv /ramdisk $(BUILDDIR)/ ; \
	else \
		apt-get install -y gcc-riscv64-unknown-elf && \
		cd / && /builder/replace-all-thead-toolchains.sh && \
		rm -rf /host-tools/gcc/riscv64-elf-x86_64 ; \
		[ "$(SDK_VER)" = "glibc_riscv64" ] || rm -rf $(CROSS_COMPILE_PATH_GLIBC_RISCV64) ; \
		[ "$(SDK_VER)" = "musl_riscv64" ] || rm -rf $(CROSS_COMPILE_PATH_MUSL_RISCV64) ; \
	fi
	@cd / && /builder/fix-thead-glibc-toolchain.sh
	@touch $@

$(BUILDDIR)/linux-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out Kernel for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b licheervnano-merged-5.10.y $(GIT_CLONE_OPTS) $(GIT_USER_URL)/linux.git $(BUILDDIR)/kernel
	@cd $(BUILDDIR)/kernel && git checkout 5cc993b
	@touch $@

$(BUILDDIR)/linux-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/linux-prepare-checkout-stamp $(BUILDDIR)/$(BOARD)-$(VARIANT)/cvi_board_memmap.h
	@echo "$(COLOUR_GREEN)Patching Kernel for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/linux/*.patch), cd $(BUILDDIR)/kernel && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/linux/*.patch), cd $(BUILDDIR)/kernel && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/linux/*.patch), cd $(BUILDDIR)/kernel && git apply --ignore-whitespace $(file);)
	@cp /configs/$(BOARD_CFG)/linux/defconfig $(BUILDDIR)/kernel/arch/$(KERNEL_ARCH)/configs/${BOARD}_defconfig
	$(call copy_dts_action,$(BUILDDIR)/kernel/arch/$(KERNEL_ARCH)/boot/dts/$(CHIP_VENDOR))
	@cp -p $(BUILDDIR)/$(BOARD)-$(VARIANT)/cvi_board_memmap.h $(BUILDDIR)/kernel/arch/$(KERNEL_ARCH)/boot/dts/$(CHIP_VENDOR)/cvi_board_memmap.h
	@touch $@

$(BUILDDIR)/linux-prepare-configure-stamp: $(BUILDDIR)/linux-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring Kernel for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/kernel && $(MAKE) -j$(NPROCS) O=$(KERNEL_OUTPUT_DIR)/ $(KERNEL_MAKE_OPTS) ${BOARD}_defconfig
	@$(eval LV=$(shell cd $(BUILDDIR)/kernel && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@sed -i 's/CONFIG_LOCALVERSION=""/CONFIG_LOCALVERSION="$(LV)"/' $(KERNEL_OUTPUT_DIR)/.config
	@touch $@

$(BUILDDIR)/linux-compile-stamp: $(BUILDDIR)/linux-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building Kernel for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/kernel && KCFLAGS=-Wno-attribute-alias $(MAKE) -j$(NPROCS) O=$(KERNEL_OUTPUT_DIR)/ $(KERNEL_MAKE_OPTS)
	@cd $(BUILDDIR)/kernel && KCFLAGS=-Wno-attribute-alias $(MAKE) -j$(NPROCS) O=$(KERNEL_OUTPUT_DIR)/ $(KERNEL_MAKE_OPTS) bindeb-pkg
	@cd $(BUILDDIR)/kernel && KCFLAGS=-Wno-attribute-alias $(MAKE) -j$(NPROCS) O=$(KERNEL_OUTPUT_DIR)/ $(KERNEL_MAKE_OPTS) modules_install INSTALL_MOD_PATH=$(KERNEL_OUTPUT_DIR)/ko headers_install INSTALL_HDR_PATH=$(KERNEL_OUTPUT_DIR)/$(KERNEL_ARCH)/usr
	@cp $(BUILDDIR)/kernel/build/*.deb /output/
	@touch $@

$(BUILDDIR)/linux-package-stamp: $(BUILDDIR)/linux-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging linux-headers-$(CHIP_FAMILY) for $(BOARD)$(END_COLOUR)"
	@$(eval KERNEL_DEB_TMP_IMAGE=$(KERNEL_OUTPUT_DIR)/debian/linux-image)
	@$(eval KERNEL_DEB_TMP_HEADERS=$(KERNEL_OUTPUT_DIR)/debian/linux-headers)
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
	@git clone -b licheervnano-cvisdk $(GIT_CLONE_OPTS) $(GIT_USER_URL)/sophgo-osdrv.git $(BUILDDIR)/osdrv
	@cd $(BUILDDIR)/osdrv && git checkout debcc0c
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

$(BUILDDIR)/osdrv-compile-stamp: $(BUILDDIR)/osdrv-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building OSdrv for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/osdrv && $(OSDRV_ENV) $(MAKE) $(KERNEL_MAKE_OPTS) KERNEL_DIR=$(KERNEL_OUTPUT_DIR) INSTALL_DIR=$(BUILDDIR)/osdrv/ko all
	@touch $@

$(BUILDDIR)/osdrv-package-stamp: $(BUILDDIR)/osdrv-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging OSdrv for $(BOARD)$(END_COLOUR)"
	@$(eval KERNEL_DEB_TMP_IMAGE=$(KERNEL_OUTPUT_DIR)/debian/linux-image)
	@$(eval KERNEL_DEB_TMP_HEADERS=$(KERNEL_OUTPUT_DIR)/debian/linux-headers)
	@$(eval KERNEL_DEB_ARCH=$(shell grep -m1 '^Architecture: ' $(KERNEL_OUTPUT_DIR)/debian/control | cut -d ' ' -f 2))
	@$(eval KERNELRELEASE=$(shell basename $(KERNEL_DEB_TMP_HEADERS)/usr/share/doc/linux-headers-* | cut -d '-' -f 3-))
	@$(eval OSDRV_PACKAGE_DIR=$(BUILDDIR)/package/$(CHIP_VENDOR)-osdrv-$(KERNELRELEASE)-$(OSDRVVERSION))
	@$(eval OSDRV_META_DIR=$(BUILDDIR)/package/$(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)-$(KERNELRELEASE))
	@$(eval OSDRV_TARGET_DIR=/mnt/system/ko/$(KERNELRELEASE))
	@mkdir -p $(OSDRV_PACKAGE_DIR)
	@cp -r /builder/deb/cvitek-osdrv/* $(OSDRV_PACKAGE_DIR)/
	@mkdir -pv $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/
	@cp -p $(BUILDDIR)/osdrv/ko/*.ko $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_clock_cooling.ko
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_pwm.ko
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_rtc.ko
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_saradc.ko
	@rm -f $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/soph_wdt.ko
	@mkdir -pv $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/3rd/
	@cp -p $(BUILDDIR)/osdrv/ko/3rd/*.ko $(OSDRV_PACKAGE_DIR)$(OSDRV_TARGET_DIR)/3rd/
	@sed -i 's/Architecture: riscv64/Architecture: $(KERNEL_DEB_ARCH)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(OSDRVVERSION)-$(KERNELRELEASE)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvitek-osdrv/Package: $(CHIP_VENDOR)-osdrv-$(KERNELRELEASE)/' $(OSDRV_PACKAGE_DIR)/DEBIAN/control
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
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)-$(KERNELRELEASE) $(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)_$(OSDRVVERSION)-$(KERNELRELEASE)_$(KERNEL_DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(CHIP_VENDOR)-osdrv-$(BOARD)-$(VARIANT)_$(OSDRVVERSION)-$(KERNELRELEASE)_$(KERNEL_DEB_ARCH).deb /output/
	@touch $@

osdrv: $(BUILDDIR)/osdrv-package-stamp

osdrv-clean:
	@rm -rf $(BUILDDIR)/osdrv
	@rm -f $(BUILDDIR)/osdrv-*-stamp


$(BUILDDIR)/middleware-prepare-clone-stamp:
	@echo "$(COLOUR_GREEN)Cloning Middleware for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b maix_mmf-cvisdk $(GIT_CLONE_OPTS) --shallow-submodules $(GIT_USER_URL)/sophgo-middleware.git $(BUILDDIR)/middleware
	@touch $@

$(BUILDDIR)/middleware-prepare-checkout-root-stamp: $(BUILDDIR)/middleware-prepare-clone-stamp
	@echo "$(COLOUR_GREEN)Checking out Middleware for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/middleware && git checkout 4ab774a
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/alsa_lib/alsa_lib $(GIT_USER_URL)/alsa-lib
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/curl/curl $(GIT_USER_URL)/curl
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/ffmpeg/ffmpeg $(GIT_USER_URL)/FFmpeg
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/flatbuffers/flatbuffers $(GIT_USER_URL)/flatbuffers
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/glog/glog $(GIT_USER_URL)/glog
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/json-c/json-c $(GIT_USER_URL)/json-c
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/libwebsockets/libwebsockets $(GIT_USER_URL)/libwebsockets
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/live/live555 $(GIT_USER_URL)/live555
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/miniz/miniz $(GIT_USER_URL)/miniz
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/nanomsg/nanomsg $(GIT_USER_URL)/nanomsg
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/opencv/opencv $(GIT_USER_URL)/opencv
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/opencv4.5/opencv $(GIT_USER_URL)/opencv
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/openssl/openssl $(GIT_USER_URL)/openssl
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/openssl3.0/openssl $(GIT_USER_URL)/openssl
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/sqlite/sqlite $(GIT_USER_URL)/sqlite
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/uv/uv $(GIT_USER_URL)/libuv
	@cd $(BUILDDIR)/middleware && git submodule set-url 3rdparty/zlib/zlib $(GIT_USER_URL)/zlib
	@cd $(BUILDDIR)/middleware && git submodule set-url component/isp $(GIT_USER_URL)/sophgo-SensorSupportList
	@cd $(BUILDDIR)/middleware && git submodule set-url modules/bin/json-c $(GIT_USER_URL)/json-c
	@cd $(BUILDDIR)/middleware && git submodule set-url modules/bin/miniz $(GIT_USER_URL)/miniz
	@cd $(BUILDDIR)/middleware && git submodule set-url sample/kvm_stream $(GIT_USER_URL)/streameye
	@cd $(BUILDDIR)/middleware && git submodule set-url sample/test_mmf/media_server-1.0.x $(GIT_USER_URL)/ireader
	@cd $(BUILDDIR)/middleware && git submodule update --init --depth=1
	@touch $@

$(BUILDDIR)/middleware-prepare-checkout-opencv-stamp: $(BUILDDIR)/middleware-prepare-checkout-root-stamp
	@echo "$(COLOUR_GREEN)Checking out Middleware opencv for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/middleware/3rdparty/opencv4.5/opencv && sed -i 's|https://github.com/opencv/ade/archive|$(GIT_RELEASES_URL)/opencv/ade/archive|g' modules/gapi/cmake/DownloadADE.cmake
	@cd $(BUILDDIR)/middleware/3rdparty/opencv4.5/opencv && sed -i 's|https://github.com/scpcom/ade/archive|$(GIT_RELEASES_URL)/scpcom/ade/archive|g' modules/gapi/cmake/DownloadADE.cmake
	@touch $@

$(BUILDDIR)/middleware-prepare-checkout-openssl-stamp: $(BUILDDIR)/middleware-prepare-checkout-root-stamp
	@echo "$(COLOUR_GREEN)Checking out Middleware openssl for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/middleware/3rdparty/openssl/openssl && git submodule set-url boringssl $(GIT_USER_URL)/boringssl
	@cd $(BUILDDIR)/middleware/3rdparty/openssl/openssl && git submodule set-url krb5 $(GIT_USER_URL)/krb5
	@cd $(BUILDDIR)/middleware/3rdparty/openssl/openssl && git submodule set-url pyca-cryptography $(GIT_USER_URL)/pyca-cryptography
	@cd $(BUILDDIR)/middleware/3rdparty/openssl/openssl && git submodule update --init --depth=1
	@#cd $(BUILDDIR)/middleware/3rdparty/openssl3.0/openssl && git submodule set-url boringssl $(GIT_USER_URL)/boringssl
	@cd $(BUILDDIR)/middleware/3rdparty/openssl3.0/openssl && git submodule set-url krb5 $(GIT_USER_URL)/krb5
	@cd $(BUILDDIR)/middleware/3rdparty/openssl3.0/openssl && git submodule set-url pyca-cryptography $(GIT_USER_URL)/pyca-cryptography
	@cd $(BUILDDIR)/middleware/3rdparty/openssl3.0/openssl && git submodule set-url gost-engine $(GIT_USER_URL)/gost-engine
	@cd $(BUILDDIR)/middleware/3rdparty/openssl3.0/openssl && git submodule set-url wycheproof $(GIT_USER_URL)/wycheproof
	@cd $(BUILDDIR)/middleware/3rdparty/openssl3.0/openssl && git submodule update --init --depth=1
	@touch $@

$(BUILDDIR)/middleware-prepare-checkout-media-server-stamp: $(BUILDDIR)/middleware-prepare-checkout-root-stamp
	@echo "$(COLOUR_GREEN)Checking out Middleware media-server for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/middleware/sample/test_mmf/media_server-1.0.x && git submodule set-url avcodec $(GIT_USER_URL)/ireader-avcodec
	@cd $(BUILDDIR)/middleware/sample/test_mmf/media_server-1.0.x && git submodule set-url media-server $(GIT_USER_URL)/ireader-media-server
	@cd $(BUILDDIR)/middleware/sample/test_mmf/media_server-1.0.x && git submodule set-url sdk $(GIT_USER_URL)/ireader-sdk
	@cd $(BUILDDIR)/middleware/sample/test_mmf/media_server-1.0.x && git submodule update --init --depth=1
	@touch $@

$(BUILDDIR)/middleware-prepare-checkout-stamp: $(BUILDDIR)/middleware-prepare-checkout-media-server-stamp $(BUILDDIR)/middleware-prepare-checkout-opencv-stamp $(BUILDDIR)/middleware-prepare-checkout-openssl-stamp
	@touch $@

$(BUILDDIR)/middleware-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/middleware-prepare-checkout-stamp $(BUILDDIR)/osdrv-compile-stamp
	@echo "$(COLOUR_GREEN)Patching Middleware for $(BOARD)$(END_COLOUR)"
	mkdir -pv $(KERNEL_OUTPUT_DIR)/$(KERNEL_ARCH)/usr/include/linux/
	$(call copy_header_action, $(KERNEL_OUTPUT_DIR)/$(KERNEL_ARCH)/usr/include)
	@[ "$(KERNEL_ARCH)" = "$(ARCH)" ] || ln -s $(KERNEL_ARCH) $(KERNEL_OUTPUT_DIR)/$(ARCH)
	@$(foreach file, $(wildcard /configs/common/patches/middleware/*.patch), cd $(BUILDDIR)/middleware && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/middleware/*.patch), cd $(BUILDDIR)/middleware && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/middleware/*.patch), cd $(BUILDDIR)/middleware && git apply --ignore-whitespace $(file);)
	sed -i 's|$$(ROOT_DIR)/../host-tools|/host-tools|g' $(BUILDDIR)/middleware/Makefile.param
	sed -i 's|$$(ROOT_DIR)/../ramdisk/sysroot/sysroot-glibc-linaro-2.23-2017.05-aarch64-linux-gnu|$(SDK_SYSROOT_64)|g' $(BUILDDIR)/middleware/Makefile.param
	sed -i 's|$$(ROOT_DIR)/../ramdisk/sysroot/sysroot-glibc-linaro-2.23-2017.05-arm-linux-gnueabihf|$(SDK_SYSROOT_32)|g' $(BUILDDIR)/middleware/Makefile.param
	sed -i 's|/host-tools/gcc/riscv64-linux-x86_64/sysroot|$(SDK_SYSROOT_GLIBC_RISCV64)|g' $(BUILDDIR)/middleware/Makefile.param
	sed -i 's|/host-tools/gcc/riscv64-linux-musl-x86_64/sysroot|$(SDK_SYSROOT_MUSL_RISCV64)|g' $(BUILDDIR)/middleware/Makefile.param
	sed -i 's|^include $$(BUILD_PATH)/.config|-include $$(BUILD_PATH)/.config|g' $(BUILDDIR)/middleware/Makefile.param
	sed -i 's|^include $$(BUILD_PATH)/.config|-include $$(BUILD_PATH)/.config|g' $(BUILDDIR)/middleware/component/isp/Makefile
	sed -i 's|^include $$(BUILD_PATH)/.config|-include $$(BUILD_PATH)/.config|g' $(BUILDDIR)/middleware/component/isp/common/Makefile
	sed -i 's|^include $$(BUILD_PATH)/.config|-include $$(BUILD_PATH)/.config|g' $(BUILDDIR)/middleware/sample/common/Makefile
	[ "X$(findstring maixcdk,$(IMAGE_ADDITIONS))" = "X" ] || sed -i s/TRD_BUILD_OPTIONAL_MODULE/TRD_BUILD_TPUSDK_MODULE/g $(BUILDDIR)/middleware/3rdparty/ffmpeg/Makefile
	@touch $@

$(BUILDDIR)/middleware-prepare-configure-stamp: $(BUILDDIR)/middleware-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring Middleware for $(BOARD)$(END_COLOUR)"
	@touch $@

$(BUILDDIR)/middleware-compile-stamp: $(BUILDDIR)/middleware-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building Middleware for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/middleware && $(MIDDLEWARE_ENV) $(MAKE) KERNEL_DIR=$(KERNEL_OUTPUT_DIR) all
	@mkdir -pv $(BUILDDIR)/middleware/install/system/
	@cd $(BUILDDIR)/middleware && $(MIDDLEWARE_ENV) $(MAKE) KERNEL_DIR=$(KERNEL_OUTPUT_DIR) install DESTDIR=$(BUILDDIR)/middleware/install/system
	@find $(BUILDDIR)/middleware/install/system -name "*.so*" -type f ! -path "*libtinyalsa.so" ! -path "*libaac*.so" ! -path "*libcvi_audio.so" ! -path "*libcvi_*ssp*.so" ! -path "*libcvi_*vqe*.so" ! -path "*libcvi_RES1.so" ! -path "*libcvi_VoiceEngine.so" ! -path "*libae.so" ! -path "*libaf.so" ! -path "*libawb.so" ! -path "*libisp_algo.so" -printf 'striping %p\n' -exec $(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)strip --strip-all {} \;
	@find $(BUILDDIR)/middleware/install/system -executable -type f ! -name "*.sh" ! -path "*etc*" ! -path "*.ko" ! -path "*.so*" -printf 'striping %p\n' -exec $(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)strip --strip-all {} 2>/dev/null \;
	@rsync -avpPxH $(BUILDDIR)/middleware/include/ $(MIDDLEWARE_OUT_DIR)/include/
	@mkdir -p $(MIDDLEWARE_OUT_DIR)/include/linux
	$(call copy_header_action, $(MIDDLEWARE_OUT_DIR)/include)
	@touch $@

$(BUILDDIR)/middleware-package-stamp: $(BUILDDIR)/middleware-compile-stamp
	@cd $(BUILDDIR)/kernel && [ "$(GIT_REF)" = "develop" ] || KCFLAGS=-Wno-attribute-alias $(MAKE) -j$(NPROCS) O=$(KERNEL_OUTPUT_DIR)/ $(KERNEL_MAKE_OPTS) clean
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
	@echo "$(COLOUR_GREEN)Cloning Buildroot dl for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b maixcdk --depth=1 $(GIT_USER_URL)/buildroot-dl.git $(BR_DIR)/dl
	@touch $@

$(BUILDDIR)/buildroot-prepare-checkout-dl-stamp: $(BUILDDIR)/buildroot-prepare-clone-dl-stamp
	@echo "$(COLOUR_GREEN)Checking out Buildroot dl for $(BOARD)$(END_COLOUR)"
	@cd $(BR_DIR)/dl && git checkout 40b4440
	@cd $(BR_DIR)/dl && [ "$(GIT_REF)" = "develop" ] || rm -rf .git
	@touch $@

$(BUILDDIR)/buildroot-prepare-clone-pinmux-stamp: $(BUILDDIR)/buildroot-prepare-clone-stamp
	@echo "$(COLOUR_GREEN)Cloning Buildroot pinmux for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)/ramdisk/tools
	@git clone -b main $(GIT_USER_URL)/cvi-pinmux $(BUILDDIR)/ramdisk/tools/cvi_pinmux
	@touch $@

$(BUILDDIR)/buildroot-prepare-checkout-pinmux-stamp: $(BUILDDIR)/buildroot-prepare-clone-pinmux-stamp
	@echo "$(COLOUR_GREEN)Checking out Buildroot pinmux for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/ramdisk/tools/cvi_pinmux && git checkout 5b90da9
	@touch $@

$(BUILDDIR)/buildroot-prepare-checkout-stamp: $(BUILDDIR)/buildroot-prepare-checkout-dl-stamp $(BUILDDIR)/buildroot-prepare-checkout-pinmux-stamp
	@echo "$(COLOUR_GREEN)Checking out Buildroot for $(BOARD)$(END_COLOUR)"
	@cd $(BR_DIR) && git checkout 9b46139
	@touch $@

$(BUILDDIR)/buildroot-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/buildroot-prepare-checkout-stamp $(BUILDDIR)/middleware-compile-stamp
	@echo "$(COLOUR_GREEN)Patching Buildroot for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/buildroot/*.patch), cd $(BR_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/buildroot/*.patch), cd $(BR_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/buildroot/*.patch), cd $(BR_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/common/patches/nanokvm/*.patch), cp $(file) $(BR_DIR)/package/nanokvm-server/;)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/nanokvm/*.patch), cp $(file) $(BR_DIR)/package/nanokvm-server/;)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/nanokvm/*.patch), cp $(file) $(BR_DIR)/package/nanokvm-server/;)
	@cd $(BR_DIR) && sed -i 's|^MAIX_CDK_RELEASES_URL = .*|MAIX_CDK_RELEASES_URL = $(GIT_RELEASES_URL)|g' package/maix-cdk/maix-cdk.mk
	@cd $(BR_DIR) && sed -i 's|https://scpcom.github.io|$(USER_SITE_URL)|g' package/nanokvm-server/nanokvm-server.mk
	@cd $(BR_DIR) && sed -i 's|https://scpcom.github.io|$(USER_SITE_URL)|g' package/nanokvm-sg200x/nanokvm-sg200x.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/scpcom|$(GIT_USER_URL)|g' package/maixcam-sg200x/maixcam-sg200x.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/scpcom|$(GIT_USER_URL)|g' package/maix-cdk/maix-cdk.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/scpcom|$(GIT_USER_URL)|g' package/nanokvm-server/nanokvm-server.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/scpcom|$(GIT_USER_URL)|g' package/nanokvm-sg200x/nanokvm-sg200x.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/lxowalle|$(GIT_USER_URL)|g' package/aic8800-sdio-firmware/aic8800-sdio-firmware.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/milkv-duo|$(GIT_USER_URL)|g' package/duo-pinmux/duo-pinmux.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/0x754C|$(GIT_USER_URL)|g' package/lcdtest/lcdtest.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/0x754C|$(GIT_USER_URL)|g' package/tpudemo-sg200x/tpudemo-sg200x.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/sipeed|$(GIT_USER_URL)|g' package/maix-cdk/maix-cdk.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/sipeed|$(GIT_USER_URL)|g' package/maix-py/maix-py.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/sipeed|$(GIT_USER_URL)|g' package/nanokvm-server/nanokvm-server.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/kmxz|$(GIT_USER_URL)|g' package/overlayfs-tools/overlayfs-tools.mk
	@cd $(BR_DIR) && sed -i 's|https://github.com/wlhe|$(GIT_USER_URL)|g' package/uvc-gadget/uvc-gadget.mk
	@cd $(BR_DIR) && [ "X$(TOOLCHAIN_URL_ARM)" = "X" ] || sed -i 's|https://developer.arm.com/-/media/Files/downloads/gnu|$(TOOLCHAIN_URL_ARM)|g' toolchain/toolchain-external/toolchain-external-arm-aarch64/toolchain-external-arm-aarch64.mk
	@cd $(BR_DIR) && [ "X$(TOOLCHAIN_URL_ARM)" = "X" ] || sed -i 's|https://developer.arm.com/-/media/Files/downloads/gnu|$(TOOLCHAIN_URL_ARM)|g' toolchain/toolchain-external/toolchain-external-arm-arm/toolchain-external-arm-arm.mk
	@cp /configs/common/buildroot/$(ARCH)_defconfig $(BR_DIR)/configs/$(BR_DEFCONFIG)
	@echo 'BR2_TOOLCHAIN_EXTERNAL_PATH="'$(SDK_CROSS_COMPILE_PATH)'"' >> $(BR_DIR)/configs/$(BR_DEFCONFIG)
	@if [ "X$(findstring kvm,$(VARIANT))$(BR_ENABLE_MAIXAPP)" = "X" ]; then \
		sed -i /BR2_CCACHE/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_CA_CERTIFICATES/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_LIBOPENSSL/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_LIBCURL/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_PYTHON/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_HOST_PYTHON/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_MAIX_CDK/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_JPEG/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
		sed -i /BR2_PACKAGE_LIBQRENCODE/d $(BR_DIR)/configs/$(BR_DEFCONFIG) ; \
	fi
	@if [ "X$(BR_ENABLE_MAIXAPP)" = "X" ]; then \
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


$(BUILDDIR)/uboot-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out U-Boot for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b licheervnano-cvisdk-2021.10 $(GIT_CLONE_OPTS) $(GIT_USER_URL)/u-boot $(BUILDDIR)/u-boot
	@cd $(BUILDDIR)/u-boot && git checkout 23740b0
	@touch $@

$(BUILDDIR)/uboot-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/uboot-prepare-checkout-stamp $(BUILDDIR)/$(BOARD)-$(VARIANT)/cvi_board_memmap.h
	@echo "$(COLOUR_GREEN)Patching U-Boot for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/u-boot/*.patch), cd $(BUILDDIR)/u-boot && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/u-boot/*.patch), cd $(BUILDDIR)/u-boot && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/u-boot/*.patch), cd $(BUILDDIR)/u-boot && git apply --ignore-whitespace $(file);)
	$(call copy_dts_action,$(BUILDDIR)/u-boot/arch/$(UBOOT_ARCH)/dts)
	@cp /configs/$(BOARD_CFG)/u-boot/cvitek.h $(BUILDDIR)/u-boot/include/cvitek.h
	@cp /configs/$(BOARD_CFG)/u-boot/cvi_board_init.c $(BUILDDIR)/u-boot/board/$(CHIP_VENDOR)/cvi_board_init.c
	@cp -p $(BUILDDIR)/$(BOARD)-$(VARIANT)/cvi_board_memmap.h $(BUILDDIR)/u-boot/include/cvi_board_memmap.h
	@python3 /builder/python/mkcvipart.py /configs/$(BOARD_CFG)/$(PARTITION_FILE) $(BUILDDIR)/u-boot/include/
	@python3 /builder/python/mk_imgHeader.py /configs/$(BOARD_CFG)/$(PARTITION_FILE) $(BUILDDIR)/u-boot/include/ 
	@touch $@

define uboot_configure_action
	@echo "$(COLOUR_GREEN)Configuring U-Boot for $(BOARD) ${1}$(END_COLOUR)"
	cd $(BUILDDIR)/u-boot/ && $(MAKE) -j$(NPROCS) ${1} $(UBOOT_MAKE_OPTS) clean
	@cp /configs/$(BOARD_CFG)/u-boot/defconfig $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig
	@if [ "X${2}" = "X" -a "X$(findstring kvm,$(VARIANT))" = "X" ] ; then \
		sed -i /^CONFIG_CMD_CVI_VO/d $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig ; \
		sed -i /^CONFIG_DM_VIDEO/d $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig ; \
		sed -i /^CONFIG_CMD_VIDCONSOLE/d $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig ; \
		sed -i /^CONFIG_VIDEO/d $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig ; \
		sed -i /^CONFIG_DISPLAY_CVITEK_MIPI/d $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig ; \
		sed -i /^CONFIG_DISPLAY=/d $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig ; \
		sed -i /^CONFIG_BMP_/d $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig ; \
		sed -i /^CONFIG_BOOTLOGO/d $(BUILDDIR)/u-boot/configs/$(BOARD)${2}_defconfig ; \
	fi
	cd $(BUILDDIR)/u-boot/ && $(MAKE) -j$(NPROCS) ${1} $(UBOOT_MAKE_OPTS) $(BOARD)${2}_defconfig
	@touch $@
endef

define uboot_compile_action
	@echo "$(COLOUR_GREEN)Building U-Boot for $(BOARD) ${1}$(END_COLOUR)"
	cd $(BUILDDIR)/u-boot/ && $(MAKE) -j$(NPROCS) ${1} $(UBOOT_MAKE_OPTS)
	cd $(BUILDDIR)/u-boot/ && $(MAKE) -j$(NPROCS) ${1} $(UBOOT_MAKE_OPTS) u-boot-initial-env
	@cp $(BUILDDIR)/u-boot/u-boot.bin $(BUILDDIR)
	@cp $(BUILDDIR)/u-boot/u-boot.dtb $(BUILDDIR)
	@cp $(BUILDDIR)/u-boot/u-boot-initial-env $(BUILDDIR)
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

$(BUILDDIR)/uboot-compile-stamp: $(BUILDDIR)/uboot-prepare-configure-stamp
	$(call uboot_compile_action,)

uboot: $(BUILDDIR)/uboot-compile-stamp

uboot-clean:
	@rm -rf $(BUILDDIR)/u-boot
	@rm -f $(BUILDDIR)/uboot-*-stamp


$(BUILDDIR)/opensbi-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out OpenSBI for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b licheervnano-cvisdk-1.2 $(GIT_CLONE_OPTS) $(GIT_USER_URL)/opensbi $(BUILDDIR)/opensbi
	@cd $(BUILDDIR)/opensbi && git checkout 3491ae4
#	git clone https://github.com/riscv-software-src/opensbi.git $(BUILDDIR)/opensbi
#	@cd $(BUILDDIR)/opensbi && git checkout a2b255b
	@touch $@


$(BUILDDIR)/opensbi-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/opensbi-prepare-checkout-stamp
	@echo "$(COLOUR_GREEN)Patching OpenSBI for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/opensbi/*.patch), cd $(BUILDDIR)/opensbi && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/opensbi/*.patch), cd $(BUILDDIR)/opensbi && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/opensbi/*.patch), cd $(BUILDDIR)/opensbi && git apply --ignore-whitespace $(file);)
	@touch $@

$(BUILDDIR)/opensbi-compile-stamp: $(BUILDDIR)/opensbi-prepare-patch-stamp $(BUILDDIR)/uboot-compile-stamp
	@echo "$(COLOUR_GREEN)Building OpenSBI for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/opensbi && CHIP_ARCH=$(SDK_CHIP) $(MAKE) $(KERNEL_MAKE_OPTS) OPENSBI_PATH="$(BUILDDIR)/opensbi" PLATFORM=generic FW_FDT_PATH=$(BUILDDIR)/u-boot.dtb
	@cp $(BUILDDIR)/opensbi/build/platform/generic/firmware/fw_dynamic.bin $(BUILDDIR) 
	@touch $@

$(BUILDDIR)/riscv-sbi-compile-stamp: $(BUILDDIR)/opensbi-compile-stamp
	@touch $@

$(BUILDDIR)/arm-sbi-compile-stamp:
	@touch $@

opensbi: $(BUILDDIR)/opensbi-compile-stamp

opensbi-clean:
	@rm -rf $(BUILDDIR)/opensbi
	@rm -f $(BUILDDIR)/opensbi-*-stamp


$(BUILDDIR)/fsbl-prepare-checkout-stamp:
	@echo "$(COLOUR_GREEN)Checking out FSBL for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b licheervnano-cvisdk $(GIT_CLONE_OPTS) $(GIT_USER_URL)/sophgo-fsbl $(BUILDDIR)/fsbl
	@cd $(BUILDDIR)/fsbl && git checkout 1e73867
	@touch $@

$(BUILDDIR)/fsbl-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/fsbl-prepare-checkout-stamp $(BUILDDIR)/$(BOARD)-$(VARIANT)/cvi_board_memmap.h
	@echo "$(COLOUR_GREEN)Patching FSBL for $(BOARD)$(END_COLOUR)"
	@$(foreach file, $(wildcard /configs/common/patches/fsbl/*.patch), cd $(BUILDDIR)/fsbl && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/fsbl/*.patch), cd $(BUILDDIR)/fsbl && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/fsbl/*.patch), cd $(BUILDDIR)/fsbl && git apply --ignore-whitespace $(file);)
	@cp -p $(BUILDDIR)/$(BOARD)-$(VARIANT)/cvi_board_memmap.h $(BUILDDIR)/fsbl/plat/$(CHIP)/include/cvi_board_memmap.h
	@printf '\163\000\120\020\157\360\337\377' > $(BUILDDIR)/fsbl/blank.bin
	@touch $@

define fsbl_compile_action
	@echo "$(COLOUR_GREEN)Building FSBL for $(BOARD) ${1}$(END_COLOUR)"
	@cd $(BUILDDIR)/fsbl && OD_CLK_SEL=y $(MAKE) -j$(NPROCS) ${1} $(FSBL_MAKE_OPTS) clean
	@cd $(BUILDDIR)/fsbl && OD_CLK_SEL=y $(MAKE) -j$(NPROCS) ${1} $(FSBL_MAKE_OPTS)
	@cp $(BUILDDIR)/fsbl/build/$(CHIP)/fip.bin $(BUILDDIR)
	@touch $@
endef

define fsbl_package_action
	@echo "$(COLOUR_GREEN)Packaging FSBL for $(BOARD) ${1}$(END_COLOUR)"
	@$(eval UV=$(shell cd $(BUILDDIR)/u-boot && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@$(eval FSBL_PACKAGE_NAME=$(CHIP_VENDOR)-fsbl-$(BOARD_EXT)${2})
	@$(eval FSBL_PACKAGE_DIR=$(BUILDDIR)/package/$(FSBL_PACKAGE_NAME)-$(FSBLVERSION))
	@$(eval PANEL_NAME_FSBL=$(shell echo '${2}' | cut -d '-' -f 2- | tr '-' '_'))
	@mkdir -p $(FSBL_PACKAGE_DIR)
	@cp -r /builder/deb/cvitek-fsbl/* $(FSBL_PACKAGE_DIR)/
	@mkdir -p $(FSBL_PACKAGE_DIR)/usr/lib/$(CHIP_VENDOR)-fsbl/$(BOARD_EXT)${2}/
	@cp $(BUILDDIR)/fip.bin $(FSBL_PACKAGE_DIR)/usr/lib/$(CHIP_VENDOR)-fsbl/$(BOARD_EXT)${2}/
	@cp $(BUILDDIR)/u-boot-initial-env $(FSBL_PACKAGE_DIR)/usr/lib/$(CHIP_VENDOR)-fsbl/$(BOARD_EXT)${2}/
	@[ ! -e /configs/$(BOARD_CFG)/logo.jpeg ] || cp /configs/$(BOARD_CFG)/logo.jpeg $(FSBL_PACKAGE_DIR)/usr/lib/$(CHIP_VENDOR)-fsbl/$(BOARD_EXT)${2}/
	@sed -i 's|cvitek-fsbl/licheervnano|$(CHIP_VENDOR)-fsbl/$(BOARD_EXT)${2}|g' $(FSBL_PACKAGE_DIR)/DEBIAN/postinst
	@[ "X$(PANEL_NAME_FSBL)" = "X" ] || sed -i s/'^panel='/'panel='$(PANEL_NAME_FSBL)/g $(FSBL_PACKAGE_DIR)/DEBIAN/postinst
	@chmod ugo+rx $(FSBL_PACKAGE_DIR)/DEBIAN/postinst
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(FSBL_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.1.0/Version: $(FSBLVERSION)$(UV)/' $(FSBL_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvitek-fsbl/Package: $(FSBL_PACKAGE_NAME)/' $(FSBL_PACKAGE_DIR)/DEBIAN/control
	@if [ "$(BOARD)" = "$(BOARD_EXT)" ]; then \
		sed -i '/Provides: .*/d' $(FSBL_PACKAGE_DIR)/DEBIAN/control && \
		sed -i '/Replaces: .*/d' $(FSBL_PACKAGE_DIR)/DEBIAN/control ; \
	else \
		sed -i 's/Provides: .*/Provides: $(CHIP_VENDOR)-fsbl-$(BOARD)/' $(FSBL_PACKAGE_DIR)/DEBIAN/control && \
		sed -i 's/Replaces: .*/Replaces: $(CHIP_VENDOR)-fsbl-$(BOARD)/' $(FSBL_PACKAGE_DIR)/DEBIAN/control ; \
	fi
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(FSBL_PACKAGE_NAME)-$(FSBLVERSION) $(FSBL_PACKAGE_NAME)_$(FSBLVERSION)$(UV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(FSBL_PACKAGE_NAME)_$(FSBLVERSION)$(UV)_$(DEB_ARCH).deb /output/
	@touch $@
endef

$(BUILDDIR)/fsbl-%.compile-stamp: $(BUILDDIR)/fsbl-prepare-patch-stamp $(BUILDDIR)/$(UBOOT_ARCH)-sbi-compile-stamp $(BUILDDIR)/uboot-%.compile-stamp
	$(eval PANEL_TUNING_FSBL=$(patsubst fsbl-%.compile-stamp,%,$(notdir $@)))
	$(call fsbl_compile_action,PANEL_TUNING_PARAM="$(PANEL_TUNING_FSBL)")

$(BUILDDIR)/fsbl-%.package-stamp: $(BUILDDIR)/fsbl-%.compile-stamp
	$(eval PANEL_TUNING_FSBL=$(patsubst fsbl-%.package-stamp,%,$(notdir $@)))
	$(eval PANEL_PACKAGE_FSBL=$(shell echo '$(PANEL_TUNING_FSBL)' | tr '[:upper:]_' '[:lower:]-' | sed s/'^mipi-panel-'/'-'/g))
	$(call fsbl_package_action,PANEL_TUNING_PARAM="$(PANEL_TUNING_FSBL)",$(PANEL_PACKAGE_FSBL))

$(BUILDDIR)/fsbl-compile-stamp: $(BUILDDIR)/fsbl-prepare-patch-stamp $(BUILDDIR)/$(UBOOT_ARCH)-sbi-compile-stamp $(BUILDDIR)/uboot-compile-stamp
	$(call fsbl_compile_action,)

$(BUILDDIR)/fsbl-package-stamp: $(BUILDDIR)/fsbl-compile-stamp
	$(call fsbl_package_action,,)

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
	@cp -v /usr/bin/qemu-$(QEMU_ARCH)-static /rootfs/tmp/install/
	@cp -v /configs/chip/$(CHIP_FAMILY)/config_rootfs.sh /rootfs/tmp/install/
	@[ $(DEB_ARCH) = $(KERNEL_DEB_ARCH) ] || chroot /rootfs/ /tmp/install/qemu-$(QEMU_ARCH)-static /usr/bin/dpkg --add-architecture $(KERNEL_DEB_ARCH)
	@chroot /rootfs/ /tmp/install/qemu-$(QEMU_ARCH)-static /bin/sh /tmp/install/config_rootfs.sh
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
	@if [ -f /rootfs/tmp/install/systemd-enable ]; then \
		echo "systemctl enable `cat /rootfs/tmp/install/systemd-enable | tr -d '\n'`" >> $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/postinst ; \
	fi
	@chmod +x $(BOARD_SUPPORT_PACKAGE_DIR)/DEBIAN/postinst
	@cd $(BUILDDIR)/package/ && dpkg-deb --build board-support-$(BOARD)-$(VARIANT)-$(BSPVERSION) board-support-$(BOARD)-$(VARIANT)_$(BSPVERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/board-support-$(BOARD)-$(VARIANT)_$(BSPVERSION)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/board-support-$(BOARD)-$(VARIANT)*.deb /rootfs/tmp/install/
	@echo "$(COLOUR_GREEN)Copying Deb files for installation on $(BOARD)$(END_COLOUR)"
	@cp /output/$(CHIP_VENDOR)-fsbl-$(BOARD_EXT)_*.deb /rootfs/tmp/install/
	@cp /output/$(CHIP_VENDOR)-osdrv-*$(BOARD)*.deb /rootfs/tmp/install/
	@cp /output/$(CHIP_VENDOR)-middleware-$(BOARD)_*.deb /rootfs/tmp/install/
	@cp /output/linux-image-*$(BOARD)*.deb /rootfs/tmp/install/
	@cp /output/linux-headers-*.deb /rootfs/tmp/install/
	@cp /output/linux-libc-dev*.deb /rootfs/tmp/install/
	@touch $@


$(BUILDDIR)/image-customize-stamp: $(BUILDDIR)/image-addons-stamp $(BUILDDIR)/linux-package-stamp $(FSBL_TARGETS)
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
	@[ "$(GIT_REF)" = "develop" ] || rm -f /builder/*gcc-*.tar.*
	@[ "$(GIT_REF)" = "develop" ] || rm -rf /host-tools/gcc/
	@rm -rf /tmp/genimage/
	@cd $(BUILDDIR) && genimage --config /configs/chip/$(CHIP_FAMILY)/genimage_$(STORAGE_TYPE).cfg --tmppath /tmp/genimage --rootpath /rootfs/
	@rm -rf /tmp/genimage/
	@if [ "$(STORAGE_TYPE)" = "emmc" ]; then \
		python3 /builder/python/raw2cimg.py -v $(BUILDDIR)/images/sdcard.img $(BUILDDIR)/images /configs/$(BOARD_CFG)/partition_emmc.xml; \
		mkdir -p /tmp/rom/; \
		cp $(BUILDDIR)/images/sdcard.img /tmp/rom/; \
		cp /configs/$(BOARD_CFG)/partition_emmc.xml /tmp/rom/; \
		cp $(BUILDDIR)/fip.bin /tmp/rom/; \
		cd /tmp && zip $(BOARD)_$(STORAGE_TYPE).zip -r rom/; \
		cp /tmp/$(BOARD)_$(STORAGE_TYPE).zip /output/; \
		echo "$(COLOUR_GREEN)Image for $(BOARD) is $(BOARD)_$(STORAGE_TYPE).zip$(END_COLOUR)"; \
	else \
		lz4 -9 -f $(BUILDDIR)/images/sdcard.img /output/$(BOARD)-$(VARIANT)_$(STORAGE_TYPE).img.lz4; \
		echo "$(COLOUR_GREEN)Image for $(BOARD) is $(BOARD)_$(STORAGE_TYPE).img$(END_COLOUR)"; \
	fi 
	@touch $@

image: $(BUILDDIR)/image-compile-stamp

image-clean:
	@rm -rf /rootfs/
	@rm -f $(BUILDDIR)/image-*-stamp $(addon-targets)
	@rm -f /output/$(BOARD)_$(STORAGE_TYPE).img

image-clean-customize:
	@rm -f $(BUILDDIR)/image-customize-stamp

clean: opensbi-clean uboot-clean linux-clean osdrv-clean middleware-clean fsbl-clean

.PHONY: image clean opensbi uboot linux osdrv middleware fsbl fsbl-clean uboot-clean linux-clean opensbi-clean

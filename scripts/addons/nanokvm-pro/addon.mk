ifneq ("$(findstring nanokvm-pro,$(IMAGE_ADDITIONS))","")
BSPFILTER += "nanokvm-pro"
endif

NANOKVM_PRO_GIT_REF = 6e6df77eddbe4947d19da375de3a84f64840f0c4
NANOKVM_PRO_GIT_URL ?= $(GIT_USER_URL)/NanoKVM-Pro

NANOKVM_PRO_SHA256 = 4e914ea0fc1980132314f782c062bd7b61352017c39ccd590625696d0f5d562d
NANOKVM_PRO_VERSION = 1.2.13

NANOKVM_PRO_GO_VENDOR_REF = f573cc27f239da8ce24646e4dbe91410c88b1c03
NANOKVM_PRO_GO_VENDOR_URL = $(GIT_USER_URL)/nanokvm-pro-server-vendor
NANOKVM_PRO_GOMOD = server

NANOKVM_PRO_STABLE_URL = https://cdn.sipeed.com/nanokvm
NANOKVM_PRO_PREVIEW_URL = https://cdn.sipeed.com/nanokvm/preview
NANOKVM_PRO_BASE_URL ?= $(NANOKVM_PRO_STABLE_URL)

NANOKVM_PRO_UPDATE_URL = $(USER_SITE_URL)/nanokvm_pro
NANOKVM_PRO_ARCH_URL = $(NANOKVM_PRO_UPDATE_URL)/glibc_$(DEB_ARCH)

NANOKVM_PRO_BUILD_DIR = $(BUILDDIR)/nanokvm-pro/NanoKVM-Pro

NANOKVM_PRO_KVMCOMM_MODULES = f_udisp_drv.ko \
fbtft.ko \
fb_jd9853.ko \
gpio_keys.ko \
lt6911_manage.ko \
rotary_encoder.ko \
wireguard.ko

NANOKVM_PRO_KVMCOMM_PACKAGE_DIR = $(BUILDDIR)/package/kvmcomm-$(NANOKVM_PRO_VERSION)

$(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json:
	@mkdir -p $(BUILDDIR)/nanokvm-pro
	@cd $(BUILDDIR)/nanokvm-pro ; wget -q -O nanokvm_pro_latest.json "$(NANOKVM_PRO_BASE_URL)/nanokvm_pro_latest.json?now=$(shell date +%s)" || wget -q -O nanokvm_pro_latest.json "$(NANOKVM_PRO_ARCH_URL)/nanokvm_pro_latest.json?now=$(shell date +%s)"

$(BUILDDIR)/nanokvm-pro-prepare-stamp: $(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json
	@echo "$(COLOUR_GREEN)Installing nanokvm-pro for $(BOARD)$(END_COLOUR)"
	@touch /rootfs/boot/check_resize2fs
	@touch /rootfs/boot/first_time_boot
	@touch /rootfs/boot/usb.ncm
	@mkdir -p $(BUILDDIR)/nanokvm-pro
	@$(eval NANOKVM_PRO_LATEST_SHA512=$(shell cat $(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json | jq -c '.sha512' | cut -d '"' -f 2 | basenc -d --base64 | xxd -p | tr -d '\n'))
	@#(eval NANOKVM_PRO_LATEST_FILE=$(shell cat $(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json | jq -c '.name' | cut -d '"' -f 2))
	@#(eval NANOKVM_PRO_VERSION=$(shell cat $(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json | jq -c '.version' | cut -d '"' -f 2))
	@$(eval NANOKVM_PRO_LATEST_FILE=nanokvm_pro_$(NANOKVM_PRO_VERSION).tar.gz)
	@$(eval NANOKVM_PRO_PACKAGE_DIR=$(BUILDDIR)/package/nanokvmpro-$(NANOKVM_PRO_VERSION))
	@cd $(BUILDDIR)/nanokvm-pro ; wget -N "$(NANOKVM_PRO_BASE_URL)/resources/kvmadmin.tar.gz" || wget -N "$(NANOKVM_PRO_ARCH_URL)/resources/kvmadmin.tar.gz"
	@cd $(BUILDDIR)/nanokvm-pro ; wget -N "$(NANOKVM_PRO_BASE_URL)/$(NANOKVM_PRO_LATEST_FILE)" || wget -N "$(NANOKVM_PRO_PREVIEW_URL)/$(NANOKVM_PRO_LATEST_FILE)" || wget -N "$(NANOKVM_PRO_ARCH_URL)/$(NANOKVM_PRO_LATEST_FILE)"
	@if [ "`sha256sum "$(BUILDDIR)/nanokvm-pro/$(NANOKVM_PRO_LATEST_FILE)" | cut -d ' ' -f 1`" != "$(NANOKVM_PRO_SHA256)" ]; then \
		if [ "`sha512sum "$(BUILDDIR)/nanokvm-pro/$(NANOKVM_PRO_LATEST_FILE)" | cut -d ' ' -f 1`" != "$(NANOKVM_PRO_LATEST_SHA512)" ]; then \
			echo "$(NANOKVM_PRO_LATEST_FILE): checksum mismatch!" ; \
			exit 1 ; \
		else \
			echo "$(NANOKVM_PRO_LATEST_FILE): used json checksum!" ; \
		fi \
	fi
	@cd $(BUILDDIR)/nanokvm-pro ; tar xzf "$(NANOKVM_PRO_LATEST_FILE)"
	@cd $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION) ; [ "$(findstring ubuntu,$(DEB_URL))" != "" ] || wget -N https://launchpadlibrarian.net/587202705/libjpeg-turbo8_2.1.2-0ubuntu1_arm64.deb
	@cd $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION) ; [ "$(DEB_DISTRO)" != "trixie" ] || wget -N https://launchpadlibrarian.net/470183065/libconfig9_1.5-0.4build1_arm64.deb
	@cd $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION) ; [ "$(DEB_DISTRO)" = "jammy" ] || wget -N https://launchpadlibrarian.net/571748137/libwebsockets16_4.0.20-2ubuntu1_arm64.deb
	@cd $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION) ; [ "$(findstring ubuntu,$(DEB_URL))" != "" ] || wget -N https://launchpadlibrarian.net/572052652/ttyd_1.6.3+20210924-1build1_arm64.deb
	@cp -p $(BUILDDIR)/nanokvm-pro/kvmadmin.tar.gz /output/$(BOARD)-kvmadmin.tar.gz
	@touch $@

$(BUILDDIR)/nanokvm-pro-package-stamp: $(BUILDDIR)/nanokvm-pro-prepare-stamp
	@cd $(BUILDDIR)/nanokvm-pro ; dpkg-deb -R nanokvm_pro_$(NANOKVM_PRO_VERSION)/nanokvmpro_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb $(NANOKVM_PRO_PACKAGE_DIR)
	@apt-get install -y golang-go npm
	@npm install -g pnpm
	@cd $(BUILDDIR)/nanokvm-pro && git clone $(NANOKVM_PRO_GIT_URL)
	@cd $(NANOKVM_PRO_BUILD_DIR) && git checkout $(NANOKVM_PRO_GIT_REF)
	@cd $(NANOKVM_PRO_BUILD_DIR)/$(NANOKVM_PRO_GOMOD) && git clone --depth 1 $(NANOKVM_PRO_GO_VENDOR_URL) vendor
	@cd $(NANOKVM_PRO_BUILD_DIR)/$(NANOKVM_PRO_GOMOD)/vendor && git checkout $(NANOKVM_PRO_GO_VENDOR_REF)
	@$(foreach file, $(wildcard /configs/common/patches/nanokvm-pro/*.patch), cd $(NANOKVM_PRO_BUILD_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/nanokvm-pro/*.patch), cd $(NANOKVM_PRO_BUILD_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/nanokvm-pro/*.patch), cd $(NANOKVM_PRO_BUILD_DIR) && git apply --ignore-whitespace $(file);)
	@sed -i 's|https://cdn.sipeed.com/nanokvm|$(NANOKVM_PRO_ARCH_URL)|g' $(NANOKVM_PRO_BUILD_DIR)/$(NANOKVM_PRO_GOMOD)/service/application/service.go
	@sed -i 's|https://cdn.sipeed.com/nanokvm|$(NANOKVM_PRO_ARCH_URL)|g' $(NANOKVM_PRO_BUILD_DIR)/$(NANOKVM_PRO_GOMOD)/service/extensions/kvmadmin/install.go
	@cd $(NANOKVM_PRO_BUILD_DIR)/support/scripts ; ./toolchain_setup.sh
	@cd $(NANOKVM_PRO_BUILD_DIR)/server/ ; ./build.sh
	@cd $(NANOKVM_PRO_BUILD_DIR)/web/ ; pnpm install
	@cd $(NANOKVM_PRO_BUILD_DIR)/web/ ; pnpm build
	@cp -p $(NANOKVM_PRO_BUILD_DIR)/server/NanoKVM-Server $(NANOKVM_PRO_PACKAGE_DIR)/kvmapp/server/
	@rm -rf $(NANOKVM_PRO_PACKAGE_DIR)/kvmapp/server/web/
	@mkdir $(NANOKVM_PRO_PACKAGE_DIR)/kvmapp/server/web/
	@cp -r $(NANOKVM_PRO_BUILD_DIR)/web/dist/* $(NANOKVM_PRO_PACKAGE_DIR)/kvmapp/server/web/
	@cd $(BUILDDIR)/nanokvm-pro ; rm -f nanokvm_pro_$(NANOKVM_PRO_VERSION)/nanokvmpro_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb
	@cd $(BUILDDIR)/package/ && dpkg-deb --build nanokvmpro-$(NANOKVM_PRO_VERSION) nanokvmpro_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/nanokvmpro_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/nanokvmpro_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/nanokvm-pro-kvmcomm-stamp: $(BUILDDIR)/nanokvm-pro-prepare-stamp
	@cd $(BUILDDIR)/nanokvm-pro ; dpkg-deb -R nanokvm_pro_$(NANOKVM_PRO_VERSION)/kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)
	@for f in $(NANOKVM_PRO_KVMCOMM_MODULES) ; do \
		cp -p $(BSP_INSTALL_DIR)/ko/$$f $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)/kvmcomm/ko/ ; \
	done
	@sed -i 's|https://cdn.sipeed.com/nanokvm|$(NANOKVM_PRO_ARCH_URL)|g' $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)/kvmcomm/scripts/firmware_update.sh
	@sed -i 's|https://cdn.sipeed.com/nanokvm|$(NANOKVM_PRO_ARCH_URL)|g' $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)/kvmcomm/scripts/reset_to_default.sh
	@cd $(BUILDDIR)/nanokvm-pro ; rm -f nanokvm_pro_$(NANOKVM_PRO_VERSION)/kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb
	@cd $(BUILDDIR)/package/ && dpkg-deb --build kvmcomm-$(NANOKVM_PRO_VERSION) kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/nanokvm-pro-firmware-stamp: $(BUILDDIR)/aic8800-firmware-stamp $(BUILDDIR)/nanokvm-pro-kvmcomm-stamp
	@$(eval NANOKVM_PRO_FIRMWARE_VERSION=$(shell grep 'REQUIRED_FIRMWARE_VERSION=".*"' $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)/kvmcomm/scripts/kvmcomm.sh | cut -d '=' -f 2- | cut -d '"' -f 2 | sed s/'^v'/''/g))
	@$(eval NANOKVM_PRO_FIRMWARE_FILE=$(CHIP_VENDOR)_firmware_v$(NANOKVM_PRO_FIRMWARE_VERSION).tar.xz)
	@$(eval NANOKVM_PRO_FIRMWARE_PACKAGE_DIR=$(BUILDDIR)/nanokvm-pro/axera_firmware_v$(NANOKVM_PRO_FIRMWARE_VERSION))
	@mkdir -p $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)
	@cp -p $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)/kvmcomm/scripts/firmware_update.sh $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/
	@mkdir -p $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/firmware/
	@cp $(BSP_INSTALL_DIR)/uboot.bin $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/firmware/u-boot_signed.bin
	@for f in $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/firmware/AX630C_$(UBOOT_BOARD)_signed.dtb ; do \
		cp $(BSP_INSTALL_DIR)/dtb.img $$f ; \
	done
	@cp $(BSP_INSTALL_DIR)/kernel.img $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/firmware/boot_signed.bin
	@mkdir -p $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/overlay/opt/firmware/
	@cp -a $(AIC8800_PACKAGE_DIR)$(AIC8800_TARGET_DIR)/* $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/overlay/opt/firmware/
	@mkdir -p $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/overlay/soc/ko/
	@cp -p $(BSP_INSTALL_DIR)/ko/aic8800_*.ko $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/overlay/soc/ko/
	@mkdir -p $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/overlay/boot/
	@cp /configs/$(BOARD_CFG)/boot/configs $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/overlay/boot/
	sed -i s/'^maix_memory_cmm=.*'/'maix_memory_cmm=$(ION_SIZE)'/g $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/overlay/boot/configs
	@echo "nanokvm-pro-$$(date +%Y-%m-%d)-v$(NANOKVM_PRO_FIRMWARE_VERSION)" > $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR)/overlay/boot/ver
	@cd $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR) && $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)/kvmcomm/scripts/firmware_update.sh gen_b2sum
	@cd $(NANOKVM_PRO_FIRMWARE_PACKAGE_DIR) && tar cJf /output/"$(BOARD)-$(NANOKVM_PRO_FIRMWARE_FILE)" *
	@touch $@

$(BUILDDIR)/nanokvm-pro-stamp: $(BUILDDIR)/nanokvm-pro-package-stamp $(BUILDDIR)/nanokvm-pro-firmware-stamp
	@cp -p $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION)/*.deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp -p $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION)/*.deb /rootfs/tmp/install/
	@mkdir -pv /rootfs/boot/
	@echo kvm > /rootfs/boot/hostname.prefix
	@touch $@

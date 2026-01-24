ifneq ("$(findstring nanokvm-pro,$(IMAGE_ADDITIONS))","")
BSPFILTER += "nanokvm-pro"
endif

NANOKVM_PRO_GIT_REF = c6ba5c8a0313d7817db9fe63f3a308d0f21c2996
NANOKVM_PRO_GIT_URL = https://github.com/sipeed/NanoKVM-Pro

NANOKVM_PRO_GO_VENDOR_REF = f573cc27f239da8ce24646e4dbe91410c88b1c03
NANOKVM_PRO_GO_VENDOR_URL = https://github.com/scpcom/nanokvm-pro-server-vendor
NANOKVM_PRO_GOMOD = server

NANOKVM_PRO_STABLE_URL = https://cdn.sipeed.com/nanokvm
NANOKVM_PRO_BASE_URL ?= $(NANOKVM_PRO_STABLE_URL)

NANOKVM_PRO_BUILD_DIR = $(BUILDDIR)/nanokvm-pro/NanoKVM-Pro

NANOKVM_PRO_KVMCOMM_MODULES = f_udisp_drv.ko \
fbtft.ko \
fb_jd9853.ko \
gpio_keys.ko \
lt6911_manage.ko \
rotary_encoder.ko

$(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json:
	@mkdir -p $(BUILDDIR)/nanokvm-pro
	@cd $(BUILDDIR)/nanokvm-pro ; wget -q -O nanokvm_pro_latest.json "$(NANOKVM_PRO_BASE_URL)/nanokvm_pro_latest.json?now=$(shell date +%s)"

$(BUILDDIR)/nanokvm-pro-stamp: $(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json
	@echo "$(COLOUR_GREEN)Installing nanokvm-pro for $(BOARD)$(END_COLOUR)"
	@mkdir -p /rootfs/boot/
	@cp -p addons/nanokvm-pro/configs /rootfs/boot/
	@touch /rootfs/boot/check_resize2fs
	@touch /rootfs/boot/first_time_boot
	@touch /rootfs/boot/usb.ncm
	@mkdir -p $(BUILDDIR)/nanokvm-pro
	@$(eval NANOKVM_PRO_LATEST_FILE=$(shell cat $(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json | jq -c '.name' | cut -d '"' -f 2))
	@$(eval NANOKVM_PRO_VERSION=$(shell cat $(BUILDDIR)/nanokvm-pro/nanokvm_pro_latest.json | jq -c '.version' | cut -d '"' -f 2))
	@$(eval NANOKVM_PRO_PACKAGE_DIR=$(BUILDDIR)/package/nanokvmpro-$(NANOKVM_PRO_VERSION))
	@cd $(BUILDDIR)/nanokvm-pro ; wget -N "$(NANOKVM_PRO_BASE_URL)/$(NANOKVM_PRO_LATEST_FILE)"
	@cd $(BUILDDIR)/nanokvm-pro ; tar xzf "$(NANOKVM_PRO_LATEST_FILE)"
	@cd $(BUILDDIR)/nanokvm-pro ; dpkg-deb -R nanokvm_pro_$(NANOKVM_PRO_VERSION)/nanokvmpro_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb $(NANOKVM_PRO_PACKAGE_DIR)
	@cd $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION) ; [ "$(findstring ubuntu,$(DEB_URL))" != "" ] || wget -N https://launchpadlibrarian.net/587202705/libjpeg-turbo8_2.1.2-0ubuntu1_arm64.deb
	@cd $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION) ; [ "$(DEB_DISTRO)" != "trixie" ] || wget -N https://launchpadlibrarian.net/725377717/libconfig9_1.5-0.4build2_arm64.deb
	@cd $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION) ; [ "$(DEB_DISTRO)" = "jammy" ] || wget -N https://launchpadlibrarian.net/571748137/libwebsockets16_4.0.20-2ubuntu1_arm64.deb
	@cd $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION) ; [ "$(findstring ubuntu,$(DEB_URL))" != "" ] || wget -N https://launchpadlibrarian.net/572052652/ttyd_1.6.3+20210924-1build1_arm64.deb
	@apt-get install -y golang-go npm
	@npm install -g pnpm
	@cd $(BUILDDIR)/nanokvm-pro && git clone $(NANOKVM_PRO_GIT_URL)
	@cd $(NANOKVM_PRO_BUILD_DIR) && git checkout $(NANOKVM_PRO_GIT_REF)
	@cd $(NANOKVM_PRO_BUILD_DIR)/$(NANOKVM_PRO_GOMOD) && git clone --depth 1 $(NANOKVM_PRO_GO_VENDOR_URL) vendor
	@cd $(NANOKVM_PRO_BUILD_DIR)/$(NANOKVM_PRO_GOMOD)/vendor && git checkout $(NANOKVM_PRO_GO_VENDOR_REF)
	@$(foreach file, $(wildcard /configs/common/patches/nanokvm-pro/*.patch), cd $(NANOKVM_PRO_BUILD_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/chip/$(CHIP_CFG)/patches/nanokvm-pro/*.patch), cd $(NANOKVM_PRO_BUILD_DIR) && git apply --ignore-whitespace $(file);)
	@$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/nanokvm-pro/*.patch), cd $(NANOKVM_PRO_BUILD_DIR) && git apply --ignore-whitespace $(file);)
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
	@$(eval NANOKVM_PRO_KVMCOMM_PACKAGE_DIR=$(BUILDDIR)/package/kvmcomm-$(NANOKVM_PRO_VERSION))
	@cd $(BUILDDIR)/nanokvm-pro ; dpkg-deb -R nanokvm_pro_$(NANOKVM_PRO_VERSION)/kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)
	@for f in $(NANOKVM_PRO_KVMCOMM_MODULES) ; do \
		cp -p $(BSP_INSTALL_DIR)/ko/$$f $(NANOKVM_PRO_KVMCOMM_PACKAGE_DIR)/kvmcomm/ko/ ; \
	done
	@cd $(BUILDDIR)/nanokvm-pro ; rm -f nanokvm_pro_$(NANOKVM_PRO_VERSION)/kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb
	@cd $(BUILDDIR)/package/ && dpkg-deb --build kvmcomm-$(NANOKVM_PRO_VERSION) kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/kvmcomm_$(NANOKVM_PRO_VERSION)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@cp -p $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION)/*.deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp -p $(BUILDDIR)/nanokvm-pro/nanokvm_pro_$(NANOKVM_PRO_VERSION)/*.deb /rootfs/tmp/install/
	@mkdir -pv /rootfs/boot/
	@echo kvm > /rootfs/boot/hostname.prefix
	@touch $@

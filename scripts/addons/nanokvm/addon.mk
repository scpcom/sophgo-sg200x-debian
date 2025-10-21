$(BUILDDIR)/nanokvm-stamp: $(BUILDDIR)/buildroot-package-stamp
	@echo "$(COLOUR_GREEN)Packaging NanoKVM for $(BOARD)$(END_COLOUR)"
	@$(eval NANOKVMVERSION=$(shell cat $(BR_OUTPUT_DIR)/target/kvmapp/version))
	@$(eval BV=$(shell cd $(BUILDDIR)/buildroot && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@find $(BR_OUTPUT_DIR)/target/kvmapp/server -name "*.so*" -type f ! -path "*libgcc_s.so" ! -path "*libtinyalsa.so" ! -path "*libaac*.so" ! -path "*libcvi_audio.so" ! -path "*libcvi_*ssp*.so" ! -path "*libcvi_*vqe*.so" ! -path "*libcvi_RES1.so" ! -path "*libcvi_VoiceEngine.so" ! -path "*libae.so" ! -path "*libaf.so" ! -path "*libawb.so" ! -path "*libisp_algo.so" ! -path "*.py*" -printf 'striping %p\n' -exec $(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)strip --strip-all {} \;
	@find $(BR_OUTPUT_DIR)/target/kvmapp/server -executable -type f ! -name "*.sh" ! -path "*etc*" ! -path "*.ko" ! -path "*.so*" ! -path "*.ini*" ! -path "*.py*" ! -path "*.script*" -printf 'striping %p\n' -exec $(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)strip --strip-all {} 2>/dev/null \;
	@mkdir -p $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)
	@cp -r /builder/deb/nanokvm-sg200x/* $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/
	@mkdir -pv $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/
	@cp -a addons/nanokvm/S01fs $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/
	@chmod +x $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/S01fs
	@cp -a addons/nanokvm/S15kvmhwd $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/
	@chmod +x $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/S15kvmhwd
	@cp -a addons/nanokvm/S95nanokvm $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/
	@chmod +x $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/S95nanokvm
	@mkdir -pv $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/systemd/system/
	@cp -a addons/nanokvm/kvm-data*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/systemd/system/
	@cp -a addons/nanokvm/kvm-hwd*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/systemd/system/
	@cp -a addons/nanokvm/nanokvm*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/systemd/system/
	@mkdir -pv $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/
	@rsync -avpPxH $(BR_OUTPUT_DIR)/target/kvmapp/ $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/
	@sed -i s/'i2cdetect -ry'/'i2cdetect -r -y'/g $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/S15kvmhwd
	@sed -i 's|# cp -r /kvmapp/server|cp -r /kvmapp/server|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/S95nanokvm
	@sed -i 's|# /tmp/server/NanoKVM-Server|/tmp/server/NanoKVM-Server|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/S95nanokvm
	@sed -i 's|/tmp/server/NanoKVM-Server &|/tmp/server/NanoKVM-Server|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/S95nanokvm
	@sed -i /S49ntp/d $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/etc/init.d/S95nanokvm
	@sed -i /'parted -s .dev.mmcblk0 "resizepart 2 -0"'/d $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i 's|parted ---pretend-input-tty /dev/mmcblk0 "resizepart 2 8192MB"|true|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i /'resize2fs .dev.mmcblk0p2'/d $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i /'mkdir -p .boot'/d $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i /'mount -t vfat .dev.mmcblk0p1'/d $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i /'mount -t configfs configfs'/d $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i /'mount -t debugfs debugfs'/d $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i s/'mkpart primary 8193MB 100%'/'mkpart primary 25% 100%'/g $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i 's|mount /dev/mmcblk0p3 /data|/usr/bin/mount -o uid=debian /dev/mmcblk0p3 /data|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S01fs
	@sed -i 's|#!/bin/sh|#!/bin/busybox sh|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S03usb*
	@sed -i 's|echo -ne .*x34 > functions/hid.GS1/report_length|echo 4 > functions/hid.GS1/report_length|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S03usb*
	@sed -i 's|#!/bin/sh|#!/bin/busybox sh|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S15kvmhwd
	@sed -i s/'i2cdetect -ry'/'i2cdetect -r -y'/g $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S15kvmhwd
	@sed -i 's|#!/bin/sh|#!/bin/busybox sh|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S95nanokvm
	@sed -i 's|# cp -r /kvmapp/server|cp -r /kvmapp/server|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S95nanokvm
	@sed -i 's|# /tmp/server/NanoKVM-Server|/tmp/server/NanoKVM-Server|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S95nanokvm
	@sed -i 's|/tmp/server/NanoKVM-Server &|/tmp/server/NanoKVM-Server|g' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S95nanokvm
	@sed -i /S49ntp/d $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S95nanokvm
	@rm -f $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S00kmod
	@rm -f $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S30eth
	@rm -f $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S30gadget_nic
	@cp -p addons/nanokvm/S30wifi $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/
	@chmod +x $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/S30wifi
	@mkdir -pv $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/systemd/
	@cp -a addons/nanokvm/kvm-data*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/systemd/
	@cp -a addons/nanokvm/kvm-hwd*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/systemd/
	@cp -a addons/nanokvm/nanokvm*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/systemd/
	@cp -a addons/usb-device/usb-device*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/systemd/
	@cp -a addons/wifi-builtin/wifi-builtin*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/systemd/
	@cp -a addons/wifi-builtin/wifi-hostapd*.service $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/systemd/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(NANOKVMVERSION)$(BV)/' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/DEBIAN/control
	@sed -i 's/Package: nanokvm-sg200x/Package: nanokvm-$(BOARD)/' $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/DEBIAN/control
	@chmod +x $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/DEBIAN/postinst
	@cd $(BUILDDIR)/package/ && dpkg-deb --build nanokvm-$(BOARD)-$(NANOKVMVERSION) nanokvm-$(BOARD)_$(NANOKVMVERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/nanokvm-$(BOARD)_$(NANOKVMVERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/nanokvm-$(BOARD)*.deb /rootfs/tmp/install/
	@rm -f /output/nanokvm-latest.zip
	@rsync -avpPxH $(BUILDDIR)/package/nanokvm-$(BOARD)-$(NANOKVMVERSION)/kvmapp/system/init.d/ $(BR_OUTPUT_DIR)/target/kvmapp/system/init.d/
	@ln -s kvmapp $(BR_OUTPUT_DIR)/target/latest
	@cd $(BR_OUTPUT_DIR)/target && zip -r --symlinks /output/nanokvm-latest.zip latest/*
	@rm $(BR_OUTPUT_DIR)/target/latest
	@echo "$(COLOUR_GREEN)Installing nanokvm for $(BOARD)$(END_COLOUR)"
	@mkdir -pv /rootfs/boot/
	@touch /rootfs/boot/usb.disk0
	@touch /rootfs/boot/usb.rndis0
	@mkdir -p /rootfs/tmp/install/
	@echo " kvm-data" >> /rootfs/tmp/install/systemd-enable
	@echo " kvm-hwd" >> /rootfs/tmp/install/systemd-enable
	@echo " nanokvm" >> /rootfs/tmp/install/systemd-enable
	@touch $@

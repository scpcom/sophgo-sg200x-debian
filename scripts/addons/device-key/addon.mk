$(BUILDDIR)/device-key-stamp:
	@echo "$(COLOUR_GREEN)Packaging device-key for $(BOARD)$(END_COLOUR)"
	@$(eval DEVICEKEYVERSION=$(shell echo "1.0.0"))
	@$(eval DEVICEKEY_PACKAGE_DIR=$(BUILDDIR)/package/device-key-$(BOARD)-$(DEVICEKEYVERSION))
	@mkdir -p $(DEVICEKEY_PACKAGE_DIR)
	@cp -r /builder/deb/device-key/* $(DEVICEKEY_PACKAGE_DIR)/
	@mkdir -pv $(DEVICEKEY_PACKAGE_DIR)/etc/init.d/
	@cp -a addons/device-key/S02devicekey $(DEVICEKEY_PACKAGE_DIR)/etc/init.d/
	@chmod +x $(DEVICEKEY_PACKAGE_DIR)/etc/init.d/S02devicekey
	@cp -a addons/device-key/S10uuid $(DEVICEKEY_PACKAGE_DIR)/etc/init.d/
	@chmod +x $(DEVICEKEY_PACKAGE_DIR)/etc/init.d/S10uuid
	@mkdir -pv $(DEVICEKEY_PACKAGE_DIR)/etc/systemd/system/
	@cp -a addons/device-key/device-key*.service $(DEVICEKEY_PACKAGE_DIR)/etc/systemd/system/
	@cp -a addons/device-key/device-uuid*.service $(DEVICEKEY_PACKAGE_DIR)/etc/systemd/system/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(DEVICEKEY_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(DEVICEKEYVERSION)/' $(DEVICEKEY_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: device-key/Package: device-key-$(BOARD)/' $(DEVICEKEY_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build device-key-$(BOARD)-$(DEVICEKEYVERSION) device-key-$(BOARD)_$(DEVICEKEYVERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/device-key-$(BOARD)_$(DEVICEKEYVERSION)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/device-key-*.deb /rootfs/tmp/install/
	@echo "$(COLOUR_GREEN)Installing device-key for $(BOARD)$(END_COLOUR)"
	@mkdir -pv /rootfs/boot/
	@[ "$(BOARD)" = "licheervnano" ] || echo $(BOARD) > /rootfs/boot/hostname.prefix
	@mkdir -p /rootfs/tmp/install/
	@echo " device-key" >> /rootfs/tmp/install/systemd-enable
	@echo " device-uuid" >> /rootfs/tmp/install/systemd-enable
	@touch $@

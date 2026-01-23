$(BUILDDIR)/gadget-nic-stamp:
	@echo "$(COLOUR_GREEN)Packaging gadget-nic for $(BOARD)$(END_COLOUR)"
	@$(eval GADGETNICVERSION=$(shell echo "1.2.0"))
	@$(eval GADGETNIC_PACKAGE_DIR=$(BUILDDIR)/package/gadget-nic-$(BOARD)-$(GADGETNICVERSION))
	@mkdir -p $(GADGETNIC_PACKAGE_DIR)
	@cp -r /builder/deb/gadget-nic/* $(GADGETNIC_PACKAGE_DIR)/
	@mkdir -pv $(GADGETNIC_PACKAGE_DIR)/etc/init.d/
	@cp -a addons/gadget-nic/S30gadget_nic $(GADGETNIC_PACKAGE_DIR)/etc/init.d/
	@chmod +x $(GADGETNIC_PACKAGE_DIR)/etc/init.d/S30gadget_nic
	@ln -s S30gadget_nic $(GADGETNIC_PACKAGE_DIR)/etc/init.d/S30rndis
	@mkdir -pv $(GADGETNIC_PACKAGE_DIR)/etc/systemd/system/
	@cp -a addons/gadget-nic/gadget-nic*.service $(GADGETNIC_PACKAGE_DIR)/etc/systemd/system/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(GADGETNIC_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(GADGETNICVERSION)/' $(GADGETNIC_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: gadget-nic/Package: gadget-nic-$(BOARD)/' $(GADGETNIC_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(GADGETNIC_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(GADGETNIC_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(GADGETNIC_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/RISC-V/$(ARCH_NAME)/' $(GADGETNIC_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build gadget-nic-$(BOARD)-$(GADGETNICVERSION) gadget-nic-$(BOARD)_$(GADGETNICVERSION)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/gadget-nic-$(BOARD)_$(GADGETNICVERSION)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/gadget-nic-*.deb /rootfs/tmp/install/
	@echo "$(COLOUR_GREEN)Installing gadget-nic for $(BOARD)$(END_COLOUR)"
	@if [ "X$(findstring kvm,$(VARIANT))" = "X" ]; then \
		mkdir -pv /rootfs/boot/ ; \
		touch /rootfs/boot/usb.rndis ; \
	fi
	@mkdir -p /rootfs/tmp/install/
	@echo " gadget-nic" >> /rootfs/tmp/install/systemd-enable
	@echo " gadget-nic-usb0.service" >> /rootfs/tmp/install/systemd-enable
	@echo " gadget-nic-usb1.service" >> /rootfs/tmp/install/systemd-enable
	@touch $@

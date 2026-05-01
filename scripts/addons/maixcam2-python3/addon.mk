ifneq ("$(findstring maixcam2-python3,$(IMAGE_ADDITIONS))","")
BSPFILTER += "maixcam2-python3"
endif

MAIXCAM2_PYTHON3_PACKAGE_NAME = maixcam2-python3

MAIXCAM2_PYTHON3_SHA256 = a37165fddf7401b3932b94a10e9cbb166d9ee825e34e23a27de2dadcacce411a
MAIXCAM2_PYTHON3_VERSION = 3.13.2
MAIXCAM2_PYTHON3_BUILD = 1

MAIXCAM2_PYTHON3_BASE_URL = $(GIT_RELEASES_URL)/sipeed/MaixCDK/releases/download/v0.0.0
MAIXCAM2_PYTHON3_FILENAME = python3.13.2_maixcam2_gcc11.4.0.tar.xz

MAIXCAM2_PYTHON3_PACKAGE_DIR = $(BUILDDIR)/package/$(MAIXCAM2_PYTHON3_PACKAGE_NAME)-$(MAIXCAM2_PYTHON3_VERSION)

MAIXCAM2_PYTHON3_SITE_PACKAGES = /usr/local/lib/python3.13/site-packages
MAIXCAM2_PYTHON3_SHARE_DIR = /usr/local/share/$(MAIXCAM2_PYTHON3_PACKAGE_NAME)

$(BUILDDIR)/maixcam2-python3-stamp:
	@echo "$(COLOUR_GREEN)Packaging maixcam2-python3 for $(BOARD)$(END_COLOUR)"
	@$(eval PV=-$(MAIXCAM2_PYTHON3_BUILD))
	@mkdir -p $(BUILDDIR)/maixcam2-python3
	@cd $(BUILDDIR)/maixcam2-python3 ; wget -N "$(MAIXCAM2_PYTHON3_BASE_URL)/$(MAIXCAM2_PYTHON3_FILENAME)"
	@if [ "`sha256sum "$(BUILDDIR)/maixcam2-python3/$(MAIXCAM2_PYTHON3_FILENAME)" | cut -d ' ' -f 1`" != "$(MAIXCAM2_PYTHON3_SHA256)" ]; then \
		echo "$(MAIXCAM2_PYTHON3_FILENAME): checksum mismatch!" ; \
		exit 1 ; \
	fi
	@mkdir -p $(MAIXCAM2_PYTHON3_PACKAGE_DIR)
	@cp -r /builder/deb/maixapp-sg200x/* $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/
	@mkdir -pv $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/usr/local/
	@cd $(BUILDDIR)/maixcam2-python3 ; tar -Jxvf $(MAIXCAM2_PYTHON3_FILENAME) -C $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/usr/local
	@mkdir -p $(MAIXCAM2_PYTHON3_PACKAGE_DIR)$(MAIXCAM2_PYTHON3_SHARE_DIR)/
	@cp -p addons/maixcam2-python3/firstrun.sh $(MAIXCAM2_PYTHON3_PACKAGE_DIR)$(MAIXCAM2_PYTHON3_SHARE_DIR)/
	@cp -p addons/maixcam2-python3/requirements.txt $(MAIXCAM2_PYTHON3_PACKAGE_DIR)$(MAIXCAM2_PYTHON3_SHARE_DIR)/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(MAIXCAM2_PYTHON3_VERSION)$(PV)/' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: maixapp-sg200x/Package: $(MAIXCAM2_PYTHON3_PACKAGE_NAME)/' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@sed -i '/Depends: .*/d' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/MaixCDK/MaixCAM2 Python3/' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CVITEK/$(CHIP_VENDOR)/' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/CV18xx and SG200X/$(CHIP)/' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/cv181x/$(CHIP)/' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/RISC-V/$(ARCH_NAME)/' $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/control
	@echo '#!/bin/sh' > $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/postinst
	@echo '$(MAIXCAM2_PYTHON3_SHARE_DIR)/firstrun.sh' >> $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/postinst
	@chmod ugo+rx $(MAIXCAM2_PYTHON3_PACKAGE_DIR)/DEBIAN/postinst
	@cd $(BUILDDIR)/package/ && dpkg-deb --build $(MAIXCAM2_PYTHON3_PACKAGE_NAME)-$(MAIXCAM2_PYTHON3_VERSION) $(MAIXCAM2_PYTHON3_PACKAGE_NAME)_$(MAIXCAM2_PYTHON3_VERSION)$(PV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/$(MAIXCAM2_PYTHON3_PACKAGE_NAME)_$(MAIXCAM2_PYTHON3_VERSION)$(PV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/$(MAIXCAM2_PYTHON3_PACKAGE_NAME)_$(MAIXCAM2_PYTHON3_VERSION)$(PV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

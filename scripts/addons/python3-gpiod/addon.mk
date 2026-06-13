ifneq ("$(findstring python3-gpiod,$(IMAGE_ADDITIONS))","")
BSPFILTER += "python3-gpiod"
endif

PYTHON3_GPIOD_VERSION = 2.2.1
PYTHON3_GPIOD_BUILD = 1

PYTHON3_GPIOD_BASE_URL = https://files.pythonhosted.org/packages/e6/6a/a8120a6c582099ea7fd3b46a7071f0b9dd32808d337dc9e3da05ef046e67
#PYTHON3_GPIOD_WHL_URL =
PYTHON3_GPIOD_WHL_FILE = gpiod-$(PYTHON3_GPIOD_VERSION)-cp3*-linux_*.whl

PYTHON3_GPIOD_BUILD_DIR = /rootfs/root/gpiod
PYTHON3_GPIOD_DL_DIR = $(BUILDDIR)/gpiod

ifneq ("$(findstring libgpiod,$(IMAGE_ADDITIONS))","")
PYTHON3_GPIOD_DEPENDS += $(BUILDDIR)/python3-gpiod-lib-stamp
endif


$(BUILDDIR)/python3-gpiod-prepare-stamp: $(BUILDDIR)/python3-dev-install-stamp
	@echo "$(COLOUR_GREEN)Building python3-gpiod for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(PYTHON3_GPIOD_DL_DIR)
	@cd $(PYTHON3_GPIOD_DL_DIR) && wget -N $(PYTHON3_GPIOD_BASE_URL)/gpiod-$(PYTHON3_GPIOD_VERSION).tar.gz || wget -N $(USER_SITE_URL)/pythonhosted/gpiod-$(PYTHON3_GPIOD_VERSION).tar.gz
	@#cd $(PYTHON3_GPIOD_DL_DIR) && wget -N $(PYTHON3_GPIOD_WHL_URL)/$(PYTHON3_GPIOD_WHL_FILE) || wget -N $(USER_SITE_URL)/pythonhosted/$(PYTHON3_GPIOD_WHL_FILE)
	@cp -p addons/python3-gpiod/gpiod-$(PYTHON3_GPIOD_VERSION).sha256 $(PYTHON3_GPIOD_DL_DIR)
	@cd $(PYTHON3_GPIOD_DL_DIR) && sha256sum -c gpiod-$(PYTHON3_GPIOD_VERSION).sha256
	@touch $@

$(BUILDDIR)/python3-gpiod-lib-stamp: $(BUILDDIR)/libgpiod-stamp
	@chroot /rootfs mount proc -t proc /proc
	@chroot /rootfs bash -c 'dpkg -i /tmp/install/libgpiod3_$(LIBGPIOD_VERSION)-$(LIBGPIOD_BUILD)_$(DEB_ARCH).deb'
	@chroot /rootfs bash -c 'dpkg -i /tmp/install/libgpiod-dev_$(LIBGPIOD_VERSION)-$(LIBGPIOD_BUILD)_$(DEB_ARCH).deb'
	@chroot /rootfs bash -c 'dpkg -i /tmp/install/gpiod_$(LIBGPIOD_VERSION)-$(LIBGPIOD_BUILD)_$(DEB_ARCH).deb'
	@chroot /rootfs apt-get install -y libgpiod-dev
	@umount /rootfs/proc || true
	@touch $@

$(BUILDDIR)/python3-gpiod-whl-stamp: $(BUILDDIR)/python3-gpiod-prepare-stamp $(PYTHON3_GPIOD_DEPENDS)
	@mkdir -p $(PYTHON3_GPIOD_BUILD_DIR)
	@tar -C $(PYTHON3_GPIOD_BUILD_DIR) -xzf $(PYTHON3_GPIOD_DL_DIR)/gpiod-$(PYTHON3_GPIOD_VERSION).tar.gz
	@chroot /rootfs mount proc -t proc /proc
	@chroot /rootfs bash -c 'cd /root/gpiod/gpiod-$(PYTHON3_GPIOD_VERSION) && python3 setup.py bdist_wheel'
	@umount /rootfs/proc || true
	@cp -p $(PYTHON3_GPIOD_BUILD_DIR)/gpiod-$(PYTHON3_GPIOD_VERSION)/dist/$(PYTHON3_GPIOD_WHL_FILE) $(PYTHON3_GPIOD_DL_DIR)/
	@touch $@

$(BUILDDIR)/python3-gpiod-stamp: $(BUILDDIR)/python3-gpiod-whl-stamp $(BUILDDIR)/python3-pip-install-stamp
	@mkdir -p /rootfs/tmp/install/
	@cp -p $(PYTHON3_GPIOD_DL_DIR)/$(PYTHON3_GPIOD_WHL_FILE) /rootfs/tmp/install/
	@chroot /rootfs bash -c 'pip install --break-system-packages /tmp/install/$(PYTHON3_GPIOD_WHL_FILE)'
	@[ "$(GIT_REF)" = "develop" ] || rm -rf $(PYTHON3_GPIOD_BUILD_DIR)
	@touch $@

ifneq ("$(findstring python3,$(IMAGE_ADDITIONS))","")
BSPFILTER += "python3"
endif
ifneq ("$(findstring python3-dev,$(IMAGE_ADDITIONS))","")
BSPFILTER += "python3-dev"
DEV_PACKAGES += " python3-all-dev libpython3-all-dev python3-venv pybuild-plugin-pyproject"
ifneq ("$(findstring maixcam2-python3,$(IMAGE_ADDITIONS))","")
DEV_PACKAGES += " python3-setuptools"
else
DEV_PACKAGES += " python3-pip"
PACKAGES += " python3-setuptools"
endif
endif

ifneq ("$(findstring maixcam2-python3,$(IMAGE_ADDITIONS))","")
$(BUILDDIR)/python3-install-stamp: $(BUILDDIR)/image-configure-stamp $(BUILDDIR)/maixcam2-python3-stamp
	@echo "$(COLOUR_GREEN)Installing python3 for $(BOARD)$(END_COLOUR)"
	@chroot /rootfs mount proc -t proc /proc
	@chroot /rootfs bash -c 'apt install --allow-downgrades -y -f /tmp/install/$(MAIXCAM2_PYTHON3_PACKAGE_NAME)_$(MAIXCAM2_PYTHON3_VERSION)*_$(DEB_ARCH).deb'
	@umount /rootfs/proc || true
	@touch $@

$(BUILDDIR)/python3-pip-install-stamp: $(BUILDDIR)/python3-install-stamp
	@echo "$(COLOUR_GREEN)Installing python3 pip for $(BOARD)$(END_COLOUR)"
	@touch $@

$(BUILDDIR)/python3-dev-install-stamp: $(BUILDDIR)/python3-install-stamp
	@echo "$(COLOUR_GREEN)Installing python3 dev for $(BOARD)$(END_COLOUR)"
	@chroot /rootfs pip install build setuptools
	@touch $@

$(BUILDDIR)/python3-dev-uninstall-stamp: $(BUILDDIR)/image-customize-stamp
	@echo "$(COLOUR_GREEN)Uninstalling python3 dev for $(BOARD)$(END_COLOUR)"
	@touch $@

else
$(BUILDDIR)/python3-install-stamp: $(BUILDDIR)/image-configure-stamp
	@echo "$(COLOUR_GREEN)Installing python3 for $(BOARD)$(END_COLOUR)"
	@chroot /rootfs apt-get update || true
	@chroot /rootfs apt-get install -y python3-minimal
	@touch $@

$(BUILDDIR)/python3-pip-install-stamp: $(BUILDDIR)/python3-install-stamp
	@echo "$(COLOUR_GREEN)Installing python3 pip for $(BOARD)$(END_COLOUR)"
	@chroot /rootfs apt-get update || true
	@chroot /rootfs mount proc -t proc /proc
	@chroot /rootfs apt-get install -y --no-install-recommends python3-pip
	@umount /rootfs/proc || true
	@touch $@

$(BUILDDIR)/python3-dev-install-stamp: $(BUILDDIR)/python3-install-stamp
	@echo "$(COLOUR_GREEN)Installing python3 dev for $(BOARD)$(END_COLOUR)"
	@chroot /rootfs apt-get update || true
	@chroot /rootfs mount proc -t proc /proc
	@chroot /rootfs apt-get install -y python3-all-dev libpython3-all-dev python3-build python3-pip python3-setuptools python3-venv python3-wheel pybuild-plugin-pyproject
	@umount /rootfs/proc || true
	@touch $@

$(BUILDDIR)/python3-dev-uninstall-stamp: $(BUILDDIR)/image-customize-stamp
	@echo "$(COLOUR_GREEN)Uninstalling python3 dev for $(BOARD)$(END_COLOUR)"
	@chroot /rootfs mount proc -t proc /proc
	@#chroot /rootfs apt-get remove --purge -y python3-all-dev libpython3-all-dev pybuild-plugin-pyproject
	@#chroot /rootfs apt-get remove --purge -y python3-build python3-pip python3-setuptools python3-venv python3-wheel
	@chroot /rootfs apt-get autoremove --purge -y
	@umount /rootfs/proc || true
	@touch $@
endif

$(BUILDDIR)/python3-stamp: $(BUILDDIR)/python3-install-stamp

$(BUILDDIR)/python3-dev-stamp: $(BUILDDIR)/python3-dev-install-stamp

ifneq ("$(findstring python3-textual,$(IMAGE_ADDITIONS))","")
BSPFILTER += "python3-textual"
PACKAGES += " python3-markdown-it python3-mdit-py-plugins python3-platformdirs python3-pygments python3-rich python3-typing-extensions python3-zipp"
PACKAGES += " python3-linkify-it python3-uc-micro"
endif

PYTHON3_TEXTUAL_VERSION = 2.1.2
PYTHON3_TEXTUAL_BUILD = 1

PYTHON3_TEXTUAL_BASE_URL = https://files.pythonhosted.org/packages/41/62/4af4689dd971ed4fb3215467624016d53550bff1df9ca02e7625eec07f8b
PYTHON3_TEXTUAL_WHL_URL = https://files.pythonhosted.org/packages/07/81/9df1988c908cbba77f10fecb8587496b3dff2838d4510457877a521d87fd
PYTHON3_TEXTUAL_WHL_FILE = textual-$(PYTHON3_TEXTUAL_VERSION)-py3-none-any.whl

PYTHON3_TEXTUAL_DL_DIR = $(BUILDDIR)/textual

$(BUILDDIR)/python3-textual-prepare-stamp: $(BUILDDIR)/python3-dev-install-stamp
	@echo "$(COLOUR_GREEN)Building python3-textual for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(PYTHON3_TEXTUAL_DL_DIR)
	@cd $(PYTHON3_TEXTUAL_DL_DIR) && wget -N $(PYTHON3_TEXTUAL_BASE_URL)/textual-$(PYTHON3_TEXTUAL_VERSION).tar.gz || wget -N $(USER_SITE_URL)/pythonhosted/textual-$(PYTHON3_TEXTUAL_VERSION).tar.gz
	@cd $(PYTHON3_TEXTUAL_DL_DIR) && wget -N $(PYTHON3_TEXTUAL_WHL_URL)/$(PYTHON3_TEXTUAL_WHL_FILE) || wget -N $(USER_SITE_URL)/pythonhosted/$(PYTHON3_TEXTUAL_WHL_FILE)
	@cp -p addons/python3-textual/textual-$(PYTHON3_TEXTUAL_VERSION).sha256 $(PYTHON3_TEXTUAL_DL_DIR)
	@cd $(PYTHON3_TEXTUAL_DL_DIR) && sha256sum -c textual-$(PYTHON3_TEXTUAL_VERSION).sha256
	@touch $@

$(BUILDDIR)/python3-textual-stamp: $(BUILDDIR)/python3-textual-prepare-stamp $(BUILDDIR)/python3-pip-install-stamp
	@mkdir -p /rootfs/tmp/install/
	@cp -p $(PYTHON3_TEXTUAL_DL_DIR)/$(PYTHON3_TEXTUAL_WHL_FILE) /rootfs/tmp/install/
	@chroot /rootfs pip install --break-system-packages /tmp/install/$(PYTHON3_TEXTUAL_WHL_FILE)
	@touch $@

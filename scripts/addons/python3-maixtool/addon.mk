ifneq ("$(findstring python3-maixtool,$(IMAGE_ADDITIONS))","")
BSPFILTER += "python3-maixtool"
endif

PYTHON3_MAIXTOOL_VERSION = 1.4.4
PYTHON3_MAIXTOOL_BUILD = 1

PYTHON3_MAIXTOOL_BASE_URL = https://files.pythonhosted.org/packages/bc/9b/7a46b046ecf5719d9d03f84a606142c39e5747c8ea5d357c75be0582549b
#PYTHON3_MAIXTOOL_WHL_URL =
PYTHON3_MAIXTOOL_WHL_FILE = maixtool-$(PYTHON3_MAIXTOOL_VERSION)-py3-none-any.whl

PYTHON3_MAIXTOOL_DL_DIR = $(BUILDDIR)/maixtool

$(BUILDDIR)/python3-maixtool-prepare-stamp:
	@echo "$(COLOUR_GREEN)Building python3-maixtool for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(PYTHON3_MAIXTOOL_DL_DIR)
	@cd $(PYTHON3_MAIXTOOL_DL_DIR) && wget -N $(PYTHON3_MAIXTOOL_BASE_URL)/maixtool-$(PYTHON3_MAIXTOOL_VERSION).tar.gz || wget -N $(USER_SITE_URL)/pythonhosted/maixtool-$(PYTHON3_MAIXTOOL_VERSION).tar.gz
	@#cd $(PYTHON3_MAIXTOOL_DL_DIR) && wget -N $(PYTHON3_MAIXTOOL_WHL_URL)/$(PYTHON3_MAIXTOOL_WHL_FILE) || wget -N $(USER_SITE_URL)/pythonhosted/$(PYTHON3_MAIXTOOL_WHL_FILE)
	@cp -p addons/python3-maixtool/maixtool-$(PYTHON3_MAIXTOOL_VERSION).sha256 $(PYTHON3_MAIXTOOL_DL_DIR)
	@cd $(PYTHON3_MAIXTOOL_DL_DIR) && sha256sum -c maixtool-$(PYTHON3_MAIXTOOL_VERSION).sha256
	@touch $@

$(BUILDDIR)/python3-maixtool-whl-stamp: $(BUILDDIR)/python3-maixtool-prepare-stamp
	@# install requirements on host
	@apt-get install -y python3-flask python3-netifaces python3-pillow python3-yaml python3-progress python3-qrcode python3-requests python3-setuptools python3-wheel
	@tar -C $(PYTHON3_MAIXTOOL_DL_DIR) -xzf $(PYTHON3_MAIXTOOL_DL_DIR)/maixtool-$(PYTHON3_MAIXTOOL_VERSION).tar.gz
	@cd $(PYTHON3_MAIXTOOL_DL_DIR)/maixtool-$(PYTHON3_MAIXTOOL_VERSION) && python3 setup.py bdist_wheel
	@cp -p $(PYTHON3_MAIXTOOL_DL_DIR)/maixtool-$(PYTHON3_MAIXTOOL_VERSION)/dist/$(PYTHON3_MAIXTOOL_WHL_FILE) $(PYTHON3_MAIXTOOL_DL_DIR)/
	@touch $@

$(BUILDDIR)/python3-maixtool-stamp: $(BUILDDIR)/python3-maixtool-whl-stamp
	@# install maixtool on host
	@apt-get install -y python3-pip
	@pip install --break-system-packages $(PYTHON3_MAIXTOOL_DL_DIR)/$(PYTHON3_MAIXTOOL_WHL_FILE)
	@touch $@

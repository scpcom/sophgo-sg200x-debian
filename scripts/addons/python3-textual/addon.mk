ifneq ("$(findstring python3-textual,$(IMAGE_ADDITIONS))","")
BSPFILTER += "python3-textual"
PACKAGES += " python3-markdown-it python3-mdit-py-plugins python3-platformdirs python3-pygments python3-rich python3-typing-extensions python3-zipp"
PACKAGES += " python3-linkify-it python3-uc-micro"
endif

PYTHON3_TEXTUAL_VERSION = 2.1.2
PYTHON3_TEXTUAL_BUILD = 1

$(BUILDDIR)/python3-textual-stamp: $(BUILDDIR)/python3-pip-install-stamp
	@chroot /rootfs pip install --break-system-packages textual==$(PYTHON3_TEXTUAL_VERSION)
	@touch $@

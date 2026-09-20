ifneq ("$(findstring nodesource-npm,$(IMAGE_ADDITIONS))","")
BSPFILTER += "nodesource-npm"
endif

ifneq ("$(findstring nodesource-npm,$(IMAGE_ADDITIONS))","")
$(BUILDDIR)/nodesource-npm-stamp:
	apt-get update
	curl -fsSL https://deb.nodesource.com/setup_24.x -o /build/nodesource_setup.sh
	bash /build/nodesource_setup.sh
	@touch $@

$(BUILDDIR)/npm-install-stamp: $(BUILDDIR)/nodesource-npm-stamp
	apt-get install -y nodejs # npm
	@touch $@

else
$(BUILDDIR)/npm-install-stamp:
	apt-get update
	apt-get install -y nodejs npm
	@touch $@
endif

$(BUILDDIR)/npm-stamp: $(BUILDDIR)/npm-install-stamp
	@touch $@

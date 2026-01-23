DEB_DISTRO ?= trixie
DEB_KEYSERVER ?= keyserver.ubuntu.com
ifneq ($(findstring "$(DEB_DISTRO)","bullseye" "bookworm" "trixie"),)
DEB_URL ?= http://deb.debian.org/debian
DEB_COMPONENTS ?= main
DEB_COMPONENTS_FULL ?= main non-free-firmware
DEB_PUBKEY ?= 78DBA3BC47EF2265
else
DEB_URL ?= http://ports.ubuntu.com/ubuntu-ports
DEB_COMPONENTS ?= main universe
DEB_COMPONENTS_FULL ?= main restricted universe multiverse
DEB_PUBKEY ?= 871920D1991BC93C
endif

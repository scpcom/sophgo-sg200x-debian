KERNELREV="6"
FSBLVERSION=1.2.0
BSPVERSION=1.0.60
OSDRVVERSION=2024.10.14
MIDDLEWAREVERSION=2024.10.14
PACKAGES="busybox-static ca-certificates debian-archive-keyring dosfstools binutils file tree sudo bash-completion u-boot-menu openssh-server dnsmasq-base libpam-systemd ppp libatomic1 libgomp1 libengine-pkcs11-openssl iptables lldpd locales locales-all picocom psmisc systemd-timesyncd vim usbutils parted exfatprogs systemd-sysv i2c-tools net-tools ifupdown ethtool avahi-utils gnupg rsync gpiod u-boot-tools libubootenv-tool bc fake-hwclock lzip python3-requests unzip wget"
ifeq ("$(findstring kvm,$(VARIANT))","")
PACKAGES += " network-manager"
endif

IMAGE_ADDITIONS="gadget-nic"
IMAGE_ADDITIONS+="overlayfs-tools"
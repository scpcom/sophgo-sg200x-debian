CHIP_VENDOR=axera
CHIP=ax630c
CHIP_FAMILY=ax620e
UBOOT_CHIP=ax620e_emmc
UBOOT_BOARD=emmc_arm64_k419_sipeed_nanokvm
BOARD_DTS=nanokvm_pro_arm64_k419
BOOT_CPU=aarch64
ARCH=arm64
DDR_CFG=ddr3_1866_x16
ION_SIZE=320
PARTITION_FILE=partition_sd.xml
STORAGE_TYPE=emmc
VARIANT?=kvm

PACKAGES += " hostapd udhcpd wireless-regdb wpasupplicant"
PACKAGES += " build-essential libasound2-dev libcjson-dev libconfig-dev libdbus-1-dev libdrm-dev libevent-dev libjpeg-dev libjson-c5 libnice-dev libopus-dev libspeexdsp-dev libsrtp2-dev libsystemd-dev libwebsockets-dev libxkbcommon-dev nginx tesseract-ocr xz-utils"
ifeq ("$(DEB_DISTRO)","trixie")
PACKAGES += " python3-aiofiles python3-aiohttp python3-evdev python3-mako python3-netifaces python3-passlib python3-pil python3-psutil python3-pyghmi python3-pygments python3-pyotp python3-ruamel.yaml python3-serial python3-setproctitle python3-systemd python3-xlib python3-yaml python-is-python3"
PACKAGES += " python3-async-lru python3-dbus-next python3-zstandard"
else
IMAGE_ADDITIONS += "maixcam2-python3"
endif
ifneq ("$(findstring ubuntu,$(DEB_URL))","")
PACKAGES += " ttyd"
endif

#IMAGE_ADDITIONS += "sensor-config"
IMAGE_ADDITIONS += "device-key"
IMAGE_ADDITIONS += "ethernet-builtin"
#IMAGE_ADDITIONS += "load-systemko"
#IMAGE_ADDITIONS += "cvi-pinmux"
#ifneq ("$(findstring kvm,$(VARIANT))","")
#IMAGE_ADDITIONS += "nanokvm"
IMAGE_ADDITIONS += "nanokvm-pro"
#else
#IMAGE_ADDITIONS += "maixapp"
#IMAGE_ADDITIONS += "tpusdk"
#endif
#IMAGE_ADDITIONS += "usb-device"
#IMAGE_ADDITIONS += "zram-config"
#IMAGE_ADDITIONS += "wifi-builtin"
IMAGE_ADDITIONS += "aic8800-firmware"

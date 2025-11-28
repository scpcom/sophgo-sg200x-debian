CHIP=cv181x
STORAGE_TYPE?=sd
VARIANT?=e
UBOOT_CHIP=cv181x
UBOOT_BOARD=milkv_duos_$(STORAGE_TYPE)
BOOT_CPU=aarch64
ARCH=arm64
DDR_CFG=ddr3_1866_x16
ION_SIZE=74
PANEL_TUNING_DEFAULT?=MIPI_panel_milkv_8hd
PANEL_TUNING_EXTRA?=MIPI_panel_milkv_8hd_2lane MIPI_panel_milkv_st7796s
PARTITION_FILE=partition_$(STORAGE_TYPE).xml

PACKAGES += " hostapd udhcpd wireless-regdb wpasupplicant bluez"

IMAGE_ADDITIONS += "cvi-pinmux"
IMAGE_ADDITIONS += "duo-pinmux"
IMAGE_ADDITIONS += "sensor-config"
IMAGE_ADDITIONS += "device-key"
IMAGE_ADDITIONS += "ethernet-builtin"
IMAGE_ADDITIONS += "load-systemko"
IMAGE_ADDITIONS += "tpusdk"
IMAGE_ADDITIONS += "usb-device"
IMAGE_ADDITIONS += "wifi-builtin"
IMAGE_ADDITIONS += "aic8800-firmware"
IMAGE_ADDITIONS += "ethernet-leds"
IMAGE_ADDITIONS += "usb-switch"
IMAGE_ADDITIONS += "hciattach-uart"
CHIP=cv181x
UBOOT_CHIP=cv181x
UBOOT_BOARD=licheea53nano_sd
BOOT_CPU=aarch64
ARCH=arm64
DDR_CFG=ddr3_1866_x16
ifneq ("$(findstring kvm,$(VARIANT))","")
BOARD_EXT=$(BOARD)-$(VARIANT)
ION_SIZE=35
MMC_MAX_FREQUENCY ?= 50000000
else
ION_SIZE=63
MMC_MAX_FREQUENCY ?= 25000000
endif
PANEL_TUNING_DEFAULT?=MIPI_panel_zct2133v1
PANEL_TUNING_EXTRA?=MIPI_panel_lt9611_1024x768_60hz MIPI_panel_lt9611_1280x720_60hz MIPI_panel_mtd700920b MIPI_panel_d240si31 MIPI_panel_st7701_hd228001c31 MIPI_panel_st7701_hd228001c31_alt0 MIPI_panel_st7701_lhcm228ts003a MIPI_panel_st7701_d300fpc9307a MIPI_panel_st7701_d310t9362v1 MIPI_panel_st7701_dxq5d0019b480854 MIPI_panel_st7701_dxq5d0019_v0
PARTITION_FILE=partition_sd.xml
STORAGE_TYPE=sd
VARIANT?=e

PACKAGES += " hostapd udhcpd wireless-regdb wpasupplicant"
PACKAGES += " python3-numpy python3-pil"

IMAGE_ADDITIONS += "sensor-config"
IMAGE_ADDITIONS += "device-key"
IMAGE_ADDITIONS += "ethernet-builtin"
IMAGE_ADDITIONS += "load-systemko"
IMAGE_ADDITIONS += "cvi-pinmux"
ifneq ("$(findstring kvm,$(VARIANT))","")
IMAGE_ADDITIONS += "nanokvm"
else
IMAGE_ADDITIONS += "maixapp"
IMAGE_ADDITIONS += "tpusdk"
endif
IMAGE_ADDITIONS += "python3-textual"
IMAGE_ADDITIONS += "usb-device"
IMAGE_ADDITIONS += "zram-config"
IMAGE_ADDITIONS += "wifi-builtin"
IMAGE_ADDITIONS += "aic8800-firmware"
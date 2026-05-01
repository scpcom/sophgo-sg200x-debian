COLOUR_GREEN=\n\033[0;32m
COLOUR_RED=\033[0;31m
COLOUR_BLUE=\033[0;34m
END_COLOUR=\033[0m\n

red:=$(shell tput setaf 1)
blue:=$(shell tput setaf 4)
reset:=$(shell tput sgr0)

GIT_REF ?= develop

BUILDDIR := /build

ARCH ?= riscv

ifeq ($(ARCH),arm64)
ARCH_NAME ?= ARM
SDK_VER ?= 64bit
else ifeq ($(ARCH),arm)
ARCH_NAME ?= ARM
SDK_VER ?= 32bit
else
ARCH_NAME ?= RISC-V
SDK_VER ?= glibc_riscv64
endif

ifeq ($(SDK_VER),glibc_riscv64)
DEB_ARCH = riscv64
else ifeq ($(SDK_VER),musl_riscv64)
DEB_ARCH = riscv64
else ifeq ($(SDK_VER),64bit)
DEB_ARCH = arm64
else ifeq ($(SDK_VER),32bit)
DEB_ARCH = armhf
else
$(error $(red)SDK_VER is invalid$(reset))
endif

ifeq ($(DEB_ARCH),riscv64)
KERNEL_ARCH = riscv
UBOOT_ARCH = riscv
QEMU_ARCH = riscv64
else ifeq ($(DEB_ARCH),arm64)
KERNEL_ARCH = arm64
UBOOT_ARCH = arm
QEMU_ARCH = aarch64
else ifeq ($(DEB_ARCH),armhf)
ifeq ($(BOOT_CPU),aarch64)
KERNEL_ARCH ?= arm64
else
KERNEL_ARCH ?= arm
endif
UBOOT_ARCH = arm
QEMU_ARCH = arm
else
$(error $(red)DEB_ARCH is invalid$(reset))
endif

SDK_CHIP = $(shell echo '$(CHIP)' | tr '[:lower:]' '[:upper:]')
UBOOT_FAMILY ?= $(UBOOT_CHIP)

GIT_CLONE_OPTS = --shallow-since=2020-03-12

KO_DIRS = drivers/i2c \
drivers/input/touchscreen \
drivers/media/usb/gspca \
drivers/net/usb \
drivers/net/wireless \
drivers/pwm \
drivers/rtc \
drivers/spi \
drivers/staging/fbtft \
drivers/video/backlight \
fs/efivarfs \
net/ipv4 \
net/wireless

ifndef BOARD
$(error $(red)BOARD is not set$(reset))
endif

include /configs/distro.mk
include /configs/git.mk
include /configs/settings.mk

ifneq ("$(wildcard /configs/$(BOARD)_$(ARCH)/settings.mk)","")
BOARD_CFG=$(BOARD)_$(ARCH)
else
BOARD_CFG=$(BOARD)
endif

ifneq ("$(wildcard /configs/$(BOARD_CFG)/settings.mk)","")
include /configs/$(BOARD_CFG)/settings.mk
else
$(error $(red)Board $(BOARD) not supported$(reset))
endif

CHIP_FAMILY ?= sg200x

ifneq ("$(wildcard /configs/chip/$(CHIP)/chip.mk)","")
CHIP_CFG=$(CHIP)
else
CHIP_CFG=$(CHIP_FAMILY)
endif

ifneq ("$(wildcard /configs/chip/$(CHIP_CFG)/chip.mk)","")
include /configs/chip/$(CHIP_CFG)/chip.mk
else
$(error $(red)Chip $(CHIP_FAMILY) not supported$(reset))
endif

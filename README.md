# Debian Images for Sophgo cv181x/sg200x based boards 
This repository builds debian images for Sophgo cv181x/sg200x based boards such as MilkV Duo256/DuoS and Sipeed LicheeRvNano/NanoKVM.

(Note, we don't support the MilkV Duo, as it does not have enough ram to run Debian)

The images aim to be as close to possible to debian best practices as possible

[AX620Q/AX630C based boards](configs/chip/ax620e/README.md) are supported too.

## Flashing the Image

### Duo256, DuoS, and LicheeRVNano
To flash from linux, either build your own image and then run the following command:
```
sudo dd if=image/(board)_sd.img of=/dev/sdX bs=4M status=progress
```
... or download a image from the releases page, and then run the following command:
```
lz4 -cd (board)_sd.img.lz4 | sudo dd of=/dev/sdX bs=4M status=progress
```

From windows, you can use tools such as balena etcher

where the (board)_sd.img is the image file you want to flash, and /dev/sdX is the device you want to flash to.
(if you build for a different board, the image file name will be different)

### DuoS with EMMC
To flash the DuoS with EMMC, you need to use the vendor tools to flash the image to the EMMC. You can follow the
instructions at https://milkv.io/docs/duo/getting-started/duos#emmc-version-firmware-burning but instead of downloading 
the  milkv-duos-emmc-v1.1.0-2024-0410.zip file, you download the duos_emmc.zip from the releases on this repository.

if you already have a image installed, but wish to upgrade, when u-boot loads up, interupt the boot process by pressing any
key and typing the following commands:
```
cvi_update
```

The flashing should then continue


## Image Info
Logins: root/rv and debian/rv

(root login is disabled via SSH, login via debian, and SU to root if needed)

### USB Gadget Support
by default, a rndis interface is started on the USB port, and the IP address is
10.x.y.1 - It also starts a DHCP Server on that interface, so your PC should automatically get an IP address in the 10.x.y.z range

To Disable the rndis interface, you can run the following command:
```
rm /boot/usb.rndis
```

There is also a option to start a serial port (ACM) interface instead of the rndis interface, to do this, you can run the following command:
```
rm /boot/usb.rndis
touch /boot/usb.GS0
```

After executing these commands, you need to reboot.

### DuoS - USB Type A Port
After disabling the usb-gadgets, if you want to use the USB Type A Ports, then you need to turn them on:
```
rm /boot/usb.dev
systemctl enable usb-switch
```

and reboot afterwards. 

### WiFi on DuoS/LicheeRVNano
For the LicheeRVNano/DuoS board, WiFi is enabled. To connect to your wifi network, execute the following command (example, use ssid and password of your wifi network):
```
touch /boot/wifi.sta
echo "My WiFi" | tee /boot/wifi.ssid
echo "Pa$$w0rd" /boot/wifi.pass
```

### Ethernet
For Boards with ethernet, they should automatically get a IP address if your network has a DHCP Server. You can configure the 
ethernet port in /etc/network/interfaces.d/end0

### Camera/ISP/Panel Support
The images are based on the vendor 5.10 kernel and osdrv, also including the following drivers:
- mipi-rx/csi drivers
- mipi-tx/dsi drivers
- TPU Drivers
- Any of the Video Encoding Drivers

The extra drivers are build on a separate package called cvitek-osdrv-(board), they will be installed to /mnt/system/ko

The libs and samples are build on a separate package called cvitek-middleware-(board), they will be installed to /mnt/system/usr

The images, by default, allocate minimum amount of memory for the ION heap to use vi/venc, so you get more memory for the OS

### Ardunio/Freertos Support
Support is disabled on my images because the small C906 core is used by ISP.

### LCD Panel Support
If you have a DSI LCD panel connected you can install the matching bootloader.

LicheeRV Nano

 - cvitek-fsbl-licheervnano (no LCD)
 - cvitek-fsbl-licheervnano-d240si31 (2.4 inch, hynitron cst7xx touchscreen, a.k.a st7701_lct024bsi20)
 - cvitek-fsbl-licheervnano-lt9611-1024x768-60hz (dsi to hdmi)
 - cvitek-fsbl-licheervnano-lt9611-1280x720-60hz (dsi to hdmi)
 - cvitek-fsbl-licheervnano-mtd700920b (7 inch)
 - cvitek-fsbl-licheervnano-st7701-d300fpc9307a (3 inch)
 - cvitek-fsbl-licheervnano-st7701-d310t9362v1 (3.1 inch)
 - cvitek-fsbl-licheervnano-st7701-dxq5d0019b480854 (5 inch)
 - cvitek-fsbl-licheervnano-st7701-dxq5d0019-v0 (5 inch)
 - cvitek-fsbl-licheervnano-st7701-hd228001c31 (2.28 inch, hynitron cst3xx touchscreen)
 - cvitek-fsbl-licheervnano-st7701-hd228001c31-alt0 (2.28 inch)
 - cvitek-fsbl-licheervnano-st7701-lhcm228ts003a (2.28 inch)
 - cvitek-fsbl-licheervnano-zct2133v1 (7 inch)

Milk-V DuoS

 - cvitek-fsbl-duos (no LCD)
 - cvitek-fsbl-duos-milkv-8hd (8 inch)
 - cvitek-fsbl-duos-milkv-8hd-2lane (8 inch)
 - cvitek-fsbl-duos-milkv-st7796s (4 inch)

Example if you have a st7701_hd228001c31 connected:
```
apt-get install cvitek-fsbl-licheervnano-st7701-hd228001c31
apt-get remove cvitek-fsbl-licheervnano
```

You may also want to enable the FB driver:
```
touch /boot/fb
```

If you have a SPI LCD panel connected you can enable the matching driver.

Additional changes to the DTS file maybe required if not using ST7789x based panel.

Available panel parameters for st7789x:
 - st7789
 - st7789v_milkv
 - st7789v_weactstudio

st7789 on spi2 of LicheeRV Nano:
```
echo "st7789x panel=st7789" > /boot/fb
```

milkv_st7789v on spi3 of Milk-V DuoS:
```
echo "st7789x panel=st7789v_milkv" > /boot/fb
```

### Additional Packages
This image also adds the debian repository for board-related packages so you can install additional repositories. The debian repository is hosted at 
https://scpcom.github.io/deb which pulls down the compiled debian packages from the above github repository occasionally.

Available debian packages:

 - cvi-pinmux-cv181x  
 Contains a tool named cvi_pinmux which allows to change the function of the pins (GPIO, SPI etc.).
 - firmware-aic8800-cv181x  
 Firmware for the on-board WiFi.
 - firmware-vcodec-cv181x  
 Firmware for the video encoder/decoder running on the small C906 core.

…and board-specific packages like:

 - board-support-licheervnano-kvm  
 Meta package, installs all board-specific packages.
 - cvitek-fsbl-licheervnano  
 The boot loader (including opensbi and u-boot).
 - cvitek-middleware-licheervnano  
 Libs and samples for the ISP (vi/vo/venc/vdec etc.).
 - cvitek-osdrv-licheervnano-kvm  
 Additional kernel drivers (required for camera support etc.).
 - cvitek-tpusdk-licheervnano  
 Libs and samples for the TPU (AI)
 - device-key-licheervnano  
 Startup script that sets the Ethernet MAC address and hostname based on the hash off the device uuid.
 - duo-pinmux-duos  
 Same as cvi-pinmux but customized for Milk-V Duo series boards.
 - ethernet-leds-duos  
 Startup script to enable ethernet LED triggers.
 - gadget-nic-licheervnano  
 Startup script to setup USB Gadget NCM/RNDIS networking.
 - hciattach-uart-duos  
 Startup script to attach bluetooth to UART.
 - linux-headers-licheervnano-kvm  
 The kernel headers for the board.
 - linux-image-licheervnano-kvm  
 The kernel customized for the board.
 - load-systemko-licheervnano  
 Startup script that loads the additional drivers (see cvitek-osdrv-licheervnano-kvm).
 - maixapp-licheervnano  
 App(s) built with MaixCDK.
 - nanokvm-licheervnano  
 NanoKVM Server that provides the web interface to control your device.
 - sensor-config-licheervnano  
 Configuration files and parameters required to initialize the camera sensor.
 - usb-device-licheervnano  
 Startup script to setup USB gadget devices.
 - usb-switch-duos  
 Startup script to enable the USB switch.
 - wifi-builtin-licheervnano  
 Startup scripts to initialize the on-board WiFi.
 - zram-config-licheervnano  
 Scripts to setup compressed ZRAM devices for overlayfs and zswap.

The package names are depending on the board you are using (licheervnano, duo256 or duos) and the variant (kvm = NanoKVM, e = all others).
For example if you want the kernel for Milk-V Duo256 the package is called linux-image-duo256-e.

## Building the Image
To build a stock image with no modifications:
```
podman run --privileged -it --rm -v ./configs/:/configs -v ./image:/output ghcr.io/scpcom/sophgo-sg200x-debian:debian make BOARD=licheervnano image
```

Replace the licheervnano with the board you want to build for:
- duo256
- duos
- licheervnano

If you want to create a image for the DuoS with EMMC, you can add "STORAGE_TYPE=emmc" to the make command:
```
podman run --privileged -it --rm -v ./configs/:/configs -v ./image:/output ghcr.io/scpcom/sophgo-sg200x-debian:debian make BOARD=duos STORAGE_TYPE=emmc image
```

If you want to create a image for the NanoKVM, you can add "VARIANT=kvm" to the make command:
```
podman run --privileged -it --rm -v ./configs/:/configs -v ./image:/output ghcr.io/scpcom/sophgo-sg200x-debian:debian make BOARD=licheervnano VARIANT=kvm image
```

The Docker image will build the image and place it in the image directory

addition make targets are available when building:
- image - builds the image
- clean - cleans the build directory
- linux - build a kernel debian package
- fsbl - build the fsbl debain package (that includes cvitek-fsbl, opensbi and u-boot)

## Customizing the Image
The configs directory contains patches, configuration and device tree files that are used to build the image.

The configs/common directory contains the common configuration for all boards, and the configs/licheervnano and configs/duo256 directories contain the board specific configuration.

To add packages to the image, either add the package name in PACKAGES variable of configs/settings.mk or if the packae is specific to a board, add it to the configs/\<board\>/settings.mk file

Patches for the kernel, opensbi, u-boot or fsbl can be placed in configs/common/patches/ or configs/\<board\>/patches/ depending what they are for.

To assist with developing the image, you can get a shell in the docker container by running:
```
docker run --privileged -it --rm -v ./configs/:/configs -v ./image:/output -v ./scripts/:/builder builder /bin/bash
```
inside the container, packages are build in the /builder/ directory, and the rootfs is placed at /rootfs/ directory

## ARM Images
If the A53 CPU core is enabled on your board you can build the matching arm64 images.

Use podman/docker run like described above and choose one of the supported boards:
```
make BOARD=duos ARCH=arm64 image
make BOARD=duo256 ARCH=arm64 image
make BOARD=licheea53nano ARCH=arm64 image
```
You can replace ARCH=arm64 with ARCH=arm to get 32 bit (armhf) images.

# TODO
- DeviceTree Overlay Support
- Possibly mainline kernel support via the sophgo linux for-next repositories

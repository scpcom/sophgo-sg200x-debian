# Debian Images for Axera AX620Q/AX630C based boards 
This repository builds debian images for Axera AX620Q/AX630C based boards such as Sipeed MaixCAM2/NanoKVM-Pro.

The images aim to be as close to possible to debian best practices as possible

## Flashing the Image

### MaixCAM2 and NanoKVM-Pro
To flash from linux, connect the board via USB to your computer and press the user button to enter flash mode.

Either build your own image and then run the following command:
```
sudo dd if=image/(board)_emmc.img of=/dev/sdX bs=4M status=progress
```
... or download a image from the releases page, and then run the following command:
```
lz4 -cd (board)_emmc.img.lz4 | sudo dd of=/dev/sdX bs=4M status=progress
```

From windows, you can use tools such as balena etcher

where the (board)_emmc.img is the image file you want to flash, and /dev/sdX is the device you want to flash to.
(if you build for a different board, the image file name will be different)

## Image Info
Logins: root/ax and debian/ax

(root login is disabled via SSH, login via debian, and SU to root if needed)

NanoKVM-Pro

Web login: admin/admin

SSH login: root/sipeed (if you change the web admin password the root password will be changed too)

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

### WiFi on MaixCAM2/NanoKVM-Pro
For the MaixCAM2/NanoKVM-Pro board, WiFi is enabled. To connect to your wifi network, execute the following command (example, use ssid and password of your wifi network):
```
touch /boot/wifi.sta
echo "My WiFi" | tee /boot/wifi.ssid
echo "Pa$$w0rd" /boot/wifi.pass
```

### Ethernet
For Boards with ethernet, they should automatically get a IP address if your network has a DHCP Server. You can configure the 
ethernet port in /etc/network/interfaces

### Camera/ISP/Panel Support
The images are based on the vendor 4.19 kernel and osdrv, also including the following drivers:
- mipi-rx/csi drivers
- mipi-tx/dsi drivers
- TPU Drivers
- Any of the Video Encoding Drivers

The extra drivers are put on a separate package called axera-osdrv-(board), they will be installed to /soc/ko

The libs are put on a separate package called axera-middleware-(board), they will be installed to /opt/lib

The images, by default, allocate minimum amount of memory for the ION heap to use vi/venc, so you get more memory for the OS

### LCD Panel Support
If your boards has a built-in LCD panel the required driver will be loaded by default.

### Additional Packages
This image also adds the debian repository for board-related packages so you can install additional repositories. The debian repository is hosted at 
https://scpcom.github.io/deb which pulls down the compiled debian packages from the above github repository occasionally.

Available debian packages:

 - firmware-aic8800-ax630c  
 Firmware for the on-board WiFi.

…and board-specific packages like:

 - axera-bsp-nanokvmpro  
 Board-specific scripts and tools.
 - board-support-nanokvmpro-kvm  
 Meta package, installs all board-specific packages.
 - axera-middleware-nanokvmpro  
 Libs and samples for the ISP (vi/vo/venc/vdec etc.).
 - axera-osdrv-nanokvmpro-kvm  
 Additional kernel drivers (required for camera support etc.).
 - device-key-nanokvmpro  
 Startup script that sets the Ethernet MAC address and hostname based on the hash off the device uuid.
 - gadget-nic-nanokvmpro  
 Startup script to setup USB Gadget NCM/RNDIS networking.
 - kvmcomm  
 Required scripts, tools and kernel modules for NanoKVM-Pro.
 - linux-headers-nanokvmpro-kvm  
 The kernel headers for the board.
 - linux-image-nanokvmpro-kvm  
 The kernel customized for the board.
 - nanokvmpro  
 NanoKVM Server that provides the web interface to control your device.
 - pikvm  
 Implementation of the feature-rich, industrial grade, Open-Source KVM over IP software.

The package names are depending on the board you are using (nanokvmpro or maixcam2) and the variant (kvm = NanoKVM, e = all others).
For example if you want the kernel for Sipeed MaixCAM2 the package is called linux-image-maixcam2-e.

## Building the Image
To build a stock image with no modifications:
```
podman run --privileged -it --rm -v ./configs/:/configs -v ./image:/output ghcr.io/scpcom/sophgo-sg200x-debian:debian make ARCH=arm64 BOARD=nanokvmpro image
```

Replace the nanokvmpro with the board you want to build for:
- maixcam2
- nanokvmpro

If you want to create a image for the NanoKVM-Pro, you can add "VARIANT=kvm" to the make command:
```
podman run --privileged -it --rm -v ./configs/:/configs -v ./image:/output ghcr.io/scpcom/sophgo-sg200x-debian:debian make ARCH=arm64 BOARD=nanokvmpro VARIANT=kvm image
```

The Docker image will build the image and place it in the image directory

addition make targets are available when building:
- image - builds the image
- clean - cleans the build directory
- linux - build a kernel debian package
- fsbl - build the fsbl debain package (that includes axera-fsbl, opensbi and u-boot)

## Customizing the Image
The configs directory contains patches, configuration and device tree files that are used to build the image.

The configs/common directory contains the common configuration for all boards, and the configs/nanokvmpro and configs/maixcam2 directories contain the board specific configuration.

To add packages to the image, either add the package name in PACKAGES variable of configs/settings.mk or if the packae is specific to a board, add it to the configs/\<board\>/settings.mk file

Patches for the kernel, opensbi, u-boot or fsbl can be placed in configs/common/patches/ or configs/\<board\>/patches/ depending what they are for.

To assist with developing the image, you can get a shell in the docker container by running:
```
docker run --privileged -it --rm -v ./configs/:/configs -v ./image:/output -v ./scripts/:/builder builder /bin/bash
```
inside the container, packages are build in the /builder/ directory, and the rootfs is placed at /rootfs/ directory

## Other Images
You can build images with a different Debian/Ubuntu version by adding DEB_DISTRO to make.

Use podman/docker run like described above and choose one of the supported boards:
```
make ARCH=arm64 BOARD=nanokvmpro DEB_DISTRO=jammy image
```
In this example we build Ubuntu 22.04 for nanokvmpro.

# TODO
- DeviceTree Overlay Support
- Possibly newer kernel support via the axera bsps

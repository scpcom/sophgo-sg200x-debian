ifneq ("$(findstring maixapp,$(IMAGE_ADDITIONS))$(findstring maixapp-$(BOARD),$(PACKAGES))","")
BSPRECOMMENDS += maixapp-$(BOARD)
BSPFILTER += "maixapp"
MAIXAPP_PACKAGES = libasound2t64 libatopology2t64 libpng16-16t64
MAIXAPP_PACKAGE_DEPENDS = $(subst $(SPACE),$(COMMA)$(SPACE),$(sort $(MAIXAPP_PACKAGES))), ffmpeg-maixapp-$(BOARD), libjpeg-maixapp-$(BOARD), opencv-maixapp-$(BOARD)
DEV_PACKAGES += " libasound2-dev libatopology-dev libpng-dev"
PACKAGES += " $(MAIXAPP_PACKAGES)"
endif

MAIXAPP_CLEANUP_LIBS = \
	libav*.so \
	libpostproc.so \
	libswresample.so \
	libswscale.so \
	libasound.so \
	libatopology.so \
	libcrypto.so \
	libssl.so \
	libbz2.so \
	liblzma.so \
	libxml2.so \
	libz.so

ifneq ("$(CHIP_FAMILY)","sg200x")
# ax620e
MAIXAPP_LIB_DEPENDS = $(BUILDDIR)/maixapp-ffmpeg-stamp $(BUILDDIR)/maixapp-onnxruntime-stamp $(BUILDDIR)/maixapp-opencv-stamp
MAIXAPP_PACKAGE_DEPENDS = $(subst $(SPACE),$(COMMA)$(SPACE),$(sort $(MAIXAPP_PACKAGES))), ffmpeg-maixapp-$(BOARD), opencv-maixapp-$(BOARD)

else
# sg200x
MAIXAPP_LIB_DEPENDS = $(BUILDDIR)/maixapp-ffmpeg-stamp $(BUILDDIR)/maixapp-opencv-stamp
MAIXAPP_PACKAGE_DEPENDS = $(subst $(SPACE),$(COMMA)$(SPACE),$(sort $(MAIXAPP_PACKAGES))), ffmpeg-maixapp-$(BOARD), opencv-maixapp-$(BOARD)
endif

ifneq ("$(findstring maixcdk,$(IMAGE_ADDITIONS))","")
MAIXAPP_GIT_DIR = $(MAIXCDK_BUILD_DIR)
MAIXAPP_OUTPUT_DIR = $(MAIXCDK_BUILD_DIR)/dist

MAIXAPP_DEPENDS = $(BUILDDIR)/maixcdk-stamp

else
MAIXAPP_GIT_DIR = $(BUILDDIR)/buildroot
MAIXAPP_OUTPUT_DIR = $(BR_OUTPUT_DIR)/target

MAIXAPP_DEPENDS = $(BUILDDIR)/buildroot-package-stamp

MAIXAPP_LIB_DEPENDS += $(BUILDDIR)/maixapp-libjpeg-stamp
MAIXAPP_PACKAGE_DEPENDS += , libjpeg-maixapp-$(BOARD)
endif

$(BUILDDIR)/maixapp-version-stamp: $(MAIXAPP_DEPENDS)
	@echo "$(COLOUR_GREEN)Packaging maixapp for $(BOARD)$(END_COLOUR)"
	@$(eval MAIXAPPVERSION=$(shell echo "1.0.0"))
	@$(eval BV=$(shell cd $(MAIXAPP_GIT_DIR) && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@touch $@

$(BUILDDIR)/maixapp-ffmpeg-stamp: $(BUILDDIR)/maixapp-version-stamp
	@$(eval MAIXAPP_FFMPEG_PACKAGE_DIR=$(shell echo "$(BUILDDIR)/package/ffmpeg-maixapp-$(BOARD)-$(MAIXAPPVERSION)"))
	@mkdir -p $(MAIXAPP_FFMPEG_PACKAGE_DIR)
	@cp -r /builder/deb/maixapp-sg200x/* $(MAIXAPP_FFMPEG_PACKAGE_DIR)/
	@mkdir -pv $(MAIXAPP_FFMPEG_PACKAGE_DIR)/usr/lib/
	@rsync -avpPxH $(MAIXAPP_OUTPUT_DIR)/usr/lib/libav*.so.* $(MAIXAPP_FFMPEG_PACKAGE_DIR)/usr/lib/
	@rsync -avpPxH $(MAIXAPP_OUTPUT_DIR)/usr/lib/libpostproc.so.* $(MAIXAPP_FFMPEG_PACKAGE_DIR)/usr/lib/ || true
	@rsync -avpPxH $(MAIXAPP_OUTPUT_DIR)/usr/lib/libswresample.so.* $(MAIXAPP_FFMPEG_PACKAGE_DIR)/usr/lib/
	@rsync -avpPxH $(MAIXAPP_OUTPUT_DIR)/usr/lib/libswscale.so.* $(MAIXAPP_FFMPEG_PACKAGE_DIR)/usr/lib/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MAIXAPP_FFMPEG_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(MAIXAPPVERSION)$(BV)/' $(MAIXAPP_FFMPEG_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: maixapp-sg200x/Package: ffmpeg-maixapp-$(BOARD)/' $(MAIXAPP_FFMPEG_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build ffmpeg-maixapp-$(BOARD)-$(MAIXAPPVERSION) ffmpeg-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/ffmpeg-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/ffmpeg-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/maixapp-libjpeg-stamp: $(BUILDDIR)/maixapp-version-stamp
	@$(eval MAIXAPP_LIBJPEG_PACKAGE_DIR=$(shell echo "$(BUILDDIR)/package/libjpeg-maixapp-$(BOARD)-$(MAIXAPPVERSION)"))
	@mkdir -p $(MAIXAPP_LIBJPEG_PACKAGE_DIR)
	@cp -r /builder/deb/maixapp-sg200x/* $(MAIXAPP_LIBJPEG_PACKAGE_DIR)/
	@mkdir -pv $(MAIXAPP_LIBJPEG_PACKAGE_DIR)/usr/lib/
	@rsync -avpPxH $(MAIXAPP_OUTPUT_DIR)/usr/lib/libjpeg.so.* $(MAIXAPP_LIBJPEG_PACKAGE_DIR)/usr/lib/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MAIXAPP_LIBJPEG_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(MAIXAPPVERSION)$(BV)/' $(MAIXAPP_LIBJPEG_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: maixapp-sg200x/Package: libjpeg-maixapp-$(BOARD)/' $(MAIXAPP_LIBJPEG_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build libjpeg-maixapp-$(BOARD)-$(MAIXAPPVERSION) libjpeg-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/libjpeg-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/libjpeg-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/maixapp-onnxruntime-stamp: $(BUILDDIR)/maixapp-version-stamp
	@$(eval MAIXAPP_ONNXRUNTIME_PACKAGE_DIR=$(shell echo "$(BUILDDIR)/package/onnxruntime-maixapp-$(BOARD)-$(MAIXAPPVERSION)"))
	@mkdir -p $(MAIXAPP_ONNXRUNTIME_PACKAGE_DIR)
	@cp -r /builder/deb/maixapp-sg200x/* $(MAIXAPP_ONNXRUNTIME_PACKAGE_DIR)/
	@mkdir -pv $(MAIXAPP_ONNXRUNTIME_PACKAGE_DIR)/usr/lib/
	@rsync -avpPxH $(MAIXAPP_OUTPUT_DIR)/usr/lib/libonnxruntime*.so.* $(MAIXAPP_ONNXRUNTIME_PACKAGE_DIR)/usr/lib/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MAIXAPP_ONNXRUNTIME_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(MAIXAPPVERSION)$(BV)/' $(MAIXAPP_ONNXRUNTIME_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: maixapp-sg200x/Package: onnxruntime-maixapp-$(BOARD)/' $(MAIXAPP_ONNXRUNTIME_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build onnxruntime-maixapp-$(BOARD)-$(MAIXAPPVERSION) onnxruntime-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/onnxruntime-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/onnxruntime-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/maixapp-opencv-stamp: $(BUILDDIR)/maixapp-version-stamp
	@$(eval MAIXAPP_OPENCV_PACKAGE_DIR=$(shell echo "$(BUILDDIR)/package/opencv-maixapp-$(BOARD)-$(MAIXAPPVERSION)"))
	@mkdir -p $(MAIXAPP_OPENCV_PACKAGE_DIR)
	@cp -r /builder/deb/maixapp-sg200x/* $(MAIXAPP_OPENCV_PACKAGE_DIR)/
	@mkdir -pv $(MAIXAPP_OPENCV_PACKAGE_DIR)/usr/lib/
	@rsync -avpPxH $(MAIXAPP_OUTPUT_DIR)/usr/lib/libopencv*.so.* $(MAIXAPP_OPENCV_PACKAGE_DIR)/usr/lib/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MAIXAPP_OPENCV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(MAIXAPPVERSION)$(BV)/' $(MAIXAPP_OPENCV_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: maixapp-sg200x/Package: opencv-maixapp-$(BOARD)/' $(MAIXAPP_OPENCV_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build opencv-maixapp-$(BOARD)-$(MAIXAPPVERSION) opencv-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/opencv-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/opencv-maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

$(BUILDDIR)/maixapp-stamp: $(MAIXAPP_LIB_DEPENDS)
	@$(eval MAIXAPP_PACKAGE_DIR=$(shell echo "$(BUILDDIR)/package/maixapp-$(BOARD)-$(MAIXAPPVERSION)"))
	@mkdir -p $(MAIXAPP_PACKAGE_DIR)
	@cp -r /builder/deb/maixapp-sg200x/* $(MAIXAPP_PACKAGE_DIR)/
	@mkdir -pv $(MAIXAPP_PACKAGE_DIR)/maixapp/
	@rsync -avpPxH $(MAIXAPP_OUTPUT_DIR)/maixapp/ $(MAIXAPP_PACKAGE_DIR)/maixapp/
	@for f in $(MAIXAPP_CLEANUP_LIBS) ; do \
		rm -f $(MAIXAPP_PACKAGE_DIR)/maixapp/lib/$$f ; \
	done
	if [ -e $(MAIXAPP_PACKAGE_DIR)/maixapp/sys_conf.ini ]; then \
		echo "/maixapp/sys_conf.ini" > $(MAIXAPP_PACKAGE_DIR)/DEBIAN/conffiles ; \
	fi
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(MAIXAPP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0-1/Version: $(MAIXAPPVERSION)$(BV)/' $(MAIXAPP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: maixapp-sg200x/Package: maixapp-$(BOARD)/' $(MAIXAPP_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Depends: .*/Depends: $(MAIXAPP_PACKAGE_DEPENDS)/' $(MAIXAPP_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build maixapp-$(BOARD)-$(MAIXAPPVERSION) maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/maixapp-$(BOARD)_$(MAIXAPPVERSION)$(BV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

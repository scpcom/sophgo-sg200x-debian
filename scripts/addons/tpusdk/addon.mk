ifneq ("$(findstring tpusdk,$(IMAGE_ADDITIONS))$(findstring cvitek-tpusdk-$(BOARD),$(PACKAGES))","")
BSPRECOMMENDS += cvitek-tpusdk-$(BOARD)
BSPFILTER += "tpusdk"
TPU_REL = 1
endif

ifeq ($(ARCH),arm64)
TPUSDK_VER ?= glibc_arm64
else ifeq ($(ARCH),arm)
TPUSDK_VER ?= glibc_arm
else
TPUSDK_VER ?= glibc_riscv64
endif

ifeq ($(BOARD),duos)
TPUSDK_CHIP ?= sg2000
else
TPUSDK_CHIP ?= sg2002
endif

ifeq ($(BOARD),duo256)
TPUSDK_BOARD ?= $(BOARD)m
else
TPUSDK_BOARD ?= $(BOARD)
endif

ifneq ("$(findstring duo,$(BOARD))","")
ifeq ($(ARCH),arm64)
TPUSDK_CONFIG ?= milkv_$(TPUSDK_BOARD)_glibc_arm64
else ifeq ($(ARCH),arm)
TPUSDK_CONFIG ?= milkv_$(TPUSDK_BOARD)_glibc_arm64
else
TPUSDK_CONFIG ?= milkv_$(TPUSDK_BOARD)_musl_riscv64
endif
else
TPUSDK_CONFIG ?= $(TPUSDK_BOARD)
endif

TPUSDK_BOARD_LINK ?= $(TPUSDK_CHIP)_$(TPUSDK_CONFIG)_$(STORAGE_TYPE)

$(BUILDDIR)/tpusdk-prepare-clone-stamp:
	@echo "$(COLOUR_GREEN)Cloning TPU SDK for $(BOARD)$(END_COLOUR)"
	@mkdir -p $(BUILDDIR)
	@git clone -b develop $(GIT_CLONE_OPTS) --shallow-submodules $(GIT_USER_URL)/LicheeSG-Nano-Build.git $(BUILDDIR)/tpusdk
	@cd $(BUILDDIR)/tpusdk && git checkout 07cce30
	@cd $(BUILDDIR)/tpusdk && git rm -r buildroot freertos fsbl isp_tuning linux_5.10 middleware opensbi osdrv ramdisk u-boot-2021.10
	@touch $@

$(BUILDDIR)/tpusdk-prepare-checkout-stamp: $(BUILDDIR)/tpusdk-prepare-clone-stamp
	@echo "$(COLOUR_GREEN)Checking out TPU SDK for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/tpusdk && git submodule set-url build $(GIT_USER_URL)/sophgo-build
	@cd $(BUILDDIR)/tpusdk && git submodule set-url cnpy $(GIT_USER_URL)/cnpy
	@cd $(BUILDDIR)/tpusdk && git submodule set-url cvi_rtsp $(GIT_USER_URL)/cvi_rtsp
	@cd $(BUILDDIR)/tpusdk && git submodule set-url cvibuilder $(GIT_USER_URL)/cvibuilder
	@cd $(BUILDDIR)/tpusdk && git submodule set-url cvikernel $(GIT_USER_URL)/cvikernel
	@cd $(BUILDDIR)/tpusdk && git submodule set-url cvimath $(GIT_USER_URL)/cvimath
	@cd $(BUILDDIR)/tpusdk && git submodule set-url cviruntime $(GIT_USER_URL)/cviruntime
	@cd $(BUILDDIR)/tpusdk && git submodule set-url flatbuffers $(GIT_USER_URL)/flatbuffers
	@cd $(BUILDDIR)/tpusdk && git submodule set-url ive $(GIT_USER_URL)/sophgo-ive
	@cd $(BUILDDIR)/tpusdk && git submodule set-url tdl_sdk $(GIT_USER_URL)/sophgo-tdl_sdk
	@cd $(BUILDDIR)/tpusdk && git submodule update --init --depth=1
	@cd $(BUILDDIR)/tpusdk && sed -i 's|GIT_REPOSITORY https://github.com/google/googletest|GIT_REPOSITORY $(GIT_USER_URL)/googletest|g' tdl_sdk/cmake/thirdparty.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i 's|GIT_REPOSITORY https://github.com/nothings/stb|GIT_REPOSITORY $(GIT_USER_URL)/stb|g' tdl_sdk/cmake/thirdparty.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i 's|GIT_REPOSITORY https://gitlab.com/libeigen/eigen|GIT_REPOSITORY $(GIT_USER_URL)/eigen|g' tdl_sdk/cmake/thirdparty.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i 's|GIT_REPOSITORY https://github.com/nlohmann/json|GIT_REPOSITORY $(GIT_USER_URL)/json|g' tdl_sdk/cmake/thirdparty.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i 's|GIT_REPOSITORY https://github.com/scpcom/kissfft|GIT_REPOSITORY $(GIT_USER_URL)/kissfft|g' tdl_sdk/cmake/thirdparty.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i 's|GIT_REPOSITORY https://github.com/scpcom/kaldi-native-fbank|GIT_REPOSITORY $(GIT_USER_URL)/kaldi-native-fbank|g' tdl_sdk/cmake/thirdparty.cmake
	@touch $@

$(BUILDDIR)/tpusdk-prepare-patch-stamp: $(BUILDDIR)/toolchain-prepare-patch-stamp $(BUILDDIR)/tpusdk-prepare-checkout-stamp $(BUILDDIR)/middleware-compile-stamp
	@echo "$(COLOUR_GREEN)Patching TPU SDK for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/tpusdk && ./host/prepare-host.sh
	@cd $(BUILDDIR)/tpusdk && ln -s ../../host-tools host-tools
	@cd $(BUILDDIR)/tpusdk && mkdir -p linux_5.10/build
	@cd $(BUILDDIR)/tpusdk && ln -s $(KERNEL_OUTPUT_DIR) linux_5.10/build/$(TPUSDK_BOARD_LINK)
	@cd $(BUILDDIR)/tpusdk && ln -s ../middleware middleware
	@cd $(BUILDDIR)/tpusdk && ln -s ../osdrv osdrv
	@cd $(BUILDDIR)/tpusdk && ln -s ../ramdisk ramdisk
	@cp -p addons/tpusdk/build-sdk.sh $(BUILDDIR)/tpusdk/
	$(foreach file, $(wildcard /configs/common/patches/tpusdk/cvi_rtsp-*.patch), cd $(BUILDDIR)/tpusdk/cvi_rtsp && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/tpusdk/cvi_rtsp-*.patch), cd $(BUILDDIR)/tpusdk/cvi_rtsp && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/common/patches/tpusdk/cvibuilder-*.patch), cd $(BUILDDIR)/tpusdk/cvibuilder && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/tpusdk/cvibuilder-*.patch), cd $(BUILDDIR)/tpusdk/cvibuilder && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/common/patches/tpusdk/cvikernel-*.patch), cd $(BUILDDIR)/tpusdk/cvikernel && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/tpusdk/cvikernel-*.patch), cd $(BUILDDIR)/tpusdk/cvikernel && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/common/patches/tpusdk/cvimath-*.patch), cd $(BUILDDIR)/tpusdk/cvimath && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/tpusdk/cvimath-*.patch), cd $(BUILDDIR)/tpusdk/cvimath && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/common/patches/tpusdk/cviruntime-*.patch), cd $(BUILDDIR)/tpusdk/cviruntime && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/tpusdk/cviruntime-*.patch), cd $(BUILDDIR)/tpusdk/cviruntime && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/common/patches/tpusdk/tdl_sdk-*.patch), cd $(BUILDDIR)/tpusdk/tdl_sdk && git apply --ignore-whitespace $(file);)
	$(foreach file, $(wildcard /configs/$(BOARD_CFG)/patches/tpusdk/tdl_sdk-*.patch), cd $(BUILDDIR)/tpusdk/tdl_sdk && git apply --ignore-whitespace $(file);)
	@cd $(BUILDDIR)/tpusdk && sed -i 's|"$$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu|$(CROSS_COMPILE_PATH_64)|g' build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i 's|"$$TOOLCHAIN_PATH"/gcc/gcc-linaro-6.3.1-2017.05-x86_64_arm-linux-gnueabihf|$(CROSS_COMPILE_PATH_32)|g' build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i 's|"$$TOOLCHAIN_PATH"/gcc/riscv64-linux-x86_64|$(CROSS_COMPILE_PATH_GLIBC_RISCV64)|g' build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i 's|"$$RAMDISK_PATH"/sysroot/sysroot-glibc-linaro-2.23-2017.05-aarch64-linux-gnu|$(SDK_SYSROOT_64)|g' build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i 's|"$$RAMDISK_PATH"/sysroot/sysroot-glibc-linaro-2.23-2017.05-arm-linux-gnueabihf|$(SDK_SYSROOT_32)|g' build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i 's|"$$RAMDISK_PATH"/sysroot/sysroot-glibc-riscv64|$(SDK_SYSROOT_GLIBC_RISCV64)|g' build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i s/'aarch64-linux-gnu-'/'$(CROSS_COMPILE_64)'/g build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i s/'aarch64-linux-gnu-'/'$(CROSS_COMPILE_64)'/g build/Kconfig
	@cd $(BUILDDIR)/tpusdk && sed -i s/'arm-linux-gnueabihf-'/'$(CROSS_COMPILE_32)'/g build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i s/'arm-linux-gnueabihf-'/'$(CROSS_COMPILE_32)'/g build/Kconfig
	@cd $(BUILDDIR)/tpusdk && sed -i s/'riscv64-unknown-linux-gnu-'/'$(CROSS_COMPILE_GLIBC_RISCV64)'/g build/envsetup_soc.sh
	@cd $(BUILDDIR)/tpusdk && sed -i s/'riscv64-unknown-linux-gnu-'/'$(CROSS_COMPILE_GLIBC_RISCV64)'/g build/Kconfig
	@cd $(BUILDDIR)/tpusdk && sed -i 's|$$ENV{TOP_DIR}/ramdisk/sysroot/sysroot-glibc-linaro-2.23-2017.05-aarch64-linux-gnu|$(SDK_SYSROOT_64)|g' cviruntime/scripts/toolchain.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i 's|$$ENV{TOP_DIR}/ramdisk/sysroot/sysroot-glibc-linaro-2.23-2017.05-arm-linux-gnueabihf|$(SDK_SYSROOT_32)|g' cviruntime/scripts/toolchain.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i 's|$$ENV{TOP_DIR}/host-tools/gcc/riscv64-linux-x86_64/sysroot|$(SDK_SYSROOT_GLIBC_RISCV64)|g' cviruntime/scripts/toolchain.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i s/'aarch64-linux-gnu-'/'$(CROSS_COMPILE_64)'/g cviruntime/scripts/toolchain.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i s/'arm-linux-gnueabihf-'/'$(CROSS_COMPILE_32)'/g cviruntime/scripts/toolchain.cmake
	@cd $(BUILDDIR)/tpusdk && sed -i s/'riscv64-unknown-linux-gnu-'/'$(CROSS_COMPILE_GLIBC_RISCV64)'/g cviruntime/scripts/toolchain.cmake
	@touch $@

$(BUILDDIR)/tpusdk-prepare-configure-stamp: $(BUILDDIR)/tpusdk-prepare-patch-stamp
	@echo "$(COLOUR_GREEN)Configuring TPU SDK for $(BOARD)$(END_COLOUR)"
	@touch $@

$(BUILDDIR)/tpusdk-compile-stamp: $(BUILDDIR)/tpusdk-prepare-configure-stamp
	@echo "$(COLOUR_GREEN)Building TPU SDK for $(BOARD)$(END_COLOUR)"
	@cd $(BUILDDIR)/tpusdk && ./build-sdk.sh --board=$(TPUSDK_BOARD_LINK) --sdkver=$(TPUSDK_VER)
	@cd $(BUILDDIR)/tpusdk && ln -s soc_$(TPUSDK_BOARD_LINK)/rootfs/mnt/system install/system
	@find $(BUILDDIR)/tpusdk/install/system -name "*.so*" -type f ! -path "*libtinyalsa.so" ! -path "*libaac*.so" ! -path "*libcvi_audio.so" ! -path "*libcvi_*ssp*.so" ! -path "*libcvi_*vqe*.so" ! -path "*libcvi_RES1.so" ! -path "*libcvi_VoiceEngine.so" ! -path "*libae.so" ! -path "*libaf.so" ! -path "*libawb.so" ! -path "*libisp_algo.so" -printf 'striping %p\n' -exec $(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)strip --strip-all {} \;
	@find $(BUILDDIR)/tpusdk/install/system -executable -type f ! -name "*.sh" ! -path "*etc*" ! -path "*.ko" ! -path "*.so*" -printf 'striping %p\n' -exec $(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)strip --strip-all {} 2>/dev/null \;
	@touch $@

$(BUILDDIR)/tpusdk-package-stamp: $(BUILDDIR)/tpusdk-compile-stamp
	@echo "$(COLOUR_GREEN)Packaging TPU SDK for $(BOARD)$(END_COLOUR)"
	@$(eval TPUSDKVERSION=$(shell echo "2024.12.10"))
	@$(eval TV=$(shell cd $(BUILDDIR)/tpusdk && git log -1 --format="%at" | xargs -I{} date -d @{} +-%Y%m%d-${KERNELREV}))
	@$(eval TPUSDK_PACKAGE_DIR=$(shell echo "$(BUILDDIR)/package/cvitek-tpusdk-$(BOARD)-$(TPUSDKVERSION)"))
	@mkdir -p $(TPUSDK_PACKAGE_DIR)
	@cp -r /builder/deb/cvitek-tpusdk/* $(TPUSDK_PACKAGE_DIR)/
	@mkdir -pv $(TPUSDK_PACKAGE_DIR)/mnt/system/lib/
	@rsync -avpPxH $(BUILDDIR)/tpusdk/install/system/lib/ $(TPUSDK_PACKAGE_DIR)/mnt/system/lib/
	@mkdir -pv $(TPUSDK_PACKAGE_DIR)/mnt/system/usr/bin/ai/
	@rsync -avpPxH $(BUILDDIR)/tpusdk/install/system/usr/bin/ai/ $(TPUSDK_PACKAGE_DIR)/mnt/system/usr/bin/ai/
	@sed -i 's/Architecture: riscv64/Architecture: $(DEB_ARCH)/' $(TPUSDK_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Version: 1.0.0/Version: $(TPUSDKVERSION)$(TV)/' $(TPUSDK_PACKAGE_DIR)/DEBIAN/control
	@sed -i 's/Package: cvitek-tpusdk/Package: cvitek-tpusdk-$(BOARD)/' $(TPUSDK_PACKAGE_DIR)/DEBIAN/control
	@cd $(BUILDDIR)/package/ && dpkg-deb --build cvitek-tpusdk-$(BOARD)-$(TPUSDKVERSION) cvitek-tpusdk-$(BOARD)_$(TPUSDKVERSION)$(TV)_$(DEB_ARCH).deb
	@cp $(BUILDDIR)/package/cvitek-tpusdk-$(BOARD)_$(TPUSDKVERSION)$(TV)_$(DEB_ARCH).deb /output/
	@mkdir -p /rootfs/tmp/install/
	@cp /output/cvitek-tpusdk-$(BOARD)_$(TPUSDKVERSION)$(TV)_$(DEB_ARCH).deb /rootfs/tmp/install/
	@touch $@

tpusdk: $(BUILDDIR)/tpusdk-package-stamp

tpusdk-clean:
	@rm -rf $(BUILDDIR)/tpusdk
	@rm -f $(BUILDDIR)/tpusdk-*-stamp

$(BUILDDIR)/tpusdk-stamp: $(BUILDDIR)/tpusdk-package-stamp

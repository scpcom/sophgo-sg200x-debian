SHELL = /bin/bash

ifeq ($(SDK_VER), 32bit)
CMAKE_SYSTEM_PROCESSOR = arm
else ifeq ($(SDK_VER), 64bit)
CMAKE_SYSTEM_PROCESSOR = aarch64
else ifeq ($(SDK_VER), glibc_riscv64)
CMAKE_SYSTEM_PROCESSOR = riscv64
else ifeq ($(SDK_VER), musl_riscv64)
CMAKE_SYSTEM_PROCESSOR = riscv64
else
$(error $(red)SDK_VER is invalid$(reset))
endif

# v1.22.0
#ONNXRUNTIME_GIT_REF = f217402897f40ebba457e2421bc0a4702771968e
# v1.22.1
ONNXRUNTIME_GIT_REF = 89746dc19a0a1ae59ebf4b16df9acab8f99f3925
# v1.22.2
#ONNXRUNTIME_GIT_REF = 5630b081cd25e4eccc7516a652ff956e51676794

ONNXRUNTIME_GIT_DIR = $(BUILDDIR)/onnxruntime/onnxruntime

ONNXRUNTIME_CMAKE_ENV = CMAKE_BUILD_TYPE="Release" \
	CROSS_COMPILE=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX) \
	CC=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)gcc CFLAGS="$(SDK_TARGET_CFLAGS) -g0" \
	CXX=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)g++ CXXFLAGS="$(SDK_TARGET_CXXFLAGS) -g0"

#-DCMAKE_TOOLCHAIN_FILE=path/to/tool.cmake
#-DPYTHON_EXECUTABLE=/mnt/pi/usr/bin/python3 
#"-DPYTHON_INCLUDE_DIR=/mnt/pi/usr/include;/mnt/pi/usr/include/python3.7m" -DNUMPY_INCLUDE_DIR=/mnt/pi/folder/to/numpy/headers

#-Donnxruntime_GCC_STATIC_CPP_RUNTIME=ON 

ONNXRUNTIME_CMAKE_OPTS = \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=$(BUILDDIR)/onnxruntime/output \
	-DCMAKE_SYSTEM_NAME=Linux \
	-DCMAKE_SYSTEM_VERSION=1 \
	-DCMAKE_SYSTEM_PROCESSOR=$(CMAKE_SYSTEM_PROCESSOR) \
	-DCMAKE_MAKE_PROGRAM=/usr/bin/make \
	-DCMAKE_C_COMPILER=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)gcc \
	-DCMAKE_CXX_COMPILER=$(SDK_CROSS_COMPILE_PATH)/bin/$(SDK_CROSS_COMPILE_PREFIX)g++ \
	-DONNX_CUSTOM_PROTOC_EXECUTABLE=/usr/bin/protoc \
	-Dprotobuf_WITH_ZLIB=OFF \
	-Donnxruntime_ENABLE_PYTHON=OFF \
	-Donnxruntime_BUILD_SHARED_LIB=ON \
	-Donnxruntime_BUILD_UNIT_TESTS=OFF \
	-Donnxruntime_DEV_MODE=OFF

$(BUILDDIR)/onnxruntime-prepare-stamp:
	@mkdir -p $(BUILDDIR)/onnxruntime/
	@cd $(BUILDDIR)/onnxruntime/ && git clone --depth 1 -b 3rd $(GIT_USER_URL)/onnxruntime
	@cd $(ONNXRUNTIME_GIT_DIR)/ && git checkout $(ONNXRUNTIME_GIT_REF)
	@cd $(ONNXRUNTIME_GIT_DIR)/ && git submodule set-url cmake/external/onnx $(GIT_USER_URL)/onnx
	@cd $(ONNXRUNTIME_GIT_DIR)/ && git submodule set-url cmake/external/libprotobuf-mutator $(GIT_USER_URL)/libprotobuf-mutator
	@cd $(ONNXRUNTIME_GIT_DIR)/ && git submodule set-url cmake/external/emsdk $(GIT_USER_URL)/emsdk
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/abseil/abseil-cpp/archive|$(GIT_RELEASES_URL)/abseil/abseil-cpp/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/eigen-mirror/eigen/archive|$(GIT_RELEASES_URL)/eigen-mirror/eigen/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/google/re2/archive|$(GIT_RELEASES_URL)/google/re2/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/google/googletest/archive|$(GIT_RELEASES_URL)/google/googletest/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/nlohmann/json/archive|$(GIT_RELEASES_URL)/nlohmann/json/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/protocolbuffers/protobuf/archive|$(GIT_RELEASES_URL)/protocolbuffers/protobuf/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/HowardHinnant/date/archive|$(GIT_RELEASES_URL)/HowardHinnant/date/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/boostorg/mp11/archive|$(GIT_RELEASES_URL)/boostorg/mp11/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/pytorch/cpuinfo/archive|$(GIT_RELEASES_URL)/pytorch/cpuinfo/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/microsoft/GSL/archive|$(GIT_RELEASES_URL)/microsoft/GSL/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/dcleblanc/SafeInt/archive|$(GIT_RELEASES_URL)/dcleblanc/SafeInt/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/google/flatbuffers/archive|$(GIT_RELEASES_URL)/google/flatbuffers/archive|g' cmake/deps.txt
	@cd $(ONNXRUNTIME_GIT_DIR)/ && sed -i 's|https://github.com/onnx/onnx/archive|$(GIT_RELEASES_URL)/onnx/onnx/archive|g' cmake/deps.txt
	# allow gcc 10.4 on riscv64
	@cd $(ONNXRUNTIME_GIT_DIR)/ && [ "$(CMAKE_SYSTEM_PROCESSOR)" != "riscv64" ] || sed -i s/'CMAKE_C_COMPILER_VERSION VERSION_LESS 11\.1'/'CMAKE_C_COMPILER_VERSION VERSION_LESS 10.4'/g cmake/CMakeLists.txt
	@# fix compile error with gcc 10.4 on riscv64
	@cd $(ONNXRUNTIME_GIT_DIR)/ && [ "$(CMAKE_SYSTEM_PROCESSOR)" != "riscv64" ] || git apply --ignore-whitespace /configs/common/patches/onnxruntime/_onnxruntime-fix-SplitReplaceWithQuant.patch
	@touch $@

$(BUILDDIR)/onnxruntime-protoc-stamp:
	@apt-get install -y protobuf-compiler
	@touch $@

$(BUILDDIR)/onnxruntime-stamp: $(BUILDDIR)/onnxruntime-prepare-stamp $(BUILDDIR)/onnxruntime-protoc-stamp
	@mkdir -p $(SDK_OSS_TARBALL_DIR)
	@mkdir -p $(BUILDDIR)/onnxruntime/build
	@mkdir -p $(BUILDDIR)/onnxruntime/output
	@cd $(BUILDDIR)/onnxruntime/build ; $(ONNXRUNTIME_CMAKE_ENV) cmake $(ONNXRUNTIME_GIT_DIR)/cmake -DCMAKE_INSTALL_PREFIX=$(BUILDDIR)/onnxruntime/output $(ONNXRUNTIME_CMAKE_OPTS)
	@cd $(BUILDDIR)/onnxruntime/build ; $(ONNXRUNTIME_CMAKE_ENV) make install
	@tar -C $(BUILDDIR)/onnxruntime/output -czf $(SDK_OSS_TARBALL_DIR)/onnxruntime.tar.gz include lib
	@touch $@

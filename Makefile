SHELL := /bin/bash
# Paths - Remember to first run the script "init.sh" to download
#
# Notes:
#	- Run 'make TARGET_MACHINE=mdmXXXX [option]' to select the platform (mdm9607 is the default)
#	- Run 'make TARGET_MACHINE=xxxx KERNEL_TREE=kernel_tree path to select a different kernel (default is themdm's current 3.18.140 kernel)
#
#
#
CURRENT_PATH:=$(shell pwd)
APPSBOOT_PATH:=$(CURRENT_PATH)/bootloader
KERNEL_TREE?=linux-3.18.140
KERNEL_PATH:=$(CURRENT_PATH)/$(KERNEL_TREE)
KERNEL_DTS_TREE?="qcom/"
$(shell mkdir -p target)

TARGET_MACHINE?=mdm9607
NUM_THREADS=12
CCFLAGS:=" -march=armv7-a -mfloat-abi=softfp -mfpu=neon"

ifeq ($(TARGET_MACHINE), mdm9607)
	ABOOT_TOOLCHAIN="arm-none-eabi-"
	ABOOT_PROJECT="mdm9607"
	ABOOT_BUILD_FILENAME=$(APPSBOOT_PATH)/build-mdm9607/appsboot.mbn
	ABOOT_BUILD_OUT=$(CURRENT_PATH)/target/appsboot_mdm9607.mbn
	KERNEL_TOOLCHAIN=arm-linux-gnueabi-
	KERNEL_DEFCONFIG="mdm9607-perf_defconfig"
	KERNEL_BASE=0x80000000
	KERNEL_PAGE_SIZE=2048
	KERNEL_TAGS_ADDR=0x81E00000
	KERNEL_OUTPUT_FILE="target/boot-mdm9607.img"
	KERNEL_OUTPUT_DTB=$(CURRENT_PATH)/target/dtb_mdm9607.img
	# Mainline
	KERNEL_CMD_PARAMS="console=ttyMSM0,115200,n8 log_buf_len=4M"
	# Ancient, fossilized kernel
	# KERNEL_CMD_PARAMS="earlycon console=ttyHSL0,115200,n8 androidboot.hardware=qcom ehci-hcd.park=3 msm_rtb.filter=0x37 lpm_levels.sleep_disabled=1 log_buf_len=4M"

else ifeq ($(TARGET_MACHINE), mdm9640)
	ABOOT_TOOLCHAIN="arm-none-eabi-"
	ABOOT_PROJECT="mdm9640"
	ABOOT_BUILD_FILENAME=$(APPSBOOT_PATH)/build-mdm9640/appsboot.mbn
	ABOOT_BUILD_OUT=$(CURRENT_PATH)/target/appsboot_mdm9640.mbn
	KERNEL_DEFCONFIG="mdm9640-perf_defconfig"
	KERNEL_BASE=0x80000000
	KERNEL_PAGE_SIZE=4096
	KERNEL_TAGS_ADDR=0x81100000
	KERNEL_OUTPUT_FILE="target/boot-mdm9640.img"
	KERNEL_OUTPUT_DTB=$(CURRENT_PATH)/target/dtb_mdm9640.img
endif

# Check if yocto/ source directory exists. If it doesn't, run init script
.PHONY: all
all:
ifneq ($(wildcard $(CURRENT_PATH)/bootloader),)
	@echo "If in doubt, use 'make build' to make a build with a bootloader and kernel"
else
	@echo "** The source trees don't seem to exist. Fetching repositories..."
	@./init.sh
endif

all:help
build: bootloader kernel
help:
	@echo "Welcome to the Standalone kernel and bootloader build env"
	@echo "------------------------------------"
	@echo " Available commands:"
	@echo " --> Bootloader"
	@echo "    make aboot : It will build the LK2ND bootloader and place the binary in /target"
	@echo " --> Kernel"
	@echo "    make kernel : Will build the kernel and place it in /target"
	@echo "    make clean : Removes all the built images and temporary directories from bootloader and kernel"
	@echo " "

aboot:
	@cd $(APPSBOOT_PATH) && \
	make -j $(NUM_THREADS) $(ABOOT_PROJECT) TOOLCHAIN_PREFIX=$(ABOOT_TOOLCHAIN) FASTBOOT_TIMER=1 || exit ; \
	cp $(ABOOT_BUILD_FILENAME) $(ABOOT_BUILD_OUT)

kernel_defconfig:
	cd $(KERNEL_PATH) && \
	make ARCH=arm defconfig KBUILD_DEFCONFIG=$(KERNEL_DEFCONFIG) O=build || exit ;
	
kernel_menuconfig:
	cd $(KERNEL_PATH) && \
	make ARCH=arm menuconfig O=build || exit ;
	
kernel_build:
	cd $(KERNEL_PATH) ; [ ! -f build/.config ] && echo -e "Please run make kernel_defconfig first!" && exit 1 ;\
	make ARCH=arm CROSS_COMPILE=$(KERNEL_TOOLCHAIN) CC=$(KERNEL_TOOLCHAIN)gcc $(CCFLAGS) LD=$(KERNEL_TOOLCHAIN)ld.bfd -j 12 O=build -k || exit ; \
	$(CURRENT_PATH)/tools/dtbtool $(KERNEL_PATH)/build/arch/arm/boot/dts/$(KERNEL_DTS_TREE) -s $(KERNEL_PAGE_SIZE) -o $(KERNEL_OUTPUT_DTB) -p $(KERNEL_PATH)/build/scripts/dtc/ \

	$(CURRENT_PATH)/tools/mkbootimg --kernel $(KERNEL_PATH)/build/arch/arm/boot/zImage \
		--ramdisk $(CURRENT_PATH)/tools/init.gz \
		--ramdisk_offset 0x00 \
		--output ${KERNEL_OUTPUT_FILE} \
		--pagesize $(KERNEL_PAGE_SIZE) \
		--base $(KERNEL_BASE) \
		--tags-addr $(KERNEL_TAGS_ADDR) \
		--dt $(KERNEL_OUTPUT_DTB) \
		--cmdline ${KERNEL_CMD_PARAMS}

clean: aboot_clean target_clean kernel_clean

target_clean:
	rm -rf $(CURRENT_PATH)/target && mkdir -p $(CURRENT_PATH)/target

aboot_clean:
	rm -rf bootloader/build-mdm9607

kernel_clean:
	rm -rf $(KERNEL_PATH)/build

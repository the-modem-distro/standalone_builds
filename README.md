# Standalone build tools

## Use this if you want to do standalone builds of the bootloader or kernel

These is just some stuff I use when I want to try stuff without having to deal with Yocto
- `./init.sh` to download lk2nd and kernel
- `make aboot` to make lk2nd
- `make kernel_defconfig || kernel_menuconfig || kernel_build` to make the kernel defconfig/build
- `make MACHINE=mdm9640 ...` to select mdm9640 as a target (use at your own risk...)


NOTE:
If building a mainline kernel, make sure you still keep
```
	qcom,msm-id = <290 0x10000>, <296 0x10000>, <297 0x10000>,
		      	  <298 0x10000>, <299 0x10000>;
	qcom,board-id = <8 0>;

```
in the DTS so dtbtool can build the dtb correctly and LK finds it
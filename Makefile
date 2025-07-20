all:
	nasm -f bin bootloader.asm -o os-image.bin
	qemu-system-x86_64 os-image.bin

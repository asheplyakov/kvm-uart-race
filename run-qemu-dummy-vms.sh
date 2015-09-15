#!/bin/sh
set -e

KVER="3.13.0-63-generic"

mkdir -p initramfs
cat > init-shutdown.c <<-EOF
#include <stdio.h>
#include <unistd.h>
#include <sys/reboot.h>
#include <linux/reboot.h>

int main() {
	printf("Good bye, cruel world!\\n");
	reboot(LINUX_REBOOT_CMD_POWER_OFF);
	return 0;
}
EOF
gcc -Os -static -o initramfs/init init-shutdown.c
( cd initramfs && find . | cpio -Hnewc --create ) > initramfs.img
while true; do
	qemu-system-x86_64 -enable-kvm \
		-nodefaults \
		-chardev stdio,id=stdio,mux=on \
		-device virtio-serial-pci \
		-device virtconsole,chardev=stdio \
		-mon chardev=stdio \
		-display none \
		-append 'console=hvc0' \
		-kernel /boot/vmlinuz-${KVER} \
		-initrd initramfs.img || true
done


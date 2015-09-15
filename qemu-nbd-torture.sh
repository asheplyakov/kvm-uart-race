#!/bin/sh
set -e
if [ "`id -u`" != "0" ]; then
	sudo exec $0 $@
fi

write_time=15
umount_timeout=10
max_nbd=15

run_once ()
{
	for count in `seq 0 $max_nbd`; do 
		img="nbd-ext4-${count}.img"
		qemu-img create -f qcow2 "$img" 16G
		qemu-nbd -c "/dev/nbd${count}" "$img"
		mkdir -p "/tmp/mnt${count}"
		mount -t ext4 -o rw,data=ordered,errors=continue "/dev/nbd${count}" "/tmp/mnt${count}"
	done

	for count in `seq 0 $max_nbd`; do
		for i in `seq 1 32`; do
			dd if=/dev/zero of=/tmp/mnt${count}/$i bs=1M count=256 &
		done
	done

	sleep $write_time
	killall qemu-nbd || true
	sleep $umount_timeout

	for count in `seq 0 $max_nbd`; do
		umount -l "/tmp/mnt${count}" || true
	done
}

while true; do
	run_once
done

dd if=virtual_disk.img bs=512 skip=112 count=16 | hexdump -C
ndisasm -b16 kernel.bin | head -n 20


  qemu-system-i386 \
  -m 1024 \
  -hda xp.img \
  -hdb virtual_disk.img \
  -boot c \
  -cpu host \
  -smp 2 \
  -net nic -net user \
  -vga std \
  -rtc base=localtime \
  -enable-kvm \
  -usbdevice tablet

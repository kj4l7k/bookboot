
CROSS=arm-linux-

CC=$(CROSS)gcc
LD=$(CROSS)ld
AS=$(CROSS)as

all: os.img

os.img: bookglue.pl bookboot.bin  zImage
	./bookglue.pl 

bookboot.elf: bookboot.S  serial.S
	$(CC) -fomit-frame-pointer -O2  -nostdlib -Wl,-Ttext,0xc8000000 -N bookboot.S  -o bookboot.elf

bookboot.bin: bookboot.elf
	$(CROSS)objcopy  -O binary bookboot.elf bookboot.bin

clean:
	rm -f *.elf  *.o os.img

mrproper: clean
	rm -f *.bin

install: os.img
	cp os.img /var/autofs/misc/hdc1/os.img
	sync

package: bookboot.bin
	tar cf - *.S bookboot.bin  *.pl README  COPYING Makefile  | gzip > bookboot.tgz

release:
	make mrproper
	make all
	make package


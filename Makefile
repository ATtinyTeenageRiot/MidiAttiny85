# WinAVR cross-compiler toolchain is used here
AVRDIR		= /Applications/Development/Arduino1.0.5_trinket.app/Contents/Resources/Java/hardware/tools/avr
AVRBIN		= $(AVRDIR)/bin
AVRCONFIG	= $(AVRDIR)/etc/avrdude.conf

CC = $(AVRBIN)/avr-gcc
OBJCOPY = $(AVRBIN)/avr-objcopy
DUDE = $(AVRBIN)/avrdude


DEVICE		= attiny85
CLOCK		= 16500000
PROGRAMMER = usbasp -B4
SERIAL_DEVICE = usb
BAUDRATE	= 19200
AVRDUDE_PROGRAMMER = -c$(PROGRAMMER) -P$(SERIAL_DEVICE) -b$(BAUDRATE)
AVRCONFIG	= $(AVRDIR)/etc/avrdude.conf
AVRDUDE = $(AVRBIN)/avrdude $(AVRDUDE_PROGRAMMER) -p $(DEVICE) -C $(AVRCONFIG)


# If you are not using ATtiny2313 and the USBtiny programmer, 
# update the lines below to match your configuration
CFLAGS = -Wall -Os -Iusbdrv -mmcu=attiny85 -DF_CPU=16500000 -I./
OBJFLAGS = -j .text -j .data -O ihex
DUDEFLAGS = -p attiny85 -c usbtiny -v

# Object files for the firmware (usbdrv/oddebug.o not strictly needed I think)
OBJECTS = usbdrv/usbdrv.o usbdrv/oddebug.o usbdrv/usbdrvasm.o main.o

# Command-line client
CMDLINE = usbtest.exe

# By default, build the firmware and command-line client, but do not flash
all: main.hex $(CMDLINE)

# With this, you can flash the firmware by just typing "make flash" on command-line
flash:	main.hex
	$(AVRDUDE) -U flash:w:main.hex:i

# One-liner to compile the command-line client from usbtest.c
$(CMDLINE): usbtest.c
	gcc -I ./libusb/include -L ./libusb/lib/gcc -O -Wall usbtest.c -o usbtest.exe -lusb

# Housekeeping if you want it
clean:
	$(RM) *.o *.hex *.elf usbdrv/*.o

# From .elf file to .hex
%.hex: %.elf
	$(OBJCOPY) $(OBJFLAGS) $< $@

bootloader:
	$(AVRDUDE) -U flash:w:main.hex:i

# Main.elf requires additional objects to the firmware, not just main.o
main.elf: $(OBJECTS)
	$(CC) $(CFLAGS) $(OBJECTS) -o $@

# Without this dependance, .o files will not be recompiled if you change 
# the config! I spent a few hours debugging because of this...
$(OBJECTS): usbdrv/usbconfig.h

# From C source to .o object file
%.o: %.c	
	$(CC) $(CFLAGS) -c $< -o $@

# From assembler source to .o object file
%.o: %.S
	$(CC) $(CFLAGS) -x assembler-with-cpp -c $< -o $@

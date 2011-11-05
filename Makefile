OBJECTS = Toggle
TARGET = Toggle.dylib
TOGGLE_NAME = RemoveBG

SDKVERSION = 4.2
SDKBINPATH = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
CC = $(SDKBINPATH)/arm-apple-darwin10-gcc-4.2.1
SYSROOT = /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVERSION).sdk

SB_PATH = /Developer/Jailbreak
MS_PATH = /Developer/Jailbreak/MobileSubstrate

LD = $(CC)
CFLAGS = -fconstant-cfstrings \
		 -std=gnu99 \
		 -Wall -O2 \
		 -isysroot $(SYSROOT)

LDFLAGS = -framework CoreFoundation \
		  -framework Foundation \
		  -framework UIKit \
		  -lobjc \
		  -bind_at_load \
		  -isysroot $(SYSROOT) \
		  -L$(MS_PATH) -lsubstrate \
		  -multiply_defined suppress \
		  -dynamiclib

INCLUDES = -I$(SB_PATH) \
		   -I$(MS_PATH)

VERSION = 1.0

all: $(TARGET)

clean:
	rm -f *.o $(TARGET)

%.o: %.m
	$(CC) -c $(CFLAGS) $(INCLUDES) $< -o $@

$(TARGET): main.o
	$(LD) $(LDFLAGS) -o $@ $^
	ldid -S $@

package: $(TARGET) control
	mkdir -p package/DEBIAN
	cp -a control package/DEBIAN
	mkdir -p package/var/mobile/Library/SBSettings/Toggles/$(TOGGLE_NAME)/
	cp -a Toggle.dylib package/var/mobile/Library/SBSettings/Toggles/$(TOGGLE_NAME)/
	cp -a Themes package/var/mobile/Library/SBSettings/
	dpkg-deb -b package $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
	rm -rf package
	#sudo chgrp -R wheel package
	#sudo chown -R root package
	#sudo dpkg-deb -b package $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
	#sudo rm -rf package

install: package
	scp -P2222 $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb root@localhost:.
	ssh -p2222 root@localhost dpkg -i $(shell grep ^Package: control | cut -d ' ' -f 2)_$(shell grep ^Version: control | cut -d ' ' -f 2)_iphoneos-arm.deb
	ssh -p2222 root@localhost respring

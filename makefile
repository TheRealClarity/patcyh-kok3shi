library := libpatcyh.dylib
package := com.saurik.patcyh
control := extrainst_ postrm

all: $(library)

clean:
	rm -f $(library) $(control)

.PHONY: all clean package

flags := -Os -Werror
flags += -framework CoreFoundation
flags += -framework Foundation
flags += -marm

lib%.dylib: %.mm
	cycc -i2.0 -o$@ -- -dynamiclib $(flags) $(filter-out %.hpp,$^) $($@) -lobjc

%: %.mm patch.hpp
	cycc -i2.0 -o$@ -- $(filter-out %.hpp,$^) $(flags) $($@)

package: all $(control)
	sudo rm -rf _
	mkdir -p _/Library/MobileSubstrate/DynamicLibraries
	cp -a patcyh.plist _/Library/MobileSubstrate/DynamicLibraries
	ln -s /usr/lib/libpatcyh.dylib _/Library/MobileSubstrate/DynamicLibraries/patcyh.dylib
	mkdir -p _/usr/lib
	cp -a $(library) _/usr/lib
	mkdir -p _/DEBIAN
	./control.sh _ >_/DEBIAN/control
	cp -a extrainst_ _/DEBIAN/
	cp -a postrm _/DEBIAN/
	mkdir -p debs
	ln -sf debs/$(package)_$$(./version.sh)_iphoneos-arm.deb $(package).deb
	sudo chown -R 0 _
	sudo chgrp -R 0 _
	dpkg-deb -b _ $(package).deb
	readlink $(package).deb

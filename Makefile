PREFIX ?= /usr/local
SRC ?= src
DIST ?= dist
VERSION := $(shell head -n1 $(SRC)/NEWS 2>/dev/null | awk '{print $$1}' | tr -d 'v' || echo "0.0.0")
TARBALL := zfsnap-$(VERSION).tar.gz

.PHONY: all build release install clean

all: build

build:
	./build.sh $(SRC) $(DIST)

release: build
	tar -czf $(TARBALL) -C $(DIST) .
	sha256sum $(TARBALL) > $(TARBALL).sha256 || true

install: build
	install -d "$(DESTDIR)$(PREFIX)/sbin"
	install -m 0755 $(DIST)/sbin/zfsnap.sh "$(DESTDIR)$(PREFIX)/sbin/zfsnap"
	install -d "$(DESTDIR)$(PREFIX)/share/zfsnap"
	install -m 0644 $(DIST)/share/zfsnap/* "$(DESTDIR)$(PREFIX)/share/zfsnap/" || true

clean:
	rm -rf $(DIST) *.tar.gz *.sha256

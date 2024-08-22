DPKG_ARCH := $(shell dpkg --print-architecture)
BASE := bionic-base-$(DPKG_ARCH).tar.gz
# dir that contans the filesystem that must be checked
TESTDIR ?= "prime/"

.PHONY: all
all: check
	# nothing

.PHONY: install
install:
	# install base
	set -ex; if [ -z "$(DESTDIR)" ]; then \
		echo "no DESTDIR set"; \
		exit 1; \
	fi
	if [ ! -f ../$(BASE) ]; then \
		wget -P ../ http://cdimage.ubuntu.com/ubuntu-base/bionic/daily/current/$(BASE); \
	fi
	rm -rf $(DESTDIR)
	mkdir -p $(DESTDIR)
	tar -x -f ../$(BASE) -C $(DESTDIR)
	# ensure resolving works inside the chroot
	cat /etc/resolv.conf > $(DESTDIR)/etc/resolv.conf
	# since recently we're also missing some /dev files that might be
	# useful during build - make sure they're there
	[ -e $(DESTDIR)/dev/null ] || mknod -m 666 $(DESTDIR)/dev/null c 1 3
	[ -e $(DESTDIR)/dev/zero ] || mknod -m 666 $(DESTDIR)/dev/zero c 1 5
	[ -e $(DESTDIR)/dev/random ] || mknod -m 666 $(DESTDIR)/dev/random c 1 8
	[ -e $(DESTDIR)/dev/urandom ] || \
		mknod -m 666 $(DESTDIR)/dev/urandom c 1 9
	# copy static files verbatim
	/bin/cp -a static/* $(DESTDIR)
	# customize
	set -ex; for f in ./hooks/[0-9]*.chroot; do \
		/bin/cp -a $$f $(DESTDIR)/tmp && \
		if ! chroot $(DESTDIR) /tmp/$$(basename $$f); then \
                    exit 1; \
                fi && \
		rm -f $(DESTDIR)/tmp/$$(basename $$f); \
	done;
	
	# refresh the previous core18 base snap
	snap refresh core18 --beta

	# generate the changelog, for this we need the previous core snap
	# to be installed, this should be handled in snapcraft.yaml
	if [ -e "/snap/core18/current/usr/share/snappy/dpkg.yaml" ]; then \
		./tools/generate-changelog.py \
			"/snap/core18/current/usr/share/snappy/dpkg.yaml" \
			"$(DESTDIR)/usr/share/snappy/dpkg.yaml" \
			"$(DESTDIR)/usr/share/doc" \
			$(DESTDIR)/usr/share/doc/ChangeLog; \
	else \
		echo "WARNING: changelog will not be generated for this build"; \
	fi

	# only generate manifest and dpkg.yaml file for lp build
	if [ -e /build/core18 ]; then \
		echo $$f; \
		/bin/cp $(DESTDIR)/usr/share/snappy/dpkg.list /build/core18/core18-$$(date +%Y%m%d%H%M)_$(DPKG_ARCH).manifest; \
		/bin/cp $(DESTDIR)/usr/share/snappy/dpkg.yaml /build/core18/core18-$$(date +%Y%m%d%H%M)_$(DPKG_ARCH).dpkg.yaml; \
		if [ -e $(DESTDIR)/usr/share/doc/ChangeLog ]; then \
			/bin/cp $(DESTDIR)/usr/share/doc/ChangeLog /build/core18/core18-$$(date +%Y%m%d%H%M)_$(DPKG_ARCH).ChangeLog; \
		fi \
	fi;

	# after generating changelogs we can cleanup those bits
	# from the base
	find "$(DESTDIR)/usr/share/doc/" -name 'changelog.Debian.gz' -print -delete
	find "$(DESTDIR)/usr/share/doc/" -name 'changelog.gz' -print -delete

.PHONY: check
check:
	# exclude "useless cat" from checks, while useless they also make
	# some code more readable
	shellcheck -e SC2002 hooks/*

.PHONY: test
test:
	# run tests - each hook should have a matching ".test" file
	set -ex; if [ ! -d $(TESTDIR) ]; then \
		echo "no $(TESTDIR) found, please build the tree first "; \
		exit 1; \
	fi
	set -ex; for f in $$(pwd)/hook-tests/[0-9]*.test; do \
			if !(cd $(TESTDIR) && $$f); then \
				exit 1; \
			fi; \
	    	done; \

# Display a report of files that are (still) present in /etc
.PHONY: etc-report
etc-report:
	cd stage && find etc/
	echo "Amount of cruft in /etc left: `find stage/etc/ | wc -l`"

.PHONY: update-image
update-image:
	sudo snapcraft clean
	sudo snapcraft
	sudo $(MAKE) -C tests/lib just-update

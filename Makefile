
PKG_NAME := virtualcandy
PKG_NAME_U := virtualcandy
PKG_VER := $(shell python -c "from __future__ import print_function; import $(PKG_NAME_U); print($(PKG_NAME_U).__version__)")

.PHONY: test cheese clean

.DEFAULT:
dist: clean
	find ./virtualcandy -type f | xargs chmod 644
	find ./virtualcandy -type d | xargs chmod 755
	chmod 755 ./virtualcandy/vcshellinstaller
	umask 0022; python ./setup.py sdist

test:
	@echo "Write some tests YO!"

cheese: clean test dist
	python ./setup.py sdist upload

clean:
	rm -fr dist
	rm -fr *.egg-info

uninstall:
	-yes y | pip uninstall --exists-action=w $(PKG_NAME)

install: clean test dist
	pip install --pre --exists-action=w ./

dinstall: uninstall install

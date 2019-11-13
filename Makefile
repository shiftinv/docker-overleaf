# Makefile

build:
	docker build -f Dockerfile -t shiftinv/sharelatex .

build-clsi:
	$(MAKE) -C clsi build

PHONY: build

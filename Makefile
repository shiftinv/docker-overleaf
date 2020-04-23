# Makefile

build:
	docker build -f Dockerfile -t shiftinv/overleaf .

build-clsi:
	$(MAKE) -C clsi build

PHONY: build

CLSI_SCHEME=basic

build:
	docker build -f Dockerfile -t shiftinv/overleaf .

build-clsi:
	$(MAKE) -C clsi build SCHEME=$(CLSI_SCHEME)

build-clsi-sagetex:
	$(MAKE) -C clsi build-sagetex SCHEME=$(CLSI_SCHEME)

PHONY: build

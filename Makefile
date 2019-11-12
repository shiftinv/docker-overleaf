# Makefile


build-base:
	docker build -f Dockerfile-base -t shiftinv/sharelatex-base .


build-community:
	docker build -f Dockerfile -t shiftinv/sharelatex .


PHONY: build-base build-community

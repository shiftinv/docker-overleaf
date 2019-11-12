# Makefile

build:
	docker build -f Dockerfile -t shiftinv/sharelatex .

PHONY: build

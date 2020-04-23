# Overleaf Docker Image

This is the base Overleaf image, with all dependencies pinned to the same versions as in the [official Docker image v2.2.0](https://hub.docker.com/r/sharelatex/sharelatex).


This image depends on mongodb and redis, as well as [sharelatex-clsi](https://hub.docker.com/r/shiftinv/sharelatex-clsi) which has been separated from the base image to simplify the TeX Live updating process. The CLSI component provides the TeX Live compilation environment and is updated to the latest TeX Live version (as of 2019-11). There are multiple CLSI containers available with different TeX Live schemes, view the image [tags](https://hub.docker.com/r/shiftinv/sharelatex-clsi/tags) for available options.
Check out the [docker-compose](https://github.com/shiftinv/docker-sharelatex/blob/master/docker-compose.yml) file for an example configuration.

---

Other changes compared to the official image:
- Optimized image size + build time

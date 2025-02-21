default_target: local

COMMIT_HASH := $(shell git log -1 --pretty=format:"%h"|tail -1)
VERSION = 0.12.1-32b
IMAGE_REPO ?= ghcr.io/ensmings/frigate
CURRENT_UID := $(shell id -u)
CURRENT_GID := $(shell id -g)

version:
	echo 'VERSION = "$(VERSION)-$(COMMIT_HASH)"' > frigate/version.py

local: version
	docker buildx build --target=frigate --tag frigate:latest --load .

local-trt: version
	docker buildx build --target=frigate-tensorrt --tag frigate:latest-tensorrt --load .

armv7:
	docker buildx build --platform linux/arm/v7 --target=frigate --tag $(IMAGE_REPO):$(VERSION)-$(COMMIT_HASH) .

build: version armv7
	docker buildx build --platform linux/arm/v7 --target=frigate --tag $(IMAGE_REPO):$(VERSION)-$(COMMIT_HASH) .

push: build
	docker buildx build --push --platform linux/arm/v7 --target=frigate --tag $(IMAGE_REPO):${GITHUB_REF_NAME}-$(COMMIT_HASH) .

run: local
	docker run --rm --publish=5000:5000 --volume=${PWD}/config/config.yml:/config/config.yml frigate:latest

run_tests: local
	docker run --rm --workdir=/opt/frigate --entrypoint= frigate:latest python3 -u -m unittest
	docker run --rm --workdir=/opt/frigate --entrypoint= frigate:latest python3 -u -m mypy --config-file frigate/mypy.ini frigate

.PHONY: run_tests

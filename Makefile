IMAGE_NAME ?= tf01-nginx
IMAGE_TAG ?= production

.PHONY: build
build:
	docker build \
		--platform linux/amd64 \
		--build-arg BUILD_ENV=production \
		--tag $(IMAGE_NAME):$(IMAGE_TAG) \
		.

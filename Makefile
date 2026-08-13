IMAGE_NAME ?= tf01-nginx
IMAGE_TAG ?= production

.PHONY: build push
build:
	docker build \
		--platform linux/amd64 \
		--build-arg BUILD_ENV=production \
		--tag $(IMAGE_NAME):$(IMAGE_TAG) \
		.

push: build
	IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG) ./scripts/push-ecr.sh

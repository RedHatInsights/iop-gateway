# Default image name (can be overridden by passing IMAGE=<your-image-name>)
IMAGE ?= quay.io/iop/gateway:latest

# Build target
build:
	@echo "Building image: $(IMAGE)"
	podman build -t $(IMAGE) -f Containerfile .

# Push target (optional, in case you want to push to a registry)
push:
	@echo "Pushing image: $(IMAGE)"
	podman push $(IMAGE)

# Clean target (optional)
clean:
	@echo "Removing local image: $(IMAGE)"
	-podman rmi $(IMAGE)

.PHONY: build push clean

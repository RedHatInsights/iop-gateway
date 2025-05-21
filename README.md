# iop-gateway

A lightweight and configurable gateway container designed to act as an entry point for deployments. It supports custom configuration mounting and includes identity handling behavior.

## Getting Started

To get started with local development, first clone the repository:

```bash
git clone https://github.com/RedHatInsights/iop-gateway.git
cd iop-gateway
```

## Local Development

### Building the Container Image

A `Containerfile` is provided in the root of the repository. You can build the container image using the included `Makefile`.

To build the image with the default image name:

```bash
make build
```
By default, the image is tagged as:

```bash
quay.io/iop/gateway:latest
```

To override the image name or tag, pass the IMAGE variable:

```bash
make build IMAGE=myregistry.local/iop-gateway:dev
```

### Running the Container Locally
After building, you can run the container using Podman:

```bash
podman run --rm -p 8080:8080 myregistry.local/iop-gateway:dev
```

You can also mount custom configuration:

```bash
podman run --rm -p 8080:8080 -v $(pwd)/config:/app/config:Z myregistry.local/iop-gateway:dev
```

### Cleaning Up
To remove the built image locally:

```bash
make clean
```

### Pushing to a Registry
If you want to push the image to a remote registry:

```bash
make push IMAGE=myregistry.local/iop-gateway:dev
```

## Contributing
Feel free to open issues or pull requests. Contributions are welcome!

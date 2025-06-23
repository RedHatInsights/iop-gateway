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


To run the container use:
```bash
make run
```

or you can run it manually with:

```bash
podman run --rm -p 8443:8443  -v ./certs/:/etc/nginx/certs:Z myregistry.local/iop-gateway:dev
```

You can also mount custom configuration that would be included in the `http` block:

```bash
podman run --rm -p 8443:8443 -v ./config:/etc/nginx/conf.d/:Z myregistry.local/iop-gateway:dev
```

Should you want to use an insecure HTTP protocol (without TLS) mount the [`hack/conf.d/http.conf`](hack/conf.d/http.conf) to `/etc/nginx/conf.d/` conainer path and bind port 3000:

```bash
podman run --rm -p 3000:3000 -v ./hack/conf.d/:/etc/nginx/conf.d/:Z myregistry.local/iop-gateway:dev
```


### TLS

The TLS is opened on port 8443.

Running the gateway requires the following certificates:

| Certificate path             | Type                       |
| :--------------------------- | :------------------------- |
| `/etc/nginx/certs/ca.crt`    | CA PEM certificate         |
| `/etc/nginx/certs/nginx.crt` | Gateway public certificate |
| `/etc/nginx/certs/nginx.key` | Gateway private key        |

These certifcates can be generated for local development with `make certs`.
The destination directory of generated certificates can be set by `CERT_DIR` variable.
The subjects can be controlled by `NGINX_SUBJECT`, `CA_SUBJECT`, and `CLIENT_SUBJECT`.

To test out the connection with curl:
```bash
curl -v -4 --key certs/client.key --cert certs/client.crt --cacert certs/ca.crt https://localhost:8443
```


### Cleaning Up
To remove the built image locally and certificates:

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

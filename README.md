# iop-gateway

A gateway to and for Insights services.
It acts as an entry point to Insights services and a gateway to Foreman for Insights services.
It includes identity handling behavior.

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
podman run --rm -p 8443:8443 -p 9090:9090  \
  -v ./certs/:/etc/nginx/certs:Z  -v ./certs/:/etc/nginx/smart-proxy-relay/certs:Z \
  myregistry.local/iop-gateway:dev
```

You can also mount custom configuration that would be included in the `http` block:

```bash
podman run --rm -p 8443:8443 -p 9090:9090 -v ./config:/etc/nginx/conf.d/:Z myregistry.local/iop-gateway:dev
```

Should you want to use an insecure HTTP protocol (without TLS) mount the [`hack/conf.d/http.conf`](hack/conf.d/http.conf) to `/etc/nginx/conf.d/` conainer path and bind port 3000:

```bash
podman run --rm -p 3000:3000 -v ./hack/conf.d/:/etc/nginx/conf.d/:Z myregistry.local/iop-gateway:dev
```


### TLS

The TLS is opened on port 8443.

Running the gateway requires the following certificates:

| Certificate path                               | Type                         |
| :--------------------------------------------- | :--------------------------- |
| `/etc/nginx/certs/ca.crt`                      | CA PEM certificate           |
| `/etc/nginx/certs/nginx.crt`                   | Gateway public certificate   |
| `/etc/nginx/certs/nginx.key`                   | Gateway private key          |
| `/etc/nginx/smart-proxy-relay/certs/ca.crt`    | CA certificate for the relay |
| `/etc/nginx/smart-proxy-relay/certs/proxy.crt` | Client certificate           |
| `/etc/nginx/smart-proxy-relay/certs/proxy.key` | Client private key           |

These certifcates can be generated for local development with `make certs`.
The destination directory of generated certificates can be set by `CERT_DIR` variable.
The subjects can be controlled by `NGINX_SUBJECT`, `CA_SUBJECT`, and `CLIENT_SUBJECT`.

To test out the connection with curl:
```bash
curl -v -4 --key certs/client.key --cert certs/client.crt --cacert certs/ca.crt https://localhost:8443
```

### Testing

Before running the tests, ensure that the container is running:

```bash
make run
```

Then run the tests:

```bash
make test
```

To stop the container:

```bash
make stop
```

### Smart Proxy Relay

The gateway opens up an http port 9090 to provide a gateway to a Foreman instance identied as a [Smart Proxy](https://github.com/theforeman/smart-proxy).
Services inside a network can use this gateway to communicate with Foreman and its plugins.

To configure the path to a Foreman instance override `/etc/nginx/smart-proxy-relay/relay.conf`:

```
# (REQUIRED) CName of the Foreman instance (must match Foreman's TLS certificate)
proxy_ssl_name "satellite.example.com";

# URI to forman
# Example of 10.130.0.1 is the container network gateway.
# This can be kept as is if the network is 10.130.0.0.
proxy_pass "https://10.130.0.1";
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

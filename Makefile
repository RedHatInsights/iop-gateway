# Default image name (can be overridden by passing IMAGE=<your-image-name>)
IMAGE ?= quay.io/iop/gateway:latest
CERT_DIR ?= certs
NGINX_SUBJECT ?= /CN=localhost
CA_SUBJECT ?= /CN=My CA
CLIENT_SUBJECT ?= /CN=localhost

# Build target
build:
	@echo "Building image: $(IMAGE)"
	podman build -t $(IMAGE) -f Containerfile .

# Push target (optional, in case you want to push to a registry)
push:
	@echo "Pushing image: $(IMAGE)"
	podman push $(IMAGE)

run: build certs
	podman run --rm -p 8443:8443 -p 3000:3000 -v ./certs/:/etc/nginx/certs:Z "$(IMAGE)"

certs: $(CERT_DIR)/nginx.crt $(CERT_DIR)/client.crt

$(CERT_DIR)/%.key:
	@echo "Generating $@ key"
	openssl genpkey -algorithm RSA -out "$@"
	chmod 604 "$@"

$(CERT_DIR)/ca.crt: $(CERT_DIR)/ca.key
	@echo "Generating CA cert"
	openssl req -new -x509 -key "$<" -subj "$(CA_SUBJECT)" -out "$@"
	chmod 644 "$@"

$(CERT_DIR)/%.crt: $(CERT_DIR)/%.csr $(CERT_DIR)/ca.crt
	@echo "Generating $@ certificate"
	openssl x509 -req -in "$<" -CA "$(CERT_DIR)/ca.crt" -CAkey "$(CERT_DIR)/ca.key" -CAcreateserial -out "$@"
	chmod 644 "$@"

$(CERT_DIR)/nginx.csr: $(CERT_DIR)/nginx.key
	openssl req -new -key "$<" -subj "$(NGINX_SUBJECT)" -out "$@"

$(CERT_DIR)/client.csr: $(CERT_DIR)/client.key
	openssl req -new -key "$<" -subj "$(CLIENT_SUBJECT)" -out "$@"

# Clean target (optional)
clean:
	@echo "Removing local image: $(IMAGE)"
	-podman rmi $(IMAGE)
	rm -rf ./certs/*

.PHONY: build push run clean

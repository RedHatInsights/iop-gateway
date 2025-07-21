# Default image name (can be overridden by passing IMAGE=<your-image-name>)
IMAGE ?= quay.io/iop/gateway:latest
CERT_DIR ?= certs
NGINX_SUBJECT ?= /CN=localhost
CA_SUBJECT ?= /CN=My CA
RELAY_SUBJECT ?= /CN=localhost
CLIENT_SUBJECT ?= /CN=localhost/O=1

# Default value for BASE_IMAGE
BASE_IMAGE ?= registry.access.redhat.com/ubi9/nginx-124:latest
# Default value for CONTAINERFILE
CONTAINERFILE ?= Containerfile

# Define the AWK command based on platform (gawk on macOS, awk elsewhere)
AWK = awk
ifeq ($(shell uname),Darwin)
AWK = gawk
endif


# Build target
build:
	@echo "Building image: $(IMAGE)"
	podman build -t $(IMAGE) -f Containerfile .

# Push target (optional, in case you want to push to a registry)
push:
	@echo "Pushing image: $(IMAGE)"
	podman push $(IMAGE)

run: build certs
	podman run --rm -p 8443:8443 -p 9090:9090 \
	  -v ./certs/:/etc/nginx/certs:Z -v ./certs/:/etc/nginx/smart-proxy-relay/certs:Z \
	  "$(IMAGE)"

certs: $(CERT_DIR)/nginx.crt $(CERT_DIR)/proxy.crt $(CERT_DIR)/client.crt

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

$(CERT_DIR)/proxy.csr: $(CERT_DIR)/proxy.key
	openssl req -new -key "$<" -subj "$(RELAY_SUBJECT)" -out "$@"

$(CERT_DIR)/client.csr: $(CERT_DIR)/client.key
	openssl req -new -key "$<" -subj "$(CLIENT_SUBJECT)" -out "$@"

# Clean target (optional)
clean:
	@echo "Removing local image: $(IMAGE)"
	-podman rmi $(IMAGE)
	rm -rf ./certs/*


# Generate the ubi.repo file from the specified BASE_IMAGE
# Usage: make generate-repo-file [BASE_IMAGE=<image>]
# Example: make generate-repo-file BASE_IMAGE=registry.access.redhat.com/ubi9/nginx-124:latest
#          make generate-repo-file (uses default BASE_IMAGE)
generate-repo-file:
	podman run -it $(BASE_IMAGE) cat /etc/yum.repos.d/ubi.repo > ubi.repo
	sed -i '' 's/ubi-9-appstream-source-rpms/ubi-9-for-x86_64-appstream-source-rpms/' ubi.repo
	sed -i '' 's/ubi-9-appstream-rpms/ubi-9-for-x86_64-appstream-rpms/' ubi.repo
	sed -i '' 's/ubi-9-baseos-source-rpms/ubi-9-for-x86_64-baseos-source-rpms/' ubi.repo
	sed -i '' 's/ubi-9-baseos-rpms/ubi-9-for-x86_64-baseos-rpms/' ubi.repo
	sed -i '' 's/\r$$//' ubi.repo
	sed -i '' '/\[.*x86_64.*\]/,/^\[/ s/enabled[[:space:]]*=[[:space:]]*0/enabled = 1/g' ubi.repo

# Generate rpms.in.yaml listing RPM packages installed via yum, dnf, or microdnf from CONTAINERFILE
# Usage: make generate-rpms-in-yaml [CONTAINERFILE=<path>]
# Example: make generate-rpms-in-yaml CONTAINERFILE=Containerfile
#          make generate-rpms-in-yaml (uses default CONTAINERFILE=Dockerfile)
generate-rpms-in-yaml:
	@if [ ! -f "$(CONTAINERFILE)" ]; then \
		exit 1; \
	fi
	@if ! command -v $(AWK) >/dev/null 2>&1; then \
		exit 1; \
	fi; \
	packages=$$(grep -E '^(RUN[[:space:]]+)?(.*[[:space:]]*(yum|dnf|microdnf)[[:space:]]+.*install.*)' "$(CONTAINERFILE)" | \
		sed -E 's/\\$$//' | \
		$(AWK) '{ \
			start=0; \
			for (i=1; i<=NF; i++) { \
				if ($$i == "install") { start=1; continue } \
				if (start && $$i ~ /^[a-zA-Z0-9][a-zA-Z0-9_.+-]*$$/ && \
					$$i !~ /^-/ && $$i != "&&" && $$i != "clean" && $$i != "all" && $$i != "upgrade") { \
					print $$i \
				} \
				if ($$i == "&&") { start=0 } \
			} \
		}' | sort -u); \
	if [ -z "$$packages" ]; then \
		exit 1; \
	else \
		echo "packages: [$$(echo "$$packages" | tr '\n' ',' | sed -E 's/,/, /g; s/, $$//')]" > rpms.in.yaml; \
		echo "contentOrigin:" >> rpms.in.yaml; \
		echo "  repofiles: [\"./ubi.repo\"]" >> rpms.in.yaml; \
		echo "arches: [x86_64]" >> rpms.in.yaml; \
	fi

# Generate rpms.lock.yaml using rpm-lockfile-prototype
# Usage: make generate-rpm-lockfile [BASE_IMAGE=<image>]
# Example: make generate-rpm-lockfile BASE_IMAGE=registry.access.redhat.com/ubi9/nginx-124:latest
#          make generate-rpm-lockfile (uses default BASE_IMAGE)
generate-rpm-lockfile: rpms.in.yaml
	@curl -s https://raw.githubusercontent.com/konflux-ci/rpm-lockfile-prototype/refs/heads/main/Containerfile | \
	podman build -t localhost/rpm-lockfile-prototype -
	@container_dir=/work; \
	podman run --rm -v $${PWD}:$${container_dir} localhost/rpm-lockfile-prototype:latest --outfile=$${container_dir}/rpms.lock.yaml --image $(BASE_IMAGE) $${container_dir}/rpms.in.yaml
	@if [ ! -f rpms.lock.yaml ]; then \
		echo "Error: rpms.lock.yaml was not generated"; \
		exit 1; \
	fi

.PHONY: build push run clean certs generate-repo-file generate-rpms-in-yaml generate-rpm-lockfile

# Hermetic Build Process

This document outlines the steps to create a hermetic build environment by generating RPM lock files using the provided Makefile targets. The process ensures reproducible builds by locking dependencies for system (RPM). Follow the steps below, committing changes to `git` after each section to track progress.

## Generating RPM Lock Files

To generate the RPM lock file (`rpms.lock.yaml`), follow these steps to create the necessary repository configuration and package lists.

### Step 1: Generate the `ubi.repo` File
Run the `generate-repo-file` target to create the `ubi.repo` file, which configures the UBI (Universal Base Image) repositories for RPM packages.

```bash
make generate-repo-file
```

- **Input**: Uses `BASE_IMAGE` (default: `registry.access.redhat.com/ubi9/nginx-124:latest`).
- **Output**: Creates `ubi.repo` with enabled x86_64 repositories.
- **Optional**: Specify a custom image with `BASE_IMAGE`, e.g., `make generate-repo-file BASE_IMAGE=registry.access.redhat.com/ubi9/nginx-124:latest`.

### Step 2: Generate the `rpms.in.yaml` File
Run the `generate-rpms-in-yaml` target to extract RPM packages from the `CONTAINERFILE` and create `rpms.in.yaml`.

```bash
make generate-rpms-in-yaml
```

- **Input**: Uses `CONTAINERFILE` (default: `Dockerfile`) to parse `yum`, `dnf`, or `microdnf install` commands.
- **Output**: Creates `rpms.in.yaml` listing RPM packages, repository files, and architecture.
- **Optional**: Specify a custom file with `CONTAINERFILE`, e.g., `make generate-rpms-in-yaml CONTAINERFILE=Containerfile`.

### Step 3: Generate the `rpms.lock.yaml` File
Run the `generate-rpm-lockfile` target to create the locked RPM dependency file using the `rpm-lockfile-prototype` tool.

```bash
make generate-rpm-lockfile
```

- **Input**: Requires `rpms.in.yaml` and `BASE_IMAGE`.
- **Output**: Creates `rpms.lock.yaml` with locked RPM versions.
- **Optional**: Use a custom `BASE_IMAGE` as in Step 1.

### Commit Changes
After completing the RPM lock file steps, commit the generated files to `git`:

```bash
git add ubi.repo rpms.in.yaml rpms.lock.yaml
git commit -m "Add generated RPM lock files"
```

# Changelog

All notable changes to Reel are documented here.

## v1.1.0

### New Features

- **Cron shorthand in schedule annotations** — `@every 1h`, `@daily`, `@hourly`, `@weekly`, `@monthly`, `@midnight` now work alongside standard 5-field cron expressions.
- **Linux arm64 CLI binary** — standalone CLI now ships for both `linux/amd64` and `linux/arm64`.
- **Automated Helm chart publishing** — chart is now versioned, tagged, and pushed to `oci://docker.io/getreel/helm` automatically on release.

### Improvements

- **ClamAV auto-download on macOS** — downloads the official universal `.pkg` from ClamAV GitHub releases. No Homebrew required. Binaries are patched with the correct rpath and ad-hoc re-signed automatically.
- **ClamAV auto-download on Linux arm64** — downloads the official `aarch64.deb`. Previously required manual installation.
- **CVD certificate handling** — uses `CVD_CERTS_DIR` environment variable instead of writing to system paths. No sudo required for ClamAV database updates.
- **Homebrew formula** — now includes `linux/arm64` alongside `darwin/arm64` and `linux/amd64`.
- **Test fixture optimization** — pre-pull images at test start, `imagePullPolicy: IfNotPresent` on all fixtures, CRI-O registry config fix.

### Bug Fixes

- **Helm chart image tags** — init container tags now use `v` prefix to match Docker Hub (was causing `ImagePullBackOff` on `init-criu`).
- **Helm chart publish** — only updates `getreel/*` image tags, no longer overwrites `clamav/clamav` tag.

## v1.0.1

### Bug Fixes

- **macOS ClamAV PKCS7 errors** — fixed certificate verification noise during `freshclam` database updates by setting `CVD_CERTS_DIR` to the extracted cert from the official package.
- **Release pipeline** — `fetch-depth: 0` for tag checkout, idempotent release creation, explicit token auth for Helm chart push.

## v1.0.0

Initial release.

### Standalone CLI

- `reel export sbom` — SBOM generation via Trivy (CycloneDX, SPDX)
- `reel export cbom` — Cryptographic bill of materials
- `reel export malware` — ClamAV malware scanning
- `reel export sarif` — Vulnerability scan with SARIF output
- `reel list images` — Local container images
- `reel list workloads` — Running containers

### Agent Mode

- Kubernetes DaemonSet deployment via Helm (`oci://docker.io/getreel/helm`)
- Annotation-driven scheduling (`reel.io/schedule`)
- Container checkpoints via CRIU
- Filesystem layer capture and restore
- Frame archives
- Volatile data and metadata capture
- S3 evidence vault archival
- ClamAV sidecar for daemon-based malware scanning

### Distribution

- `brew install getreeldev/tap/reel` (macOS arm64)
- `curl` from `getreeldev/releases` (Linux amd64)
- `uses: getreeldev/releases@v1` (GitHub Action)
- `helm install reel oci://docker.io/getreel/helm` (Kubernetes agent)

### Infrastructure

- Netavark stub for buildah on Alpine
- Raised `fs.inotify.max_user_instances` for CRIU checkpoint support
- Runtime detection fix for CRI-O (`crio` without hyphen)

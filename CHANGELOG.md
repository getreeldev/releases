# Changelog

All notable changes to Reel are documented here.

## v1.3.0

### GitHub Action

- **`local` input** — new pass-through for `reel export --local`. When `true`, image scans are restricted to the runner's container daemon and fail fast if the image isn't present. Default is `false`; with no flag set, reel CLI v1.3+ already looks locally first and falls back to the registry — so CI workflows that build an image in the runner and immediately scan it no longer need any special configuration.

### Compatibility

- Requires reel CLI `v1.3.0` or later in the runner (delivered via `reel-version: latest` by default). Earlier CLIs on `cbom` / `malware` don't recognize `--local`; setting `local: true` against a pinned older version will error.

### Housekeeping

- Removed `test-action.sh` — the jq-based gate tests duplicated trivial expressions and the reel-backed tests depended on drifting upstream CVE state; nothing in CI invoked the script. End-to-end validation now rides on downstream callers (e.g. vex-hub's release workflow).

## v1.2.0

### Standalone CLI — macOS container scanning

- **Scan running containers on macOS.** `reel export sbom|cbom|malware <container>` now works against Docker Desktop, OrbStack, Colima, and Rancher Desktop. Previously the container's overlay filesystem lived inside the Linux VM and wasn't reachable from the host. The CLI now uses the Docker API as a fallback when direct filesystem access isn't available — `docker commit` + `docker save` + `trivy image --input` for SBOMs (preserves the writable layer); `CopyFromContainer(/)` + safe tar extract for CBOM and malware. Linux behavior is unchanged: GraphDriver / `/proc/{pid}/root` remain the fast path.
- **Auto-detection of Docker socket on macOS.** Probes `~/.orbstack/run/docker.sock`, `~/.docker/run/docker.sock`, `~/.colima/default/docker.sock`, `~/.rd/docker.sock`. `DOCKER_HOST=unix://...` is now honored on all platforms.
- **Intel Mac (darwin/amd64) binary.** `reel_darwin_amd64.tar.gz` ships alongside `reel_darwin_arm64.tar.gz`. `brew install getreeldev/tap/reel` now works on both Intel and Apple Silicon Macs.

### GitHub Action

- **`fail-on-findings` input** — fail the workflow step if any vulnerabilities or malware survive the scan filters. Scans always complete and produce artifacts; the gate evaluates after.
- **`scanners` input** — passthrough to Trivy `--scanners` (vuln, secret, license, config, all).
- **`severity` input** — passthrough to Trivy `--severity` (LOW, MEDIUM, HIGH, CRITICAL).
- **Structured outputs** — `sbom-file`, `sarif-file`, `malware-file` (paths), `vuln-count`, `malware-count` (counts).

### Notes

- `reel export checkpoint|frame|memory` still require agent mode on Linux — they need CRIU and kernel access that cannot be emulated via the Docker API.
- Runtime tar extraction is conservative: zip-slip rejected, absolute/`..` symlinks skipped, device nodes skipped, setuid bits stripped, 5 GiB size cap.

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

# Reel

Kubernetes continuous compliance. Captures container state — SBOMs, cryptographic inventories, vulnerability scans, and malware detection — before pods disappear.

## Install

```bash
curl -sL https://github.com/getreeldev/releases/releases/latest/download/reel_linux_amd64.tar.gz | tar xz && sudo mv reel /usr/local/bin/
```

Verify:

```bash
reel version
reel status
```

## Quick Start

```bash
# Generate an SBOM
reel export sbom --image nginx:latest -o sbom.json

# Vulnerability scan (SARIF output)
reel export sarif --image nginx:latest -o results.sarif

# Cryptographic bill of materials
reel export cbom --image nginx:latest -o cbom.json

# Malware detection
reel export malware --image nginx:latest -o malware.json
```

## GitHub Action

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write   # required when scan-types includes `sarif`
    steps:
      - uses: getreeldev/releases@v1
        with:
          image: myapp:${{ github.sha }}
          scan-types: sbom,cbom,sarif,malware
          fail-on-findings: true

      - uses: actions/upload-artifact@v4
        with:
          name: security-reports
          path: reel-results/
```

### Required permissions

When `scan-types` includes `sarif`, the caller must grant `security-events: write` so findings upload to GitHub Code Scanning. Without it, the upload step fails.

### Two-layer gating

The action supports two complementary gates:

| Gate | Trigger | What fails | Dismissal-aware |
|---|---|---|---|
| **Workflow run** | `fail-on-findings: true` on the action | Any SBOM vulns or malware hits after filters | No |
| **PR merge** | "Code Scanning results" status check in branch protection | GCS alerts from uploaded SARIF, above repo's configured severity threshold | Yes |

For most consumers: enable both. The workflow gate gives fast feedback on the CI run; the PR gate is triage-friendly — dismissals in the Security tab persist across runs, and the severity threshold is configurable per-repo.

### Outputs

| Output | Description |
|---|---|
| `sbom-file` | Path to `sbom.json` if generated |
| `sarif-file` | Path to `results.sarif` if generated |
| `cbom-file` | Path to `cbom.json` if generated |
| `malware-file` | Path to `malware.json` if generated |
| `vuln-count` | Vulnerability count from SBOM (emitted on every run) |
| `malware-count` | Infected file count from malware scan (emitted on every run) |

### Scan summary

Each run appends a readable markdown summary to the Actions run page (`$GITHUB_STEP_SUMMARY`), covering all four scan types with per-scan findings counts and a sorted list of the top vulnerabilities when findings exist.

See [GitHub Action docs](https://getreel.dev/docs/github-action) for full configuration options.

## Documentation

Full documentation at [getreel.dev/docs](https://getreel.dev/docs).

## License

Proprietary. See [LICENSE](LICENSE) for terms.

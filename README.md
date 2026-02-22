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
- uses: getreeldev/releases@v1
  with:
    image: myapp:${{ github.sha }}
    scan-types: sbom,cbom,sarif,malware

- uses: actions/upload-artifact@v4
  with:
    name: security-reports
    path: reel-results/
```

See [GitHub Action docs](https://getreel.dev/docs/github-action) for full configuration options.

## Documentation

Full documentation at [getreel.dev/docs](https://getreel.dev/docs).

## License

Proprietary. See [LICENSE](LICENSE) for terms.

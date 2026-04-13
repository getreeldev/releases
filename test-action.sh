#!/usr/bin/env bash
# Test the GitHub Action gate logic locally using Docker.
# Runs reel inside a Linux container, scans real images, and validates
# that the fail-on-findings jq expressions produce correct results.
#
# Usage:
#   ./test-action.sh                    # run all tests
#   ./test-action.sh --reel-version v1.1.0  # pin reel version

set -euo pipefail

REEL_VERSION="v1.1.0"
if [ "${1:-}" = "--reel-version" ]; then
  REEL_VERSION="${2:-v1.1.0}"
fi

echo "=== Reel Action Local Tests ==="
echo "reel version: $REEL_VERSION"
echo ""

# Run all tests inside a single container to avoid repeated setup
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ubuntu:22.04 bash -c "
set -euo pipefail

# Setup
apt-get update -qq && apt-get install -yqq curl jq docker.io > /dev/null 2>&1
curl -sL https://github.com/getreeldev/releases/releases/download/${REEL_VERSION}/reel_linux_amd64.tar.gz | tar xz
mv reel /usr/local/bin/
echo \"reel \$(reel version 2>&1 | head -1)\"
echo ''

mkdir -p /tmp/results

# --- Test 1: Vulnerable image produces findings ---
echo 'Test 1: Vulnerable image with --severity CRITICAL'
reel export sbom --image nginx:1.21 --scanners vuln --severity CRITICAL -f cyclonedx -o /tmp/results/vuln-sbom.json 2>&1 | tail -1
COUNT=\$(jq '.vulnerabilities // [] | length' /tmp/results/vuln-sbom.json)
if [ \"\$COUNT\" -gt 0 ]; then
  echo \"  PASS: Found \$COUNT critical vulnerabilities (expected >0)\"
else
  echo \"  FAIL: Expected vulnerabilities, got 0\"
  exit 1
fi

# --- Test 2: Clean image produces no findings ---
echo ''
echo 'Test 2: Clean image with --severity CRITICAL'
reel export sbom --image alpine:3.21 --scanners vuln --severity CRITICAL -f cyclonedx -o /tmp/results/clean-sbom.json 2>&1 | tail -1
COUNT=\$(jq '.vulnerabilities // [] | length' /tmp/results/clean-sbom.json)
if [ \"\$COUNT\" -eq 0 ]; then
  echo \"  PASS: No critical vulnerabilities (expected 0)\"
else
  echo \"  FAIL: Expected 0 vulnerabilities, got \$COUNT\"
  exit 1
fi

# --- Test 3: Severity filter actually filters ---
echo ''
echo 'Test 3: Severity filtering (CRITICAL vs all)'
reel export sbom --image nginx:1.21 --scanners vuln -f cyclonedx -o /tmp/results/all-sbom.json 2>&1 | tail -1
ALL=\$(jq '.vulnerabilities // [] | length' /tmp/results/all-sbom.json)
CRIT=\$(jq '.vulnerabilities // [] | length' /tmp/results/vuln-sbom.json)
if [ \"\$ALL\" -gt \"\$CRIT\" ]; then
  echo \"  PASS: All severities=\$ALL, critical only=\$CRIT (filter works)\"
else
  echo \"  FAIL: Expected all (\$ALL) > critical (\$CRIT)\"
  exit 1
fi

# --- Test 4: Malware gate - clean ---
echo ''
echo 'Test 4: Malware gate (clean)'
echo '{\"summary\":{\"infected_count\":0},\"infected_files\":[]}' > /tmp/results/clean-malware.json
COUNT=\$(jq '.summary.infected_count // 0' /tmp/results/clean-malware.json)
if [ \"\$COUNT\" -eq 0 ]; then
  echo \"  PASS: No malware (expected 0)\"
else
  echo \"  FAIL: Expected 0 infected, got \$COUNT\"
  exit 1
fi

# --- Test 5: Malware gate - infected ---
echo ''
echo 'Test 5: Malware gate (infected)'
echo '{\"summary\":{\"infected_count\":3},\"infected_files\":[{\"path\":\"/bad1\"},{\"path\":\"/bad2\"},{\"path\":\"/bad3\"}]}' > /tmp/results/infected-malware.json
COUNT=\$(jq '.summary.infected_count // 0' /tmp/results/infected-malware.json)
if [ \"\$COUNT\" -gt 0 ]; then
  echo \"  PASS: Found \$COUNT infected files (expected >0)\"
else
  echo \"  FAIL: Expected infected files, got 0\"
  exit 1
fi

# --- Test 6: Missing vulnerabilities key handled ---
echo ''
echo 'Test 6: SBOM without vulnerabilities key'
echo '{\"bomFormat\":\"CycloneDX\",\"components\":[]}' > /tmp/results/no-vulns.json
COUNT=\$(jq '.vulnerabilities // [] | length' /tmp/results/no-vulns.json)
if [ \"\$COUNT\" -eq 0 ]; then
  echo \"  PASS: No vulnerabilities key handled correctly\"
else
  echo \"  FAIL: Expected 0, got \$COUNT\"
  exit 1
fi

# --- Test 7: Empty vulnerabilities array ---
echo ''
echo 'Test 7: SBOM with empty vulnerabilities array'
echo '{\"vulnerabilities\":[]}' > /tmp/results/empty-vulns.json
COUNT=\$(jq '.vulnerabilities // [] | length' /tmp/results/empty-vulns.json)
if [ \"\$COUNT\" -eq 0 ]; then
  echo \"  PASS: Empty vulnerabilities array handled correctly\"
else
  echo \"  FAIL: Expected 0, got \$COUNT\"
  exit 1
fi

echo ''
echo '=== All 7 tests passed ==='
"

echo ""
echo "Local action tests completed successfully."

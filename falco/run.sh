#!/usr/bin/env bash
# Run Falco on the Docker host that runs OpenShell sandboxes (Linux host, or the
# colima / Docker Desktop VM on macOS). Needs a kernel with BTF (modern eBPF).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
image="${FALCO_IMAGE:-falcosecurity/falco:0.45.0}"
name="${FALCO_NAME:-openshell-falco}"
docker rm -f "$name" >/dev/null 2>&1 || true
# The rules dir must be visible to the Docker daemon (on colima: under $HOME).
# rule_matching=all: by default only the first matching rule fires, and stock rules
# (e.g. "Drop and execute new binary in container") would hide the OpenShell ones.
exec docker run --rm --name "$name" --privileged --pid=host \
  -v /var/run/docker.sock:/host/var/run/docker.sock \
  -v /proc:/host/proc:ro -v /etc:/host/etc:ro \
  -v "$here/openshell_rules.yaml:/etc/falco/rules.d/openshell_rules.yaml:ro" \
  "$image" falco -o engine.kind=modern_ebpf -o rule_matching=all "$@"

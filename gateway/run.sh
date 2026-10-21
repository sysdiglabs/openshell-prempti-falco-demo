#!/usr/bin/env bash
# Start a local OpenShell gateway (Docker driver) unless one is already listening.
set -euo pipefail

port=17670
state="${XDG_STATE_HOME:-$HOME/.local/state}/openshell"
config="${XDG_CONFIG_HOME:-$HOME/.config}/openshell/gateway.toml"
log="$state/gateway.log"
tls="$state/tls"

if nc -z 127.0.0.1 "$port" 2>/dev/null; then
  echo "Gateway already running on 127.0.0.1:$port (a launchd agent or a previous 'just gateway'); nothing to do."
  exit 0
fi

docker_version="$(docker version --format '{{.Server.Version}}' 2>/dev/null || true)"
if [ "${docker_version%%.*}" -lt 28 ] 2>/dev/null; then
  echo "Warning: Docker $docker_version; OpenShell 0.1.2 needs 28+ (sandbox creation fails on 27.x)." >&2
fi

mkdir -p "$state" "$(dirname "$config")"

# mTLS + sandbox JWT bundle. Idempotent.
openshell-gateway generate-certs --output-dir "$tls" --server-san host.openshell.internal

# Inside colima 127.0.0.1 is the VM, so sandboxes call back through host.docker.internal.
if [ ! -f "$config" ]; then
  echo "Writing $config"
  cat >"$config" <<TOML
[openshell]
version = 2

[openshell.gateway]
compute_driver = "docker"
server_sans = ["host.openshell.internal"]

[openshell.gateway.tls]
cert_path = "$tls/server/tls.crt"
key_path = "$tls/server/tls.key"
client_ca_path = "$tls/ca.crt"

[openshell.gateway.gateway_jwt]
signing_key_path = "$tls/jwt/signing.pem"
public_key_path = "$tls/jwt/public.pem"
kid_path = "$tls/jwt/kid"

[openshell.drivers.docker]
grpc_endpoint = "https://host.docker.internal:$port"
TOML
fi

OPENSHELL_GATEWAY_CONFIG="$config" nohup openshell-gateway >"$log" 2>&1 &
echo "Started gateway (pid $!), log: $log"

for _ in $(seq 20); do
  nc -z 127.0.0.1 "$port" 2>/dev/null && break
  sleep 0.5
done
nc -z 127.0.0.1 "$port" 2>/dev/null || { echo "Gateway did not come up; see $log" >&2; exit 1; }

# Register the CLI once (TLS stays on: with JWT enabled a plaintext CLI is rejected).
if ! openshell gateway list 2>/dev/null | grep -qw local; then
  openshell gateway add "https://127.0.0.1:$port" --local --name local
fi
openshell gateway select local
openshell status

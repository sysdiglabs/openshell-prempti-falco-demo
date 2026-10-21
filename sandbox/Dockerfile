# Claude Code sandbox for NVIDIA OpenShell, guarded by Prempti (Falco for AI coding agents).
ARG BASE_IMAGE=ghcr.io/nvidia/openshell-community/sandboxes/base:latest
FROM ${BASE_IMAGE}

ARG PREMPTI_VERSION=0.2.1
ARG PREMPTI_SHA256_aarch64=a7da1101e63e96f0462ccfe95b1ce51a9877e3906ede4059a4b1af67d3c7ece1
ARG PREMPTI_SHA256_x86_64=6f3b3cb37b791d74cf0ae99ee4cedcda388f185f2bb1a95a790889bec77e40fa

USER root
# Root-owned install so the agent (uid sandbox) cannot edit Prempti binaries, config or rules.
# Only run/ and log/ are writable, via /tmp.
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in aarch64) sum="$PREMPTI_SHA256_aarch64" ;; x86_64) sum="$PREMPTI_SHA256_x86_64" ;; *) exit 1 ;; esac; \
    tgz="prempti-${PREMPTI_VERSION}-linux-${arch}.tar.gz"; \
    curl -fsSL -o "/tmp/$tgz" "https://github.com/falcosecurity/prempti/releases/download/v${PREMPTI_VERSION}/$tgz"; \
    echo "$sum  /tmp/$tgz" | sha256sum -c -; \
    mkdir /tmp/pkg; tar -xzf "/tmp/$tgz" -C /tmp/pkg --strip-components=1; \
    P=/opt/prempti; \
    mkdir -p $P/bin $P/config $P/share $P/rules/default $P/rules/user; \
    install -m 0755 /tmp/pkg/bin/* $P/bin/; \
    install -m 0644 /tmp/pkg/share/libcoding_agent.so $P/share/; \
    install -m 0644 /tmp/pkg/config/*.yaml $P/config/; \
    install -m 0644 /tmp/pkg/rules/default/coding_agents_rules.yaml $P/rules/default/; \
    install -m 0644 /tmp/pkg/rules/seen.yaml $P/rules/; \
    ln -s /tmp/prempti/run $P/run; ln -s /tmp/prempti/log $P/log; \
    ln -s $P /sandbox/.prempti; \
    rm -rf /tmp/pkg "/tmp/$tgz"

COPY --chmod=0644 prempti-rules/openshell.yaml /opt/prempti/rules/user/openshell.yaml

# Prempti hook in Claude Code managed settings: root-owned, so it survives the daemon
# removing its own hook on SIGTERM, and every tool call is denied while the daemon is down.
# COPY --chmod would also create the directory as 0644 (not traversable).
RUN install -d -m 0755 /etc/claude-code
COPY --chmod=0644 managed-settings.json /etc/claude-code/managed-settings.json

# Image policy: used when the gateway has no policy for the sandbox (no --policy needed).
COPY --chmod=0644 policy.yaml /etc/openshell/policy.yaml
COPY --chmod=0755 claude-prempti /usr/local/bin/claude-prempti
USER sandbox

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git jq build-essential \
    python3.12 python3-pip \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# .NET 8 — installed via Microsoft's signed APT repository.
# The GPG key is downloaded then fingerprint-verified before trusting it.
# Expected fingerprint: BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF
# Source: https://learn.microsoft.com/en-us/linux/packages
RUN apt-get update && apt-get install -y ca-certificates gnupg \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
       -o /tmp/microsoft.asc \
    && gpg --no-default-keyring \
           --keyring /tmp/ms-verify.gpg \
           --import /tmp/microsoft.asc \
    && gpg --no-default-keyring \
           --keyring /tmp/ms-verify.gpg \
           --fingerprint "BC528686B50D79E339D3721CEB3E94ADBE1229CF" \
    && gpg --dearmor < /tmp/microsoft.asc > /usr/share/keyrings/microsoft.gpg \
    && rm -f /tmp/microsoft.asc /tmp/ms-verify.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
       https://packages.microsoft.com/repos/microsoft-ubuntu-noble-prod noble main" \
       > /etc/apt/sources.list.d/microsoft-prod.list \
    && apt-get update && apt-get install -y dotnet-sdk-8.0 \
    && rm -rf /var/lib/apt/lists/*

# uv — installed via pip (PyPI, TLS-verified) to avoid curl|bash
RUN pip3 install --break-system-packages uv

# Claude Code
RUN npm install -g @anthropic-ai/claude-code@2.1.92

# GitHub Copilot CLI
RUN npm install -g @githubnext/github-copilot-cli@0.1.36

# OpenCode
RUN npm install -g opencode-ai@1.3.13

# Run as non-root user; UID 1000 matches the typical dev host user
RUN useradd -m -s /bin/bash agent
USER agent

WORKDIR /workspace
CMD ["/bin/bash"]

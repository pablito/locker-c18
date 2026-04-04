FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git jq build-essential \
    python3.12 python3-pip \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# .NET 8 — installed via Microsoft's signed APT repository (GPG-verified)
RUN apt-get update && apt-get install -y ca-certificates gnupg \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
       | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
       https://packages.microsoft.com/repos/microsoft-ubuntu-noble-prod noble main" \
       > /etc/apt/sources.list.d/microsoft-prod.list \
    && apt-get update && apt-get install -y dotnet-sdk-8.0 \
    && rm -rf /var/lib/apt/lists/*

# uv — installed via pip (PyPI, TLS-verified) to avoid curl|bash
RUN pip3 install --break-system-packages uv

# Claude Code
RUN npm install -g @anthropic-ai/claude-code

# GitHub Copilot CLI
RUN npm install -g @githubnext/github-copilot-cli

# OpenCode
RUN npm install -g opencode-ai

# Run as non-root user; UID 1000 matches the typical dev host user
RUN useradd -m -s /bin/bash agent
USER agent

WORKDIR /workspace
CMD ["/bin/bash"]

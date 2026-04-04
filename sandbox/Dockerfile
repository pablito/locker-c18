FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl git jq build-essential \
    python3.12 python3-pip \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# .NET 8
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash -s -- \
    --channel 8.0 --install-dir /usr/share/dotnet
ENV PATH="$PATH:/usr/share/dotnet"
ENV DOTNET_ROOT="/usr/share/dotnet"

# uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="$PATH:/root/.local/bin"

# Claude Code
RUN npm install -g @anthropic-ai/claude-code

# GitHub Copilot CLI
RUN npm install -g @githubnext/github-copilot-cli

# OpenCode
RUN npm install -g opencode-ai

WORKDIR /workspace
CMD ["/bin/bash"]

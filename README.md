# Agent DevBox

Ambiente di sviluppo isolato e riproducibile per agenti AI.
Supporta Claude Code, GitHub Copilot CLI e OpenCode su Linux e WSL2.

## Prerequisiti

- Linux (Ubuntu 22.04+, Debian, Fedora, Arch) oppure WSL2 su Windows
- Docker Engine in esecuzione
- Connessione internet per il primo setup

## Setup (una volta sola)

```bash
git clone https://github.com/TUO_ORG/agent-devbox
cd agent-devbox
bash scripts/setup.sh
```

Apri un nuovo terminale e torna nella cartella: il devbox shell si attiverà automaticamente tramite direnv.

## Utilizzo

```bash
# Agenti direttamente nel devbox shell
claude          # Claude Code
opencode        # OpenCode
copilot         # GitHub Copilot CLI

# Agente in container isolato (permessi massimi, zero impatto sull'host)
devbox run sandbox -- claude
devbox run sandbox -- opencode

# Reset ambiente
devbox run reset
```

## API Keys

Crea un file `.env` nella root (non viene committato):

```bash
ANTHROPIC_API_KEY=sk-ant-...
GITHUB_TOKEN=ghp_...
OPENAI_API_KEY=sk-...
```

## WSL2

Tieni il repo dentro il filesystem WSL (`~/`, non `/mnt/c/`) per performance ottimali.

## MCP Servers inclusi

| Server     | Funzione                        |
|------------|---------------------------------|
| filesystem | Accesso ai file del progetto    |
| git        | Operazioni git                  |
| fetch      | Richieste HTTP                  |
| memory     | Memoria persistente tra sessioni|
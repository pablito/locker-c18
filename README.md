# Locker C18

<p align="center">
  <img src="logo.svg" alt="Locker C18 logo" width="160"/>
</p>

> *"You are the man who would be king of the train locker."*
> — Men in Black II (2002)

Ambiente di sviluppo isolato e riproducibile per agenti AI.
Supporta Claude Code, GitHub Copilot CLI e OpenCode su Linux e WSL2.

Come l'armadietto C-18 della Grand Central Station nel film, questo ambiente contiene molto più di quanto sembri dall'esterno: un universo completo di tool, runtime e agenti AI, accessibile con un singolo comando.

## Prerequisiti

- Linux (Ubuntu 22.04+, Debian, Fedora, Arch) oppure WSL2 su Windows
- Docker Engine in esecuzione
- Connessione internet per il primo setup
- **[devbox](https://www.jetify.com/docs/devbox/installing-devbox)** installato

## Setup (una volta sola)

1. Installa devbox seguendo le [istruzioni ufficiali](https://www.jetify.com/docs/devbox/installing-devbox).

2. Clona il repo e avvia il setup:

```bash
git clone https://github.com/TUO_ORG/locker-c18
cd locker-c18
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

> **Nota sandbox:** il container isolato espone solo `ANTHROPIC_API_KEY` per default.
> Se hai bisogno di altre chiavi nel container, passale esplicitamente con `-e`:
> `devbox run sandbox -- bash -c "docker run ... -e GITHUB_TOKEN ..."`

## WSL2

Tieni il repo dentro il filesystem WSL (`~/`, non `/mnt/c/`) per performance ottimali.

## MCP Servers inclusi

| Server     | Funzione                        |
|------------|---------------------------------|
| filesystem | Accesso ai file del progetto    |
| git        | Operazioni git                  |
| fetch      | Richieste HTTP                  |
| memory     | Memoria persistente tra sessioni|

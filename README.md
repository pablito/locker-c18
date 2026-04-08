# Locker C18

<p align="center">
  <img src="logo.svg" alt="Locker C18 logo" width="160"/>
</p>

> *"You are the man who would be king of the train locker."*
> — Men in Black II (2002)

Skill generica per configurare ambienti di sviluppo AI-driven da un catalogo di template.
Funziona con Claude Code, GitHub Copilot CLI e OpenCode su Linux e WSL2.

Come l'armadietto C-18 della Grand Central Station nel film, questo ambiente contiene molto più di quanto sembri dall'esterno: un universo completo di tool, runtime e agenti AI, accessibile con un singolo comando.

## Utilizzo (skill)

### 1. Installa la skill (una volta sola)

```bash
# Claude Code
claude skill install github:TUO_ORG/locker-c18

# GitHub Copilot CLI
copilot skill install github:TUO_ORG/locker-c18

# OpenCode
opencode skill install github:TUO_ORG/locker-c18
```

### 2. In un repo vuoto, avvia il setup interattivo

```
/locker
```

La skill presenta il catalogo dei template disponibili, riceve la tua scelta e configura il repo automaticamente — senza sovrascrivere file già esistenti.

### 3. Completa il setup

```bash
bash scripts/setup.sh
```

Apri un nuovo terminale: il devbox shell si attiverà automaticamente tramite direnv.

## Prerequisiti

- Linux (Ubuntu 22.04+, Debian, Fedora, Arch) oppure WSL2 su Windows
- **[devbox](https://www.jetify.com/docs/devbox/installing-devbox)** installato
- **[direnv](https://direnv.net/docs/installation.html)** installato e configurato nella shell
- Docker Engine in esecuzione

## Template disponibili

| ID   | Nome                              | Stack                              |
|------|-----------------------------------|------------------------------------|
| a-01 | AI Dev Environment — Full Stack   | Python 3.12 · Node 20 · .NET 8 · Docker sandbox |

## Utilizzo (ambiente)

Una volta configurato il repo con `/locker`, l'ambiente offre:

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

> La memoria persistente usa `bd remember` / `bd memories` (beads) — non un MCP memory server.

## Aggiungere template

1. Crea una cartella in `templates/<id>/` con tutti i file di scaffolding
2. Registra il template in `templates/catalog.yaml` con id, nome, descrizione, lista file e prerequisiti
3. Apri una PR al repo locker

### Naming convention — formato `x-yy`

Gli ID dei template seguono il formato `x-yy`: una singola lettera seguita da due cifre (es. `a-01`, `c-18`, `z-42`).

**La lettera NON ha significato semantico.** Non indica una categoria, un tipo o una versione.
È parte di un identificatore arbitrario — come i numeri degli armadietti della Grand Central Station in *Men in Black II*.
Il nome del repo stesso (`locker-c18`) usa questa convenzione: l'armadietto C-18 conteneva un universo intero.

**Regola pratica:** scegli una lettera e due cifre non ancora usate. La coerenza del formato conta più della logica della scelta.

### Registro ID assegnati

| ID   | Template                          |
|------|-----------------------------------|
| a-01 | AI Dev Environment — Full Stack   |

Aggiorna questa tabella quando aggiungi un nuovo template per evitare collisioni.

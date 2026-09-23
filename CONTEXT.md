# Locker

Locker configura un repository perché un team possa lavorarci con agenti AI in un comando solo. Il catalogo è curato da poche persone e consumato da molte.

## Language

**Locker**:
Il prodotto: ciò che il Consumer invoca per configurare un repo.
_Avoid_: framework, devbox environment, locker-c18 (è il nome del repo, non del prodotto)

**Curator**:
Chi cura il catalogo: crea, rivede e versiona i Template per l'organizzazione.
_Avoid_: team lead, maintainer

**Consumer**:
Chi lancia il comando in un repo per configurarlo.
_Avoid_: developer, utente, sviluppatore

**Template**:
Un'unità del catalogo, identificata da un id `x-yy`, che descrive come configurare un repo per un tipo di progetto.
_Avoid_: archetype, environment, locker (il singolo template non è "un locker")

**Catalog**:
L'insieme dei Template disponibili a un Consumer, con i loro metadati.
_Avoid_: registry, bank

**Target repo**:
Il repository su cui il Consumer lancia il comando e in cui Locker scrive.
_Avoid_: target-dir, progetto, workspace

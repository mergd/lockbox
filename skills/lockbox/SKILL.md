---
name: lockbox
description: >-
  Manage SOPS secrets and encrypted documents via the lockbox CLI with
  1Password. Use when working in repos with .lockbox/, encrypting secrets or
  PDFs, running lockbox commands, setting up new secret repos, or when the user
  mentions lockbox, SOPS, age encryption, or encrypted documents.
---

# lockbox

Cross-repo CLI for SOPS secrets + age-encrypted documents. Private keys bootstrap from 1Password and cache locally in `.lockbox/age.key`; encrypted files go to GitHub.

Install CLI: `brew tap mergd/lockbox https://github.com/mergd/lockbox && brew install --HEAD mergd/lockbox/lockbox`

Install this skill in a project: `lockbox skill install` → `.agents/skills/lockbox/SKILL.md`

## Before any secret/doc operation

```bash
lockbox where
```

Run from inside the project. lockbox walks up to find `.lockbox/config.env`. If `.lockbox/age.key` is missing, run `eval "$(op signin)"` then `lockbox setup` to sync it from 1Password.

## Architecture

| Where | What |
|-------|------|
| GitHub | `secrets/*`, `documents/records/**/*.age`, `.sops.yaml` |
| 1Password | Bootstrap copy of age private key (`OP_ITEM` in config) |
| `.lockbox/age.key` | Local age private key cache (gitignored) |
| `documents/local/` | Decrypted workspace (gitignored) |
| `documents/inbox/` | Intake (gitignored) |

## Commands

```bash
lockbox setup
lockbox secret edit|new|decrypt|encrypt <file>
lockbox doc add|checkout|sync|open|list
lockbox where
```

## Agent rules

**Do:** use `lockbox` commands; run `lockbox setup` after signing into 1Password when `.lockbox/age.key` is missing; commit only encrypted `secrets/` and `documents/records/`; edit docs in `documents/local/` then `lockbox doc sync --all`

**Do not:** commit `documents/local/`, `documents/inbox/`, `.lockbox/local.env`, `.lockbox/age.key`, plaintext files, or private keys

## Workflows

**New project:** `lockbox init` → `lockbox setup` → `lockbox skill install` → `direnv allow`

**Add doc:** inbox → `lockbox doc add documents/inbox/...` → commit `.age`

**Edit doc:** `lockbox doc checkout --all` → edit `documents/local/` → `lockbox doc sync --all` → commit

## Config (`.lockbox/config.env`)

```bash
OP_VAULT=Personal
OP_ITEM=<project>-sops-age-key
SECRETS_DIR=secrets
DOCUMENTS_DIR=documents
```

Also read project `AGENTS.md` if present.

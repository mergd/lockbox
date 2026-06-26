# lockbox

SOPS + 1Password CLI for secrets and encrypted documents. Works across any repo with a `.lockbox/` config.

## Install

```bash
brew tap mergd/lockbox https://github.com/mergd/lockbox
brew trust mergd/lockbox
brew install --HEAD mergd/lockbox/lockbox
brew install --cask 1password-cli
```

Requires: `sops`, `age`, `jq` (brew dependencies).

## Agent skill

The skill ships with lockbox at `skills/lockbox/SKILL.md`. Install into each project:

```bash
lockbox skill install   # writes .agents/skills/lockbox/SKILL.md
```

Commit `.agents/skills/lockbox/` in project repos so agents load it from the repo.

## New project

```bash
cd your-repo
lockbox init my-project
eval "$(op signin)"
lockbox setup
```

Creates `.lockbox/config.env`, directory layout, and gitignore rules.

## Usage

```bash
# Secrets (SOPS)
lockbox secret edit secrets/production.env
lockbox secret new secrets/staging.env
lockbox secret decrypt secrets/production.env

# Documents (age + local workspace)
lockbox doc add documents/inbox/report.pdf
lockbox doc checkout --all
lockbox doc open report.pdf.age
lockbox doc sync --all

# Text notes (SOPS)
lockbox doc edit visit-notes.md
lockbox doc list

lockbox where    # show project root + config
```

## Local key cache

`lockbox setup` syncs the age private key from 1Password into `.lockbox/age.key` with `0600` permissions. After that, `lockbox secret` and `lockbox doc` commands use the local key cache and do not need an active 1Password session unless the cache is missing.

`.lockbox/age.key` is gitignored by `lockbox init`; never commit it.

## Project config

`.lockbox/config.env`:

```bash
OP_VAULT=Personal
OP_ITEM=my-project-sops-age-key
SECRETS_DIR=secrets
DOCUMENTS_DIR=documents
```

Optional `.lockbox/local.env` (gitignored) for `OP_ACCOUNT` and `LOCKBOX_AGE_KEY_FILE` overrides.

## direnv

```bash
# .envrc
dotenv .lockbox/config.env
dotenv_if_exists .lockbox/local.env
export SOPS_AGE_KEY_FILE="${LOCKBOX_AGE_KEY_FILE:-$PWD/.lockbox/age.key}"
```

## Architecture

| Location | Contents |
|----------|----------|
| GitHub | Encrypted `secrets/*`, `documents/records/*.age`, public key in `.sops.yaml` |
| 1Password | Bootstrap copy of age private key |
| `.lockbox/age.key` | Local age private key cache (gitignored) |
| `documents/local/` | Decrypted workspace (gitignored) |

# lockbox

SOPS + 1Password CLI for secrets and encrypted documents. Works across any repo with a `.lockbox/` config.

## Install

```bash
brew tap mergd/lockbox https://github.com/mergd/lockbox
brew trust mergd/lockbox
brew install --HEAD mergd/lockbox/lockbox
```

Requires: `sops`, `age`, `1password-cli`, `jq` (installed as dependencies).

Local dev:

```bash
git clone https://github.com/mergd/lockbox.git
brew tap mergd/lockbox "$(pwd)/lockbox"  # or symlink bin/lockbox to ~/bin
```

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

## Project config

`.lockbox/config.env`:

```bash
OP_VAULT=Personal
OP_ITEM=my-project-sops-age-key
SECRETS_DIR=secrets
DOCUMENTS_DIR=documents
```

Optional `.lockbox/local.env` (gitignored) for `OP_ACCOUNT` overrides.

## direnv

```bash
# .envrc
dotenv .lockbox/config.env
dotenv_if_exists .lockbox/local.env
export SOPS_AGE_KEY_CMD="op read --no-newline -- op://${OP_VAULT}/${OP_ITEM}/password"
```

## Architecture

| Location | Contents |
|----------|----------|
| GitHub | Encrypted `secrets/*`, `documents/records/*.age`, public key in `.sops.yaml` |
| 1Password | Age private key |
| `documents/local/` | Decrypted workspace (gitignored) |

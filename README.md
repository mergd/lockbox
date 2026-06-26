# lockbox

SOPS + 1Password CLI for secrets and encrypted documents. Works across any repo with a `.lockbox/` config.

## Install

**Note:** The tap clones from GitHub. If `mergd/lockbox` is **private**, you need GitHub auth (`gh auth login` or SSH keys). Consider making the lockbox repo **public** — it contains no secrets, only the CLI.

```bash
# Requires access to github.com/mergd/lockbox
brew tap mergd/lockbox https://github.com/mergd/lockbox
brew trust mergd/lockbox
brew install --HEAD mergd/lockbox/lockbox
brew install --cask 1password-cli   # not a brew formula
```

Requires: `sops`, `age`, `jq` (installed as dependencies).

**Without brew tap** (private repo, no auth):

```bash
git clone git@github.com:mergd/lockbox.git ~/dev/lockbox
ln -sf ~/dev/lockbox/bin/lockbox ~/bin/lockbox   # or add to PATH
```

Local dev tap:

```bash
git clone https://github.com/mergd/lockbox.git
brew tap mergd/lockbox "$(pwd)/lockbox"
brew install --HEAD mergd/lockbox/lockbox
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

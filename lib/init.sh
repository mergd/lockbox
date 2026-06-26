#!/usr/bin/env bash

lockbox_init() {
  local name="${1:-$(basename "$PWD")}"
  local item="${name}-sops-age-key"

  mkdir -p .lockbox secrets documents/inbox documents/local documents/records documents/text

  if [[ ! -f .lockbox/config.env ]]; then
    cat > .lockbox/config.env <<EOF
# lockbox project config
OP_VAULT=Personal
OP_ITEM=${item}
SECRETS_DIR=secrets
DOCUMENTS_DIR=documents
EOF
  fi

  if [[ ! -f .lockbox/local.env.example ]]; then
    cat > .lockbox/local.env.example <<'EOF'
# Copy to .lockbox/local.env (gitignored) for local overrides
OP_ACCOUNT=
# Optional override; default is .lockbox/age.key
LOCKBOX_AGE_KEY_FILE=
EOF
  fi

  if [[ ! -f .gitignore ]] || ! grep -q '\.lockbox/local\.env' .gitignore 2>/dev/null; then
    cat >> .gitignore <<'EOF'

# lockbox
.lockbox/local.env
.lockbox/age.key
secrets/**/*.dec.*
secrets/**/*.plain.*
documents/inbox/*
!documents/inbox/.gitkeep
documents/local/*
!documents/local/.gitkeep
documents/**/*.plain.*
documents/**/*.dec.*
EOF
  fi

  if [[ -f .gitignore ]] && ! grep -q '\.lockbox/age\.key' .gitignore 2>/dev/null; then
    cat >> .gitignore <<'EOF'
.lockbox/age.key
EOF
  fi

  echo "Initialized lockbox for: $name"
  echo "  .lockbox/config.env"
  echo "  OP_ITEM=$item"
  echo ""
  echo "Next:"
  echo "  eval \"\$(op signin)\""
  echo "  lockbox setup"
  echo "  lockbox skill install"
}

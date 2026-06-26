#!/usr/bin/env bash

lockbox_find_project_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.lockbox/config.env" ]]; then
      LOCKBOX_ROOT="$dir"
      export LOCKBOX_ROOT
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "No .lockbox/config.env found. Run: lockbox init" >&2
  exit 1
}

load_config() {
  # shellcheck source=/dev/null
  source "$LOCKBOX_ROOT/.lockbox/config.env"
  # shellcheck source=/dev/null
  [[ -f "$LOCKBOX_ROOT/.lockbox/local.env" ]] && source "$LOCKBOX_ROOT/.lockbox/local.env"

  SECRETS_DIR="${SECRETS_DIR:-secrets}"
  DOCUMENTS_DIR="${DOCUMENTS_DIR:-documents}"
  OP_VAULT="${OP_VAULT:-Personal}"
  OP_ITEM="${OP_ITEM:-$(basename "$LOCKBOX_ROOT")-sops-age-key}"
  LOCKBOX_AGE_KEY_FILE="${LOCKBOX_AGE_KEY_FILE:-$LOCKBOX_ROOT/.lockbox/age.key}"

  export OP_VAULT OP_ITEM SECRETS_DIR DOCUMENTS_DIR LOCKBOX_AGE_KEY_FILE
  export SOPS_AGE_KEY_OP_REF="op://${OP_VAULT}/${OP_ITEM}/password"
  if [[ -f "$LOCKBOX_AGE_KEY_FILE" ]]; then
    export SOPS_AGE_KEY_FILE="$LOCKBOX_AGE_KEY_FILE"
    unset SOPS_AGE_KEY_CMD
  else
    unset SOPS_AGE_KEY_FILE
    export SOPS_AGE_KEY_CMD="op read --no-newline -- ${SOPS_AGE_KEY_OP_REF}"
  fi
}

op_cmd() {
  if [[ -n "${OP_ACCOUNT:-}" ]]; then
    op --account "$OP_ACCOUNT" "$@"
  else
    op "$@"
  fi
}

require_op() {
  if [[ -f "${LOCKBOX_AGE_KEY_FILE:-}" ]]; then
    return 0
  fi

  if ! op_cmd whoami &>/dev/null; then
    echo "1Password CLI not signed in. Run:" >&2
    echo '  eval "$(op signin)"' >&2
    exit 1
  fi
}

op_item_id() {
  op_cmd item list --vault "$OP_VAULT" --format json \
    | jq -r --arg title "$OP_ITEM" '.[] | select(.title == $title) | .id' \
    | head -1
}

read_private_key() {
  if [[ -f "${LOCKBOX_AGE_KEY_FILE:-}" ]]; then
    cat "$LOCKBOX_AGE_KEY_FILE"
  elif [[ -n "${LOCKBOX_AGE_KEY:-}" ]]; then
    printf '%s' "$LOCKBOX_AGE_KEY"
  else
    op_cmd read --no-newline "$SOPS_AGE_KEY_OP_REF"
  fi
}

write_private_key_cache() {
  local key_material="$1"

  [[ -n "${LOCKBOX_AGE_KEY_FILE:-}" ]] || return 0
  mkdir -p "$(dirname "$LOCKBOX_AGE_KEY_FILE")"
  umask 077
  printf '%s' "$key_material" >"$LOCKBOX_AGE_KEY_FILE"
  chmod 600 "$LOCKBOX_AGE_KEY_FILE"
  export SOPS_AGE_KEY_FILE="$LOCKBOX_AGE_KEY_FILE"
  unset SOPS_AGE_KEY_CMD
}

public_key_from_private() {
  age-keygen -y -
}

public_key() {
  local key sops_yaml="$LOCKBOX_ROOT/.sops.yaml"
  key="$(grep -E '^\s+age:' "$sops_yaml" 2>/dev/null | head -1 | awk '{print $2}')"
  if [[ -z "$key" ]]; then
    echo "No public key in .sops.yaml — run: lockbox setup" >&2
    exit 1
  fi
  echo "$key"
}

age_encrypt_file() {
  age -r "$(public_key)" -o "$2" "$1"
}

age_decrypt_file() {
  local input="$1" output="$2" identity
  identity="$(mktemp)"
  chmod 600 "$identity"
  read_private_key >"$identity"
  age -d -i "$identity" -o "$output" "$input"
  rm -f "$identity"
}

ensure_sops_yaml() {
  local pubkey="$1" sops_yaml="$LOCKBOX_ROOT/.sops.yaml"

  if [[ -f "$sops_yaml" ]] && grep -qF "$pubkey" "$sops_yaml"; then
    return 0
  fi

  cat > "$sops_yaml" <<EOF
creation_rules:
  - path_regex: ${SECRETS_DIR}/.*\\.(yaml|yml|json|env|ini|toml)\$
    age: ${pubkey}
  - path_regex: ${DOCUMENTS_DIR}/text/.*\\.(md|txt|yaml|json)\$
    age: ${pubkey}
EOF
}

resolve_vault() {
  local requested="$1"

  if op_cmd vault get "$requested" &>/dev/null; then
    echo "$requested"
    return
  fi

  for fallback in Personal Private; do
    if [[ "$fallback" != "$requested" ]] && op_cmd vault get "$fallback" &>/dev/null; then
      echo "Vault '$requested' not found; using '$fallback'." >&2
      echo "$fallback"
      return
    fi
  done

  local first
  first="$(op_cmd vault list --format json | jq -r '.[0].name // empty')"
  if [[ -n "$first" ]]; then
    echo "Vault '$requested' not found; using '$first'." >&2
    echo "$first"
    return
  fi

  echo "No vaults found in this 1Password account." >&2
  exit 1
}

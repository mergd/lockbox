#!/usr/bin/env bash

lockbox_setup() {
  require_op

  local resolved_vault key_material pubkey existing_id
  resolved_vault="$(resolve_vault "$OP_VAULT")"

  if [[ "$resolved_vault" != "$OP_VAULT" ]]; then
    OP_VAULT="$resolved_vault"
    export OP_VAULT
    export SOPS_AGE_KEY_OP_REF="op://${OP_VAULT}/${OP_ITEM}/password"
  fi

  existing_id="$(op_item_id)"

  if [[ -n "$existing_id" ]]; then
    key_material="$(read_private_key)"
    pubkey="$(printf '%s' "$key_material" | public_key_from_private)"
    echo "Using existing 1Password item: $OP_ITEM"
  else
    local local_key="${HOME}/Library/Application Support/sops/age/keys.txt"

    if [[ -f "$local_key" ]]; then
      key_material="$(cat "$local_key")"
      echo "Uploading existing local age key to 1Password"
    else
      echo "Generating new age key"
      local tmp
      tmp="$(mktemp)"
      age-keygen -o "$tmp" >/dev/null
      key_material="$(cat "$tmp")"
      rm -f "$tmp"
    fi

    pubkey="$(printf '%s' "$key_material" | public_key_from_private)"
    echo "Creating 1Password item: $OP_ITEM in vault $OP_VAULT"
    op_cmd item create \
      --category=password \
      --vault="$OP_VAULT" \
      --title="$OP_ITEM" \
      password="$key_material" >/dev/null
  fi

  ensure_sops_yaml "$pubkey"

  echo ""
  echo "Ready."
  echo "  1Password: $SOPS_AGE_KEY_OP_REF"
  echo "  Public key: $pubkey"
  echo "  .sops.yaml: synced"
}

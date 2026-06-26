#!/usr/bin/env bash

lockbox_secret() {
  local cmd="${1:-}"
  shift || true

  case "$cmd" in
    edit)
      require_op
      sops "${1:?usage: lockbox secret edit <file>}"
      ;;
    decrypt)
      require_op
      sops --decrypt "${1:?usage: lockbox secret decrypt <file>}"
      ;;
    encrypt)
      require_op
      sops --encrypt --in-place "${1:?usage: lockbox secret encrypt <file>}"
      ;;
    new)
      require_op
      local file="${1:?usage: lockbox secret new <file>}"
      touch "$file"
      sops --encrypt --in-place "$file"
      sops "$file"
      ;;
    *)
      echo "usage: lockbox secret edit|new|decrypt|encrypt <file>" >&2
      exit 1
      ;;
  esac
}

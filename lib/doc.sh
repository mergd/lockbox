#!/usr/bin/env bash

lockbox_doc() {
  local cmd="${1:-}"
  shift || true

  local docs_dir="$LOCKBOX_ROOT/$DOCUMENTS_DIR"
  local records_dir="$docs_dir/records"
  local text_dir="$docs_dir/text"
  local local_dir="$docs_dir/local"

  local_path_for_age() {
    echo "$local_dir/$(basename "$1" .age)"
  }

  age_path_for_local() {
    echo "$records_dir/$(basename "$1").age"
  }

  require_op

  case "$cmd" in
    add)
      local src="${1:?usage: lockbox doc add <file>}"
      [[ -f "$src" ]] || { echo "Not found: $src" >&2; exit 1; }

      local dest local_dest
      if [[ $# -ge 2 ]]; then
        dest="$2"
      else
        mkdir -p "$records_dir"
        dest="$records_dir/$(basename "$src").age"
      fi

      local_dest="$(local_path_for_age "$dest")"
      mkdir -p "$(dirname "$dest")" "$(dirname "$local_dest")"
      cp "$src" "$local_dest"
      age_encrypt_file "$src" "$dest"
      echo "Encrypted: $dest"
      echo "Local copy: $local_dest"
      ;;

    checkout)
      if [[ "${1:-}" == "--all" || -z "${1:-}" ]]; then
        shopt -s nullglob
        local files=("$records_dir"/*.age) enc local_dest
        if [[ ${#files[@]} -eq 0 ]]; then
          echo "No encrypted documents in records/"
          return 0
        fi
        for enc in "${files[@]}"; do
          local_dest="$(local_path_for_age "$enc")"
          mkdir -p "$(dirname "$local_dest")"
          age_decrypt_file "$enc" "$local_dest"
          echo "$local_dest"
        done
      else
        local enc="$1" local_dest
        [[ "$enc" != "$records_dir"/* ]] && enc="$records_dir/$(basename "$enc")"
        [[ -f "$enc" ]] || { echo "Not found: $enc" >&2; exit 1; }
        local_dest="$(local_path_for_age "$enc")"
        mkdir -p "$(dirname "$local_dest")"
        age_decrypt_file "$enc" "$local_dest"
        echo "$local_dest"
      fi
      ;;

    sync)
      if [[ "${1:-}" == "--all" || -z "${1:-}" ]]; then
        shopt -s nullglob
        local files=("$local_dir"/*) local enc
        if [[ ${#files[@]} -eq 0 ]]; then
          echo "No files in documents/local/"
          return 0
        fi
        for local in "${files[@]}"; do
          [[ -f "$local" ]] || continue
          enc="$(age_path_for_local "$local")"
          age_encrypt_file "$local" "$enc"
          echo "Synced: $enc"
        done
      else
        local local="$1" enc
        [[ "$local" != "$local_dir"/* ]] && local="$local_dir/$(basename "$local")"
        [[ -f "$local" ]] || { echo "Not found: $local" >&2; exit 1; }
        enc="$(age_path_for_local "$local")"
        mkdir -p "$(dirname "$enc")"
        age_encrypt_file "$local" "$enc"
        echo "Synced: $enc"
      fi
      echo "Run git add $DOCUMENTS_DIR/records/ && git commit when ready."
      ;;

    open)
      if [[ -z "${1:-}" ]]; then
        shopt -s nullglob
        local files=("$local_dir"/*)
        if [[ ${#files[@]} -eq 1 ]]; then
          open "${files[0]}"
          echo "Opened: ${files[0]}"
          return 0
        fi
        echo "usage: lockbox doc open <file.age>" >&2
        exit 1
      fi

      local enc="$1" local_dest
      [[ "$enc" != "$records_dir"/* ]] && enc="$records_dir/$(basename "$enc")"
      [[ -f "$enc" ]] || { echo "Not found: $enc" >&2; exit 1; }

      local_dest="$(local_path_for_age "$enc")"
      if [[ ! -f "$local_dest" ]]; then
        mkdir -p "$(dirname "$local_dest")"
        age_decrypt_file "$enc" "$local_dest"
        echo "Checked out: $local_dest"
      fi
      open "$local_dest"
      ;;

    decrypt)
      local enc="${1:?usage: lockbox doc decrypt <file.age> [out]}"
      shift || true
      [[ -f "$enc" ]] || { echo "Not found: $enc" >&2; exit 1; }

      if [[ $# -ge 1 && -n "${1:-}" ]]; then
        age_decrypt_file "$enc" "$1"
        echo "Decrypted: $1"
      else
        local tmp
        tmp="$(mktemp)"
        age_decrypt_file "$enc" "$tmp"
        cat "$tmp"
        rm -f "$tmp"
      fi
      ;;

    edit)
      local file="${1:?usage: lockbox doc edit <file>}"
      if [[ "$file" != "$DOCUMENTS_DIR/text"/* && "$file" != documents/text/* ]]; then
        file="$DOCUMENTS_DIR/text/$(basename "$file")"
      fi
      mkdir -p "$text_dir"
      if [[ ! -f "$file" ]]; then
        touch "$file"
        sops --encrypt --in-place "$file"
      fi
      sops "$file"
      ;;

    list)
      echo "Encrypted (records/):"
      find "$records_dir" -name '*.age' 2>/dev/null | sort || true
      echo ""
      echo "Local (decrypted):"
      find "$local_dir" -type f ! -name '.*' 2>/dev/null | sort || true
      echo ""
      echo "Text (SOPS):"
      find "$text_dir" -type f ! -name '.*' 2>/dev/null | sort || true
      ;;

    *)
      echo "usage: lockbox doc add|checkout|sync|open|decrypt|edit|list" >&2
      exit 1
      ;;
  esac
}

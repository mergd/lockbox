#!/usr/bin/env bash

lockbox_doc() {
  local cmd="${1:-}"
  shift || true

  local docs_dir="$LOCKBOX_ROOT/$DOCUMENTS_DIR"
  local records_dir="$docs_dir/records"
  local text_dir="$docs_dir/text"
  local local_dir="$docs_dir/local"

  resolve_enc_path() {
    local enc="$1"
    [[ "$enc" != "$records_dir"/* ]] && enc="$records_dir/$enc"
    [[ "$enc" != *.age ]] && enc="${enc}.age"
    if [[ ! -f "$enc" ]]; then
      enc="$(find "$records_dir" -name "$(basename "$enc")" 2>/dev/null | head -1)"
    fi
    echo "$enc"
  }

  local_path_for_age() {
    local enc="$1" rel
    rel="${enc#"$records_dir"/}"
    rel="${rel%.age}"
    echo "$local_dir/$rel"
  }

  age_path_for_local() {
    local file="$1" rel
    [[ "$file" == "$local_dir"/* ]] || file="$local_dir/$file"
    rel="${file#"$local_dir"/}"
    echo "$records_dir/${rel}.age"
  }

  require_op

  case "$cmd" in
    add)
      local src="${1:?usage: lockbox doc add <file> [dest.age]}"
      [[ -f "$src" ]] || { echo "Not found: $src" >&2; exit 1; }

      local dest local_dest
      if [[ $# -ge 2 ]]; then
        dest="$2"
      elif [[ "$src" == "$docs_dir/inbox"/* ]]; then
        local rel="${src#"$docs_dir/inbox"/}"
        dest="$records_dir/${rel}.age"
      else
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
        local enc local_dest
        local found=0
        while IFS= read -r enc; do
          found=1
          local_dest="$(local_path_for_age "$enc")"
          mkdir -p "$(dirname "$local_dest")"
          age_decrypt_file "$enc" "$local_dest"
          echo "$local_dest"
        done < <(find "$records_dir" -name '*.age' 2>/dev/null | sort)
        [[ "$found" -eq 1 ]] || echo "No encrypted documents in records/"
      else
        local enc local_dest
        enc="$(resolve_enc_path "$1")"
        [[ -f "$enc" ]] || { echo "Not found: $1" >&2; exit 1; }
        local_dest="$(local_path_for_age "$enc")"
        mkdir -p "$(dirname "$local_dest")"
        age_decrypt_file "$enc" "$local_dest"
        echo "$local_dest"
      fi
      ;;

    sync)
      if [[ "${1:-}" == "--all" || -z "${1:-}" ]]; then
        local file enc found=0
        while IFS= read -r file; do
          found=1
          enc="$(age_path_for_local "$file")"
          mkdir -p "$(dirname "$enc")"
          age_encrypt_file "$file" "$enc"
          echo "Synced: $enc"
        done < <(find "$local_dir" -type f ! -name '.*' 2>/dev/null | sort)
        [[ "$found" -eq 1 ]] || echo "No files in documents/local/"
      else
        local file="$1" enc
        [[ "$file" != "$local_dir"/* ]] && file="$local_dir/$file"
        [[ -f "$file" ]] || { echo "Not found: $file" >&2; exit 1; }
        enc="$(age_path_for_local "$file")"
        mkdir -p "$(dirname "$enc")"
        age_encrypt_file "$file" "$enc"
        echo "Synced: $enc"
      fi
      echo "Run git add $DOCUMENTS_DIR/records/ && git commit when ready."
      ;;

    open)
      if [[ -z "${1:-}" ]]; then
        local files=()
        while IFS= read -r f; do files+=("$f"); done < <(find "$local_dir" -type f ! -name '.*' 2>/dev/null)
        if [[ ${#files[@]} -eq 1 ]]; then
          open "${files[0]}"
          echo "Opened: ${files[0]}"
          return 0
        fi
        echo "usage: lockbox doc open <path/to/file.age>" >&2
        exit 1
      fi

      local enc local_dest
      enc="$(resolve_enc_path "$1")"
      [[ -f "$enc" ]] || { echo "Not found: $1" >&2; exit 1; }

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
      enc="$(resolve_enc_path "$enc")"
      [[ -f "$enc" ]] || { echo "Not found: $1" >&2; exit 1; }

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

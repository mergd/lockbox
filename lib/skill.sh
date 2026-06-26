#!/usr/bin/env bash

lockbox_skill_install() {
  local target_root="${1:-}"

  if [[ -z "$target_root" ]]; then
    lockbox_find_project_root
    target_root="$LOCKBOX_ROOT"
  fi

  local skill_src="$LOCKBOX_HOME/skills/lockbox"
  local skill_dest="$target_root/.agents/skills/lockbox"

  if [[ ! -f "$skill_src/SKILL.md" ]]; then
    echo "Skill not found at $skill_src/SKILL.md" >&2
    exit 1
  fi

  mkdir -p "$skill_dest"
  cp "$skill_src/SKILL.md" "$skill_dest/SKILL.md"
  echo "Installed skill: $skill_dest/SKILL.md"
  echo "Commit .agents/skills/lockbox/ so agents pick it up in this repo."
}

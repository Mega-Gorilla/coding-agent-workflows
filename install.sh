#!/usr/bin/env sh
set -eu

target=all
force=0
legacy_claude_commands=0
claude_root=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
codex_root=${CODEX_HOME:-"$HOME/.codex"}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      [ "$#" -ge 2 ] || { echo "--target requires all, claude, or codex" >&2; exit 2; }
      target=$2
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    --legacy-claude-commands)
      legacy_claude_commands=1
      shift
      ;;
    --claude-root)
      [ "$#" -ge 2 ] || { echo "--claude-root requires a path" >&2; exit 2; }
      claude_root=$2
      shift 2
      ;;
    --codex-root)
      [ "$#" -ge 2 ] || { echo "--codex-root requires a path" >&2; exit 2; }
      codex_root=$2
      shift 2
      ;;
    *)
      echo "Usage: $0 [--target all|claude|codex] [--legacy-claude-commands] [--force] [--claude-root PATH] [--codex-root PATH]" >&2
      exit 2
      ;;
  esac
done

case "$target" in
  all|claude|codex) ;;
  *) echo "Invalid target: $target" >&2; exit 2 ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
skill_source="$script_dir/skills"
command_source="$script_dir/commands"

install_skills() {
  destination=$1
  label=$2
  mkdir -p "$destination"

  for skill in "$skill_source"/*; do
    [ -d "$skill" ] || continue
    skill_name=$(basename -- "$skill")
    skill_target="$destination/$skill_name"

    if [ -e "$skill_target" ] && [ "$force" -ne 1 ]; then
      echo "Skipped existing $label: $skill_target" >&2
      continue
    fi

    mkdir -p "$skill_target"
    cp -R "$skill/." "$skill_target/"
    echo "Installed $label: $skill_target"
  done
}

if [ "$target" = all ] || [ "$target" = claude ]; then
  install_skills "$claude_root/skills" "Claude Code skill"
fi

if [ "$target" = all ] || [ "$target" = codex ]; then
  install_skills "$codex_root/skills" "Codex skill"
fi

if [ "$legacy_claude_commands" -eq 1 ]; then
  mkdir -p "$claude_root/commands"
  for command in "$command_source"/*.md; do
    [ -f "$command" ] || continue
    command_target="$claude_root/commands/$(basename -- "$command")"
    if [ -e "$command_target" ] && [ "$force" -ne 1 ]; then
      echo "Skipped existing Claude Code command: $command_target" >&2
      continue
    fi
    cp "$command" "$command_target"
    echo "Installed Claude Code command: $command_target"
  done
fi

echo "Installation complete. Start a new agent session before using newly installed skills."

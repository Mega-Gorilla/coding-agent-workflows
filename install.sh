#!/usr/bin/env sh
set -eu

force=0
if [ "${1:-}" = "--force" ]; then
  force=1
elif [ "$#" -gt 0 ]; then
  echo "Usage: $0 [--force]" >&2
  exit 2
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_dir="$script_dir/commands"
config_dir=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
destination="$config_dir/commands"

if [ ! -d "$source_dir" ]; then
  echo "Command directory not found: $source_dir" >&2
  exit 1
fi

mkdir -p "$destination"

installed=0
skipped=0
for command in "$source_dir"/*.md; do
  [ -e "$command" ] || continue
  target="$destination/$(basename -- "$command")"

  if [ -e "$target" ] && [ "$force" -ne 1 ]; then
    echo "Skipped existing command: $target" >&2
    skipped=$((skipped + 1))
    continue
  fi

  cp "$command" "$target"
  echo "Installed: $target"
  installed=$((installed + 1))
done

echo "Completed. Installed: $installed; skipped: $skipped"


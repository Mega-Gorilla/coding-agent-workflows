#!/usr/bin/env sh
set -eu

target=all
force=0
legacy_claude_commands=0
migrate_legacy=0
dry_run=0
allow_downgrade=0
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
    --migrate-legacy)
      migrate_legacy=1
      shift
      ;;
    --legacy-claude-commands)
      legacy_claude_commands=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --allow-downgrade)
      allow_downgrade=1
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
      echo "Usage: $0 [--target all|claude|codex] [--dry-run] [--migrate-legacy] [--force] [--allow-downgrade] [--legacy-claude-commands] [--claude-root PATH] [--codex-root PATH]" >&2
      exit 2
      ;;
  esac
done

case "$target" in
  all|claude|codex) ;;
  *) echo "Invalid target: $target" >&2; exit 2 ;;
esac

if [ "$legacy_claude_commands" -eq 1 ] && [ "$migrate_legacy" -eq 1 ]; then
  echo "--legacy-claude-commands and --migrate-legacy cannot be used together" >&2
  exit 2
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
skill_source="$script_dir/skills"
legacy_command_source="$script_dir/legacy/claude-commands"
version_file="$script_dir/VERSION"

[ -d "$skill_source" ] || { echo "Skill directory not found: $skill_source" >&2; exit 1; }
[ -f "$version_file" ] || { echo "VERSION file not found: $version_file" >&2; exit 1; }

package_version=$(tr -d '\r\n' < "$version_file")
run_timestamp=$(date -u '+%Y%m%d-%H%M%S')
temporary_root=$(mktemp -d "${TMPDIR:-/tmp}/coding-agent-workflows.XXXXXX")
trap 'rm -rf -- "$temporary_root"' EXIT HUP INT TERM
migration_log="$temporary_root/migrations.tsv"
legacy_paths="$temporary_root/legacy-paths.txt"
: > "$migration_log"
: > "$legacy_paths"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print tolower($1)}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print tolower($1)}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$1" | awk '{print tolower($NF)}'
  else
    echo "A SHA-256 tool (sha256sum, shasum, or openssl) is required" >&2
    exit 1
  fi
}

sha256_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print tolower($1)}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print tolower($1)}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 | awk '{print tolower($NF)}'
  else
    echo "A SHA-256 tool (sha256sum, shasum, or openssl) is required" >&2
    exit 1
  fi
}

directory_map() {
  directory=$1
  prefix=${2:-}
  [ -d "$directory" ] || return 0
  find "$directory" -type f -print | LC_ALL=C sort | while IFS= read -r file; do
    relative=${file#"$directory"/}
    if [ -n "$prefix" ]; then
      relative=${prefix%/}/$relative
    fi
    printf '%s\t%s\n' "$relative" "$(sha256_file "$file")"
  done
}

directories_equal() {
  left=$1
  right=$2
  [ -d "$left" ] && [ -d "$right" ] || return 1
  left_map=$(mktemp "$temporary_root/left.XXXXXX")
  right_map=$(mktemp "$temporary_root/right.XXXXXX")
  directory_map "$left" > "$left_map"
  directory_map "$right" > "$right_map"
  cmp -s "$left_map" "$right_map"
}

path_fingerprint() {
  path=$1
  if [ -f "$path" ]; then
    sha256_file "$path"
  else
    directory_map "$path" | sha256_stdin
  fi
}

assert_safe_child() {
  safe_root=${1%/}
  safe_path=$2
  case "$safe_path" in
    "$safe_root"/*) ;;
    *) echo "Unsafe path outside root: $safe_path" >&2; exit 1 ;;
  esac
}

validate_agent_root() {
  candidate=$1
  non_slashes=$(printf '%s' "$candidate" | tr -d '/')
  case "$candidate" in
    ''|.|..|../*|*/../*|*/..)
      echo "Agent root must be a dedicated directory without parent traversal: $candidate" >&2
      exit 1
      ;;
  esac
  [ -n "$non_slashes" ] || {
    echo "Agent root must not be a filesystem root" >&2
    exit 1
  }
}

manifest_hash() {
  manifest=$1
  relative=$2
  [ -f "$manifest" ] || return 0
  grep -F "\"$relative\"" "$manifest" 2>/dev/null | head -n 1 | sed -n 's/.*:[[:space:]]*"\([0-9A-Fa-f][0-9A-Fa-f]*\)".*/\1/p' | tr 'A-F' 'a-f'
}

managed_directory_unchanged() {
  agent_root=$1
  skill_name=$2
  manifest="$agent_root/coding-agent-workflows/install-manifest.json"
  destination="$agent_root/skills/$skill_name"
  [ -f "$manifest" ] && [ -d "$destination" ] || return 1

  actual_map=$(mktemp "$temporary_root/actual.XXXXXX")
  directory_map "$destination" "skills/$skill_name" > "$actual_map"
  actual_count=$(wc -l < "$actual_map" | tr -d ' ')
  expected_count=$(grep -F -c "\"skills/$skill_name/" "$manifest" 2>/dev/null || true)
  [ "$actual_count" -gt 0 ] && [ "$actual_count" -eq "$expected_count" ] || return 1

  tab=$(printf '\t')
  while IFS="$tab" read -r relative actual_hash; do
    expected_hash=$(manifest_hash "$manifest" "$relative")
    [ -n "$expected_hash" ] && [ "$actual_hash" = "$expected_hash" ] || return 1
  done < "$actual_map"
  return 0
}

manifest_package_version() {
  manifest=$1
  [ -f "$manifest" ] || return 0
  sed -n 's/^[[:space:]]*"packageVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -n 1 | tr -d '\r'
}

version_is_valid() {
  case "$1" in
    ''|.*|*.|*..*|*[!0-9.]*) return 1 ;;
  esac
  return 0
}

# Prints lt, eq, or gt for numeric dotted versions; missing components count as 0.
version_compare() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    n = split(a, x, "."); m = split(b, y, "."); k = (n > m ? n : m)
    for (i = 1; i <= k; i++) {
      xi = (i <= n ? x[i] + 0 : 0); yi = (i <= m ? y[i] + 0 : 0)
      if (xi < yi) { print "lt"; exit }
      if (xi > yi) { print "gt"; exit }
    }
    print "eq"
  }'
}

check_package_version() {
  agent_root=$1
  validate_agent_root "$agent_root"
  manifest="$agent_root/coding-agent-workflows/install-manifest.json"
  installed_version=$(manifest_package_version "$manifest")
  [ -n "$installed_version" ] || return 0

  if ! version_is_valid "$installed_version" || ! version_is_valid "$package_version"; then
    if [ "$allow_downgrade" -eq 1 ]; then
      echo "Warning: cannot compare package $package_version with installed $installed_version in $manifest; continuing because --allow-downgrade was given." >&2
      return 0
    fi
    echo "Cannot compare package $package_version with installed $installed_version in $manifest. Review the checkout, or re-run with --allow-downgrade." >&2
    exit 1
  fi

  if [ "$(version_compare "$package_version" "$installed_version")" = lt ]; then
    if [ "$allow_downgrade" -eq 1 ]; then
      echo "Warning: downgrading $agent_root from package $installed_version to $package_version because --allow-downgrade was given." >&2
      return 0
    fi
    echo "Refusing to install package $package_version over newer installed package $installed_version in $agent_root. Update this checkout, or re-run with --allow-downgrade after review." >&2
    exit 1
  fi
}

manifest_has_skill() {
  agent_root=$1
  skill_name=$2
  manifest="$agent_root/coding-agent-workflows/install-manifest.json"
  [ -f "$manifest" ] || return 1
  grep -F -q "\"skills/$skill_name/" "$manifest"
}

record_or_migrate_legacy() {
  agent_root=$1
  path=$2
  relative=$3
  replacement=$4
  [ -e "$path" ] || return 0

  fingerprint=$(path_fingerprint "$path")
  echo "Legacy item: $path [sha256:$fingerprint] -> $replacement" >&2
  printf '%s\n' "$path" >> "$legacy_paths"
  if [ "$migrate_legacy" -ne 1 ]; then
    return 0
  fi

  backup="$agent_root/coding-agent-workflows/backups/$run_timestamp/$relative"
  assert_safe_child "$agent_root" "$path"
  assert_safe_child "$agent_root" "$backup"
  if [ "$dry_run" -eq 1 ]; then
    echo "Would back up legacy item: $path -> $backup"
    return 0
  fi
  mkdir -p "$(dirname -- "$backup")"
  mv -- "$path" "$backup"
  printf '%s\t%s\t%s\t%s\n' "$path" "$backup" "$fingerprint" "$replacement" >> "$migration_log"
  echo "Backed up legacy item: $path -> $backup"
}

inspect_legacy() {
  agent_root=$1
  agent=$2
  found=0

  for entry in \
    'review:pr-review' \
    'pr-review:pr-review' \
    'pr-re-review:pr-review' \
    'review-followup:pr-followup' \
    'pr-merge:pr-merge' \
    'startup-status:startup-status'
  do
    old_name=${entry%%:*}
    replacement=${entry#*:}
    path="$agent_root/skills/$old_name"
    [ -d "$path" ] || continue
    current_source="$skill_source/$old_name"
    if [ -d "$current_source" ]; then
      if directories_equal "$current_source" "$path" || manifest_has_skill "$agent_root" "$old_name"; then
        continue
      fi
    fi
    found=1
    record_or_migrate_legacy "$agent_root" "$path" "skills/$old_name" "$replacement"
  done

  if [ "$agent" = claude ]; then
    for entry in \
      'review.md:pr-review' \
      'pr_review.md:pr-review' \
      'pr_re_review.md:pr-review' \
      'review_followup.md:pr-followup' \
      'pr_merge.md:pr-merge' \
      'startup_status.md:startup-status'
    do
      file_name=${entry%%:*}
      replacement=${entry#*:}
      path="$agent_root/commands/$file_name"
      [ -f "$path" ] || continue
      found=1
      record_or_migrate_legacy "$agent_root" "$path" "commands/$file_name" "$replacement"
    done
  elif [ "$agent" = codex ]; then
    for entry in \
      'pr_review.md:pr-review' \
      'pr_re_review.md:pr-review' \
      'review_followup.md:pr-followup' \
      'pr_merge.md:pr-merge' \
      'startup_status.md:startup-status'
    do
      file_name=${entry%%:*}
      replacement=${entry#*:}
      path="$agent_root/prompts/$file_name"
      [ -f "$path" ] || continue
      found=1
      record_or_migrate_legacy "$agent_root" "$path" "prompts/$file_name" "$replacement"
    done
  fi

  if [ "$found" -eq 1 ] && [ "$migrate_legacy" -ne 1 ]; then
    echo "Legacy items were not changed. Re-run with --migrate-legacy to back them up and remove the originals." >&2
  elif [ "$found" -eq 1 ] && [ "$dry_run" -eq 1 ]; then
    echo "Dry run: legacy items were not moved." >&2
  fi
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_manifest() {
  agent_root=$1
  manifest_directory="$agent_root/coding-agent-workflows"
  manifest="$manifest_directory/install-manifest.json"
  if [ "$dry_run" -eq 1 ]; then
    echo "Would write install manifest: $manifest (package $package_version)"
    return 0
  fi
  manifest_tmp="$temporary_root/manifest.json"
  previous_migrations=$(mktemp "$temporary_root/previous-migrations.XXXXXX")
  mkdir -p "$manifest_directory"

  if [ -f "$manifest" ]; then
    awk '
      /"migrations"[[:space:]]*:[[:space:]]*\[/ {
        line = $0
        sub(/^.*"migrations"[[:space:]]*:[[:space:]]*\[/, "", line)
        if (line ~ /\][,]?[[:space:]]*$/) {
          sub(/\][,]?[[:space:]]*$/, "", line)
          if (line !~ /^[[:space:]]*$/) print line
          exit
        }
        inside = 1
        next
      }
      inside && /^[[:space:]]*\][,]?[[:space:]]*$/ { exit }
      inside { print }
    ' "$manifest" | sed '/^[[:space:]]*$/d' > "$previous_migrations"
  else
    : > "$previous_migrations"
  fi

  {
    echo '{'
    echo '  "schemaVersion": 1,'
    printf '  "packageVersion": "%s",\n' "$(json_escape "$package_version")"
    printf '  "installedAt": "%s",\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo '  "files": {'

    first=1
    for source in "$skill_source"/*; do
      [ -d "$source" ] || continue
      skill_name=$(basename -- "$source")
      destination="$agent_root/skills/$skill_name"
      map_file=$(mktemp "$temporary_root/map.XXXXXX")
      if directories_equal "$source" "$destination"; then
        directory_map "$destination" "skills/$skill_name" > "$map_file"
      elif manifest_has_skill "$agent_root" "$skill_name"; then
        grep -F "\"skills/$skill_name/" "$manifest" | while IFS= read -r line; do
          relative=$(printf '%s\n' "$line" | sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p')
          hash=$(printf '%s\n' "$line" | sed -n 's/.*:[[:space:]]*"\([0-9A-Fa-f][0-9A-Fa-f]*\)".*/\1/p' | tr 'A-F' 'a-f')
          [ -n "$relative" ] && [ -n "$hash" ] && printf '%s\t%s\n' "$relative" "$hash"
        done > "$map_file"
      else
        continue
      fi
      tab=$(printf '\t')
      while IFS="$tab" read -r relative hash; do
        [ -n "$relative" ] || continue
        if [ "$first" -eq 0 ]; then
          echo ','
        fi
        printf '    "%s": "%s"' "$(json_escape "$relative")" "$hash"
        first=0
      done < "$map_file"
    done

    # Keep entries for managed Skills that this package does not contain, so an
    # older or narrower package never turns them into unmanaged Skills.
    if [ -f "$manifest" ]; then
      sed -n 's/^[[:space:]]*"skills\/\([^/"]*\)\/[^"]*"[[:space:]]*:.*/\1/p' "$manifest" | LC_ALL=C sort -u > "$temporary_root/manifest-skills.txt"
      while IFS= read -r skill_name; do
        [ -n "$skill_name" ] || continue
        [ -d "$skill_source/$skill_name" ] && continue
        [ -d "$agent_root/skills/$skill_name" ] || continue
        grep -F "\"skills/$skill_name/" "$manifest" | while IFS= read -r line; do
          relative=$(printf '%s\n' "$line" | sed -n 's/^[[:space:]]*"\([^"]*\)".*/\1/p')
          hash=$(printf '%s\n' "$line" | sed -n 's/.*:[[:space:]]*"\([0-9A-Fa-f][0-9A-Fa-f]*\)".*/\1/p' | tr 'A-F' 'a-f')
          [ -n "$relative" ] && [ -n "$hash" ] && printf '%s\t%s\n' "$relative" "$hash"
        done > "$temporary_root/retained.tsv"
        tab=$(printf '\t')
        while IFS="$tab" read -r relative hash; do
          [ -n "$relative" ] || continue
          if [ "$first" -eq 0 ]; then
            echo ','
          fi
          printf '    "%s": "%s"' "$(json_escape "$relative")" "$hash"
          first=0
        done < "$temporary_root/retained.tsv"
        echo "Retained manifest entries for managed skill not in package $package_version: $agent_root/skills/$skill_name" >&2
      done < "$temporary_root/manifest-skills.txt"
    fi
    echo
    echo '  },'
    echo '  "migrations": ['

    if [ -s "$previous_migrations" ]; then
      cat "$previous_migrations"
      first=0
    else
      first=1
    fi
    tab=$(printf '\t')
    while IFS="$tab" read -r source backup hash replacement; do
      [ -n "$source" ] || continue
      if [ "$first" -eq 0 ]; then
        echo ','
      fi
      printf '    {"source": "%s", "backup": "%s", "sha256": "%s", "replacement": "%s"}' \
        "$(json_escape "$source")" "$(json_escape "$backup")" "$hash" "$(json_escape "$replacement")"
      first=0
    done < "$migration_log"
    echo
    echo '  ]'
    echo '}'
  } > "$manifest_tmp"

  mv -- "$manifest_tmp" "$manifest"
  echo "Wrote install manifest: $manifest"
}

install_skills() {
  agent_root=$1
  agent=$2
  validate_agent_root "$agent_root"
  [ "$dry_run" -eq 1 ] || mkdir -p "$agent_root"
  destination_root="$agent_root/skills"

  : > "$migration_log"
  : > "$legacy_paths"
  inspect_legacy "$agent_root" "$agent"
  [ "$dry_run" -eq 1 ] || mkdir -p "$destination_root"

  for source in "$skill_source"/*; do
    [ -d "$source" ] || continue
    skill_name=$(basename -- "$source")
    destination="$destination_root/$skill_name"

    if directories_equal "$source" "$destination"; then
      echo "Already current $agent skill: $destination"
      continue
    fi
    is_legacy=0
    if grep -F -x -e "$destination" "$legacy_paths" >/dev/null 2>&1; then
      is_legacy=1
    fi
    if [ -e "$destination" ] && [ "$is_legacy" -eq 1 ] && [ "$migrate_legacy" -ne 1 ]; then
      echo "Skipped legacy $agent skill: $destination (use --migrate-legacy to back it up first; --force does not bypass migration)" >&2
      continue
    fi
    if [ -e "$destination" ] && [ "$is_legacy" -eq 0 ] && [ "$force" -ne 1 ] && ! managed_directory_unchanged "$agent_root" "$skill_name"; then
      echo "Skipped unmanaged or modified $agent skill: $destination (use --force after review)" >&2
      continue
    fi

    assert_safe_child "$agent_root" "$destination"
    if [ "$dry_run" -eq 1 ]; then
      if [ "$is_legacy" -eq 1 ]; then
        echo "Would install $agent skill after legacy backup: $destination"
      elif [ -e "$destination" ]; then
        echo "Would update $agent skill: $destination"
      else
        echo "Would install $agent skill: $destination"
      fi
      continue
    fi
    if [ -e "$destination" ]; then
      rm -rf -- "$destination"
    fi
    cp -R "$source" "$destination"
    echo "Installed $agent skill: $destination"
  done

  write_manifest "$agent_root"
}

install_legacy_commands() {
  agent_root=$1
  validate_agent_root "$agent_root"
  [ "$dry_run" -eq 1 ] || mkdir -p "$agent_root"
  [ -d "$legacy_command_source" ] || { echo "Legacy command directory not found: $legacy_command_source" >&2; exit 1; }

  for source in "$skill_source"/*; do
    [ -d "$source" ] || continue
    skill_name=$(basename -- "$source")
    if [ -e "$agent_root/skills/$skill_name" ]; then
      echo "Legacy commands cannot be installed alongside new workflow skills: $agent_root/skills/$skill_name" >&2
      exit 1
    fi
  done

  echo "--legacy-claude-commands is deprecated. No new Claude Code workflow Skills will be installed in this mode." >&2
  destination_root="$agent_root/commands"
  [ "$dry_run" -eq 1 ] || mkdir -p "$destination_root"
  for command in "$legacy_command_source"/*.md; do
    [ -f "$command" ] || continue
    destination="$destination_root/$(basename -- "$command")"
    if [ -e "$destination" ] && [ "$force" -ne 1 ]; then
      echo "Skipped existing legacy Claude Code command: $destination" >&2
      continue
    fi
    if [ "$dry_run" -eq 1 ]; then
      echo "Would install legacy Claude Code command: $destination"
      continue
    fi
    cp "$command" "$destination"
    echo "Installed legacy Claude Code command: $destination"
  done
}

# Check every targeted Skill root before changing any of them.
if { [ "$target" = all ] || [ "$target" = claude ]; } && [ "$legacy_claude_commands" -ne 1 ]; then
  check_package_version "$claude_root"
fi
if [ "$target" = all ] || [ "$target" = codex ]; then
  check_package_version "$codex_root"
fi

if [ "$dry_run" -eq 1 ]; then
  echo "Dry run: no files will be changed."
fi

if [ "$target" = all ] || [ "$target" = claude ]; then
  if [ "$legacy_claude_commands" -eq 1 ]; then
    install_legacy_commands "$claude_root"
  else
    install_skills "$claude_root" claude
  fi
fi

if [ "$target" = all ] || [ "$target" = codex ]; then
  install_skills "$codex_root" codex
fi

if [ "$dry_run" -eq 1 ]; then
  echo "Dry run complete (package $package_version). No files were changed."
else
  echo "Installation complete (package $package_version). Start a new agent session before using newly installed skills."
fi

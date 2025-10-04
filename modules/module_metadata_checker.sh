#!/usr/bin/env bash

# Purpose: Verify each module declares basic metadata to support clean dependency management.
# Checks for the presence of header fields within the first 30 lines:
#   - "# Module:"        human-readable module name
#   - "# Version:"       semantic version or date version
#   - "# Depends:"       comma-separated module dependencies (may be empty)
# Produces a summary and non-zero exit if critical metadata is missing.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODULES_DIR="${ROOT_DIR}/modules"

log_info()  { echo "[INFO] $*"; }
log_warn()  { echo "[WARN] $*"; }
log_error() { echo "[ERROR] $*"; }

if [[ ! -d "${MODULES_DIR}" ]]; then
  log_error "Modules directory not found: ${MODULES_DIR}"
  exit 2
fi

missing_count=0
checked_count=0
declare -a missing_list

log_info "Scanning modules for metadata headers in: ${MODULES_DIR}"

for file in "${MODULES_DIR}"/*.sh; do
  [[ -f "$file" ]] || continue

  # Skip helper-only scripts that may not require headers
  base="$(basename "$file")"
  case "$base" in
    common_functions.sh|common_utils.sh|menu_templates.sh)
      continue
      ;;
  esac

  checked_count=$((checked_count+1))

  header_chunk=$(head -n 30 "$file" || true)

  module_name=$(grep -E "^#\s*Module:\s*" <<< "$header_chunk" | sed -E 's/^#\s*Module:\s*//')
  module_version=$(grep -E "^#\s*Version:\s*" <<< "$header_chunk" | sed -E 's/^#\s*Version:\s*//')
  module_depends=$(grep -E "^#\s*Depends:\s*" <<< "$header_chunk" | sed -E 's/^#\s*Depends:\s*//')

  missing_fields=()
  [[ -n "$module_name"   ]] || missing_fields+=("Module")
  [[ -n "$module_version" ]] || missing_fields+=("Version")
  # Depends may be empty but the field should exist to signal intent
  if ! grep -qE "^#\s*Depends:\s*" <<< "$header_chunk"; then
    missing_fields+=("Depends")
  fi

  if (( ${#missing_fields[@]} > 0 )); then
    missing_count=$((missing_count+1))
    missing_list+=("${base}: missing ${missing_fields[*]}")
  fi
done

log_info "Checked modules: ${checked_count}"

if (( missing_count > 0 )); then
  log_warn "Modules with incomplete metadata: ${missing_count}"
  for item in "${missing_list[@]}"; do
    echo " - ${item}"
  done
  log_warn "Please add headers to each module, e.g.:"
  cat <<'EOT'
# Module: example_module
# Version: 1.0.0
# Depends: common_functions, dependency_manager
EOT
  exit 1
else
  log_info "All checked modules contain required metadata headers."
fi

exit 0
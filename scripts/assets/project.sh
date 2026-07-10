#!/bin/bash

# ------------------------------------------------------------------------------
# PROJECT ROOT & METADATA RESOLUTION
# ------------------------------------------------------------------------------

# discover_project_root climbs up the directory tree to find the mandatory 'go.mod' marker.
#
# Returns:
#   - 0: Successfully resolved the absolute path to the project root workspace directory.
#   - 1: If the tracking marker cannot be found or an engine traversal boundary is reached.
#
# Side Effects:
#   - Mutates and populates the global ROOT_PATH configuration variable assignment.
discover_project_root() {
  local current_dir="$PWD"

  # Reset global root tracking register
  ROOT_PATH=""

  # Traverse directories upwards until reaching the file system base barrier
  while [ "$current_dir" != "/" ] && [ -n "$current_dir" ]; do
    if [ -f "${current_dir}/go.mod" ]; then
      # Convert path into a canonical clean absolute string pattern using cd and pwd
      ROOT_PATH=$(cd "$current_dir" && pwd)
      return 0
    fi
    current_dir=$(dirname "$current_dir")
  done

  VALIDATION_ERROR_MSG="Workspace error: Could not locate a valid project root tracking 'go.mod' file."
  return 1
}

# get_project_metadata extracts atomic keys from the local repository config file.
#
# Arguments:
#   - key_name: The uppercase configuration key string identifier to extract.
#
# Returns:
#   - 0: Successfully extracted the key and echoes its text payload.
#   - 1: If the configuration file is missing or the target key is not set.
get_project_metadata() {
  local key_name="$1"
  
  # Ensure the project root path is loaded and present
  if [ -z "$ROOT_PATH" ]; then
    if ! discover_project_root; then return 1; fi
  fi

  local config_file="${ROOT_PATH}/.github/config.txt"

  # 1. Assert physical configuration metadata file existence
  if [ ! -f "$config_file" ]; then
    VALIDATION_ERROR_MSG="Project metadata failure: '${config_file}' is missing."
    return 1
  fi

  # 2. Extract assignment value ignoring commentary lines and blank boundaries
  local extracted_value
  extracted_value=$(grep -v '^#' "$config_file" | grep "^${key_name}=" | cut -d'=' -f2)

  if [ -z "$extracted_value" ]; then
    VALIDATION_ERROR_MSG="Project metadata failure: Key '${key_name}' not defined in config."
    return 1
  fi

  echo "$extracted_value"
  return 0
}

# resolve_xerrors_filepath computes the dynamic destination path based on scope criteria.
#
# Arguments:
#   - scope: The raw input scope indicator ('internal', 'i', 'pkg', 'p').
#
# Returns:
#   - 0: Successfully resolved the physical filepath and echoes the string.
#   - 1: If an unknown scope is provided or the computed directory structure fails.
resolve_xerrors_filepath() {
  local scope="$1"

  # Ensure the project root path is loaded and present
  if [ -z "$ROOT_PATH" ]; then
    if ! discover_project_root; then return 1; fi
  fi

  # 1. Evaluate internal scoping routing guidelines
  if [ "$scope" = "internal" ] || [ "$scope" = "i" ]; then
    echo "${ROOT_PATH}/internal/xerrors/xerrors.go"
    return 0
  fi

  # 2. Evaluate public package scoping routing guidelines
  if [ "$scope" = "pkg" ] || [ "$scope" = "p" ]; then
    local main_pkg
    if ! main_pkg=$(get_project_metadata "MAIN_PKG"); then
      return 1
    fi
    echo "${ROOT_PATH}/pkg/${main_pkg}xerrors/xerrors.go"
    return 0
  fi

  VALIDATION_ERROR_MSG="Invalid scope target '${scope}'. Use 'internal (i)' or 'pkg (p)'."
  return 1
}

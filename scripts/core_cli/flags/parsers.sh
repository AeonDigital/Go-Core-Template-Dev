#!/bin/bash

# ==============================================================================
# SCRIPT: core_cli/flags/parsers.sh
# DESCRIPTION: Native linear collection extractors populating clean global 
#              indexed arrays and associative maps from string payloads.
# ==============================================================================

# core_cli_flag_extract_array parses string components into a native indexed array.
#
# Arguments:
#   - value: The verified raw array string sequence (e.g., ['val1', 'val2']).
#
# Side Effects:
#   - Resets and populates the global indexed array CORE_CLI_VALIDATED_ARRAY.
core_cli_flag_extract_array() {
  local input="$1"
  local inner="${input#?}"
  inner="${inner%?}"

  # Reset global indexed array cleanly
  CORE_CLI_VALIDATED_ARRAY=()
  
  local current=""
  local idx=0
  local len=${#inner}
  local in_q=0

  while [ "$idx" -lt "$len" ]; do
    local char="${inner:$idx:1}"
    if [ "$in_q" -eq 1 ]; then
      if [ "$char" = "'" ] || [ "$char" = '"' ]; then
        in_q=0
        CORE_CLI_VALIDATED_ARRAY+=("$current")
        current=""
      else
        current+="$char"
      fi
    else
      if [ "$char" = "'" ] || [ "$char" = '"' ]; then
        in_q=1
      fi
    fi
    idx=$((idx + 1))
  done
}

# core_cli_flag_extract_assoc parses string components into a native associative map.
#
# Arguments:
#   - value: The verified flat JSON object string sequence.
#
# Side Effects:
#   - Resets and populates the global associative map CORE_CLI_VALIDATED_ASSOC.
core_cli_flag_extract_assoc() {
  local input="$1"
  local inner="${input#?}"
  inner="${inner%?}"

  # Reset global associative array cleanly
  CORE_CLI_VALIDATED_ASSOC=()
  
  local key=""
  local val=""
  local current=""
  local idx=0
  local len=${#inner}
  local in_q=0
  local capture_state=0 # 0=key, 1=value

  while [ "$idx" -lt "$len" ]; do
    local char="${inner:$idx:1}"
    if [ "$in_q" -eq 1 ]; then
      if [ "$char" = '"' ] || [ "$char" = "'" ]; then
        in_q=0
        if [ "$capture_state" -eq 0 ]; then
          key="$current"
        else
          val="$current"
          CORE_CLI_VALIDATED_ASSOC["$key"]="$val"
          capture_state=0
        fi
        current=""
      else
        current+="$char"
      fi
    else
      case "$char" in
        '"'|"'") in_q=1 ;;
        ':')     capture_state=1 ;;
        ',')     : ;;
      esac
    fi
    idx=$((idx + 1))
  done
}

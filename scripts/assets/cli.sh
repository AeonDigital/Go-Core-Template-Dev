#!/bin/bash

# ------------------------------------------------------------------------------
# CLI FLAG PARSING & INTERACTION
# ------------------------------------------------------------------------------

# validate_cli_spec asserts and standardizes a structural CLI flag specification array.
#
# Arguments:
#   - spec_array_name: The string name of the global indexed configuration array.
#
# Returns:
#   - 0: If the structural definitions are well-formed and valid.
#   - 1: If any architectural layout constraint or mandatory element is missing.
#
# Operational Constraints:
#   - Mutates the target array elements to guarantee order: [short_flag] [long_flag].
#   - Triggers an error state equivalent to a Go runtime panic if rules are violated.
validate_cli_spec() {
  local array_name="$1"

  # Verify if the target configuration array name is non-empty and exists
  if [ -z "$array_name" ] || ! declare -p "$array_name" &> /dev/null; then
    VALIDATION_ERROR_MSG="CLI spec error: Configuration array name '${array_name}' does not exist"
    return 1
  fi

  # Create a local reference alias pointing directly to the global array variables
  eval "local -n local_spec=\"$array_name\""
  local total_items="${#local_spec[@]}"

  if [ "$total_items" -eq 0 ]; then
    VALIDATION_ERROR_MSG="CLI spec panic: Explicit flag definition array cannot resolve to an empty state"
    return 1
  fi

  # Loop through each item position inside the indexed configuration specification
  for i in "${!local_spec[@]}"; do
    local raw_item="${local_spec[$i]}"
    local short_flag=""
    local long_flag=""

    # Tokenize the items based on standard blank spaces boundaries
    for token in $raw_item; do
      if [[ "$token" =~ ^--[A-Za-z0-9_-]+$ ]]; then
        long_flag="$token"
      elif [[ "$token" =~ ^-[A-Za-z0-9]$ ]]; then
        short_flag="$token"
      else
        VALIDATION_ERROR_MSG="CLI spec panic: Invalid token format '${token}' detected at position [${i}]"
        return 1
      fi
    done

    # Enforce strict architectural presence of at least one long flag option
    if [ -z "$long_flag" ]; then
      VALIDATION_ERROR_MSG="CLI spec panic: Missing mandatory long flag option ('--') at position [${i}]"
      return 1
    fi

    # Mutate the global array structure index to establish strict predictable positioning
    if [ -n "$short_flag" ]; then
      local_spec[$i]="$short_flag $long_flag"
    else
      local_spec[$i]="$long_flag"
    fi
  done

  return 0
}

# parse_dynamic_flags evaluates and extracts key-value combinations into global storage.
#
# Arguments:
#   - spec_array_name: The string name of the verified flag specification array.
#   - $@: The comprehensive execution argument stream passdown from the CLI entrypoint.
#
# Returns:
#   - 0: Successfully populates the associative registers with user configurations.
#   - 1: If an unknown flag sequence is encountered during evaluation.
parse_dynamic_flags() {
  local spec_array_name="$1"
  shift

  # Clear target dynamic global lookup tracking cache entirely
  PARSED_FLAGS=()

  eval "local -n local_spec=\"$spec_array_name\""
  local raw_arguments=("$@")
  local total_args="${#raw_arguments[@]}"

  # Loop through the comprehensive stream ignoring positionals and capturing flags
  local idx=0
  while [ "$idx" -lt "$total_args" ]; do
    local arg="${raw_arguments[$idx]}"

    # Skip positional commands and advance cursor state until a flag token is found
    if [[ ! "$arg" =~ ^- ]]; then
      idx=$((idx + 1))
      continue
    fi

    local input_flag=""
    local input_value=""

    # Check for inline assignment definitions containing equal '=' delimiters
    if [[ "$arg" == *=* ]]; then
      input_flag="${arg%%=*}"
      input_value="${arg#*=}"
    else
      input_flag="$arg"
      local next_idx=$((idx + 1))
      
      # Lookahead check: Only consume next argument as value if it exists 
      # AND does not start with a dash '-', meaning it is a pure value token
      if [ "$next_idx" -lt "$total_args" ] && [[ ! "${raw_arguments[$next_idx]}" =~ ^- ]]; then
        input_value="${raw_arguments[$next_idx]}"
        idx="$next_idx"
      else
          # Default to 1 (True) for boolean flags or flags declared without explicit bounds
        input_value="1"
      fi
    fi

    # Locate the parsed token identifier against structural configuration definitions
    local match_found=1
    local flag_key=""

    for spec in "${local_spec[@]}"; do
      local s_part=""
      local l_part=""

      # Extract structural parameters out of the normalized local specification sequence
      for token in $spec; do
        if [[ "$token" =~ ^-- ]]; then l_part="$token"; else s_part="$token"; fi
      done

      # Match criteria evaluating whether input correlates to configurations
      if [ "$input_flag" = "$l_part" ] || [ "$input_flag" = "$s_part" ]; then
        match_found=0
        # Sanitize the long flag name removing leading dashes to act as map keys
        flag_key="${l_part#--}"
        break
      fi
    done

    if [ "$match_found" -ne 0 ]; then
      VALIDATION_ERROR_MSG="CLI parsing error: Unknown or unregistered parameter option '${input_flag}'"
      return 1
    fi

    # Commit extracted parameters onto global dynamic associative registers
    PARSED_FLAGS["$flag_key"]="$input_value"
    idx=$((idx + 1))
  done

  return 0
}

# prompt_and_validate_flag requests and asserts user inputs for specific CLI flags.
#
# Arguments:
#   - flag_key: The associative key name to populate inside PARSED_FLAGS (e.g., name).
#   - prompt_message: The technical text phrase to display when requesting inputs.
#   - allowed_enum: Space separated listing of valid choices if treating an enum.
#   - validate_fn: The name of the specific investigator function to execute.
#
# Returns:
#   - 0: When the target flag contains a perfectly validated, sanitized value.
#   - 1: If an unrecoverable validation error occurs or validation fails.
#
# Side Effects:
#   - Mutates and populates the global PARSED_FLAGS associative map.
prompt_and_validate_flag() {
  local key="$1"
  local msg="$2"
  local enum="$3"
  local val_fn="$4"

  local current_value="${PARSED_FLAGS[$key]}"

  # Loop until a valid, non-empty sanitized value is successfully captured
  while true; do
    # If the buffer is completely empty, request data interactively from standard input
    if [ -z "$current_value" ]; then
      echo -n "[ > ] ${msg}: "
      read -r current_value
      current_value=$(echo "$current_value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    fi

    # Trigger validation orchestrated pipelines using our generic architecture
    if validate_argument "$current_value" "$enum" "$val_fn"; then
      PARSED_FLAGS["$key"]="$current_value"
      return 0
    fi

    # Print validation failure message and reset buffer to force interactive retry
    echo "[ERR] Validation failure: ${VALIDATION_ERROR_MSG}"
    current_value=""
    
    # If the command was executed non-interactively via flags, abort immediately
    if [ -n "${PARSED_FLAGS[$key]}" ]; then
      return 1
    fi
  done
}

# run_family_wizard displays active error families and captures user selection.
#
# Arguments:
#   - file: The absolute physical path to the target xerrors.go file.
#
# Returns:
#   - 0: Successfully resolved a family ID and mutated global registers.
#   - 1: If the user selection is structurally out of bounds.
run_family_wizard() {
  local file="$1"

  echo ""
  echo "Available Structural Error Families:"
  
  # Parse and list all existing families dynamically from the file comments
  local family_regex="===[[:space:]]*FAMILY:[[:space:]]*([0-9]+)[[:space:]]*\|[[:space:]]*TITLE:[[:space:]]*(.+)"
  local max_id=0
  
  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ $family_regex ]]; then
      local fid="${BASH_REMATCH[1]}"
      local ftitle="${BASH_REMATCH[2]}"
      ftitle=$(echo "$ftitle" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
      echo "  [$fid] $ftitle"
      [ "$fid" -gt "$max_id" ] && max_id=$fid
    fi
  done < "$file"

  local next_id=$((max_id + 1))
  echo "  [$next_id] Create a new sequential semantic family"
  echo ""

  local choice=""
  echo -n "[ > ] Select Family Destination Index [1-${next_id}]: "
  read -r choice

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$next_id" ]; then
    VALIDATION_ERROR_MSG="Invalid structural index selection."
    return 1
  fi

  PARSED_FLAGS["family"]="$choice"
  return 0
}

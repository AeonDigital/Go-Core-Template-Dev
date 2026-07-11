#!/bin/bash

# ==============================================================================
# SCRIPT: core_cli/flags/validate.sh
# DESCRIPTION: Core verification primitives and structural validation library 
#              processing native command-line data type compliance checks.
# ==============================================================================

# core_cli_flag_validate_string asserts structural text compliance and safety.
#
# Arguments:
#   - value: The raw input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the text contains only printable characters and safe whitespace.
#   - 1: If invisible malicious terminal control characters are detected.
core_cli_flag_validate_string() {
  local value="$1"
  local aux="$2"

  # Strip allowed whitespace components (space, tabs, newline, carriage return)
  # before evaluation to isolate potential malicious hidden control characters
  local clean_text
  clean_text=$(echo -n "$value" | tr -d '[:space:]')

  # Assert if any remaining invisible control character block is present
  if [[ "$clean_text" =~ [[:cntrl:]] ]]; then
    return 1
  fi

  return 0
}

# core_cli_flag_validate_int verifies whole numeric data layout compliance.
#
# Arguments:
#   - value: The raw input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the payload matches a clean positive or negative integer sequence.
#   - 1: If alphabetical characters or illegal decimals are intercepted.
core_cli_flag_validate_int() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  if [[ "$value" =~ ^-?[0-9]+$ ]]; then
    return 0
  fi

  return 1
}

# core_cli_flag_validate_float verifies decimal numeric data layout compliance.
#
# Arguments:
#   - value: The raw input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the payload matches a valid integer or a standard floating point.
#   - 1: If character layouts break mathematical numeric formatting rules.
core_cli_flag_validate_float() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  if [[ "$value" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    return 0
  fi

  return 1
}

# core_cli_flag_validate_bool verifies structural boolean parameter conformity.
#
# Arguments:
#   - value: The raw input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the value perfectly matches true/false indicators (1 or 0).
#   - 1: If the input resolves to unmapped or unsafe character states.
core_cli_flag_validate_bool() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  if [ "$value" = "1" ] || [ "$value" = "0" ]; then
    return 0
  fi

  return 1
}





# core_cli_flag_validate_date verifies and infers calendar tracking timelines.
#
# Arguments:
#   - value: The raw or partial input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the sequence can be successfully inferred and represents a real day.
#   - 1: If the input layout violates partial formatting rules or is impossible.
core_cli_flag_validate_date() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  local inferred="$value"

  # Infer based on input length boundaries
  case "${#value}" in
    4)  # YYYY -> YYYY-01-01
      [[ "$value" =~ ^[0-9]{4}$ ]] || return 1
      inferred="${value}-01-01"
      ;;
    7)  # YYYY-MM -> YYYY-MM-01
      [[ "$value" =~ ^[0-9]{4}-[0-9]{2}$ ]] || return 1
      inferred="${value}-01"
      ;;
    10) # YYYY-MM-DD -> Fully formed
      [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 1
      ;;
    *)
      return 1 
      ;;
  esac

  # Assert real calendar compliance mapping via native system clock tools
  if date -d "$inferred" +%Y-%m-%d &>/dev/null; then
    CORE_CLI_VALIDATED_VALUE="$inferred"
    return 0
  elif date -j -f "%Y-%m-%d" "$inferred" +%Y-%m-%d &>/dev/null; then
    CORE_CLI_VALIDATED_VALUE="$inferred"
    return 0
  fi

  return 1
}

# core_cli_flag_validate_time verifies and infers chronological pattern constraints.
#
# Arguments:
#   - value: The raw or partial input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the sequence can be successfully inferred and represents a real time.
#   - 1: If chronological layout boundaries or numerical patterns fail format.
core_cli_flag_validate_time() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  local inferred="$value"

  case "${#value}" in
    2)  # HH -> HH:00:00
      [[ "$value" =~ ^[0-9]{2}$ ]] || return 1
      inferred="${value}:00:00"
      ;;
    5)  # HH:MM -> HH:MM:00
      [[ "$value" =~ ^[0-9]{2}:[0-9]{2}$ ]] || return 1
      inferred="${value}:00"
      ;;
    8)  # HH:MM:SS -> Fully formed
      [[ "$value" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || return 1
      ;;
    *)
      return 1 
      ;;
  esac

  # Strict chronological time bounds check on the fully inferred string
  local time_regex="^([0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$"
  if [[ "$inferred" =~ $time_regex ]]; then
    CORE_CLI_VALIDATED_VALUE="$inferred"
    return 0
  fi

  return 1
}

# core_cli_flag_validate_datetime verifies combined calendar timestamp constraints.
#
# Arguments:
#   - value: The raw or partial input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the sequence satisfies or infers a real unified timestamp.
#   - 1: If the timestamp breaks layout rules or contains impossible dates.
core_cli_flag_validate_datetime() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  local date_part=""
  local time_part=""

  # Separate input into date and time tokens if space delimiter exists
  if [[ "$value" == *[[:space:]]* ]]; then
    date_part="${value%% *}"
    time_part="${value#* }"
  else
    # If no space, evaluate if input belongs to date portion or time portion
    if [[ "$value" == *:* ]]; then
      date_part="0001-01-01"
      time_part="$value"
    else
      date_part="$value"
      time_part="00:00:00"
    fi
  fi

  # Delegate inference and validation to sub-components cleanly
  if ! core_cli_flag_validate_date "$date_part"; then
    return 1
  fi
  local clean_date="$CORE_CLI_VALIDATED_VALUE"

  if ! core_cli_flag_validate_time "$time_part"; then
    return 1
  fi
  local clean_time="$CORE_CLI_VALIDATED_VALUE"

  # Consolidate inferred results back into global pipeline registers
  CORE_CLI_VALIDATED_VALUE="${clean_date} ${clean_time}"
  return 0
}

# core_cli_flag_validate_email verifies internet mailbox address structure masks.
#
# Arguments:
#   - value: The raw input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the target sequence satisfies a valid standard email address mask.
#   - 1: If structural domain names, identifiers, or at-sign boundaries fail.
core_cli_flag_validate_email() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  local email_regex="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
  if [[ "$value" =~ $email_regex ]]; then
    return 0
  fi

  return 1
}

# core_cli_flag_validate_enum evaluates membership against active dictionary arrays.
#
# Arguments:
#   - value: The raw input string payload to be evaluated.
#   - aux: The target global index dictionary array name acting as an enum pointer.
#
# Returns:
#   - 0: If the target input matches one of the authorized array keys/values.
#   - 1: If the dictionary reference is empty or membership evaluation fails.
core_cli_flag_validate_enum() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  # Re-assert if the pointer array exists inside the active configuration runtime
  if [ -z "$array_name" ] || ! declare -p "$array_name" &> /dev/null; then
    return 1
  fi

  # Establish a native reference alias linking directly to the global dictionary array
  local -n target_array="$array_name"

  # Check if the input exists as a value or an aliased group literal string
  for item in "${target_array[@]}"; do
    if [ "$value" = "$item" ]; then
      return 0
    fi
  done

  return 1
}

# core_cli_flag_validate_json checks structural syntax boundary masks for json content.
#
# Arguments:
#   - value: The raw input string payload to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the string matches a baseline valid flat JSON object sequence.
#   - 1: If the input layout violates syntax state routing or token boundaries.
core_cli_flag_validate_json() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  # Perform native extreme trim removing leading and trailing space characters
  input=$(echo "$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

  # 1. Enforce physical outer structural boundaries verification
  if [[ ! "$input" =~ ^\{.*\}$ ]] && [[ ! "$input" =~ ^\[.*\]$ ]]; then
    return 1
  fi

  # Support trivial minimal representation states immediately
  if [ "$input" = "{}" ] || [ "$input" = "[]" ]; then
    CORE_CLI_VALIDATED_VALUE="$input"
    return 0
  fi

  # State routing flags: 
  # state: 0=expect_key, 1=expect_colon, 2=expect_value, 3=expect_comma_or_end
  local state=0
  local in_quotes=0
  local current_token=""
  local normalized_json="{"
  
  # Strip the outermost wrapping brackets to isolate the core stream content
  local payload="${input#?}"
  payload="${payload%?}"

  local len=${#payload}
  local idx=0

  # 2. Execute deep character-by-character validation loop pipeline
  while [ "$idx" -lt "$len" ]; do
    local char="${payload:$idx:1}"
    
    if [ "$in_quotes" -eq 1 ]; then
      # Handle escaping character masks lookahead safely
      if [ "$char" = "\\" ]; then
        local next_idx=$((idx + 1))
        local next_char="${payload:$next_idx:1}"
        current_token+="${char}${next_char}"
        idx=$((idx + 2))
        continue
      fi

      if [ "$char" = '"' ]; then
        in_quotes=0
        # Finalize active string block token evaluation depending on engine state
        if [ "$state" -eq 0 ]; then
          # Validate that keys conform strictly to safe corporate ASCII guidelines
          if [[ ! "$current_token" =~ ^[A-Za-z0-9_-]+$ ]]; then
            return 1
          fi
          normalized_json+="\"${current_token}\""
          state=1 # Advance state layout router to expect a colon ':'
        elif [ "$state" -eq 2 ]; then
          normalized_json+="\"${current_token}\""
          state=3 # Advance state layout router to expect a comma ',' or end '}'
        fi
        current_token=""
      else
        current_token+="$char"
      fi
    else
      # Outside quotes: ignore whitespace components entirely
      if [[ "$char" =~ [[:space:]] ]]; then
        idx=$((idx + 1))
        continue
      fi

      case "$char" in
        '"')
          in_quotes=1
          if [ "$state" -ne 0 ] && [ "$state" -ne 2 ]; then
            return 1 # Unexpected quote placement detected
          fi
          ;;
        ':')
          if [ "$state" -ne 1 ]; then return 1; fi
          normalized_json+=":"
          state=2 # Advance state layout router to expect a value string
          ;;
        ',')
          if [ "$state" -ne 3 ]; then return 1; fi
          normalized_json+=","
          state=0 # Reset state layout router back to expect a new key string
          ;;
        *)
          # Catch numbers, booleans or nulls if unquoted value assignment occurs
          if [ "$state" -eq 2 ]; then
            current_token+="$char"
            # Fast lookahead peek ahead until non-alphanumeric or delimiter is found
            local next_idx=$((idx + 1))
            local next_char="${payload:$next_idx:1}"
            if [[ "$next_char" =~ [,:[:space:]\}] ]] || [ "$next_idx" -eq "$len" ]; then
              if [[ "$current_token" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
                 [ "$current_token" = "true" ] || \
                 [ "$current_token" = "false" ] || \
                 [ "$current_token" = "null" ]; then
                normalized_json+="$current_token"
                current_token=""
                state=3
              else
                return 1 # Invalid unquoted primitive content format type intercepted
              fi
            fi
          else
            return 1 # Structural illegal character encountered outside quotes string bounds
          fi
          ;;
      esac
    fi
    idx=$((idx + 1))
  done

  # 3. Assert target machine integrity boundaries upon pipeline termination
  if [ "$in_quotes" -ne 0 ] || [ "$state" -ne 3 ]; then
    return 1 # Open quotes string state or trailing comma structural corruption
  fi

  normalized_json+="}"
  CORE_CLI_VALIDATED_VALUE="$normalized_json"
  return 0
}





# core_cli_flag_validate_path asserts structural path character conformity.
#
# Arguments:
#   - value: The raw input string path sequence to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the string contains only legal directory and separator characters.
#   - 1: If illegal control characters, wildcards, or null bytes are detected.
core_cli_flag_validate_path() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  # Rejects control characters, wildcards (?, *), and illegal character signs
  if [[ "$value" =~ [\x00-\x1F\x7F\*\"\?\<\>\|] ]]; then
    return 1
  fi

  return 0
}

# core_cli_flag_validate_relativepath verifies strict non-root directory masks.
#
# Arguments:
#   - value: The raw input string path sequence to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the string conforms to a path and does not initialize as root.
#   - 1: If path triggers absolute roots (/ or C:\) or contains illegal signs.
core_cli_flag_validate_relativepath() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  # Leverage core validation rules for general character checking first
  if ! core_cli_flag_validate_path "$value"; then
    return 1
  fi

  # Reject absolute Unix roots or Windows drive letters prefix structures
  if [[ "$value" =~ ^\/ ]] || [[ "$value" =~ ^[A-Za-z]:\\ ]] || [[ "$value" =~ ^[A-Za-z]:\/ ]]; then
    return 1
  fi

  return 0
}

# core_cli_flag_validate_filename asserts safe naming schemas for individual files.
#
# Arguments:
#   - value: The raw input filename token string to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the string is a valid file token without folder path dividers.
#   - 1: If slash dividers, paths tokens, or forbidden characters are present.
core_cli_flag_validate_filename() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  # File names cannot possess directory trailing slash or path separator tokens
  if [[ "$value" == *\/* ]] || [[ "$value" == *\\* ]]; then
    return 1
  fi

  # Validate against forbidden system file character specifications
  if [[ "$value" =~ [\x00-\x1F\x7F\*\"\?\<\>\|] ]] || [ -z "$value" ]; then
    return 1
  fi

  return 0
}

# core_cli_flag_validate_filepath asserts character compliance for files sequences.
#
# Arguments:
#   - value: The raw input filepath string sequence to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the string contains a legal folder and filename sequence structure.
#   - 1: If file endings are blank or contain system illegal layout markers.
core_cli_flag_validate_filepath() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  if ! core_cli_flag_validate_path "$value"; then
    return 1
  fi

  # Rejects strings terminating with a path divider trailing slash character
  if [[ "$value" =~ \/$ ]] || [[ "$value" =~ \\$ ]] || [ -z "$value" ]; then
    return 1
  fi

  return 0
}

# core_cli_flag_validate_dirname asserts safe naming schemas for single directories.
#
# Arguments:
#   - value: The raw input directory token string to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the string is a valid standalone directory name token string.
#   - 1: If path slashes delimiters or system illegal markers are present.
core_cli_flag_validate_dirname() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  # Reuses individual filename structural constraints as rules match exactly
  if ! core_cli_flag_validate_filename "$value"; then
    return 1
  fi

  return 0
}

# core_cli_flag_validate_dirpath asserts character compliance for folders trees.
#
# Arguments:
#   - value: The raw input directory path string to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the string maps to a well-formed directory path layout model.
#   - 1: If character boundaries or structural mask formatting fail check.
core_cli_flag_validate_dirpath() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  if ! core_cli_flag_validate_path "$value"; then
    return 1
  fi

  return 0
}

# core_cli_flag_validate_url checks flexible protocol or relative web address formatting.
#
# Arguments:
#   - value: The raw input web address string sequence to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the payload qualifies as either a valid absolute or relative URL.
#   - 1: If spaces or severe syntax corruption break standard address masks.
core_cli_flag_validate_url() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  if core_cli_flag_validate_fullurl "$value" || core_cli_flag_validate_relativeurl "$value"; then
    return 0
  fi

  return 1
}

# core_cli_flag_validate_fullurl asserts absolute corporate internet mask constraints.
#
# Arguments:
#   - value: The raw absolute URL address string sequence to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If schema protocol, domain boundaries, and paths layout match criteria.
#   - 1: If protocol configurations are absent or character structures fail.
core_cli_flag_validate_fullurl() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  # Enforces explicit schema protocol definitions followed by hostname validation
  local url_regex="^(https?|ftp|file):\/\/([A-Za-z0-9.-]+)(:[0-9]+)?(\/[A-Za-z0-9._%+-]*)*(\?.*)?(#.*)?$"
  if [[ "$value" =~ $url_regex ]]; then
    return 0
  fi

  return 1
}

# core_cli_flag_validate_relativeurl asserts local web path context routing masks.
#
# Arguments:
#   - value: The raw localized endpoint URI string sequence to be evaluated.
#   - aux: Optional auxiliary validation constraints configuration.
#
# Returns:
#   - 0: If the sequence establishes a clean relative path interface signature.
#   - 1: If schemas protocols are embedded or white spaces are intercepted.
core_cli_flag_validate_relativeurl() {
  local value="$1"
  local aux="$2"

  # Enforce strict terminal and structural string safety first
  if ! core_cli_flag_validate_string "$value" "$aux"; then
    return 1
  fi

  # Relative URLs must omit network protocol configurations and initialize with a forward slash
  if [[ "$value" =~ ^https?:\/\/ ]] || [[ "$value" =~ ^ftp:\/\/ ]]; then
    return 1
  fi

  if [[ "$value" =~ ^\/[A-Za-z0-9._%+-]*(\/[A-Za-z0-9._%+-]*)*(\?.*)?(#.*)?$ ]]; then
    return 0
  fi

  return 1
}

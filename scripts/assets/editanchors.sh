#!/bin/bash

# ------------------------------------------------------------------------------
# TEMPLATE ANCHOR EXTRACTION & INJECTION
# ------------------------------------------------------------------------------

# verify_anchor_pair_layout checks a single anchor prefix for strict start/end blocks.
#
# Arguments:
#   - file: The absolute path to the target Go file.
#   - anchor_prefix: The semantic token identifier prefix (e.g., X_ANCHOR_PKGCTX).
#
# Returns:
#   - 0: If both the START block and END block match their exact structural layout.
#   - 1: If either the START or END multi-line signature layout is broken.
verify_anchor_pair_layout() {
  local file="$1"
  local prefix="$2"

  # 1. Assert START anchor layout (expects two blank comment lines above the token)
  if ! awk -v target="${prefix}_START" '
    /\/\// {
      l1=$0; getline; l2=$0; getline; l3=$0;
      if (l1 ~ /\/\// && l2 ~ /\/\// && l3 ~ target) { exit 0 }
    }
    END { exit 1 }
  ' "$file"; then
    VALIDATION_ERROR_MSG="Structural corruption: '${prefix}_START' block layout is invalid or missing"
    return 1
  fi

  # 2. Assert END anchor layout (expects two blank comment lines below the token)
  if ! awk -v target="${prefix}_END" '
    $0 ~ target {
      l1=$0; getline; l2=$0; getline; l3=$0;
      if (l1 ~ target && l2 ~ /\/\// && l3 ~ /\/\//) { exit 0 }
    }
    END { exit 1 }
  ' "$file"; then
    VALIDATION_ERROR_MSG="Structural corruption: '${prefix}_END' block layout is invalid or missing"
    return 1
  fi

  return 0
}

# assert_xerrors_file_integrity validates the structural layout anchors inside xerrors.go.
#
# Arguments:
#   - filepath: The absolute file path to the target xerrors.go file to test.
#
# Returns:
#   - 0: If the target file exists and all multi-line anchors are perfectly intact.
#   - 1: If the file is missing or any strict visual signature boundary is broken.
assert_xerrors_file_integrity() {
  local file="$1"

  # 1. Assert physical file existence
  if [ ! -f "$file" ]; then
    VALIDATION_ERROR_MSG="Target file '${file}' not found. Ensure the scope configuration is correct."
    return 1
  fi

  # 2. Define all semantic base components to evaluate sequentially
  local anchor_prefixes=(
    "X_ANCHOR_PKGCTX"
    "X_ANCHOR_CONSTANTS"
    "X_ANCHOR_REGISTRY"
  )

  # Iterate through prefixes using the centralized layout validator
  for prefix in "${anchor_prefixes[@]}"; do
    if ! verify_anchor_pair_layout "$file" "$prefix"; then
      # Forward the upstream specific validation message populated by the checker
      return 1
    fi
  done

  return 0
}

# get_anchor_block_content extracts lines and raw text bounded by a specific anchor pair.
#
# Arguments:
#   - file: The absolute physical path to the target source file.
#   - anchor_prefix: The semantic prefix of the tracking anchors (e.g., X_ANCHOR_PKGCTX).
#
# Returns:
#   - 0: Successfully located the blocks and streamed the layout content to stdout.
#   - 1: If either start or end anchors cannot be identified inside the target stream.
get_anchor_block_content() {
  local file="$1"
  local prefix="$2"

  local start_target="${prefix}_START"
  local end_target="${prefix}_END"

  # Find the exact line numbers where the markers reside using grep
  local start_ln
  start_ln=$(grep -n "$start_target" "$file" | cut -d':' -f1 | head -n1)
  local end_ln
  end_ln=$(grep -n "$end_target" "$file" | cut -d':' -f1 | head -n1)

  if [ -z "$start_ln" ] || [ -z "$end_ln" ]; then
    VALIDATION_ERROR_MSG="Block extraction failure: Could not resolve lines for anchor '${prefix}'"
    return 1
  fi

  # Output the line bounds metadata convention string on the first line
  echo "${start_ln}::${end_ln}"
  echo "" # Mandatory empty line providing visual and parsing breathing space

  # Stream the exact interior block content utilizing sed line boundaries filtering
  sed -n "$((start_ln + 1)),$((end_ln - 1))p" "$file"
  return 0
}

# parse_family_error_bounds extracts maximum sequential error bounds per family context.
#
# Arguments:
#   - block_content: The comprehensive raw string block output from the constants anchor.
#
# Returns:
#   - 0: Always terminates with success after populating global indexed registers.
parse_family_error_bounds() {
  local block_content="$1"

  # Reset tracking global indexed buffer state entirely
  FAMILY_MAX_CODES=()

  local current_family=0
  local family_regex="=== Family:[[:space:]]*([0-9]+)"
  local code_regex='"E([0-9]+)"'

  # Convert block contents into a line-by-line stream reading loop
  while IFS= read -r line || [ -n "$line" ]; do
    # 1. Catch current working family context bounds transition
    if [[ "$line" =~ $family_regex ]]; then
      current_family="${BASH_REMATCH[1]}"
    fi

    # 2. Catch individual error allocation identifiers under active family context
    if [ "$current_family" -gt 0 ]; then
      if [[ "$line" =~ $code_regex ]]; then
        local full_num="${BASH_REMATCH[1]}"
        local current_max="${FAMILY_MAX_CODES[$current_family]}"

        # Mutate array sequence bound if empty or higher numeric sequence found
        if [ -z "$current_max" ] || [ "$full_num" -gt "$current_max" ]; then
          FAMILY_MAX_CODES[$current_family]=$full_num
        fi
      fi
    fi
  done <<< "$block_content"

  return 0
}

# parse_package_context_metadata extracts baseline packages context metadata variables.
#
# Arguments:
#   - block_content: The comprehensive raw string block output from the pkgctx anchor.
#
# Returns:
#   - 0: Always terminates with success after populating global associative registers.
parse_package_context_metadata() {
  local block_content="$1"

  # Reset target dynamic global lookup tracking cache entirely
  PARSED_PKG_CONTEXT=()

  # Regex captures pattern: CONSTANT_NAME xerrors.ErrorCode = "STRING_VALUE"
  local context_regex='(XERR_[A-Z0-9_]*)[[:space:]]+xerrors\.ErrorCode[[:space:]]*=[[:space:]]*"([^"]+)"'

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" =~ $context_regex ]]; then
      local constant_name="${BASH_REMATCH[1]}"
      local string_value="${BASH_REMATCH[2]}"

      # Commit extracted parameters onto global dynamic associative registers
      PARSED_PKG_CONTEXT["$constant_name"]="$string_value"
    fi
  done <<< "$block_content"

  return 0
}

# check_token_duplication asserts if an error constant token already exists in the file content.
#
# Arguments:
#   - file: The absolute physical path to the target Go matrix file.
#   - token: The uppercase snake case constant token string to check (e.g., XERR_UNKNOWN).
#
# Returns:
#   - 0: If the token sequence is unique and does not cause a naming collision.
#   - 1: If the constant string is already registered anywhere inside the target file.
check_token_duplication() {
  local file="$1"
  local token="$2"

  # Perform a precise regular expression search checking for tabs or spaces boundaries
  # around the token to prevent false-positives with substrings names
  if grep -q -E "([[:space:]]|\t)${token}[[:space:]]" "$file"; then
    VALIDATION_ERROR_MSG="Token constant '${token}' already exists inside registry. Aborting to protect consistency."
    return 1
  fi

  return 0
}

# assert_base_context_presence verifies that the root package context constant is mapped.
#
# Returns:
#   - 0: If the core XERR_PKGCTX constant and value strings are validly populated.
#   - 1: If the base package context maps are completely missing or empty.
assert_base_context_presence() {
  local base_val="${PARSED_PKG_CONTEXT["XERR_PKGCTX"]}"

  if [ -z "$base_val" ]; then
    VALIDATION_ERROR_MSG="Context resolution failure: Could not locate the baseline XERR_PKGCTX definition inside the target file."
    return 1
  fi

  return 0
}

# inject_code_block_before_marker performs structural text slicing inside files.
#
# Arguments:
#   - file: The absolute path to the target source file.
#   - marker: The search string token identifying the next family context.
#   - fallback_anchor: The string visual anchor applied if marker is not detected.
#   - block_to_inject: The comprehensive multiline string to append.
#
# Returns:
#   - 0: Successfully updated the target physical file state.
inject_code_block_before_marker() {
  local file="$1"
  local marker="$2"
  local fallback_anchor="$3"
  local block_to_inject="$4"

  if grep -q "$marker" "$file"; then
    # Look for the last standard separator line right above the next family context match
    # Reconstruct the file dynamically utilizing an inline awk process stream
    awk -v target="$marker" -v injection="$block_to_inject" '
      BEGIN { found=0 }
      $0 ~ target && !found {
        print injection $0
        found=1
        next
      }
      { print $0 }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  else
    # Fallback directly to the visual section tail anchor constraint
    # We escape slashes safely to prevent standard sed interpretation issues
    local escaped_block
    escaped_block=$(echo "$block_to_inject" | sed 's:/::\\/:g')
    sed -i "s/\/\/ ${fallback_anchor}/${escaped_block}  \/\/ ${fallback_anchor}/g" "$file"
  fi

  return 0
}

# inject_content_at_anchor_tail performs surgical string insertions before target markers.
#
# Arguments:
#   - file: The absolute physical path to the target source code file.
#   - anchor_end_name: The exact string signature of the closing anchor (e.g., X_ANCHOR_CONSTANTS_END).
#   - block_content: The comprehensive raw multi-line text payload block to append.
#
# Returns:
#   - 0: If the insertion executes successfully and updates the file.
#   - 1: If the targeted anchor line can not be located.
inject_content_at_anchor_tail() {
  local file="$1"
  local anchor_end="$2"
  local block_content="$3"

  # Find the exact physical line number where the closing anchor resides
  local target_line
  target_line=$(grep -n "$anchor_end" "$file" | cut -d':' -f1 | head -n1)

  if [ -z "$target_line" ]; then
    VALIDATION_ERROR_MSG="Injection engine failure: Closing anchor '${anchor_end}' undetected"
    return 1
  fi

  # Escape special backslashes characters inside the block to preserve layout compliance
  # and execute surgical insertion using an optimized line-based awk stream
  awk -v target_ln="$target_line" -v injection="$block_content" '
    NR == target_ln {
      print injection $0
      next
    }
    { print $0 }
  ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

  return 0
}

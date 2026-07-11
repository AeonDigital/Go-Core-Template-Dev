#!/bin/bash

# ==============================================================================
# SCRIPT: core_cli/utils/math.sh
# DESCRIPTION: Native arbitrary-precision string math library processing 
#              decimal and float comparison boundaries in pure Bash.
# ==============================================================================

# core_cli_math_compare_float compares two string-formatted decimal numbers.
#
# Arguments:
#   - val1: The first string decimal number to compare.
#   - val2: The second string decimal number acting as the boundary threshold.
#   - strict_mode: If "1", forces exclusive inequality (e.g., > or < instead of >= or <=).
#                  Defaults to "0" (inclusive inequality).
#
# Returns:
#   - 0: If val1 is strictly greater than val2 (or equal when strict_mode=0).
#   - 1: If val1 is less than val2 (or equal when strict_mode=1).
core_cli_math_compare_float() {
  local val1="$1"
  local val2="$2"
  local strict="${3:-0}"

  # Extract integer and decimal components using native pattern stripping
  local int1="${val1%%.*}"
  local int2="${val2%%.*}"
  local dec1="${val1#*.}"
  local dec2="${val2#*.}"

  # Fallback to zero if no decimal point exists in the string sequence
  [[ "$val1" != *.* ]] && dec1="0"
  [[ "$val2" != *.* ]] && dec2="0"

  # Normalize negative zero string alignments natively (-0 -> 0)
  [ "$int1" = "-0" ] && int1="0"
  [ "$int2" = "-0" ] && int2="0"

  # 1. Coordinate primary integer comparison logic
  if (( int1 > int2 )); then
    return 0
  elif (( int1 < int2 )); then
    return 1
  fi

  # 2. Integer components are equal: normalize decimal length matrices (Zero padding)
  local len1=${#dec1}
  local len2=${#dec2}

  if (( len1 < len2 )); then
    while (( ${#dec1} < len2 )); do dec1="${dec1}0"; done
  elif (( len2 < len1 )); then
    while (( ${#dec2} < len1 )); do dec2="${dec2}0"; done
  fi

  # 3. Coordinate secondary fractional comparison logic
  if (( dec1 > dec2 )); then
    return 0
  elif (( dec1 < dec2 )); then
    return 1
  fi

  # 4. Values are mathematically identical: evaluate strict operational parameters
  if [ "$strict" = "1" ]; then
    return 1 # Rejected as inclusive equality was disabled
  fi

  return 0
}

# core_cli_math_is_greater_or_equal asserts if val1 is higher/equal than val2 bounds.
#
# Arguments:
#   - val1: The user input float payload value string.
#   - val2: The baseline lower minimum configuration limit threshold string.
#   - strict: If active (1), checks strictly greater than (>), rejecting equal.
#
# Returns:
#   - 0: If the verification condition is perfectly satisfied.
#   - 1: If the input falls short of the expected boundary range.
core_cli_math_is_greater_or_equal() {
  core_cli_math_compare_float "$1" "$2" "$3"
  return $?
}

# core_cli_math_is_less_or_equal asserts if val1 is lower/equal than val2 bounds.
#
# Arguments:
#   - val1: The user input float payload value string.
#   - val2: The baseline upper maximum configuration limit threshold string.
#   - strict: If active (1), checks strictly less than (<), rejecting equal.
#
# Returns:
#   - 0: If the verification condition is perfectly satisfied.
#   - 1: If the input exceeds the expected boundary range.
core_cli_math_is_less_or_equal() {
  core_cli_math_compare_float "$2" "$1" "$3"
  return $?
}

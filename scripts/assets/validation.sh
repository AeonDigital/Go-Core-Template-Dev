#!/bin/bash

# ------------------------------------------------------------------------------
# VALIDATION PIPELINES
# ------------------------------------------------------------------------------

# validate_argument orchestrates validation pipelines for single inputs.
#
# Arguments:
#   - value: The raw input string payload to be evaluated.
#   - allowed_enum: A space-separated list of exact matching valid options.
#   - validate_fn: The name of a specific Bash function to execute.
#
# Returns:
#   - 0: If the payload passes all structural and custom boundary criteria.
#   - 1: If any constraint is violated or validation checks fail.
#
# Downstream Automation Notes:
#   - Any custom function passed to 'validate_fn' must expect two arguments
#     at runtime: the target '$value' as $1, and the '$allowed_enum' list as $2.
validate_argument() {
  local value="$1"
  local allowed_enum="$2"
  local validate_fn="$3"

  # Reset global exception reporting pipeline state
  VALIDATION_ERROR_MSG=""

  # 1. Evaluate enumeration boundary constraints if provided
  if [ -n "$allowed_enum" ]; then
    local match_found=1
    for item in $allowed_enum; do
      if [ "$value" = "$item" ]; then
        match_found=0
        break
      fi
    done

    if [ "$match_found" -ne 0 ]; then
      VALIDATION_ERROR_MSG="Value '${value}' is invalid. Allowed options are: [ ${allowed_enum} ]"
      return 1
    fi
  fi

  # 2. Delegate deep inspection to the secondary validator command if declared
  if [ -n "$validate_fn" ]; then
    # Verify if the target investigative function exists in current runtime
    if ! declare -f "$validate_fn" > /dev/null; then
      VALIDATION_ERROR_MSG="Internal routing error: Investigator function '${validate_fn}' not found"
      return 1
    fi

    # Invoke the dynamic check passing the raw value
    if ! "$validate_fn" "$value"; then
      # Fallback message if the investigator did not populate the global error
      if [ -z "$VALIDATION_ERROR_MSG" ]; then
        VALIDATION_ERROR_MSG="Value '${value}' failed validation against '${validate_fn}' ruleset"
      fi
      return 1
    fi
  fi

  return 0
}

# check_required_text_field validates that strings are populated with actual data.
#
# Arguments:
#   - value: The string sequence to evaluate.
#
# Returns:
#   - 0: If string contains characters.
#   - 1: If value resolves to an empty state.
check_required_text_field() {
  local value="$1"
  if [ -z "$value" ]; then
    VALIDATION_ERROR_MSG="This field parameter is mandatory and cannot be left blank."
    return 1
  fi
  return 0
}

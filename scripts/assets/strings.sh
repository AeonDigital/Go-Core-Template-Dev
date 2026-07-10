#!/bin/bash

# ------------------------------------------------------------------------------
# TOOLS & FUNCTIONS: STRING TRANSFORMATION & VALIDATION
# ------------------------------------------------------------------------------

# to_snake_upper_case converts text strings into strict uppercase snake layout.
#
# Arguments:
#   - input: The raw text string containing spaces, camelCase, or snake_case.
#
# Returns:
#   - string: The standardized token transformed to SNAKE_CASE_UPPERCASE.
#
# Operational Constraints:
#   - Performs leading and trailing space stripping before parsing.
#   - Safely returns an empty string sequence if the input resolves to null.
to_snake_upper_case() {
  local input="$1"
  
  # Perform leading and trailing white space trimming
  input=$(echo "$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  
  if [ -z "$input" ]; then
    echo ""
    return
  fi

  # Inject an underscore prior to any uppercase character preceded by lowercase letters or digits,
  # then map the entire resulting sequence to its uppercase equivalent.
  echo "$input" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:lower:]' '[:upper:]'
}

# validate_token asserts if a string matches strict architectural criteria.
#
# Arguments:
#   - token: The normalized string sequence to evaluate against specifications.
#
# Returns:
#   - 0: If the token sequence perfectly conforms to design boundaries.
#   - 1: If the input length fails or matches invalid structural characters.
validate_token() {
  local token="$1"
  
  # Validate character length restriction (max 32 characters)
  if [ ${#token} -eq 0 ] || [ ${#token} -gt 32 ]; then
    return 1 # False
  fi
  
  # Validate token layout using native Bash regular expression matching
  if [[ "$token" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
    return 0 # True
  fi
  
  return 1 # False
}

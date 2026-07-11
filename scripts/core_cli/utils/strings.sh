#!/bin/bash

# ==============================================================================
# SCRIPT: core_cli/utils/strings.sh
# DESCRIPTION: Native utility operations processing safe character wrapping
#              and dynamic terminal geometry line adjustments.
# ==============================================================================

# core_cli_string_wrap formats long paragraphs into word-wrapped lines.
#
# Arguments:
#   - text: The comprehensive raw text string sentence to be wrapped.
#   - max_width: Optional static numeric upper boundary character width limit.
#                Defaults to 80 characters if left empty or unassigned.
#
# Returns:
#   - 0: Always terminates with success echoing the formatted paragraphs.
core_cli_string_wrap() {
  local raw_text="$1"
  local target_width="${2:-80}"

  # Capture the current terminal window column geometry count dynamically
  local term_cols
  if term_cols=$(tput cols 2>/dev/null); then
    # If the user terminal window is narrower than our limit, adapt to its width
    if [ "$term_cols" -lt "$target_width" ] && [ "$term_cols" -gt 20 ]; then
      target_width="$term_cols"
    fi
  fi

  # Enforce hard boundaries constraint ceiling to protect horizontal standard
  if [ "$target_width" -gt 120 ]; then
    target_width=120
  fi

  # Process paragraph lines natively utilizing the system standard word wrap calculator
  echo "$raw_text" | fmt -w "$target_width"

  return 0
}

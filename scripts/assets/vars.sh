#!/bin/bash
# ------------------------------------------------------------------------------
# GLOBAL VARIABLE DECLARATIONS
# ------------------------------------------------------------------------------

# Global buffer storing the dynamically discovered absolute root directory path of the project
declare -g ROOT_PATH=""

# Global variable to store specific failure reasons across validation chains
declare -g VALIDATION_ERROR_MSG=""

# Global associative array storing the evaluated key-value outputs of parsed flags
declare -gA PARSED_FLAGS=()

# Global indexed array mapping Family IDs to their maximum active numerical error code sequence
declare -gA FAMILY_MAX_CODES=()

# Global associative array storing the baseline package context keys and string values
declare -gA PARSED_PKG_CONTEXT=()

# Global immutable framework layout divider standard bar string configuration
declare -g DIVIDER_BAR="// ============================================================================"

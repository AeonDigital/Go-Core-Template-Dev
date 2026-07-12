#!/bin/bash

# ==============================================================================
# SCRIPT: core_cli/vars.sh
# DESCRIPTION: Shared runtime variables and framework-wide constants for core_cli.
# ==============================================================================

# Root path used by the framework to locate the current workspace context.
declare -g CORE_CLI_ROOT_PATH=""

# Global associative array capturing raw un-validated token indicators from the CLI
declare -gA CORE_CLI_RAW_INPUTS=()

# Global tracking variables mapping active resource execution layers
declare -g CORE_CLI_ACTIVE_PKG=""
declare -g CORE_CLI_ACTIVE_COMMAND_TREE=""
declare -g CORE_CLI_TRIGGER_HELP="0"
declare -g CORE_CLI_TRIGGER_INTERACTIVE="0"

# Global buffer storing the successfully validated, normalized, and inferred data
# values processed during flag evaluation pipelines.
declare -g CORE_CLI_VALIDATED_VALUE=""

# Global indexed array storing the fully parsed and clean elements of an evaluated list.
declare -ga CORE_CLI_VALIDATED_ARRAY=()

# Global associative array mapping the clean key-value pairs of an evaluated dictionary.
declare -gA CORE_CLI_VALIDATED_ASSOC=()

# Global variable applied across execution pipelines to store the specific failure
# or violation reasons reported by internal validation loops.
declare -g VALIDATION_ERROR_MSG=""

# Global associative array mapping all mandatory and optional metadata schema keys
# to their framework-specified fallback default compilation values.
declare -gA CORE_METAFLAG_DEFAULTS=(
  ["short"]=""
  ["long"]=""
  ["type"]="string"
  ["array"]="0"
  ["assoc"]="0"
  ["required"]="0"
  ["default"]=""
  ["enum"]=""
  ["assoc_keys"]=""
  ["min"]=""
  ["max"]=""
  ["min_array"]=""
  ["max_array"]=""
  ["regex"]=""
  ["description"]=""
  ["tipinput"]=""
  ["validate"]=""
)

# Global indexed array defining the strict execution sequence order for evaluating
# metadata schema configuration rules during framework pre-flight compilation loops.
declare -ga CORE_METAFLAG_DEFAULTS_ORDER=(
  "short" "long" "type" "array" "assoc" "required" "default"
  "enum" "assoc_keys" "min" "max" "min_array" "max_array"
  "regex" "description" "tipinput" "validate"
)

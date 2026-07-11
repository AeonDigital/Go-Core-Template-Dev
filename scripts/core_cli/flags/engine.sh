#!/bin/bash

# ==============================================================================
# SCRIPT: core_cli/flags/engine.sh
# DESCRIPTION: Framework flag compilation filler and orchestrated runtime 
#              validation engines processing structural user argument matrices.
# ==============================================================================

# Global buffer storing the successfully validated, normalized, and inferred 
# data values processed during flag evaluation pipelines (e.g., auto-completed dates/times).
declare -g CORE_CLI_VALIDATED_VALUE=""

# Global indexed array storing the fully parsed and clean elements of an evaluated list.
declare -ga CORE_CLI_VALIDATED_ARRAY=()

# Global associative array mapping the clean key-value pairs of an evaluated dictionary.
declare -gA CORE_CLI_VALIDATED_ASSOC=()

# Global variable applied across execution pipelines to store the specific 
# failure or violation reasons reported by internal validation loops.
declare -g VALIDATION_ERROR_MSG=""

# Global associative array mapping all mandatory and optional metadata schema 
# keys to their framework-specified fallback default compilation values.
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





# core_cli_flag_fill normalizes and populates uninitialized schema metadata keys.
#
# Arguments:
#   - flag_array_name: The string name of the target global associative array.
#
# Returns:
#   - 0: Always terminates with success state after dynamically filling missing keys.
core_cli_flag_fill() {
  local flag_name="$1"
  local -n flag_ref="$flag_name"

  # Iteratively evaluate and apply official system fallbacks using data-driven keys
  for key in "${!CORE_METAFLAG_DEFAULTS[@]}"; do
    if [ -z "${flag_ref["$key"]}" ]; then
      flag_ref["$key"]="${CORE_METAFLAG_DEFAULTS["$key"]}"
    fi
  done

  return 0
}

# core_cli_flag_validate_single_value checks a scalar string against core rules.
#
# Arguments:
#   - value: The raw or inferred scalar value string to be evaluated.
#   - flag_array_name: The name of the target flag metadata configuration map.
#   - context_key: Optional dictionary key identifier for error messages.
#   - context_index: Optional indexed array counter position for error messages.
#
# Returns:
#   - 0: If the scalar value passes all type, bounds, and regex constraints.
#   - 1: If any individual constraint or system rule boundary is violated.
core_cli_flag_validate_single_value() {
  local value="$1"
  local flag_name="$2"
  local c_key="$3"
  local c_idx="$4"
  
  # Prefix variables to protect against native circular name reference bugs
  local -n _sval_rules="$flag_name"

  local l_name="--${_sval_rules["long"]}"
  local target_type="${_sval_rules["type"]}"
  local validator_fn="core_cli_flag_validate_${target_type}"

  # Build the dynamic contextual visual signature prefix uniformly
  local prefix="[ ${l_name} ]"
  [ -n "$c_key" ] && prefix+="[ key: ${c_key} ]"
  [ -n "$c_idx" ] && prefix+="[ index: ${c_idx} ]"

  # 1. Assert core type classification mask conformity
  if ! "$validator_fn" "$value" "${_sval_rules["enum"]}"; then
    VALIDATION_ERROR_MSG="[ x ] ${prefix} :: value '${value}' violates type '${target_type}'."
    return 1
  fi

  # Synchronize potential completion updates from inference pipelines
  [ -n "$CORE_CLI_VALIDATED_VALUE" ] && value="$CORE_CLI_VALIDATED_VALUE"

  # 2. Evaluate scalar boundary limitations (min / max bounds)
  if [ -n "${_sval_rules["min"]}" ] || [ -n "${_sval_rules["max"]}" ]; then
    if [ "$target_type" = "int" ]; then
      if [ -n "${_sval_rules["min"]}" ] && (( value < ${_sval_rules["min"]} )); then
        VALIDATION_ERROR_MSG="[ x ] ${prefix} :: value violates minimum allowed (min: ${_sval_rules["min"]})."
        return 1
      fi
      if [ -n "${_sval_rules["max"]}" ] && (( value > ${_sval_rules["max"]} )); then
        VALIDATION_ERROR_MSG="[ x ] ${prefix} :: value violates maximum allowed (max: ${_sval_rules["max"]})."
        return 1
      fi
    elif [ "$target_type" = "float" ]; then
      if [ -n "${_sval_rules["min"]}" ]; then
        if ! core_cli_math_is_greater_or_equal "$value" "${_sval_rules["min"]}" "0"; then
          VALIDATION_ERROR_MSG="[ x ] ${prefix} :: value violates minimum allowed (min: ${_sval_rules["min"]})."
          return 1
        fi
      fi
      if [ -n "${_sval_rules["max"]}" ]; then
        if ! core_cli_math_is_less_or_equal "$value" "${_sval_rules["max"]}" "0"; then
          VALIDATION_ERROR_MSG="[ x ] ${prefix} :: value violates maximum allowed (max: ${_sval_rules["max"]})."
          return 1
        fi
      fi
    elif [[ "$target_type" =~ ^(date|time|datetime)$ ]]; then
      # Chronological epoch timestamp processing alignment via system tools
      local val_sec=$(date -d "$value" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$value" +%s 2>/dev/null)
      
      if [ -n "${_sval_rules["min"]}" ]; then
        local min_sec=$(date -d "${_sval_rules["min"]}" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "${_sval_rules["min"]}" +%s 2>/dev/null)
        if [ -n "$min_sec" ] && [ "$val_sec" -lt "$min_sec" ]; then
          VALIDATION_ERROR_MSG="[ x ] ${prefix} :: value violates minimum allowed (min: ${_sval_rules["min"]})."
          return 1
        fi
      fi
      if [ -n "${_sval_rules["max"]}" ]; then
        local max_sec=$(date -d "${_sval_rules["max"]}" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "${_sval_rules["max"]}" +%s 2>/dev/null)
        if [ -n "$max_sec" ] && [ "$val_sec" -gt "$max_sec" ]; then
          VALIDATION_ERROR_MSG="[ x ] ${prefix} :: value violates maximum allowed (max: ${_sval_rules["max"]})."
          return 1
        fi
      fi
    else
      # Text strings and system paths length evaluation (Character count)
      if [ -n "${_sval_rules["min"]}" ] && [ "${#value}" -lt "${_sval_rules["min"]}" ]; then
        VALIDATION_ERROR_MSG="[ x ] ${prefix} :: character length is lower than required (min: ${_sval_rules["min"]})."
        return 1
      fi
      if [ -n "${_sval_rules["max"]}" ] && [ "${#value}" -gt "${_sval_rules["max"]}" ]; then
        VALIDATION_ERROR_MSG="[ x ] ${prefix} :: character length is bigger than required (max: ${_sval_rules["max"]})."
        return 1
      fi
    fi
  fi

  # 3. Assert static regular expression custom mask rules if configured
  if [ -n "${_sval_rules["regex"]}" ] && [[ ! "$value" =~ ${_sval_rules["regex"]} ]]; then
    VALIDATION_ERROR_MSG="[ x ] ${prefix} :: does not match with regular expression (regex: ${_sval_rules["regex"]} )."
    return 1
  fi

  # 4. Invoke secondary domain custom developer function hooks FOR THIS SPECIFIC VALUE
  if [ -n "${_sval_rules["validate"]}" ]; then
    for custom_fn in ${_sval_rules["validate"]}; do
      if declare -f "$custom_fn" >/dev/null; then
        if ! "$custom_fn" "$value"; then
          # Ensure custom message maps precisely to the required signature format
          if [[ ! "$VALIDATION_ERROR_MSG" =~ ^\[[[:space:]]*x[[:space:]]*\] ]]; then
            VALIDATION_ERROR_MSG="[ x ] ${prefix} :: ${VALIDATION_ERROR_MSG}"
          fi
          return 1
        fi
      fi
    done
  fi

  return 0
}

# core_cli_flag_validate_value asserts arguments against compiled metadata matrices.
#
# Arguments:
#   - value: The raw parameter argument string typed by the user terminal.
#   - flag_array_name: The name of the fully filled flag metadata configuration map.
#
# Returns:
#   - 0: If the user input perfectly satisfies all rule constraints.
#   - 1: If any boundary, type mask, collection, or custom validator fails.
core_cli_flag_validate_value() {
  local value="$1"
  local flag_name="$2"
  
  # Prefix variables to protect against native circular name reference bugs
  local -n _vval_rules="$flag_name"

  local l_name="--${_vval_rules["long"]}"

  # 1. Evaluate primitive presence constraints (Required checking)
  if [ "${_vval_rules["required"]}" = "1" ] && [ -z "$value" ]; then
    VALIDATION_ERROR_MSG="[ x ] [ ${l_name} ] :: cannot be empty or omitted."
    return 1
  fi

  # Skip further validation checking loops if optional parameter is empty
  if [ -z "$value" ] && [ "${_vval_rules["required"]}" = "0" ]; then
    CORE_CLI_VALIDATED_VALUE="${_vval_rules["default"]}"
    CORE_CLI_VALIDATED_ARRAY=()
    CORE_CLI_VALIDATED_ASSOC=()
    return 0
  fi

  # 2. Direct data routing evaluation according to array layout configurations
  if [ "${_vval_rules["array"]}" = "1" ]; then
    if ! core_cli_flag_validate_array "$value"; then
      VALIDATION_ERROR_MSG="[ x ] [ ${l_name} ] :: must be a valid array collection []."
      return 1
    fi

    core_cli_flag_extract_array "$value"
    
    local count=0
    for current_token in "${CORE_CLI_VALIDATED_ARRAY[@]}"; do
      if ! core_cli_flag_validate_single_value "$current_token" "$flag_name" "" "$count"; then
        return 1
      fi
      count=$((count + 1))
    done

    # Validate overall collection sizing array length restrictions
    local total_elements="${#CORE_CLI_VALIDATED_ARRAY[@]}"
    if [ -n "${_vval_rules["min_array"]}" ] && [ "$total_elements" -lt "${_vval_rules["min_array"]}" ]; then
      VALIDATION_ERROR_MSG="[ x ] [ ${l_name} ] :: collection violates minimum item count (min_array: ${_vval_rules["min_array"]})."
      return 1
    fi
    if [ -n "${_vval_rules["max_array"]}" ] && [ "$total_elements" -gt "${_vval_rules["max_array"]}" ]; then
      VALIDATION_ERROR_MSG="[ x ] [ ${l_name} ] :: collection violates maximum item count (max_array: ${_vval_rules["max_array"]})."
      return 1
    fi

    CORE_CLI_VALIDATED_VALUE="$value"

  # 3. Direct data routing evaluation according to map dictionary layouts
  elif [ "${_vval_rules["assoc"]}" = "1" ]; then
    if ! core_cli_flag_validate_json "$value"; then
      VALIDATION_ERROR_MSG="[ x ] [ ${l_name} ] :: must be a valid json string."
      return 1
    fi

    core_cli_flag_extract_assoc "$value"

    # Enforce strict sorted predictability over mandatory structural key checks
    if [ -n "${_vval_rules["assoc_keys"]}" ]; then
      local keys_list="${_vval_rules["assoc_keys"]}"
      # Split, clear whitespace and pass through sort to guarantee predictable order
      local sorted_expected_keys
      sorted_expected_keys=$(echo "${keys_list// /}" | tr ',' '\n' | sort)

      while IFS= read -r expected || [ -n "$expected" ]; do
        [ -z "$expected" ] && continue
        if [ -z "${CORE_CLI_VALIDATED_ASSOC["$expected"]+exists}" ]; then
          VALIDATION_ERROR_MSG="[ x ] [ ${l_name} ] :: required key '${expected}' is missing."
          return 1
        fi
      done <<< "$sorted_expected_keys"
    fi

    # Sort dictionary keys to provide deterministic sequential evaluation outputs
    local sorted_assoc_keys
    sorted_assoc_keys=$(echo "${!CORE_CLI_VALIDATED_ASSOC[@]}" | tr ' ' '\n' | sort)

    while IFS= read -r key || [ -n "$key" ]; do
      [ -z "$key" ] && continue
      local current_val="${CORE_CLI_VALIDATED_ASSOC["$key"]}"
      if ! core_cli_flag_validate_single_value "$current_val" "$flag_name" "$key" ""; then
        return 1
      fi
    done <<< "$sorted_assoc_keys"

    CORE_CLI_VALIDATED_VALUE="$value"

  # 4. Standard validation loop for single scalar values parameters
  else
    if ! core_cli_flag_validate_single_value "$value" "$flag_name" "" ""; then
      return 1
    fi
    value="$CORE_CLI_VALIDATED_VALUE"
  fi

  return 0
}

# core_cli_flag_validate_rules compiles and asserts a developer flag specification.
#
# Arguments:
#   - flag_array_name: The string name of the developer target associative array.
#
# Returns:
#   - 0: If the configuration schema is structurally intact and logically sound.
#   - 1: If any metadata constraint fails or a logical architectural rule breaks.
core_cli_flag_validate_rules() {
  local target_flag_name="$1"
  
  # Protect against native circular name reference bugs via strict local prefixing
  local -n _comp_flag="$target_flag_name"

  # First, ensure all uninitialized metadata keys are filled with system defaults
  core_cli_flag_fill "$target_flag_name"

  local f_label="[ flag_meta: ${target_flag_name} ]"

  # ------------------------------------------------------------------------------
  # PHASE 1: ATOMIC METADATA VALIDATION (FOLLOWING STRICT SPECIFIED ORDER)
  # ------------------------------------------------------------------------------
  for meta_key in "${CORE_METAFLAG_DEFAULTS_ORDER[@]}"; do
    local current_meta_val="${_comp_flag["$meta_key"]}"
    local meta_spec_array="METAFLAG_${meta_key}"

    # Verify if the framework schema matrix for the target meta-key exists
    if ! declare -p "$meta_spec_array" &>/dev/null; then
      VALIDATION_ERROR_MSG="[ERR] ${f_label} :: internal engine layout error. Schema array '${meta_spec_array}' is missing."
      return 1
    fi

    # Invoke the central engine validator to check the developer's assignment
    if ! core_cli_flag_validate_value "$current_meta_val" "$meta_spec_array"; then
      VALIDATION_ERROR_MSG="[ERR] ${f_label}[ key: ${meta_key} ] :: invalid design property. ${VALIDATION_ERROR_MSG}"
      return 1
    fi
  done



  # ------------------------------------------------------------------------------
  # PHASE 2: CROSS-PROPERTY LOGICAL CONSTRAINTS VERIFICATION
  # ------------------------------------------------------------------------------

  # Rule A: Exclusive Collection Layout Bounds (Array vs Assoc exclusivity)
  if [ "${_comp_flag["array"]}" = "1" ] && [ "${_comp_flag["assoc"]}" = "1" ]; then
    VALIDATION_ERROR_MSG="[ERR] ${f_label} :: structural conflict. A parameter cannot be declared as 'array' and 'assoc' simultaneously."
    return 1
  fi

  # Rule B: Conflicting Required Default Mappings (Required vs Default exclusivity)
  if [ "${_comp_flag["required"]}" = "1" ] && [ -n "${_comp_flag["default"]}" ]; then
    VALIDATION_ERROR_MSG="[ERR] ${f_label} :: logical breakdown. A mandatory 'required=1' flag cannot provision a fallback 'default' assignment."
    return 1
  fi

  # Rule C: Orphaned Structural Collection Size Constraints (min_array / max_array)
  if [ "${_comp_flag["array"]}" = "0" ]; then
    if [ -n "${_comp_flag["min_array"]}" ] || [ -n "${_comp_flag["max_array"]}" ]; then
      VALIDATION_ERROR_MSG="[ERR] ${f_label} :: design orphan. Properties 'min_array' or 'max_array' mandate 'array=1' activation."
      return 1
    fi
  fi

  # Rule D: Orphaned Map Dictionary Validation Properties (assoc_keys)
  if [ "${_comp_flag["assoc"]}" = "0" ] && [ -n "${_comp_flag["assoc_keys"]}" ]; then
    VALIDATION_ERROR_MSG="[ERR] ${f_label} :: design orphan. The property 'assoc_keys' mandates 'assoc=1' activation."
    return 1
  fi

  # Rule E: Mandatory Enum Pointer Verification (Enum type check)
  if [ "${_comp_flag["type"]}" = "enum" ] && [ -z "${_comp_flag["enum"]}" ]; then
    VALIDATION_ERROR_MSG="[ERR] ${f_label} :: configuration breakdown. Flags classifying as 'type=enum' must declare a target dynamic 'enum' pointer array name."
    return 1
  fi

  # Rule F: Collection Size Range Inversion (min_array vs max_array boundaries)
  if [ -n "${_comp_flag["min_array"]}" ] && [ -n "${_comp_flag["max_array"]}" ]; then
    if (( ${_comp_flag["min_array"]} > ${_comp_flag["max_array"]} )); then
      VALIDATION_ERROR_MSG="[ERR] ${f_label} :: logical inversion. The 'min_array' property cannot be higher than 'max_array'."
      return 1
    fi
  fi

  # Rule G: Scalar Limits Range Inversion (min vs max chronological/numerical limits)
  if [ -n "${_comp_flag["min"]}" ] && [ -n "${_comp_flag["max"]}" ]; then
    local target_type="${_comp_flag["type"]}"
    
    if [ "$target_type" = "int" ]; then
      if (( ${_comp_flag["min"]} > ${_comp_flag["max"]} )); then
        VALIDATION_ERROR_MSG="[ERR] ${f_label} :: range inversion. The 'min' mathematical limit cannot exceed 'max'."
        return 1
      fi
    elif [ "$target_type" = "float" ]; then
      if ! core_cli_math_is_less_or_equal "${_comp_flag["min"]}" "${_comp_flag["max"]}" "0"; then
        VALIDATION_ERROR_MSG="[ERR] ${f_label} :: range inversion. The 'min' decimal limit cannot exceed 'max'."
        return 1
      fi
    elif [[ "$target_type" =~ ^(date|time|datetime)$ ]]; then
      local min_sec=$(date -d "${_comp_flag["min"]}" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "${_comp_flag["min"]}" +%s 2>/dev/null)
      local max_sec=$(date -d "${_comp_flag["max"]}" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "${_comp_flag["max"]}" +%s 2>/dev/null)
      if [ -n "$min_sec" ] && [ -n "$max_sec" ] && [ "$min_sec" -gt "$max_sec" ]; then
        VALIDATION_ERROR_MSG="[ERR] ${f_label} :: range inversion. The 'min' chronological limit cannot exceed 'max'."
        return 1
      fi
    else
      # Standard character length bounds
      if (( ${_comp_flag["min"]} > ${_comp_flag["max"]} )); then
        VALIDATION_ERROR_MSG="[ERR] ${f_label} :: sizing inversion. The 'min' character length threshold cannot exceed 'max'."
        return 1
      fi
    fi
  fi

  # Rule H: Structural Integrity Validation over custom Regular Expression Masks
  if [ -n "${_comp_flag["regex"]}" ]; then
    # Test if the expression complies with the native Bash regex parser in a sandboxed command
    if ! [[ "" =~ ${_comp_flag["regex"]} ]] 2>/dev/null; then
      VALIDATION_ERROR_MSG="[ERR] ${f_label}[ key: regex ] :: syntax corruption. The regular expression pattern is malformed or invalid."
      return 1
    fi
  fi

  # Rule I: Dynamic Function Presence Checks over registered downstream validators
  if [ -n "${_comp_flag["validate"]}" ]; then
    for custom_fn in ${_comp_flag["validate"]}; do
      if ! declare -f "$custom_fn" >/dev/null; then
        VALIDATION_ERROR_MSG="[ERR] ${f_label}[ key: validate ] :: implementation gap. Custom validation investigator function '${custom_fn}' does not exist."
        return 1
      fi
    done
  fi

  # Rule J: System Reserved Keyword Collision Protection
  local check_long="${_comp_flag["long"]}"
  local check_short="${_comp_flag["short"]}"
  
  if [[ "$check_long" =~ ^(h|help|itr|interactive)$ ]] || [[ "$check_short" =~ ^(h|help|itr|interactive)$ ]]; then
    VALIDATION_ERROR_MSG="[ERR] ${f_label} :: nomenclature collision. The names 'help', 'h', 'interactive', and 'itr' are strictly reserved for framework core orchestration."
    return 1
  fi

  return 0
}

# core_cli_flag_validate orchestrates the sequential validation of all parsed CLI flags.
#
# Arguments:
#   - flag_prefix: The global naming prefix for the flag schema arrays (e.g., "FLAG").
#   - order_array_name: Name of the indexed array defining the strict evaluation order.
#   - parsed_maps_name: Name of the associative array storing the parsed user arguments.
#
# Returns:
#   - 0: If all present user arguments perfectly satisfy their compiled schemas.
#   - 1: If any configuration schema is missing or a validation rule fails.
core_cli_flag_validate() {
  local prefix_key="$1"
  local order_array="$2"
  local parsed_maps="$3"

  # Protect against native circular name reference bugs via unique local prefixes
  local -n _val_order="$order_array"
  local -n _val_parsed="$parsed_maps"

  # Iteratively process every flag defined in the developer's strict order checklist
  for flag_name in "${_val_order[@]}"; do
    local target_schema_array="${prefix_key}_${flag_name}"

    # 1. Assert physical schema definition existence in the active runtime space
    if ! declare -p "$target_schema_array" &>/dev/null; then
      VALIDATION_ERROR_MSG="[ERR] Configuration schema array '${target_schema_array}' not exists."
      return 1
    fi

    # Reference the target flag's rule matrix dynamically
    local -n _current_rules="$target_schema_array"
    local raw_user_value="${_val_parsed["$flag_name"]}"

    # 2. Invoke the central engine validator passing the user input and the schema pointer
    if ! core_cli_flag_validate_value "$raw_user_value" "$target_schema_array"; then
      return 1
    fi

    # 3. Synchronize clean inferred or default updates back into the user's parsed map registers
    _val_parsed["$flag_name"]="$CORE_CLI_VALIDATED_VALUE"
  done

  return 0
}

#!/bin/bash

# ==============================================================================
# SCRIPT: core_cli/main.sh
# DESCRIPTION: Framework root lifecycle controller driving auto-sourcing, 
#              pre-flight parsing, and deterministic execution pipelines.
# ==============================================================================

# core_cli_bootstrap_input tokenizes the entrypoint command stream parameters.
#
# Arguments:
#   - pkg_name: The uppercase canonical name of the active CLI application (e.g., XERRORS).
#   - $@: The comprehensive execution argument passdown from the terminal stream.
#
# Returns:
#   - 0: Successfully parsed the stream into routing registers and raw inputs maps.
#   - 1: If the input command architecture is severely malformed.
core_cli_bootstrap_input() {
  CORE_CLI_ACTIVE_PKG="${1:?Framework error: Package name identifier missing}"
  shift

  # Reset global ingestion registers and maps cleanly
  CORE_CLI_RAW_INPUTS=()
  CORE_CLI_ACTIVE_COMMAND_TREE=""
  CORE_CLI_TRIGGER_HELP="0"
  CORE_CLI_TRIGGER_INTERACTIVE="0"

  local positionals=()
  local has_help_keyword="0"
  local raw_arguments=("$@")
  local total_args=${#raw_arguments[@]}
  local idx=0

  # 1. Pipeline Stage A: Scan arguments separating positional commands from flags
  while [ "$idx" -lt "$total_args" ]; do
    local arg="${raw_arguments[$idx]}"

    if [[ "$arg" =~ ^- ]]; then
      # Intercept system reserved flags immediately to compute precedence
      if [ "$arg" = "-h" ] || [ "$arg" = "--help" ]; then
        CORE_CLI_TRIGGER_HELP="1"
        idx=$((idx + 1))
        continue
      fi

      if [ "$arg" = "-itr" ] || [ "$arg" = "--interactive" ]; then
        CORE_CLI_TRIGGER_INTERACTIVE="1"
        idx=$((idx + 1))
        continue
      fi

      local input_key=""
      local input_value=""

      # Parse inline key-value parameters containing equal '=' signs boundaries
      if [[ "$arg" == *=* ]]; then
        input_key="${arg%%=*}"
        input_value="${arg#*=}"
      else
        input_key="$arg"
        local next_idx=$((idx + 1))
        if [ "$next_idx" -lt "$total_args" ] && [[ ! "${raw_arguments[$next_idx]}" =~ ^- ]]; then
          input_value="${raw_arguments[$next_idx]}"
          idx="$next_idx"
        else
          input_value="1"
        fi
      fi

      input_key="${input_key#--}"
      input_key="${input_key#-}"

      if [ "${CORE_CLI_RAW_INPUTS["$input_key"]+x}" = "x" ]; then
        echo "[ x ] Duplicate flag input '${arg}'."
        return 1
      fi
      CORE_CLI_RAW_INPUTS["$input_key"]="$input_value"
      idx=$((idx + 1))
    else
      # Catch trailing 'help' as a standalone subcommand keyword token
      if [ "$arg" = "help" ]; then
        has_help_keyword="1"
        idx=$((idx + 1))
        continue
      fi
      # Accumulate pure non-flag positional commands into order arrays
      positionals+=("$arg")
      idx=$((idx + 1))
    fi
  done

  # 2. Pipeline Stage B: Enforce Strict Flag Precedence (Help completely overrides Interactive)
  if [ "$CORE_CLI_TRIGGER_HELP" = "1" ] || [ "$has_help_keyword" = "1" ]; then
    CORE_CLI_TRIGGER_HELP="1"
    CORE_CLI_TRIGGER_INTERACTIVE="0" # Force interactive mode shutdown
  fi

  # 3. Pipeline Stage C: Build N-Level Command Tree dynamically using underscores
  local total_pos="${#positionals[@]}"

  if [ "$total_pos" -eq 0 ]; then
    # Fallback to ORES root help if no positional parameters exist
    CORE_CLI_ACTIVE_COMMAND_TREE="ORES_help"
    CORE_CLI_TRIGGER_HELP="1"
  elif [ "$total_pos" -eq 1 ]; then
    # Single level command converts natively using our ORES convention prefix
    CORE_CLI_ACTIVE_COMMAND_TREE="ORES_${positionals[0]}"
  else
    # Multi-level subcommands path loop (cmd1 cmd2 action1 -> cmd1_cmd2_action1)
    local tree_buffer=""
    for ((i=0; i<total_pos; i++)); do
      if [ "$i" -gt 0 ]; then tree_buffer+="_"; fi
      tree_buffer+="${positionals[$i]}"
    done
    CORE_CLI_ACTIVE_COMMAND_TREE="$tree_buffer"
  fi

  # Synchronize contextual trigger hooks into raw input maps for routing subsystems
  if [ "$CORE_CLI_TRIGGER_HELP" = "1" ]; then
    CORE_CLI_RAW_INPUTS["_trigger_help_context"]="1"
  fi

  return 0
}

core_cli_validate_flag_aliases() {
  local p_name="$1"
  local c_tree="$2"

  local cmd_array_name="CMD_${p_name}_${c_tree}"
  local order_array_name="${cmd_array_name}_FLAG_ORDER"

  if ! declare -p "$order_array_name" &>/dev/null; then
    return 0
  fi

  local -n _val_order="$order_array_name"

  for f_token in "${_val_order[@]}"; do
    local active_schema="CMD_${p_name}_${c_tree}_FLAG_${f_token}"
    if ! [[ "$(declare -p "$active_schema" 2>/dev/null)" =~ "declare -A" ]]; then
      active_schema="CORE_CLI_RUNTIME_FLAG_${f_token}"
    fi

    local -n _act_rules="$active_schema"
    local long_key="${_act_rules["long"]}"
    local short_key="${_act_rules["short"]}"

    local has_long="0"
    local has_short="0"

    if [ "${CORE_CLI_RAW_INPUTS["$long_key"]+x}" = "x" ]; then
      has_long="1"
    fi

    if [ -n "$short_key" ] && [ "${CORE_CLI_RAW_INPUTS["$short_key"]+x}" = "x" ]; then
      has_short="1"
    fi

    if [ "$has_long" = "1" ] && [ "$has_short" = "1" ]; then
      echo "[ x ] Conflicting input: both '--${long_key}' and '-${short_key}' were supplied."
      return 1
    fi
  done

  for raw_key in "${!CORE_CLI_RAW_INPUTS[@]}"; do
    [ "$raw_key" = "_trigger_help_context" ] && continue

    local recognized="0"
    for f_token in "${_val_order[@]}"; do
      local active_schema="CMD_${p_name}_${c_tree}_FLAG_${f_token}"
      if ! [[ "$(declare -p "$active_schema" 2>/dev/null)" =~ "declare -A" ]]; then
        active_schema="CORE_CLI_RUNTIME_FLAG_${f_token}"
      fi

      local -n _act_rules="$active_schema"
      local long_key="${_act_rules["long"]}"
      local short_key="${_act_rules["short"]}"

      if [ "$raw_key" = "$long_key" ] || [ "$raw_key" = "$short_key" ]; then
        recognized="1"
        break
      fi
    done

    if [ "$recognized" = "0" ]; then
      echo "[ x ] Unknown flag input '${raw_key}'."
      return 1
    fi
  done

  return 0
}

# core_cli_command_orchestrate routes and executes the lifecycle of a command.
#
# Returns:
#   - 0: Script completed its lifecycle actions with absolute success.
#   - 1: If pre-flight checks, schema processing, or validations fail.
core_cli_command_orchestrate() {
  local p_name="$CORE_CLI_ACTIVE_PKG"
  local c_tree="$CORE_CLI_ACTIVE_COMMAND_TREE"

  # Reconstruct the canonical command array identifier prefix based on convention
  local cmd_array_name="CMD_${p_name}_${c_tree}"
  local order_array_name="${cmd_array_name}_FLAG_ORDER"

  # 1. Pre-flight Check: Verify if the primary command metadata array is registered
  if ! declare -p "$cmd_array_name" &>/dev/null; then
    echo "[ERR] Target command tree '${c_tree}' is unrecognized or unregistered in this CLI."
    return 1
  fi

  if ! core_cli_validate_flag_aliases "$p_name" "$c_tree"; then
    return 1
  fi

  local -n _corch_cmd="$cmd_array_name"

  # Handle immediate explicit help requests targeted to this contextual command
  if [ "$CORE_CLI_TRIGGER_HELP" = "1" ]; then
    # Direct execution stream routing into the dynamic contextual manual generator
    core_cli_help_render_contextual "$p_name" "$c_tree"
    return 0
  fi

  # 2. Schema Construction Layer: Resolve Global Flags and Overrides dynamically
  if declare -p "$order_array_name" &>/dev/null; then
    local -n _corch_order="$order_array_name"

    for f_token in "${_corch_order[@]}"; do
      local local_flag_ptr="CMD_${p_name}_${c_tree}_FLAG_${f_token}"
      local override_flag_map="${local_flag_ptr}_OVERRIDE"

      # Investigate the variable signature layout (String Pointer vs Associative Array)
      local var_meta
      var_meta=$(declare -p "$local_flag_ptr" 2>/dev/null)

      if [[ "$var_meta" =~ "declare -A" ]]; then
        # It is already a local specialized associative array: run atomic fill normalizer
        core_cli_flag_fill "$local_flag_ptr"
        
        # Meta-Validate developer configuration definitions before runtime validation
        if ! core_cli_flag_validate_rules "$local_flag_ptr"; then
          echo "$VALIDATION_ERROR_MSG"
          return 1
        fi
      else
        # It is a string pointer pointing to a global flag array: extract its content value
        eval "local target_global_array=\"\$$local_flag_ptr\""

        if [ -z "$target_global_array" ] || ! declare -p "$target_global_array" &>/dev/null; then
          echo "[ERR] Broken Reference Contract: Local flag link '${f_token}' points to an unregistered global array '${target_global_array}'."
          return 1
        fi

        # Instantiate a virtual runtime local copy array mimicking the global rule template
        local runtime_flag_matrix="CORE_CLI_RUNTIME_FLAG_${f_token}"
        declare -gA "$runtime_flag_matrix"
        local -n _r_matrix="$runtime_flag_matrix"
        local -n _g_matrix="$target_global_array"

        # Clone global rules metadata criteria across onto our clean runtime matrix instance
        for key in "${!_g_matrix[@]}"; do _r_matrix["$key"]="${_g_matrix["$key"]}"; done

        # Apply localized context changes if an explicit _OVERRIDE array is defined
        if declare -p "$override_flag_map" &>/dev/null; then
          local -n _o_map="$override_flag_map"
          for key in "${!_o_map[@]}"; do _r_matrix["$key"]="${_o_map["$key"]}"; done
        fi

        # Run compilation fill and meta-checks on our dynamically consolidated runtime matrix
        core_cli_flag_fill "$runtime_flag_matrix"
        if ! core_cli_flag_validate_rules "$runtime_flag_matrix"; then
          echo "$VALIDATION_ERROR_MSG"
          return 1
        fi
      fi
    done
  fi

  # 3. Data Ingestion & Parameter Capture Processing Layer
  # Prepare a command-specific definitive mapping storage register instance
  local cmd_parsed_map="CMD_${p_name}_${c_tree}_PARSED"
  declare -gA "$cmd_parsed_map"
  local -n _final_parsed="$cmd_parsed_map"

  if declare -p "$order_array_name" &>/dev/null; then
    local -n _eval_order="$order_array_name"

    for f_token in "${_eval_order[@]}"; do
      # Point to the active rule schema (local or dynamically generated runtime instance)
      local active_schema="CMD_${p_name}_${c_tree}_FLAG_${f_token}"
      if ! [[ "$(declare -p "$active_schema" 2>/dev/null)" =~ "declare -A" ]]; then
        active_schema="CORE_CLI_RUNTIME_FLAG_${f_token}"
      fi

      local -n _act_rules="$active_schema"
      local l_tag="--${_act_rules["long"]}"
      
      # Route capture based on whether the CLI operates on strict interactive loops
      if [ "$CORE_CLI_TRIGGER_INTERACTIVE" = "1" ]; then
        # INTERACTIVE MODE LOOP: Prompt field-by-field following exact FLAG_ORDER
        local input_buffer=""
        local prompt_msg="${_act_rules["tipinput"]}"
        [ -z "$prompt_msg" ] && prompt_msg="Enter value for ${l_tag}"

        while true; do
          echo -n "[ > ] ${prompt_msg}: "
          read -r input_buffer

          # Execute instant atomic data validation on input capture
          if core_cli_flag_validate_value "$input_buffer" "$active_schema"; then
            _final_parsed["$f_token"]="$CORE_CLI_VALIDATED_VALUE"
            break
          fi

          # Output atomic validation error tracing and force immediate user retry loop
          echo "$VALIDATION_ERROR_MSG"
        done
      else
        # NON-INTERACTIVE MODE LAYER: Evaluate incoming inputs from terminal streams
        if ! core_cli_flag_validate_value "$current_raw_val" "$active_schema"; then
          # Halt and output error footprint on the absolute first validation failure
          echo "$VALIDATION_ERROR_MSG"
          return 1
        fi

        # Persist safe clean validated tokens back onto command registers
        _final_parsed["$f_token"]="$CORE_CLI_VALIDATED_VALUE"
      fi
    done
  fi

  # 4. Phase 3 Business Cross-Validation Layer (cmd_pkg_resource_action_main_validate)
  local main_val_fn="cmd_$(echo "${p_name}" | tr '[:upper:]' '[:lower:]')_${c_tree}_main_validate"
  if declare -f "$main_val_fn" >/dev/null; then
    if ! "$main_val_fn"; then
      # Expecting a standard user-facing error signature [ x ] populated within VALIDATION_ERROR_MSG
      echo "$VALIDATION_ERROR_MSG"
      return 1
    fi
  fi

  # 5. Execution Fire Phase (cmd_pkg_resource_action_action)
  local action_fn="cmd_$(echo "${p_name}" | tr '[:upper:]' '[:lower:]')_${c_tree}_action"
  if ! declare -f "$action_fn" >/dev/null; then
    echo "[ERR] Implementation deficit: Contract action target function '${action_fn}' is missing from the active context runtime."
    return 1
  fi

  # Fire business logic instructions with 100% data predictability guarantees
  "$action_fn"
  return $?
}





# ------------------------------------------------------------------------------
# AUTOMATED TERMINAL HELP MANUAL GENERATORS
# ------------------------------------------------------------------------------

# core_cli_help_render_global renders the root CLI guidance and command directory.
#
# Arguments:
#   - pkg_name: The uppercase canonical name of the active CLI application.
#
# Returns:
#   - 0: Always terminates successfully after rendering the console layout.
core_cli_help_render_global() {
  local p_name="$1"

  echo "================================================================================"
  echo "  ${p_name} - Enterprise Shell Command Automation Utility"
  echo "================================================================================"
  echo ""
  echo "Usage:"
  echo "  ./$(echo "${p_name}" | tr '[:upper:]' '[:lower:]').sh <resource> <action> [flags]"
  echo "  ./$(echo "${p_name}" | tr '[:upper:]' '[:lower:]').sh <ores-action> [flags]"
  echo ""
  echo "Global System Flags:"
  echo "  -h, --help          Display guidance documentation and metadata definitions."
  echo "  -itr, --interactive Force step-by-step user interaction prompt mode."
  echo ""
  echo "Available Operational Command Tree:"

  # Scan the active runtime context to dynamically identify registered command structures
  for cmd_var in $(declare -p | cut -d'=' -f1 | rev | cut -d' ' -f1 | rev | grep "^CMD_${p_name}_" | sort); do
    # Skip metadata sub-arrays like FLAG_ORDER or OVERRIDE to isolate root commands
    if [[ "$cmd_var" == *_FLAG_* ]] || [[ "$cmd_var" == *_PARSED ]]; then
      continue
    fi

    local -n _g_cmd="$cmd_var"
    # Extract the clean tree identifier layout from the variable nomenclature string
    local raw_tree="${cmd_var#"CMD_${p_name}_"}"
    
    # Standardize the print layout: convert underscore structures back into command spacing
    local print_cmd="${raw_tree//_/ }"
    if [[ "$print_cmd" =~ ^ores[[:space:]] ]]; then
      print_cmd="${print_cmd#ores }"
    fi

    printf "  %-20s %s\n" "$print_cmd" "${_g_cmd["summary"]:-No summary documented.}"
  done
  echo "================================================================================"
  return 0
}

# core_cli_help_render_contextual builds a dynamic manual for a specific command tree.
#
# Arguments:
#   - pkg_name: The uppercase canonical name of the active CLI application.
#   - command_tree: The underscore-separated active command string identifier.
#
# Returns:
#   - 0: Always terminates successfully after rendering the contextual details.
core_cli_help_render_contextual() {
  local p_name="$1"
  local c_tree="$2"

  local cmd_array_name="CMD_${p_name}_${c_tree}"
  local order_array_name="${cmd_array_name}_FLAG_ORDER"

  if ! declare -p "$cmd_array_name" &>/dev/null; then
    core_cli_help_render_global "$p_name"
    return 0
  fi

  local -n _h_cmd="$cmd_array_name"
  local print_cmd="${c_tree//_/ }"
  [[ "$print_cmd" =~ ^ores[[:space:]] ]] && print_cmd="${print_cmd#ores }"

  echo "================================================================================"
  echo "COMMAND: ${print_cmd}"
  echo "SUMMARY: ${_h_cmd["summary"]:-No summary available.}"
  if [ -n "${_h_cmd["description"]}" ]; then
    echo "DESCRIPTION:"
    core_cli_string_wrap "${_h_cmd["description"]}" "120"
  fi
  echo "================================================================================"

  if declare -p "$order_array_name" &>/dev/null; then
    local -n _h_order="$order_array_name"
    echo "Command Parameter Flags (Evaluated in strict checklist sequence):"
    echo ""

    for f_token in "${_h_order[@]}"; do
      local local_flag_ptr="CMD_${p_name}_${c_tree}_FLAG_${f_token}"
      local active_help_schema="$local_flag_ptr"

      # Determine if the flag points to a local override or an abstract global template
      if ! [[ "$(declare -p "$local_flag_ptr" 2>/dev/null)" =~ "declare -A" ]]; then
        eval "active_help_schema=\"\$$local_flag_ptr\""
      fi

      if [ -z "$active_help_schema" ] || ! declare -p "$active_help_schema" &>/dev/null; then
        continue # Bypass broken links gracefully during help generation rendering
      fi

      local -n _f_h_rules="$active_help_schema"
      
      # Assemble the option display mask combination string
      local short_opt="${_f_h_rules["short"]}"
      local long_opt="${_f_h_rules["long"]}"
      local display_flag=""

      if [ -n "$short_opt" ]; then
        display_flag="-${short_opt}, --${long_opt}"
      else
        display_flag="    --${long_opt}"
      fi

      # Build the parameter status indicators (Required vs Optional)
      local meta_status="[optional]"
      [ "${_f_h_rules["required"]}" = "1" ] && meta_status="[REQUIRED]"

      # Extract array and assoc structural identifiers for high-density typing info
      local structural_type="${_f_h_rules["type"]}"
      [ "${_f_h_rules["array"]}" = "1" ] && structural_type="array<${structural_type}>"
      [ "${_f_h_rules["assoc"]}" = "1" ] && structural_type="map<string,${structural_type}>"

      # Render the primary compiled specification parameter line block
      printf "  %-25s %-18s %s\n" "${display_flag}" "${structural_type}" "${meta_status}"
      
      # Render the human-centric functional usage description text statement
      if [ -n "${_f_h_rules["description"]}" ]; then
        echo -n "      Description: "
        core_cli_string_wrap "${_f_h_rules["description"]}" "100" | sed '2,$s/^/                   /'
      fi

      # Render optional default fallback mapping hints if configured in the matrix
      if [ "${_f_h_rules["required"]}" = "0" ] && [ -n "${_f_h_rules["default"]}" ]; then
        echo "      Fallback Default: \"${_f_h_rules["default"]}\""
      fi
      echo ""
    done
  else
    echo "This operational command option does not register or mandate any parameter flags."
  fi
  echo "================================================================================"
  return 0
}





# ------------------------------------------------------------------------------
# FRAMEWORK ROOT LIFECYCLE CONTROLLER (AUTO-BOOTSTRAP ENGINE)
# ------------------------------------------------------------------------------

# core_cli_run centralizes and drives the comprehensive lifecycle execution pipeline.
#
# Arguments:
#   - pkg_name: The uppercase canonical name of the active CLI application (e.g., XERRORS).
#   - $@: The comprehensive execution argument passdown directly from the shell entrypoint.
#
# Returns:
#   - 0: If the complete orchestration pipeline and downstream business actions pass perfectly.
#   - 1: If any compilation error, user parameter violation, or logic contract fails.
core_cli_run() {
  local active_pkg_identifier="$1"
  shift

  # Reset tracking registers and error boundaries buffers globally before initialization
  VALIDATION_ERROR_MSG=""
  CORE_CLI_VALIDATED_VALUE=""

  # ----------------------------------------------------------------------------
  # STEP 1: VALIDATE THE DEVELOPER PROVIDED WORKSPACE ROOT DIRECTION
  # ----------------------------------------------------------------------------
  # Assert if the mandatory unique root path register exists and maps to an active folder
  if [ -z "$CORE_CLI_ROOT_PATH" ] || [ ! -d "$CORE_CLI_ROOT_PATH" ]; then
    echo "[ERR] Critical Workspace Fault :: Target 'CORE_CLI_ROOT_PATH'='$CORE_CLI_ROOT_PATH' is missing or points to an invalid directory."
    return 1
  fi


  # ----------------------------------------------------------------------------
  # STEP 2: RAW ARGUMENT STREAM INGESTION & BOOTSTRAP TOKENS PARSING
  # ----------------------------------------------------------------------------
  if ! core_cli_bootstrap_input "$active_pkg_identifier" "$@"; then
    unset CORE_CLI_ROOT_PATH # Evacuate memory registers upon error interception
    return 1
  fi


  # ----------------------------------------------------------------------------
  # STEP 4: SPECIFICATION RESOLUTION & METADATA OVERRIDE COMPILATION
  # ----------------------------------------------------------------------------
  if ! core_cli_command_orchestrate; then
    unset CORE_CLI_ROOT_PATH # Evacuate memory registers upon error interception
    return 1
  fi

  # ----------------------------------------------------------------------------
  # STEP 5: MEMORY EVACUATION GARBAGE CLEANUP
  # ----------------------------------------------------------------------------
  # Erase the specific global context variable to allow subsequent scripts configuration overrides
  unset CORE_CLI_ROOT_PATH

  return 0
}
#!/bin/bash
# ==============================================================================
# SCRIPT: xerrors.sh
# DESCRIPTION: Entrypoint engine to safely orchestrate corporate error registry
#              allocations and specialized context boundary injections.
# ==============================================================================

# Abort immediately if any unhandled intermediate pipeline command fails
set -e

# Sourcing external core structural validation and parsing library bundle
. functions.sh




# ------------------------------------------------------------------------------
# CLI SPECIFICATION & GLOBAL REGISTER LAYOUTS
# ------------------------------------------------------------------------------

# Define the comprehensive global list of allowed inline flags for error tasks
ERROR_CLI_SPEC=(
  "-s --scope"
  "-f --family"
  "--family-title"
  "-n --name"
  "-m --message"
  "-t --tech"
  "--fields"
)


# ------------------------------------------------------------------------------
# CORE INPUT ASSERTERS (VALIDATE_FN TARGETS)
# ------------------------------------------------------------------------------

# check_command_action validates positional subcommand lifecycle actions.
#
# Arguments:
#   - value: The action string token captured from the prompt execution.
#   - allowed_enum: Space separated listing of structural targets allowed.
#
# Returns:
#   - 0: If the captured action matches acceptable framework specifications.
#   - 1: If an unknown or unmapped execution step is provided.
check_command_action() {
  local value="$1"
  local allowed_enum="$2"

  if [ "$value" != "add" ]; then
    VALIDATION_ERROR_MSG="Unknown action '${value}'. Expected 'add'."
    return 1
  fi
  return 0
}

# check_error_token_layout wraps the core regex boundary constraint checks.
#
# Arguments:
#   - value: The raw or converted string sequence representing the token name.
#
# Returns:
#   - 0: If token satisfies strict naming boundaries.
#   - 1: If layout boundaries or naming limits are violated.
check_error_token_layout() {
  local value="$1"

  if ! validate_token "$value"; then
    VALIDATION_ERROR_MSG="Token layout violates constraints (A-Z base, max 32 chars)"
    return 1
  fi
  return 0
}

# check_scope_value asserts if the provided scope matches accepted blueprints.
#
# Arguments:
#   - value: The raw parameter input string representing the scope.
#   - allowed_enum: Space separated listing of allowable options.
#
# Returns:
#   - 0: If the scope maps safely to internal configuration structures.
#   - 1: If an unknown or unmapped ecosystem scope is supplied.
check_scope_value() {
  local value="$1"
  local allowed_enum="$2"

  # Convert values to a loop evaluation array to ensure matching parity
  for item in $allowed_enum; do
    if [ "$value" = "$item" ]; then
      return 0
    fi
  done

  VALIDATION_ERROR_MSG="Scope '${value}' is invalid. Allowed options are: [ ${allowed_enum} ]"
  return 1
}




# check_error_name_field asserts format constraints for error constant names.
#
# Arguments:
#   - value: The raw input token typed by the user.
#
# Returns:
#   - 0: If token conforms to strict uppercase snake case layout.
#   - 1: If length or character layout constraints are violated.
#
# Side Effects:
#   - Automatically normalizes camelCase/spaces inputs to SNAKE_CASE_UPPERCASE.
check_error_name_field() {
  local value="$1"
  
  if [ -z "$value" ]; then
    VALIDATION_ERROR_MSG="Error name cannot resolve to an empty textual state."
    return 1
  fi

  local normalized
  normalized=$(to_snake_upper_case "$value")

  if ! validate_token "$normalized"; then
    VALIDATION_ERROR_MSG="Token layout violates constraints (A-Z base, max 32 chars)"
    return 1
  fi

  # Double check: ensure the normalized token does not cause file collisions
  # We read target_xerrors_path from the main shell execution scope safely
  if grep -q -E "([[:space:]]|\t)${normalized}[[:space:]]" "$target_xerrors_path"; then
    VALIDATION_ERROR_MSG="Token constant '${normalized}' already exists inside registry."
    return 1
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






# ------------------------------------------------------------------------------
# HIGH-LEVEL TERMINAL LIFE-CYCLE LOGGERS
# ------------------------------------------------------------------------------

# print_general_usage renders the root CLI help guide for the xpkg-errors entrypoint.
#
# Returns:
#   - 0: Always terminates after outputting the usage text.
print_general_usage() {
  echo "xpkg-errors - Structural Error Code and Sub-Context Manager CLI"
  echo ""
  echo "Usage:"
  echo "  xpkg-errors.sh <resource> <action> [flags]"
  echo ""
  echo "Available Resources:"
  echo "  code add      Append a new corporate error code token configuration."
  echo "  subctx add    Derive and insert a new specialized sub-context scope."
  echo "  help          Display help guidelines and flag metadata definitions."
}

# print_init_usage displays help documentation for the package bootstrap command.
#
# Returns:
#   - 0: Always terminates with success state after rendering text strings.
print_init_usage() {
  echo "Usage: xpkg-errors.sh init --name=<package_path_or_name>"
  echo ""
  echo "Description:"
  echo "  Bootstraps architecture compliance boilerplate artifacts."
  echo ""
  echo "Flags:"
  echo "  --name         The target directory path or name configuration."
}

# print_error_usage displays structural guidelines for adding new errors.
#
# Returns:
#   - 0: Always terminates with success state after rendering text strings.
print_error_usage() {
  echo "Usage: xpkg-errors.sh error <sub-resource> add [flags]"
  echo ""
  echo "Available Sub-Resources:"
  echo "  code add       Append a new corporate error code identifier index."
  echo "  subctx add     Append a new specialized error sub-context scope."
  echo ""
  echo "Global Flags:"
  echo "  --scope        Target project environment scope boundary ('internal/i' or 'pkg/p')."
  echo ""
  echo "Flags for 'code add':"
  echo "  --family       Family ID index bounds. Use 0 for interactive mode."
  echo "  --family-title Title for the new sequential family index metadata."
  echo "  --name         Error token layout schema key (camelCase/snake_case)."
  echo "  --fields       Comma-separated extra tag metadata structural keys."
  echo "  --message      Fallback text message for human consumption."
  echo "  --tech         Strict technical architecture guidance documentation."
  echo ""
  echo "Flags for 'subctx add':"
  echo "  --name         The name of the new specialized sub-context scope."
}




# ------------------------------------------------------------------------------
# CORE ERROR INPUT PROCESSING
# ------------------------------------------------------------------------------

# process_error_code_inputs orchestrates interactive data collection and family routing.
#
# Arguments:
#   - file: The absolute physical path to the target xerrors.go file.
#
# Returns:
#   - 0: If all core parameters (name, family, code, messages) are successfully processed.
#   - 1: If any input constraint or sequential index validation fails.
process_error_code_inputs() {
  local file="$1"

  # Electronically validate name field (will auto-prompt and auto-convert to SNAKE_CASE)
  if ! prompt_and_validate_flag "name" "Enter Error Name (camelCase or snake_case)" "" "check_error_name_field"; then
    return 1
  fi
  PARSED_FLAGS["name"]=$(to_snake_upper_case "${PARSED_FLAGS["name"]}")

  # Electronically validate human message and tech documentation text requirements
  if ! prompt_and_validate_flag "message" "Enter Default Fallback Human Message" "" "check_required_text_field"; then
    return 1
  fi
  if ! prompt_and_validate_flag "tech" "Enter Technical/Architecture Guidance Commentary" "" "check_required_text_field"; then
    return 1
  fi

  # Resolve Family parameter inputs context
  local fam_id="${PARSED_FLAGS["family"]}"
  if [ -z "$fam_id" ] || [ "$fam_id" -eq 0 ]; then
    if ! run_family_wizard "$file"; then
      echo "[ERR] Wizard execution failure: ${VALIDATION_ERROR_MSG}"
      return 1
    fi
    fam_id="${PARSED_FLAGS["family"]}"
  fi

  # Determine if the target family configuration is a new sequential layer
  local max_existing_family=0
  for existing_id in "${!FAMILY_MAX_CODES[@]}"; do
    if [ "$existing_id" -gt "$max_existing_family" ]; then
      max_existing_family=$existing_id
    fi
  done

  local next_sequential_family=$((max_existing_family + 1))
  if [ "$fam_id" -gt "$next_sequential_family" ]; then
    echo "[ERR] Invalid family ID ${fam_id}. Next sequential available family is ${next_sequential_family}."
    return 1
  fi

  # Handle new family metadata title collection if required
  if [ "$fam_id" -eq "$next_sequential_family" ]; then
    local fam_title="${PARSED_FLAGS["family-title"]}"
    if [ -z "$fam_title" ]; then
      echo -n "[ > ] Enter Corporate Title for the new Error Family: "
      read -r fam_title
      fam_title=$(echo "$fam_title" | tr '[:lower:]' '[:upper:]' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    fi
    if [ -z "$fam_title" ]; then
      echo "[ERR] Family title declaration cannot resolve to empty value states."
      return 1
    fi
    PARSED_FLAGS["family-title"]="$fam_title"
  fi

  # Compute the next sequential absolute Error Code identifier
  local computed_code=""
  if [ "$fam_id" -eq "$next_sequential_family" ]; then
    computed_code="E${fam_id}001"
  else
    local last_code="${FAMILY_MAX_CODES[$fam_id]}"
    if [ -z "$last_code" ] || [ "$last_code" -eq 0 ]; then
      computed_code="E${fam_id}001"
    else
      local clean_num
      clean_num=$(echo "$last_code" | sed 's/[^0-9]//g')
      computed_code="E$((clean_num + 1))"
    fi
  fi
  PARSED_FLAGS["computed_code"]="$computed_code"

  return 0
}

# generate_error_code_payloads formats the comprehensive structural text strings.
#
# Arguments:
#   - const_payload_var: String name of a local reference variable to store constants code.
#   - reg_payload_var: String name of a local reference variable to store registry code.
#
# Returns:
#   - 0: Always terminates with a success state after populating payloads references.
generate_error_code_payloads() {
  local -n out_const="$1"
  local -n out_reg="$2"

  local name="${PARSED_FLAGS["name"]}"
  local msg="${PARSED_FLAGS["message"]}"
  local tech="${PARSED_FLAGS["tech"]}"
  local fam_id="${PARSED_FLAGS["family"]}"
  local code="${PARSED_FLAGS["computed_code"]}"
  local fam_title="${PARSED_FLAGS["family-title"]}"

  # Evaluate whether family title or codes match new sequential family state requirements
  local is_new_family=false
  if [ -n "$fam_title" ]; then
    is_new_family=true
  fi

  # Process optional metadata extra fields tags list boundaries
  local raw_fields="${PARSED_FLAGS["fields"]}"
  local expect_tokens="CTX, MSG"
  local tags_string=""
  if [ -n "$raw_fields" ]; then
    IFS=',' read -r -a fields_array <<< "$raw_fields"
    local idx=0
    for f in "${fields_array[@]}"; do
      local san_f
      san_f=$(to_snake_upper_case "$f")
      if [ -n "$san_f" ]; then
        if ! validate_token "$san_f"; then
          echo "[ERR] Extra field tag '${f}' matches an invalid layout format structure."
          exit 1
        fi
        expect_tokens+=", ${san_f}"
        if [ "$idx" -gt 0 ]; then tags_string+=", "; fi
        tags_string+="\"${san_f}\""
        idx=$((idx + 1))
      fi
    done
  fi
  expect_tokens+=", [error]"

  # Construct and stitch comprehensive formatted payloads strings blocks
  out_const=""
  out_reg=""

  if [ "$is_new_family" = true ]; then
    out_const=$(generate_family_divider_blocks "$fam_id" "$fam_title" "constant")
    out_reg=$(generate_family_divider_blocks "$fam_id" "$fam_title" "registry")
  fi

  out_const+="\n  // ${name} belongs to Family ${fam_id}.\n"
  out_const+="  // ${tech}\n"
  out_const+="  // Format expects: ${expect_tokens}\n"
  out_const+="  ${name} xerrors.ErrorCode = \"${code}\"\n"

  out_reg+="\n  ${name}: {\n"
  out_reg+="    Message:   \"${msg}\",\n"
  out_reg+="    ExtraTags: []string{${tags_string}},\n"
  out_reg+="  },\n"

  return 0
}

# process_error_subctx_inputs orchestrates data collection for sub-contexts.
#
# Returns:
#   - 0: If the specialized sub-context name parameter is successfully processed.
#   - 1: If input constraints or token naming layout validation fails.
process_error_subctx_inputs() {
  # Electronically validate name field (will auto-prompt and auto-convert to SNAKE_CASE)
  if ! prompt_and_validate_flag "name" "Enter Sub-Context Name (e.g., validation, auth)" "" "check_required_text_field"; then
    return 1
  fi
  
  local normalized_ctx
  normalized_ctx=$(to_snake_upper_case "${PARSED_FLAGS["name"]}")
  
  # Re-assert naming structure constraints via our generic investigator
  if ! validate_argument "$normalized_ctx" "" "check_error_token_layout"; then
    echo "[ERR] Sub-context name validation failed: ${VALIDATION_ERROR_MSG}"
    return 1
  fi

  # Build the final proposed sub-context token structure to check for collisions
  local base_constant="XERR_PKGCTX"
  local computed_subctx_token="${base_constant}_${normalized_ctx}"

  # Assert combined subcontext token does not cause a naming collision anywhere in the file
  if ! check_token_duplication "$target_xerrors_path" "$computed_subctx_token"; then
    echo "[ERR] Duplication failure: ${VALIDATION_ERROR_MSG}"
    return 1
  fi

  # Store the fully validated and sanitized results back into registers
  PARSED_FLAGS["name"]="$normalized_ctx"
  PARSED_FLAGS["computed_token"]="$computed_subctx_token"
  
  return 0
}

# generate_error_subctx_payload formats the dynamic sub-context text injection blocks.
#
# Arguments:
#   - subctx_payload_var: String name of a local reference variable to store formatted code.
#
# Returns:
#   - 0: Always terminates with a success state after populating payload reference.
generate_error_subctx_payload() {
  local -n out_payload="$1"

  local subctx_token="${PARSED_FLAGS["computed_token"]}"
  local subctx_name="${PARSED_FLAGS["name"]}"
  
  # Fetch the upstream baseline package context string value discovered from the matrix
  local base_value="${PARSED_PKG_CONTEXT["XERR_PKGCTX"]}"
  local computed_value="${base_value}_${subctx_name}"

  # Update registers with the computed target string values for external tracking logs
  PARSED_FLAGS["computed_value"]="$computed_value"

  # Construct comprehensive formatted multiline payload block mapping constants fields
  out_payload=""
  out_payload+="\n  // ${subctx_token} defines a specialized sub-context scope derived from XERR_PKGCTX.\n"
  out_payload+="  ${subctx_token} xerrors.ErrorCode = \"${computed_value}\"\n"

  return 0
}






# ------------------------------------------------------------------------------
# PRE-FLIGHT COMPILATION & STATIC SPECIFICATION VALIDATION
# ------------------------------------------------------------------------------

# Boot up internal framework spec asserter (Developer-facing syntax validation)
if ! validate_cli_spec "ERROR_CLI_SPEC"; then
  echo "[ERR] Static engine specification failure: ${VALIDATION_ERROR_MSG}"
  exit 1
fi

# Assert minimum positionals boundaries exist before invoking underlying code blocks
if [ $# -lt 1 ]; then
  echo "[ERR] Missing operational resource target parameters"
  print_general_usage
  exit 1
fi

resource="$1"
shift




# ------------------------------------------------------------------------------
# MAIN EXECUTION ROUTER (ENTRYPOINT MOTOR)
# ------------------------------------------------------------------------------

case "$resource" in
  help)
    # Check if a specific sub-resource focus target was requested
    if [ $# -gt 0 ]; then
      local target="$1"
      case "$target" in
        init)   print_init_usage ;;
        error)  print_error_usage ;;
        *)
          echo "[ERR] No specific help documentation found for '${target}'"
          echo ""
          print_general_usage
          ;;
      esac
    else
      print_general_usage
    fi
    exit 0
    ;;

  code|subctx)
    if [ $# -lt 1 ]; then
      echo "[ERR] Missing parameter action for resource '${resource}'"
      exit 1
    fi

    action="$1"
    shift

    # Validate whether positionals conform to standard strict 'add' blueprints
    if ! validate_argument "$action" "add" "check_command_action"; then
      echo "[ERR] ${VALIDATION_ERROR_MSG}"
      exit 1
    fi

    # Parse inline data sequences directly onto global associative registers
    if ! parse_dynamic_flags "ERROR_CLI_SPEC" "$@"; then
      echo "[ERR] ${VALIDATION_ERROR_MSG}"
      exit 1
    fi

    # Trigger runtime execution visual signature only after all static compiler checks clear
    echo "================================================================================"
    echo "[RUN] Initializing standard error core infrastructure engine..."
    echo "================================================================================"

    # ------------------------------------------------------------------------------
    # RUNTIME DATA VALIDATION (HTTP 400 BOUNDARIES)
    # ------------------------------------------------------------------------------

    target_scope="${PARSED_FLAGS["scope"]}"
    
    # Assert and validate user input scope using the generic argument orchestrator
    if ! validate_argument "$target_scope" "internal i pkg p" "check_scope_value"; then
      echo "[ERR] Validation failure: ${VALIDATION_ERROR_MSG}"
      exit 1
    fi

    # Dynamically resolve the absolute physical location of the xerrors file
    if ! target_xerrors_path=$(resolve_xerrors_filepath "$target_scope"); then
      echo "[ERR] Resolution failure: ${VALIDATION_ERROR_MSG}"
      exit 1
    fi

    # Assert repository and target registry integrity using the computed absolute path
    if ! assert_xerrors_file_integrity "$target_xerrors_path"; then
      echo "[ERR] Integrity failure: ${VALIDATION_ERROR_MSG}"
      exit 1
    fi

    # ------------------------------------------------------------------------------
    # RUNTIME METADATA INGESTION & PIPELINE CHECKS
    # ------------------------------------------------------------------------------

    # 1. Ingest package core domain context tracking keys from the file layout
    if raw_pkg_block=$(get_anchor_block_content "$target_xerrors_path" "X_ANCHOR_PKGCTX"); then
      clean_pkg_content=$(echo "$raw_pkg_block" | tail -n +3)
      parse_package_context_metadata "$clean_pkg_content"
    fi

    # 2. Ingest active error families and max sequential numeric bounds from the file layout
    if raw_const_block=$(get_anchor_block_content "$target_xerrors_path" "X_ANCHOR_CONSTANTS"); then
      clean_const_content=$(echo "$raw_const_block" | tail -n +3)
      parse_family_error_bounds "$clean_const_content"
    fi




    # Routines isolation split boundary depending on primary requested tokens
    # Routines isolation split boundary depending on primary requested tokens
    if [ "$resource" = "code" ]; then
      
      # 1. Coordinate step for ingestion and checking parameters inputs configurations
      if ! process_error_code_inputs "$target_xerrors_path"; then
        exit 1
      fi

      # 2. Coordinate step for translating structures parameters onto text blocks payloads
      local const_block_payload=""
      local reg_block_payload=""
      generate_error_code_payloads const_block_payload reg_block_payload

      # 3. Coordinate step for injecting generated blocks text back into Go artifacts source
      local fam_id="${PARSED_FLAGS["family"]}"
      local target_c_anchor="X_ANCHOR_CONSTANTS_END"
      local target_r_anchor="X_ANCHOR_REGISTRY_END"
      
      if [ -z "${PARSED_FLAGS["family-title"]}" ]; then
        local next_marker="=== FAMILY: $((fam_id + 1))"
        local c_ln
        c_ln=$(grep -n "$next_marker" "$target_xerrors_path" | cut -d':' -f1 | head -n1)
        if [ -n "$c_ln" ]; then
          target_c_anchor="$next_marker"
          target_r_anchor="$next_marker"
        fi
      fi

      # Fire the agnostics injection engines safely using targeted anchors boundaries
      inject_content_at_anchor_tail "$target_xerrors_path" "$target_c_anchor" "$const_block_payload"
      inject_content_at_anchor_tail "$target_xerrors_path" "$target_r_anchor" "$reg_block_payload"

      echo "[ v ] Successfully appended '${PARSED_FLAGS["name"]}' (${PARSED_FLAGS["computed_code"]}) inside family ${fam_id}."

    else
      
      # --- SUB-CONTEXT RESOURCES VALIDATION BLOCKS ---
      
      # Sub-contexts explicitly demand that the baseline XERR_PKGCTX metadata is mapped
      if ! assert_base_context_presence; then
        echo "[ERR] Infrastructure failure: ${VALIDATION_ERROR_MSG}"
        exit 1
      fi

      # 1. Coordinate step for ingestion and checking parameters inputs configurations
      if ! process_error_subctx_inputs; then
        exit 1
      fi

      # 2. Coordinate step for translating structures parameters onto text blocks payloads
      local subctx_block_payload=""
      generate_error_subctx_payload subctx_block_payload

      # 3. Coordinate step for injecting generated blocks text back into Go artifacts source
      local target_anchor="X_ANCHOR_PKGCTX_END"

      # Fire the agnostics injection engine safely using the targeted context boundary anchor
      inject_content_at_anchor_tail "$target_xerrors_path" "$target_anchor" "$subctx_block_payload"

      echo "[ v ] Successfully appended sub-context '${PARSED_FLAGS["computed_token"]}' (${PARSED_FLAGS["computed_value"]})."

    fi
    ;;

  *)
    echo "[ERR] Unknown corporate command resource target option '${resource}'"
    print_general_usage
    exit 1
    ;;
esac

echo "================================================================================"
echo "[OKK] Initial orchestration checks executed with zero validation failures"
echo "================================================================================"

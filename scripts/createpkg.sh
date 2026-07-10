#!/bin/bash
# ==============================================================================
# SCRIPT: createpkg.sh
# DESCRIPTION: Dynamically discovers project roots, validates compliance, and
#              injects architectural blueprints into internal or public scopes.
# ==============================================================================

# Ensure strict failure handling
set -e

# Define path configurations relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
DEV_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$DEV_ROOT/templatepkgs"

# ------------------------------------------------------------------------------
# Input Parameter Variables
# ------------------------------------------------------------------------------
TEMPLATE_NAME="${1}"
TARGET_SCOPE="${2}"
PKG_PREFIX="${3}"
CUSTOM_BASEPATH="${4}"

# ================================================================================
# [RUN] Evaluating help commands and dynamic template discovery...
# ================================================================================

if [ "$TEMPLATE_NAME" == "help" ] || [ "$TEMPLATE_NAME" == "-h" ] || [ "$TEMPLATE_NAME" == "--help" ] || [ -z "$TEMPLATE_NAME" ]; then
  echo "================================================================================"
  echo " ARCHITECTURAL BLUEPRINT CReAGE PKG CLI"
  echo "================================================================================"
  echo "Usage:"
  echo "  ./createpkg.sh <template_name> <internal|pkg> <pkg_prefix> [custom_basepath]"
  echo ""
  echo "Arguments:"
  echo "  <template_name>   Name of the blueprint core to inject (see list below)"
  echo "  <internal|pkg>    Target ecosystem boundary scope"
  echo "  <pkg_prefix>      Principal shorthand project context name (Required for both)"
  echo "  [custom_basepath] Optional absolute path override to target module root"
  echo ""
  echo "Available Architectural Templates (Dynamic):"
  
  # Dynamically list templates by stripping path and .tmpl extension
  if [ -d "$TEMPLATE_DIR" ]; then
    for file in "$TEMPLATE_DIR"/*.tmpl; do
      if [ -f "$file" ]; then
        name=$(basename "$file" .tmpl)
        echo "  - $name"
      fi
    done
  else
    echo "  [ x ] Error: templatepkgs directory not found at $TEMPLATE_DIR"
  fi
  
  echo "================================================================================"
  exit 0
fi




# ================================================================================
# [RUN] Validating initial execution arguments and environment state...
# ================================================================================

# Check for minimal required arguments after help evaluation
if [ -z "$TARGET_SCOPE" ] || [ -z "$PKG_PREFIX" ]; then
  echo "[ x ] Missing required scope or package prefix arguments."
  echo "Usage: ./createpkg.sh <template_name> <internal|pkg> <pkg_prefix> [custom_basepath]"
  echo "[ERR] Global execution halted due to invalid arguments."
  exit 1
fi

# Validate target scope constraint
if [ "$TARGET_SCOPE" != "internal" ] && [ "$TARGET_SCOPE" != "pkg" ]; then
  echo "[ x ] Invalid target scope: '$TARGET_SCOPE'. Must be 'internal' or 'pkg'."
  echo "[ERR] Global execution halted due to invalid boundary rules."
  exit 1
fi

# Validate presence of template file
TEMPLATE_FILE="$TEMPLATE_DIR/${TEMPLATE_NAME}.tmpl"
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "[ x ] Template file not found: '$TEMPLATE_FILE'"
  echo "[ERR] Global execution halted due to missing structural assets."
  exit 1
fi

# Normalize prefix cases
PKG_PREFIX_LOWER=$(echo "$PKG_PREFIX" | tr '[:upper:]' '[:lower:]')
PKG_PREFIX_UPPER=$(echo "$PKG_PREFIX" | tr '[:lower:]' '[:upper:]')




# ================================================================================
# [RUN] Discovering dynamic project root and workspace boundaries...
# ================================================================================

TARGET_ROOT=""

if [ -n "$CUSTOM_BASEPATH" ]; then
  # Use explicitly provided fallback path if defined
  if [ -d "$CUSTOM_BASEPATH" ]; then
    TARGET_ROOT="$(cd "$CUSTOM_BASEPATH" && pwd)"
    echo "[ v ] Using explicitly provided custom basepath root: $TARGET_ROOT"
  else
    echo "[ x ] Provided custom basepath directory does not exist: $CUSTOM_BASEPATH"
    echo "[ERR] Global execution halted due to invalid workspace pointer."
    exit 1
  fi
else
  # Dynamic discovery: climb up to 5 levels looking for go.mod
  CURRENT_LOOKUP="$SCRIPT_DIR"
  for i in {1..5}; do
    CURRENT_LOOKUP="$(dirname "$CURRENT_LOOKUP")"
    if [ -f "$CURRENT_LOOKUP/go.mod" ]; then
      TARGET_ROOT="$CURRENT_LOOKUP"
      break
    fi
  done

  if [ -z "$TARGET_ROOT" ]; then
    echo "[ x ] Could not locate go.mod within 5 parent directories."
    echo "[ERR] Dynamic project root discovery failed. Provide a custom basepath."
    exit 1
  fi
  echo "[ v ] Dynamically discovered project root at: $TARGET_ROOT"
fi




# ================================================================================
# [RUN] Resolving target directory paths and package naming structures...
# ================================================================================

BASE_RESOURCE_NAME=$(basename "$TEMPLATE_FILE" .tmpl)

if [ "$TARGET_SCOPE" == "internal" ]; then
  # Internal packages ignore the prefix on the folder level but use it inside
  FINAL_PKG_NAME="$BASE_RESOURCE_NAME"
  TARGET_DEST_DIR="$TARGET_ROOT/internal/$FINAL_PKG_NAME"
else
  # Public packages enforce the context-prefixed naming layouts globally
  FINAL_PKG_NAME="${PKG_PREFIX_LOWER}${BASE_RESOURCE_NAME}"
  TARGET_DEST_DIR="$TARGET_ROOT/pkg/${PKG_PREFIX_LOWER}/${FINAL_PKG_NAME}"
fi

FINAL_OUTPUT_FILE="$TARGET_DEST_DIR/${BASE_RESOURCE_NAME}.go"

echo "[ . ] Output Target File: $FINAL_OUTPUT_FILE"
echo "[ . ] Target Package Name: $FINAL_PKG_NAME"




# ================================================================================
# [RUN] Executing filesystem injection and string transformation...
# ================================================================================

# Ensure the full destination directory path exists cleanly
mkdir -p "$TARGET_DEST_DIR"
echo "[ v ] Destination directory tree validated and created successfully."

# CRITICAL SECURITY GATE: Prevent accidental code overwriting
if [ -f "$FINAL_OUTPUT_FILE" ]; then
  echo "[ x ] Safety Failure: Target file already exists at: $FINAL_OUTPUT_FILE"
  echo "[ERR] Injection aborted to prevent overwriting existing codebase files."
  exit 1
fi

# Read raw template data
TEMPLATE_CONTENT=$(cat "$TEMPLATE_FILE")

# Apply scope transformations specifically to the package declaration header line via <pkge>
if [ "$TARGET_SCOPE" == "internal" ]; then
  # Strip '<pkge>' entirely so 'package <pkge>xerrors' becomes 'package xerrors'
  NORMALIZED_CONTENT=$(echo "$TEMPLATE_CONTENT" | sed "1s/package <pkge>/package /")
else
  # Substitute '<pkge>' with lowercase prefix so 'package <pkge>xerrors' becomes 'package billingxerrors'
  NORMALIZED_CONTENT=$(echo "$TEMPLATE_CONTENT" | sed "1s/<pkge>/${PKG_PREFIX_LOWER}/")
fi

# Cleanly substitute inner body tokens now that package declaration collisions are solved
NORMALIZED_CONTENT=$(echo "$NORMALIZED_CONTENT" | sed "s/<pkg>/${PKG_PREFIX_LOWER}/g")
NORMALIZED_CONTENT=$(echo "$NORMALIZED_CONTENT" | sed "s/<PKG>/${PKG_PREFIX_UPPER}/g")

# Persist transformed content stream into production workspace
echo "$NORMALIZED_CONTENT" > "$FINAL_OUTPUT_FILE"

if [ -f "$FINAL_OUTPUT_FILE" ]; then
  echo "[ v ] Production code module generated and written successfully."
else
  echo "[ x ] File writing pipeline collapsed abruptly."
  echo "[ERR] Critical filesystem IO failure encountered."
  exit 1
fi




# ================================================================================
# [END] Finalizing pipeline lifecycle routines
# ================================================================================

echo "[OKK] Package structural layout injected cleanly into the ecosystem!"

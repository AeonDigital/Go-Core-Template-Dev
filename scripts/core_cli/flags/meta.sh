#!/bin/bash

# ==============================================================================
# SCRIPT: core_cli/flags/meta.sh
# DESCRIPTION: Centralized registry for all validated core and system data types.
# ==============================================================================

# Global array indexing all primitive, structured, and system types supported by the core engine.
declare -gA CORE_SUPPORTED_TYPES=(
  # Primitives
  ["string"]="1" 
  ["int"]="1" 
  ["float"]="1" 
  ["bool"]="1"
  
  # Structured
  ["date"]="1" 
  ["time"]="1" 
  ["datetime"]="1" 
  ["email"]="1" 
  ["enum"]="1"
  ["json"]="1" 
  
  # System
  ["path"]="1" 
  ["relativepath"]="1" 

  ["filename"]="1" 
  ["filepath"]="1" 

  ["dirname"]="1" 
  ["dirpath"]="1"

  ["url"]="1" 
  ["fullurl"]="1" 
  ["relativeurl"]="1"
)

# METAFLAG_short defines the short alphanumeric alias for a command-line flag.
# It acts as a single-dash alternative (e.g., -s) and must not exceed 3 characters.
declare -gA METAFLAG_short=()
METAFLAG_short["short"]=""
METAFLAG_short["long"]="short"
METAFLAG_short["type"]="string"
METAFLAG_short["array"]="0"
METAFLAG_short["assoc"]="0"
METAFLAG_short["required"]="0"
METAFLAG_short["default"]=""
METAFLAG_short["enum"]=""
METAFLAG_short["assoc_keys"]=""
METAFLAG_short["min"]="1"
METAFLAG_short["max"]="3"
METAFLAG_short["min_array"]=""
METAFLAG_short["max_array"]=""
METAFLAG_short["regex"]="^[a-zA-Z0-9]+$"
METAFLAG_short["description"]="Short alphanumeric character alias for the flag (1 to 3 chars)."
METAFLAG_short["tipinput"]=""
METAFLAG_short["validate"]=""

# METAFLAG_long defines the canonical long name identifier for a command-line flag.
# It acts as a double-dash option (e.g., --scope) and maps directly to parsed storage keys.
declare -gA METAFLAG_long=()
METAFLAG_long["short"]=""
METAFLAG_long["long"]="long"
METAFLAG_long["type"]="string"
METAFLAG_long["array"]="0"
METAFLAG_long["assoc"]="0"
METAFLAG_long["required"]="1"
METAFLAG_long["default"]=""
METAFLAG_long["enum"]=""
METAFLAG_long["assoc_keys"]=""
METAFLAG_long["min"]="1"
METAFLAG_long["max"]="32"
METAFLAG_long["min_array"]=""
METAFLAG_long["max_array"]=""
METAFLAG_long["regex"]="^[a-z0-9_-]+$"
METAFLAG_long["description"]="Long canonical name identifier for the flag execution mapping."
METAFLAG_long["tipinput"]=""
METAFLAG_long["validate"]=""

# METAFLAG_type defines the primitive, structured, or system classification of the flag data.
# It instructs the core engine which specialized native validation routine to trigger.
declare -gA METAFLAG_type=()
METAFLAG_type["short"]=""
METAFLAG_type["long"]="type"
METAFLAG_type["type"]="enum"
METAFLAG_type["array"]="0"
METAFLAG_type["assoc"]="0"
METAFLAG_type["required"]="1"
METAFLAG_type["default"]="string"
METAFLAG_type["enum"]="CORE_SUPPORTED_TYPES"
METAFLAG_type["assoc_keys"]=""
METAFLAG_type["min"]=""
METAFLAG_type["max"]=""
METAFLAG_type["min_array"]=""
METAFLAG_type["max_array"]=""
METAFLAG_type["regex"]=""
METAFLAG_type["description"]="Data type classification enforcing specific core parsing and validation pipelines."
METAFLAG_type["tipinput"]=""
METAFLAG_type["validate"]=""

# METAFLAG_array declares whether the flag parameter accepts a structured collection.
# If active (1), the engine parses the payload as a JSON array and validates every item.
declare -gA METAFLAG_array=()
METAFLAG_array["short"]=""
METAFLAG_array["long"]="array"
METAFLAG_array["type"]="bool"
METAFLAG_array["array"]="0"
METAFLAG_array["assoc"]="0"
METAFLAG_array["required"]="0"
METAFLAG_array["default"]="0"
METAFLAG_array["enum"]=""
METAFLAG_array["assoc_keys"]=""
METAFLAG_array["min"]=""
METAFLAG_array["max"]=""
METAFLAG_array["min_array"]=""
METAFLAG_array["max_array"]=""
METAFLAG_array["regex"]=""
METAFLAG_array["description"]="Boolean flag asserting if the parameter operates as an iterable collection array."
METAFLAG_array["tipinput"]=""
METAFLAG_array["validate"]="check_meta_array_exclusivity"

# METAFLAG_assoc declares whether the flag parameter operates as an associative map.
# Accepts a global variable name pointer or an inline JSON object sequence.
declare -gA METAFLAG_assoc=()
METAFLAG_assoc["short"]=""
METAFLAG_assoc["long"]="assoc"
METAFLAG_assoc["type"]="bool"
METAFLAG_assoc["array"]="0"
METAFLAG_assoc["assoc"]="0"
METAFLAG_assoc["required"]="0"
METAFLAG_assoc["default"]="0"
METAFLAG_assoc["enum"]=""
METAFLAG_assoc["assoc_keys"]=""
METAFLAG_assoc["min"]=""
METAFLAG_assoc["max"]=""
METAFLAG_assoc["min_array"]=""
METAFLAG_assoc["max_array"]=""
METAFLAG_assoc["regex"]=""
METAFLAG_assoc["description"]="Boolean flag asserting if the parameter operates as an associative map."
METAFLAG_assoc["tipinput"]=""
METAFLAG_assoc["validate"]="check_meta_assoc_exclusivity"

# METAFLAG_required declares whether the flag must be explicitly supplied by the user.
# If active (1), the framework automatically mandates a non-empty presence check.
declare -gA METAFLAG_required=()
METAFLAG_required["short"]=""
METAFLAG_required["long"]="required"
METAFLAG_required["type"]="bool"
METAFLAG_required["array"]="0"
METAFLAG_required["assoc"]="0"
METAFLAG_required["required"]="0"
METAFLAG_required["default"]="0"
METAFLAG_required["enum"]=""
METAFLAG_required["assoc_keys"]=""
METAFLAG_required["min"]=""
METAFLAG_required["max"]=""
METAFLAG_required["min_array"]=""
METAFLAG_required["max_array"]=""
METAFLAG_required["regex"]=""
METAFLAG_required["description"]="Boolean flag asserting if the parameter must be explicitly present during runtime execution."
METAFLAG_required["tipinput"]=""
METAFLAG_required["validate"]=""

# METAFLAG_default defines the fallback value automatically assigned if the user omits the flag.
# Core compiler rules reject schemas where required is true (1) and a default is simultaneously set.
declare -gA METAFLAG_default=()
METAFLAG_default["short"]=""
METAFLAG_default["long"]="default"
METAFLAG_default["type"]="string"
METAFLAG_default["array"]="0"
METAFLAG_default["assoc"]="0"
METAFLAG_default["required"]="0"
METAFLAG_default["default"]=""
METAFLAG_default["enum"]=""
METAFLAG_default["assoc_keys"]=""
METAFLAG_default["min"]=""
METAFLAG_default["max"]=""
METAFLAG_default["min_array"]=""
METAFLAG_default["max_array"]=""
METAFLAG_default["regex"]=""
METAFLAG_default["description"]="Fallback visual or data value applied if the user execution omits the parameter."
METAFLAG_default["tipinput"]=""
METAFLAG_default["validate"]=""

# METAFLAG_enum specifies a structured comma-separated collection of allowed key-value mappings.
# Mandatory if type is set to 'enum'. Rejects definitions that fail alias syntax rules.
declare -gA METAFLAG_enum=()
METAFLAG_enum["short"]=""
METAFLAG_enum["long"]="enum"
METAFLAG_enum["type"]="string"
METAFLAG_enum["array"]="0"
METAFLAG_enum["assoc"]="0"
METAFLAG_enum["required"]="0"
METAFLAG_enum["default"]=""
METAFLAG_enum["enum"]=""
METAFLAG_enum["assoc_keys"]=""
METAFLAG_enum["min"]=""
METAFLAG_enum["max"]=""
METAFLAG_enum["min_array"]=""
METAFLAG_enum["max_array"]=""
METAFLAG_enum["regex"]=""
METAFLAG_enum["description"]="Structured comma-separated list mapping accepted values and internal semantic aliases."
METAFLAG_enum["tipinput"]=""
METAFLAG_enum["validate"]="check_meta_enum_syntax"

# METAFLAG_assoc_keys defines a comma-separated list of mandatory keys for maps.
# Operates exclusively when assoc is active (1) to enforce field presence.
declare -gA METAFLAG_assoc_keys=()
METAFLAG_assoc_keys["short"]=""
METAFLAG_assoc_keys["long"]="assoc_keys"
METAFLAG_assoc_keys["type"]="string"
METAFLAG_assoc_keys["array"]="0"
METAFLAG_assoc_keys["assoc"]="0"
METAFLAG_assoc_keys["required"]="0"
METAFLAG_assoc_keys["default"]=""
METAFLAG_assoc_keys["enum"]=""
METAFLAG_assoc_keys["assoc_keys"]=""
METAFLAG_assoc_keys["min"]=""
METAFLAG_assoc_keys["max"]=""
METAFLAG_assoc_keys["min_array"]=""
METAFLAG_assoc_keys["max_array"]=""
METAFLAG_assoc_keys["regex"]=""
METAFLAG_assoc_keys["description"]="Comma-separated collection of mandatory dictionary keys required in the map."
METAFLAG_assoc_keys["tipinput"]=""
METAFLAG_assoc_keys["validate"]=""

# METAFLAG_min enforces the minimum boundary size constraint allowed for the payload.
# Evaluates string/token length or raw numerical boundaries based on the primary type field.
declare -gA METAFLAG_min=()
METAFLAG_min["short"]=""
METAFLAG_min["long"]="min"
METAFLAG_min["type"]="int"
METAFLAG_min["array"]="0"
METAFLAG_min["assoc"]="0"
METAFLAG_min["required"]="0"
METAFLAG_min["default"]=""
METAFLAG_min["enum"]=""
METAFLAG_min["assoc_keys"]=""
METAFLAG_min["min"]=""
METAFLAG_min["max"]=""
METAFLAG_min["min_array"]=""
METAFLAG_min["max_array"]=""
METAFLAG_min["regex"]=""
METAFLAG_min["description"]="Minimum boundary size asserting string token length or lower numerical value restrictions."
METAFLAG_min["tipinput"]=""
METAFLAG_min["validate"]=""

# METAFLAG_max enforces the maximum boundary size constraint allowed for the payload.
# Evaluates string/token length or raw numerical boundaries based on the primary type field.
declare -gA METAFLAG_max=()
METAFLAG_max["short"]=""
METAFLAG_max["long"]="max"
METAFLAG_max["type"]="int"
METAFLAG_max["array"]="0"
METAFLAG_max["assoc"]="0"
METAFLAG_max["required"]="0"
METAFLAG_max["default"]=""
METAFLAG_max["enum"]=""
METAFLAG_max["assoc_keys"]=""
METAFLAG_max["min"]=""
METAFLAG_max["max"]=""
METAFLAG_max["min_array"]=""
METAFLAG_max["max_array"]=""
METAFLAG_max["regex"]=""
METAFLAG_max["description"]="Maximum boundary size asserting string token length or upper numerical value restrictions."
METAFLAG_max["tipinput"]=""
METAFLAG_max["validate"]=""

# METAFLAG_min_array defines the minimum number of elements required inside a collection.
# This evaluation is optional and operates exclusively when the array attribute is active (1).
declare -gA METAFLAG_min_array=()
METAFLAG_min_array["short"]=""
METAFLAG_min_array["long"]="min_array"
METAFLAG_min_array["type"]="int"
METAFLAG_min_array["array"]="0"
METAFLAG_min_array["assoc"]="0"
METAFLAG_min_array["required"]="0"
METAFLAG_min_array["default"]=""
METAFLAG_min_array["enum"]=""
METAFLAG_min_array["assoc_keys"]=""
METAFLAG_min_array["min"]=""
METAFLAG_min_array["max"]=""
METAFLAG_min_array["min_array"]=""
METAFLAG_min_array["max_array"]=""
METAFLAG_min_array["regex"]=""
METAFLAG_min_array["description"]="Minimum allowable element count within a validated array collection."
METAFLAG_min_array["tipinput"]=""
METAFLAG_min_array["validate"]=""

# METAFLAG_max_array defines the maximum number of elements allowed inside a collection.
# This evaluation is optional and operates exclusively when the array attribute is active (1).
declare -gA METAFLAG_max_array=()
METAFLAG_max_array["short"]=""
METAFLAG_max_array["long"]="max_array"
METAFLAG_max_array["type"]="int"
METAFLAG_max_array["array"]="0"
METAFLAG_max_array["assoc"]="0"
METAFLAG_max_array["required"]="0"
METAFLAG_max_array["default"]=""
METAFLAG_max_array["enum"]=""
METAFLAG_max_array["assoc_keys"]=""
METAFLAG_max_array["min"]=""
METAFLAG_max_array["max"]=""
METAFLAG_max_array["min_array"]=""
METAFLAG_max_array["max_array"]=""
METAFLAG_max_array["regex"]=""
METAFLAG_max_array["description"]="Maximum allowable element count within a validated array collection."
METAFLAG_max_array["tipinput"]=""
METAFLAG_max_array["validate"]=""

# METAFLAG_regex provisions an optional regular expression verification constraint pattern.
# Evaluates whether incoming values perfectly satisfy native Bash or grep pattern criteria.
declare -gA METAFLAG_regex=()
METAFLAG_regex["short"]=""
METAFLAG_regex["long"]="regex"
METAFLAG_regex["type"]="string"
METAFLAG_regex["array"]="0"
METAFLAG_regex["assoc"]="0"
METAFLAG_regex["required"]="0"
METAFLAG_regex["default"]=""
METAFLAG_regex["enum"]=""
METAFLAG_regex["assoc_keys"]=""
METAFLAG_regex["min"]=""
METAFLAG_regex["max"]=""
METAFLAG_regex["min_array"]=""
METAFLAG_regex["max_array"]=""
METAFLAG_regex["regex"]=""
METAFLAG_regex["description"]="Optional structural regular expression layout pattern verified natively at runtime."
METAFLAG_regex["tipinput"]=""
METAFLAG_regex["validate"]=""

# METAFLAG_description maps the essential human documentation text used to render help modules.
# Mandatory framework constraint ensuring zero undocumented features bypass compiler loops.
declare -gA METAFLAG_description=()
METAFLAG_description["short"]=""
METAFLAG_description["long"]="description"
METAFLAG_description["type"]="string"
METAFLAG_description["array"]="0"
METAFLAG_description["assoc"]="0"
METAFLAG_description["required"]="1"
METAFLAG_description["default"]=""
METAFLAG_description["enum"]=""
METAFLAG_description["assoc_keys"]=""
METAFLAG_description["min"]="1"
METAFLAG_description["max"]="256"
METAFLAG_description["min_array"]=""
METAFLAG_description["max_array"]=""
METAFLAG_description["regex"]=""
METAFLAG_description["description"]="Human-readable operational statement describing flag objective for automated UI rendering."
METAFLAG_description["tipinput"]=""
METAFLAG_description["validate"]=""

# METAFLAG_tipinput specifies the custom interactive question or behavioral guide 
# displayed to the user when the framework operates under strict interactive modes.
declare -gA METAFLAG_tipinput=()
METAFLAG_tipinput["short"]=""
METAFLAG_tipinput["long"]="tipinput"
METAFLAG_tipinput["type"]="string"
METAFLAG_tipinput["array"]="0"
METAFLAG_tipinput["assoc"]="0"
METAFLAG_tipinput["required"]="0"
METAFLAG_tipinput["default"]=""
METAFLAG_tipinput["enum"]=""
METAFLAG_tipinput["assoc_keys"]=""
METAFLAG_tipinput["min"]=""
METAFLAG_tipinput["max"]="256"
METAFLAG_tipinput["min_array"]=""
METAFLAG_tipinput["max_array"]=""
METAFLAG_tipinput["regex"]=""
METAFLAG_tipinput["description"]="Custom interactive question phrase displayed during user prompt execution."
METAFLAG_tipinput["tipinput"]=""
METAFLAG_tipinput["validate"]=""

# METAFLAG_validate captures space-separated downstream investigator function names.
# Invoked at the absolute tail of validation loops to compute complex domain-specific rules.
declare -gA METAFLAG_validate=()
METAFLAG_validate["short"]=""
METAFLAG_validate["long"]="validate"
METAFLAG_validate["type"]="string"
METAFLAG_validate["array"]="0"
METAFLAG_validate["assoc"]="0"
METAFLAG_validate["required"]="0"
METAFLAG_validate["default"]=""
METAFLAG_validate["enum"]=""
METAFLAG_validate["assoc_keys"]=""
METAFLAG_validate["min"]=""
METAFLAG_validate["max"]=""
METAFLAG_validate["min_array"]=""
METAFLAG_validate["max_array"]=""
METAFLAG_validate["regex"]=""
METAFLAG_validate["description"]="Space-separated dynamic function pointers processing deep user custom validation states."
METAFLAG_validate["tipinput"]=""
METAFLAG_validate["validate"]=""

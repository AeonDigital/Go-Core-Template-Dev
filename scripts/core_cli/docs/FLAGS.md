Flags
================================

This document serves as the absolute engineering source of truth for declaring 
and configuring command-line flags within the agnostic CLI Engine. It provides 
technical teams and Large Language Models (LLMs) with the precise operational 
mechanics, boundary behaviors, and data formats required to author flawless CLI 
schemas without needing to audit the underlying framework source code.


&nbsp;
&nbsp;


________________________________________________________________________________

## PROPERTY SPECIFICATION DIRECTORY

The core framework evaluates exactly 17 configuration keys for every flag. Each 
property listed below dictates a specific pre-flight compilation constraint or 
a runtime validation route.


&nbsp;


### 3.1 short

Defines the single-dash short character alias for prompt and terminal speed.

*   **Data Type:** `string`
*   **Default:** `""`
*   **Constraints:** Must be strictly between 1 and 3 alphanumeric characters. 
    Rejects punctuation or dashes.
*   **Engine Behavior:** The engine automatically prefixes the character with a 
    single dash `-` for user interaction. Short flags can be standalone or 
    attached to their values via spaces or equal signs.

&nbsp;

#### Schema Declaration

```bash
FLAG_scope["short"]="s"
```




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.2 long

The canonical, immutable primary double-dash identifier for the flag.

*   **Data Type:** `string`
*   **Default:** Mandatory (Cannot be empty)
*   **Constraints:** Max 32 characters. Must conform strictly to Kebab-case 
    or Snake-case (`^[a-z0-9_-]+$`).
*   **Engine Behavior:** Acts as the unique definitive hash key inside the 
command-specific parsed registers (`CMD_<PKG>_<TREE>_PARSED`). The engine 
    forces the double-dash `--` format for CLI ingestion.

&nbsp;

#### Schema Declaration

```bash
FLAG_scope["long"]="scope"
```




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.3 type

Specifies the data type classification enforcing the validation routing.

*   **Data Type:** `enum` (Pointer to `CORE_SUPPORTED_TYPES`)
*   **Default:** `"string"`
*   **Accepted Value Tokens:** `string`, `int`, `float`, `bool`, `json`, 
    `date`, `time`, `datetime`, `email`, `enum`, `path`, `relativepath`, 
    `filename`, `filepath`, `dirname`, `dirpath`, `url`, `fullurl`, 
    `relativeurl`.
*   **Engine Behavior:** Directly maps the argument string to a validator 
    function named `core_cli_flag_validate_[type]`.

&nbsp;

#### Schema Declaration

```bash
FLAG_scope["type"]="enum"
```




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.4 array

Declares whether the parameter processes a flat iterable collection list.

*   **Data Type:** `bool` (`1` or `0`)
*   **Default:** `"0"`
*   **Engine Behavior:** If active (`1`), the engine expects the data format 
    `['val1', 'val2']`. It strips the bracket bounds and triggers a native 
    char-by-char state machine parser that extracts strings and populates a 
    legitimate global Bash indexed array named `CORE_CLI_VALIDATED_ARRAY`. It 
    then loops through the array, running type, boundary, and custom function 
    checks on every element.
*   **Compiler Constraint:** Mutually exclusive with `assoc`. Declaring 
    `array="1"` and `assoc="1"` halts initialization.

&nbsp;

#### Schema Complex Implementation

```bash
FLAG_tags["type"]="string"
FLAG_tags["array"]="1"
FLAG_tags["min"]="3" # Every individual element must be >= 3 characters
```

*   **Accepted Input:** `['admin', 'moderator', 'guest']`
*   **Rejected Input:** `['go', 'js']` -> Throws `Element [0] length violates 
    sizing specifications.`




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.5 assoc

Declares whether the parameter operates as a flat key-value object map 
dictionary.

*   **Data Type:** `bool` (`1` or `0`)
*   **Default:** `"0"`
*   **Engine Behavior:** If active (`1`), the engine expects a valid inline 
    JSON object syntax string: `{"key1":"val1", "key2":"val2"}`. It passes the 
    value through a specialized native linear JSON character-by-character state 
    parser (Machine State). This machine handles string escaping, strips 
    non-textual syntactical spaces, extracts pairs, and populates a true global 
    Bash associative array named `CORE_CLI_VALIDATED_ASSOC`. Every isolated 
    value 
    is then sequentially validated against the flag `type` and boundary 
    constraints.
*   **Compiler Constraint:** Mutually exclusive with `array`.

&nbsp;

#### Schema Complex Implementation

```bash
FLAG_config["type"]="int"
FLAG_config["assoc"]="1" # Every value inside the JSON dictionary must be an integer
```

*   **Accepted Input:** `{"port": 8080, "timeout": 30}`
*   **Rejected Input:** `{"port": 8080, "host": "localhost"}` -> Host value 
    breaks `type=int` validation.




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.6 required

Enforces parameter presence assertions during runtime execution.

*   **Data Type:** `bool` (`1` or `0`)
*   **Default:** `"0"`
*   **Engine Behavior:** If set to `1`, the engine intercepts empty strings or 
    missing parameters immediately, short-circuiting downstream execution. If 
    `required="0"`, empty options bypass all validation loops and load the 
    `default` property.

&nbsp;

#### Schema Declaration

```bash
FLAG_scope["required"]="1"
```




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.7 default

The fallback data value applied if the user omits the flag.

*   **Data Type:** `string`
*   **Default:** `""`
*   **Engine Behavior:** If the parameter is omitted and `required="0"`, the 
    engine automatically populates the parameter register with this string.
*   **Compiler Constraint:** The compiler throws an `[ERR]` if a schema 
    declares `required="1"` and provides a `default` value simultaneously, as 
    they are mutually exclusive concepts.

&nbsp;

#### Schema Declaration

```bash
FLAG_scope["default"]="internal"
```




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.8 enum

A string pointer directing the engine to a global associative array name 
containing allowed values.

*   **Data Type:** `string` (Must resolve to an active array name variable)
*   **Default:** `""`
*   **Engine Behavior:** Used exclusively when `type="enum"`. The engine 
    creates a dynamic reference pointer (`local -n`) to the target array. It 
    reads the array values (not keys) to evaluate membership. 

&nbsp;

#### Schema Complex Implementation

```bash
# 1. Define the dynamic data dictionary list
declare -gA APP_SCOPES=( ["i"]="internal" ["p"]="pkg" )

# 2. Reference the exact variable name inside the metadata schema
FLAG_scope["type"]="enum"
FLAG_scope["enum"]="APP_SCOPES"
```

*   **Accepted Input:** `"internal"`, `"pkg"`
*   **Rejected Input:** `"production"`, `"i"` (unless `"i"` is also declared 
    as a value in the array)




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.9 assoc_keys

Defines a comma-separated collection of mandatory dictionary keys required 
in the map.

*   **Data Type:** `string` (Comma-separated tokens)
*   **Default:** `""`
*   **Engine Behavior:** After the JSON parsing cycle populates
    `CORE_CLI_VALIDATED_ASSOC`, the engine splits this property, sorts the 
    expected keys alphabetically for deterministic tracking, and queries the 
    native map structure using high-performance internal memory checks: 
    `[ -z "${CORE_CLI_VALIDATED_ASSOC["$key"]+exists}" ]`.
*   **Compiler Constraint:** Mandates `assoc="1"`. Otherwise, causes an 
    orphaned design compiler error.

&nbsp;

#### Schema Complex Implementation

```bash
FLAG_db["type"]="string"
FLAG_db["assoc"]="1"
FLAG_db["assoc_keys"]="user,password" # These specific keys MUST exist inside the object
```

*   **Accepted Input:** `{"user":"admin", "password":"foo", "dbname":"metrics"}`
*   **Rejected Input:** `{"user":"admin", "host":"localhost"}` -> Throws 
    `required key 'password' is missing.`




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.10 min

Dictates lower ranges, character counts, or chronological start thresholds.

*   **Data Type:** `string` / `int` (Contextual)
*   **Default:** `""` (Empty string means no lower limit restriction)
*   **Engine Behavior:** Automatically adapts its logic based on the `type` 
    property:
    *   For `int`: Evaluates native mathematical floors (`value < min`).
    *   For `date`, `time`, `datetime`: Converts values to integer Unix epoch 
        seconds before mathematical comparison.
    *   For `string`, `float`, and system environments: Evaluates string length 
        (`${#value} < min`).

&nbsp;

#### Schema Complex Implementation

```bash
FLAG_release["type"]="date"
FLAG_release["min"]="2020-01-01" # Chronological lower boundary
```

*   **Accepted Input:** `"2025-05-12"`
*   **Rejected Input:** `"2019-12-31"` -> Throws `(min: 2020-01-01)`




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.11 max

Dictates upper ranges, character counts, or chronological end thresholds.

*   **Data Type:** `string` / `int` (Contextual)
*   **Default:** `""` (Empty string means no upper limit restriction)
*   **Engine Behavior:** Adapts logic identically to the `min` property:
    *   For `int`: Evaluates native mathematical ceilings (`value > max`).
    *   For `date`, `time`, `datetime`: Evaluates integer Unix epoch seconds.
    *   For `string`, `float`, and system environments: Evaluates character 
        length restrictions.
*   **Compiler Constraint:** Rejects schemas where `min` exceeds `max`.

&nbsp;

#### Schema Complex Implementation

```bash
FLAG_age["type"]="int"
FLAG_age["min"]="18"
FLAG_age["max"]="65"
```

*   **Accepted Input:** `"42"`
*   **Rejected Input:** `"70"` -> Throws `(max: 65)`




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.12 min_array

Restricts the minimum allowable count of elements within an active collection.

*   **Data Type:** `int`
*   **Default:** `""`
*   **Engine Behavior:** Evaluates the length of the parsed array structure 
    `${#CORE_CLI_VALIDATED_ARRAY[@]}`.
*   **Compiler Constraint:** Mandates `array="1"`. If `array="0"`, this key 
    triggers an orphaned design `[ERR]`.

&nbsp;

#### Schema Complex Implementation

```bash
FLAG_hosts["type"]="string"
FLAG_hosts["array"]="1"
FLAG_hosts["min_array"]="2" # The list MUST contain at least two items
```

*   **Accepted Input:** `['server-a', 'server-b']`
*   **Rejected Input:** `['server-a']` -> Throws `(min_array: 2)`




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.13 max_array

Restricts the maximum allowable count of elements within an active collection.

*   **Data Type:** `int`
*   **Default:** `""`
*   **Engine Behavior:** Evaluates the length of the parsed array structure 
     `${#CORE_CLI_VALIDATED_ARRAY[@]}`. Setting `max_array="0"` forces the 
     array to remain completely empty.
*   **Compiler Constraint:** Mandates `array="1"`. Rejects schemas where 
    `min_array` exceeds `max_array`.

&nbsp;

#### Schema Complex Implementation

```bash
FLAG_ips["type"]="string"
FLAG_ips["array"]="1"
FLAG_ips["max_array"]="3"
```

*   **Accepted Input:** `['10.0.0.1', '10.0.0.2']`
*   **Rejected Input:** `['10.0.0.1', '10.0.0.2', '10.0.0.3', '10.0.0.4']` -> 
    Throws `(max_array: 3)`




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.14 regex

An optional custom regular expression pattern verified natively at runtime.

*   **Data Type:** `string`
*   **Default:** `""`
*   **Engine Behavior:** Runs the string through the native Bash match 
    operator `[[ "$value" =~ $regex ]]`.
*   **Compiler Behavior:** Pre-flight loops compile the regex pattern inside 
    a sandbox. Malformed syntax (e.g., mismatched brackets) triggers an `[ERR]` 
    compiler halt before the CLI boots.

&nbsp;

#### Schema Complex Implementation

```bash
FLAG_id["type"]="string"
FLAG_id["regex"]="^XERR-[0-9]{4}\$" # Escape dollar sign in double quotes
```

*   **Accepted Input:** `"XERR-1024"`
*   **Rejected Input:** `"abc-123"`, `"XERR-12"`




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.15 description

The documentation text statement describing the flag's behavioral objective.

*   **Data Type:** `string`
*   **Default:** Mandatory (Cannot be left blank)
*   **Constraints:** Min 1, Max 256 characters.
*   **Engine Behavior:** Extracted by the orchestration manager to 
    automatically stitch and render the global help screens or contextual 
    subresource documentation formats.

&nbsp;

#### Schema Declaration

```bash
FLAG_scope["description"]="Target project environment scope boundary mapping."
```




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.16 tipinput

The custom human-centric question or message phrase applied during interactive 
execution modes.

*   **Data Type:** `string`
*   **Default:** `""` (Empty string triggers an automated framework fallback 
    prompt)
*   **Engine Behavior:** Evaluated exclusively when the user invokes the `-itr` 
    or `--interactive` flag sequence. If the property is empty, the terminal 
    generator fallback defaults natively to rendering a standard text pattern: 
    `[ > ] Enter value for --[long_name]: `.

&nbsp;

#### Schema Declaration

```bash
FLAG_name["tipinput"]="Enter Corporate Title for the new sequential Error Family"
```




&nbsp;
---- ---- ---- -------- ---- ---- -------- ---- ---- -------- ---- ---- ----

### 3.17 validate

Space-separated pointers targeting dynamic downstream custom investigator 
functions.

*   **Data Type:** `string` (Space-separated function names)
*   **Default:** `""`
*   **Engine Behavior:** Executed at the absolute tail of validation loops. 
    For scalar items, it triggers once. For collections (`array`/`assoc`), the 
    engine loops and invokes these functions **individually for each extracted 
    value**.
*   **Compiler Behavior:** Asserts whether the listed function names 
    physically exist in the script execution environment via `declare -f`. If a 
    function is missing, it breaks the initialization with an implementation 
    gap `[ERR]`.

&nbsp;

#### Schema Complex Implementation

```bash
# 1. Author the specialized domain business validation rule function
check_error_file_collision() {
  local val="\$1"
  if grep -q "\$val" "./registry.go"; then
    VALIDATION_ERROR_MSG="Token collision detected inside registry.go file."
    return 1
  fi
  return 0
}

# 2. Register the exact function pointer token inside the metadata schema matrix
FLAG_name["type"]="string"
FLAG_name["validate"]="check_error_file_collision"
```


&nbsp;
&nbsp;


________________________________________________________________________________

## CORE INITIATION CONSTRAINTS (HIDDEN LAWS)

Technical authors must note specific framework behaviors that occur behind the 
scenes during validation execution:

*   **String Safety Interception:** Before a property value reaches its typed 
    validator, the core runs `core_cli_flag_validate_string` to block hidden 
    malicious or invisible terminal control bytes (`[[:cntrl:]]`). Space, tabs, 
    and carriage returns are stripped during testing to allow multi-line 
    payloads while maintaining safety.
*   **Temporal Chronological Padding:** The types `date`, `time`, and 
    `datetime` run intelligent inference pipelines. If a user inputs just a 
    year (`2026`), the date layer expands it into `2026-01-01` inside the 
    tracking register variable `CORE_CLI_VALIDATED_VALUE` before triggering 
    system calendar checks.
*   **Deterministic Map Sorting:** Because Bash associative arrays do not
    preserve data insertion order, the engine pipes all key evaluations 
    through a system `sort`. This guarantees that error validation output 
    lists appear in a deterministic, reproducible sequence.

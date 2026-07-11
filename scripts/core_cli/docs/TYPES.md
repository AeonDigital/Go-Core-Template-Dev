Types
================================

This document serves as the absolute engineering source of truth for the type 
system implemented inside the agnostic CLI Engine. It defines how the execution 
layer interprets data classifications, executes native validation routines, and 
interacts with schema constraints. Technical teams and LLMs must utilize this 
specification to architect flawless data inputs without configuration conflicts.


&nbsp;
&nbsp;


________________________________________________________________________________

## TYPE SYSTEM MATRIX OVERVIEW

The framework divides data types into three main tiers to optimize runtime 
checks and parse behaviors natively in Bash without external binaries. 

&nbsp;

#### Supported Type Catalog

*   **Primitives:** Evaluates baseline scalar data definitions (`string`, 
    `int`, `float`, `bool`).
*   **Structured Layouts:** Validates structural syntactical syntax masks 
    (`json`, `date`, `time`, `datetime`, `email`, `enum`).
*   **System Environments:** Validates environment tokens and paths rules 
    (`path`, `relativepath`, `filename`, `filepath`, `dirname`, `dirpath`, 
    `url`, `fullurl`, `relativeurl`).


&nbsp;
&nbsp;


________________________________________________________________________________

## PRIMITIVE TYPES ARCHITECTURE

Primitives form the baseline scalar storage units of the engine. When evaluated 
individually, they trigger fundamental text or mathematical validation 
pipelines.

&nbsp;


### 1.1 string

The generic fallback type designed to capture standard printable text streams.

*   **Constraint Correlations:** `min` and `max` evaluate character counts 
    (`${#value}`). Supports `regex`, `array`, and `assoc`.
*   **Engine Behavior:** Automatically routes data through
    `core_cli_flag_validate_string` to strip spaces and assert that no nvisible 
    malicious terminal control bytes (`[[:cntrl:]]`) are present.
*   **Accepted Input:** `"XERR_UNKNOWN"`, `"A concise human message with 
    accents (á, ç)."`
*   **Rejected Input:** Any string embedding binary null bytes `\x00` or raw 
    terminal escape codes `\x1B`.


&nbsp;


### 1.2 int

Enforces strict positive or negative whole mathematical integers.

*   **Constraint Correlations:** `min` and `max` shift behavior to evaluate 
    absolute mathematical integer floors and ceilings 
    (`(( value < min ))` / `(( value > max ))`). Supports `array` and `assoc`. 
    Rejects alphabetical character arrays in `regex`.
*   **Engine Behavior:** Evaluates inputs natively via pure Bash arithmetic 
    brackets. Bypasses character length checks in favor of numeric values.
*   **Accepted Input:** `"42"`, `"-105"`, `"0"`
*   **Rejected Input:** `"3.14"` (decimals are illegal), `"10a"` (alphabetic 
    suffixes are rejected).


&nbsp;


### 1.3 float

Enforces positive or negative fractional decimal numeric formatting layout 
rules.

*   **Constraint Correlations:** `min` and `max` evaluate absolute mathematical 
    ranges utilizing the native framework string comparison algorithm 
    (`core_cli_math_compare_float`). Supports `array` and `assoc`.
*   **Engine Behavior:** To prevent system crashes in minimalist environments, 
    the engine executes string-splitting and fraction zero-padding natively 
    inside Bash, eliminating third-party calculators like `bc`.
*   **Accepted Input:** `"3.14"`, `"-0.005"`, `"42"` (integers qualify as valid 
    floats)
*   **Rejected Input:** `"1,5"` (comma delimiters are illegal; dot notation is 
    mandatory), `"abc"`.


&nbsp;


### 1.4 bool

Enforces strict true/false structural binary boolean parameter states.

*   **Constraint Correlations:** Rejects `min`, `max`, and `regex` 
    configurations during pre-flight compiler loops. Supports `array` and 
    `assoc`.
*   **Engine Behavior:** Normalizes text assignments immediately into literal 
    system triggers (`1` or `0`). If a user passes a boolean flag inline 
    without an explicit value, the engine assigns `"1"` automatically.
*   **Accepted Input:** `"1"` (True), `"0"` (False)
*   **Rejected Input:** `"true"`, `"false"`, `"Y"`, `"N"` (only binary numeric 
    layout digits are allowed).


&nbsp;
&nbsp;


________________________________________________________________________________

## STRUCTURED LAYOUTS ARCHITECTURE

Structured types enforce exact syntactical masks or text data formatting 
models, bridging raw console strings into valid data contracts.

&nbsp;


### 2.1 json

Asserts that the text content matches a well-formed, flat JSON layout sequence.

*   **Constraint Correlations:** `min` and `max` evaluate total character 
    counts of the raw string. Supports `regex` and `array`. **Rejects `assoc`** 
    configuration loops to prevent circular mapping recursion.
*   **Engine Behavior:** Invokes a dedicated character-by-character state 
    machine parser that ignores syntactical white spaces while safely 
    preserving inner text spaces within quotation marks.
*   **Accepted Input:** `{"port":8080,"host":"localhost"}`
*   **Rejected Input:** `{"port": 8080,}` (trailing commas are illegal syntax 
    formatting corruption).


&nbsp;


### 2.2 date

Validates ISO-8601 standard calendar timelines with real chronological checking.

*   **Constraint Correlations:** `min` and `max` expect structural `YYYY-MM-DD` 
    strings. The engine translates boundaries into Unix epoch seconds natively 
    before evaluating limits. Supports `array` and `assoc`.
*   **Engine Behavior:** Runs a lookahead length check to execute automated 
    inference. If the input format contains fewer characters than the full 
    mask, it applies structural padding before validating real calendar bounds 
    via system clock tools.
*   **Inference Rules:** 
    *   Entering `"2026"` infers and outputs `"2026-01-01"`.
    *   Entering `"2026-05"` infers and outputs `"2026-05-01"`.
*   **Accepted Input:** `"2026-02-28"`, `"2026"`
*   **Rejected Input:** `"2026-02-30"` (impossible calendar day), 
    `"2026/05/12"` (slash formatting is rejected).


&nbsp;


### 2.3 time

Validates standard hourly chronological sequences with numeric time-range 
bounds.

*   **Constraint Correlations:** `min` and `max` expect `HH:MM:SS` strings. 
    Supports `array` and `assoc`.
*   **Engine Behavior:** Enforces strict internal mathematical ranges across 
    tokens (Hours: `00-23`, Minutes: `00-59`, Seconds: `00-59`). Pads missing 
    elements dynamically.
*   **Inference Rules:**
    *   Entering `"14"` infers and outputs `"14:00:00"`.
    *   Entering `"14:30"` infers and outputs `"14:30:00"`.
*   **Accepted Input:** `"23:59:59"`, `"08:15"`
*   **Rejected Input:** `"24:00:00"` (out of bounds), `"14:61:00"` 
    (impossible minute count).


&nbsp;


### 2.4 datetime

Combines calendar dates and hourly timelines into a single unified UTC sequence.

*   **Constraint Correlations:** `min` and `max` expect full `YYYY-MM-DD 
    HH:MM:SS` targets. Supports `array` and `assoc`.
*   **Engine Behavior:** Decouples the input string into separate date and time 
    tokens. It routes them individually through the `date` and `time` 
    sub-validators, then captures their safe inferred outputs into the global 
    transit register `CORE_CLI_VALIDATED_VALUE`.
*   **Inference Rules:**
    *   Entering just `"2026"` outputs `"2026-01-01 00:00:00"`.
    *   Entering just `"14:30"` outputs `"0001-01-01 14:30:00"`.
*   **Accepted Input:** `"2026-07-10 22:15:00"`
*   **Rejected Input:** `"2026-02-30 12:00:00"` (fails the underlying calendar 
    test).


&nbsp;


### 2.5 email

Asserts standard corporate and internet mailbox address layout constraints.

*   **Constraint Correlations:** `min` and `max` evaluate total character 
    counts. Supports `regex`, `array`, and `assoc`.
*   **Engine Behavior:** Runs the string against an optimized native regex 
    layer validating identity tokens, at-sign delimiters, and top-level domain 
    structures.
*   **Accepted Input:** `"developer@corp.internal"`, `"cli.bot+test@gmail.com"`
*   **Rejected Input:** `"developer@corp"`, `"admin@@domain.com"`.


&nbsp;


### 2.6 enum

Forces argument values to match a predefined, closed dictionary list.

*   **Data Type Pointer:** Requires the `enum` configuration property to hold 
    the exact name of an existing global Bash associative array variable.
*   **Constraint Correlations:** Rejects `min` and `max` properties. Supports 
    `array` and `assoc`.
*   **Engine Behavior:** Resolves the dictionary array name dynamically via 
    reference aliases (`local -n`). It scans the **values** (not keys) of the 
    target structure to validate user input membership.
*   **Accepted Input:** Any string literal present inside the target array 
    values.
*   **Rejected Input:** Any string absent from the target array values.


&nbsp;
&nbsp;


________________________________________________________________________________

## SYSTEM ENVIRONMENTS ARCHITECTURE

System types process folder paths, file allocations, and address masks. They 
execute structural semantic verification without making physical disk calls to 
ensure portability.

&nbsp;


### 3.1 path / dirpath

Asserts the general character formatting safety for directory hierarchies.

*   **Constraint Correlations:** `min` and `max` evaluate character counts. 
    Supports `regex`, `array`, and `assoc`.
*   **Engine Behavior:** Scans for forbidden system symbols and characters that 
    would cause string slicing failures or security vulnerabilities during 
    directory traversal.
*   **Accepted Input:** `"/usr/local/bin"`, `"internal/xerrors/"`, `"C:\Go\src"`
*   **Rejected Input:** Any path containing shell wildcards or illegal control 
    characters (`*`, `?`, `<`, `>`, `|`, `"`).


&nbsp;


### 3.2 relativepath

Enforces localized directory structures that exclude system root privileges.

*   **Constraint Correlations:** Same as `path`.
*   **Engine Behavior:** Reuses the core path character filter and asserts that 
    the string does not initialize with root indicators (`/` or drive letters 
    like `C:\`).
*   **Accepted Input:** `"internal/xerrors"`, `".github/workflows"`
*   **Rejected Input:** `"/internal/xerrors"`, `"D:\project"`.


&nbsp;


### 3.3 filename

Asserts character and formatting compliance for individual, standalone file 
tokens.

*   **Constraint Correlations:** Same as `string`.
*   **Engine Behavior:** Blocks folder path dividers (`/` or `\`) to ensure the 
input represents a single file unit on disk, preventing directory traversal 
attempts.
*   **Accepted Input:** `"xerrors.go"`, `"config_production.json"`
*   **Rejected Input:** `"xerrors/xerrors.go"`, `"/"`.


&nbsp;


### 3.4 filepath

Validates path sequences that must resolve into a specific file target.

*   **Constraint Correlations:** Same as `path`.
*   **Engine Behavior:** Asserts character safety and rejects string 
    expressions that terminate with folder slashes (`/` or `\`), ensuring a 
    file token is present at the tail.
*   **Accepted Input:** `"/internal/xerrors/xerrors.go"`, `"config.json"`
*   **Rejected Input:** `"/internal/xerrors/"`.


&nbsp;


### 3.5 dirname

Asserts character safety constraints for single directory names.

*   **Constraint Correlations:** Same as `filename`.
*   **Engine Behavior:** Reuses the filename validator rules to bar all 
    directory separators, enforcing a single folder token naming schema.
*   **Accepted Input:** `"xerrors"`, `"pkg"`
*   **Rejected Input:** `"pkg/xerrors"`.


&nbsp;


### 3.6 url

Validates both absolute network protocols and relative URI web paths.

*   **Constraint Correlations:** `min` and `max` evaluate character length. 
    Supports `array` and `assoc`.
*   **Engine Behavior:** Acts as a generic router that allows the input to pass 
    if it qualifies under either absolute or relative URL structural rules.
*   **Accepted Input:** `"https://localhost:8080/api"`, `"/v1/metrics?
    sort=true"`
*   **Rejected Input:** `"https:localhost"`, `"api/v1/users"` (missing the 
    leading relative slash).


&nbsp;


### 3.7 fullurl

Enforces absolute network paths featuring explicit protocols and hosts.

*   **Constraint Correlations:** Same as `url`.
*   **Engine Behavior:** Uses a strict network regex validating schema 
    protocols (`http`, `https`, `ftp`, `file`), hostnames, ports, and 
    downstream path parameters.
*   **Accepted Input:** `"https://corp.internal"`, 
    `"ftp://10.0.0.1:21/dump.sql"`
*   **Rejected Input:** `"/api/v1/users"`, `"localhost:8080"`.


&nbsp;


### 3.8 relativeurl

Enforces localized endpoints web paths while barring remote network protocols.

*   **Constraint Correlations:** Same as `url`.
*   **Engine Behavior:** Mandates a leading forward slash `/` and 
    systematically rejects external schemas (`http://`, `https://`) to block 
    server-side request forgery (SSRF) inputs.
*   **Accepted Input:** `"/v1/users"`, `"/index.html?user=admin#profile"`
*   **Rejected Input:** `"https://localhost/api"`, `"api/v1/users"`.


&nbsp;
&nbsp;


________________________________________________________________________________

## CORE MATRIX RULES MATRIX (COMPILER LAWS)

To avoid configuration runtime failures, technical authors must understand how 
schema properties interact with different types:

*   **Numerical vs. Sizing Limits:** When evaluating `min` and `max`, the 
    system switches from counting characters to evaluating absolute numerical 
    value floors and ceilings only for the `int` type. For `float`, it triggers 
    string decimal comparisons. For `date`, `time`, and `datetime`, it tests 
    chronological ranges using epoch seconds. All other types default to 
    testing string length.
*   **Collection Array Extraction:** Activating `array="1"` forces the 
    framework to bypass simple scalar evaluations. It parses the target string 
    into the native Bash indexed array `CORE_CLI_VALIDATED_ARRAY`, loops 
    through it, and validates every single element against the rules of the 
    selected `type`.
*   **Object Map Extraction:** Activating `assoc="1"` triggers the flat JSON 
    state machine parser, loading key-value pairs into 
    `CORE_CLI_VALIDATED_ASSOC`. Every individual value inside the dictionary is 
    then evaluated against the `type` limits, while `assoc_keys` checks for 
    mandatory fields.

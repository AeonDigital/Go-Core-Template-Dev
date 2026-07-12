Shell Core Cli
================================

> [Aeon Digital](http://www.aeondigital.com.br)  
> rianna@aeondigital.com.br

&nbsp;

> Core engineering manual and architectural specifications for the agnostic 
> corporate shell automation command-line framework.


&nbsp;


The `core_cli` framework is an enterprise-grade, compiler-driven automation 
engine built entirely in native Bash. Designed to enforce absolute data 
predictability and user-interface harmony across complex repository ecosystems, 
this framework completely decouples user interaction parsing, dynamic flag 
validation, and pre-flight schema checking from raw downstream script business 
logic.

By treating commands and configurations strictly as structured datasets, 
`core_cli` intercepts development omissions during initialization and 
guarantees clean, typed variables before a single execution instruction fires.


&nbsp;
&nbsp;


________________________________________________________________________________

## ARCHITECTURAL PILLARS

The driving philosophy behind the engine is **Convention over Configuration (CoC)** 
coupled with **Self-Hosted Compilation**. It guarantees shell portability 
across heterogeneous technical environments (Linux, macOS) by eliminating 
external binary calculator requirements or disparate interface behaviors.

&nbsp;

#### Key Structural Capabilities

*   **Self-Hosted Pre-Flight Compilation:** Validates developer configuration 
    schemas against core metadata constraints before runtime processing begins.
*   **Decoupled Interface Handling:** Automates double-dash (`--flag=value`) 
    string parsing, short flag matching, and error isolation without custom 
    loop blocks.
*   **Contextual Auto-Help Generation:** Dynamically stitches terminal 
    documentation layout maps utilizing character-wrapping and column geometry 
    rules.
*   **Fail-Fast Evaluation Pipelines:** Evaluates parameter properties 
    sequentially, immediately halting streams upon intercepting the first 
    structural error.
*   **Deterministic Type Ingestion:** Parses and maps primitives, dates, times, 
    and maps directly into legitimate native Bash iterable data structures.


&nbsp;
&nbsp;


________________________________________________________________________________

## CORE CLI SYSTEM ANATOMY

The framework operates on a zero-overhead **Plug-and-Play** layout. The root 
component `main.sh` computes the absolute physical position of its directory 
structure at runtime, auto-sources every internal system utility module 
seamlessly, and exposes a shared runtime state through the `vars.sh` bundle.

&nbsp;

#### Directory Component Layout

```text
core_cli/
├── docs/
│   ├── FLAGS.md              # Detailed 17-key compilation reference manual.
│   └── TYPES.md              # Native type validation reference for the engine.
│ 
├── flags/
│   ├── engine.sh             # Main parameter and scalar orchestration routines.
│   ├── meta.sh               # Pre-flight flag integrity schema checker.
│   ├── parsers.sh            # Native character state-machines for arrays/maps.
│   └── validate.sh           # 19 low-level type mask regex validator hooks.
│ 
├── utils/
│   ├── math.sh               # Pure Bash arbitrary-precision float comparisons.
│   └── strings.sh            # Dynamic terminal geometry and word wrapping.
│ 
└── main.sh                   # Master orchestrator, bootstrap, and entrypoint core.
```


&nbsp;
&nbsp;


________________________________________________________________________________

## INTEGRATED LIFECYCLE BOUNDARIES

The framework divides script runtime lifecycles into four explicit 
architectural chambers to separate error ownership (Error 400 user mistakes vs 
Error 500 system logic deficits):


&nbsp;


### 3.1 Pre-Flight Compilation (Developer Domain - Error 500)

Triggered instantly during initialization. The core inspects the registered 
structures and halts with an immutable `[ERR]` signature if the schema is 
broken (e.g., range inversions like `min > max`, overlapping structures, or 
missing custom function hooks).


&nbsp;


### 3.2 Ingest and Atomic Validation (User Domain - Error 400)

The engine reads the raw input streams. If `--interactive` or `-itr` is 
supplied, it prompts the terminal field-by-field following the exact 
`FLAG_ORDER` matrix, forcing retries until rules pass. If scalar limits are 
violated, it halts on the first infraction with a punchy `[ x ]` trace.


&nbsp;


### 3.3 Cross-Validation Hook (Business Domain - Error 400)

The last line of user defense. If a function matching the convention pattern 
`cmd_<pkg>_<tree>_main_validate` exists, the core triggers it. This is the 
precise room designed to enforce cross-parameter rules (e.g., checking if 
option A restricts the allowed value ranges of option B).


&nbsp;


### 3.4 Execution Phase (Action Domain - Success State)

The business logic function `cmd_<pkg>_<tree>_action` fires. It runs with 100% 
guarantees that all variables are sanitized, typed, and available through an 
unfettered, clean local associative map register.


&nbsp;
&nbsp;


________________________________________________________________________________

## STRICT CONVENTION NAMING BLUEPRINT

The framework architecture operates entirely on **Convention over Configuration (CoC)**. 
By matching global shell structures to predictable, multi-block token layouts, 
`core_cli` eliminates the need for manual routing registries, isolates 
application context, and prevents namespace collisions entirely.

&nbsp;

#### Variable and Token Formatting Laws

*   **Package Name Tag (`<PKGNAME>`):** Must be uppercase, alpha-numeric, and 
    represent the global core identity of the utility tool (e.g., `XERRORS`).
*   **Command Tree Identifiers (`<TREE>`):** Positional parameters are 
    dynamically merged with underscores. (`code add` compiles to `code_add`).
*   **Mono-Command Fallback (`ORES`):** If a script runs with a single 
    positional action (e.g., `./mycli status`), the core handles the 
    single-level hierarchy by binding the prefix token `ORES` into the tree 
    identifier context (`ORES_status`).


&nbsp;


### 4.1 Command Registry Schema Structures

To declare a command capability, the developer must provision a unified, 
predefined global signature matrix composed of three tightly coupled structures:

```bash
# 1. Base Command Configuration Definition Matrix
declare -gA CMD_XERRORS_code_add=(
  ["cmd"]="add"
  ["summary"]="insert a new error code index"
  ["description"]="Full structural automation engine writing safe corporate constants."
)

# 2. Strict Checklist Validation and Interaction Sequence Order
declare -ga CMD_XERRORS_code_add_FLAG_ORDER=(
  "scope" "name" "message"
)

# 3. Dynamic Business Logic Contract Execution Target
cmd_xerrors_code_add_action() {
  # Your business script goes here with 100% data safety guarantees!
  local clean_name="\${CMD_XERRORS_code_add_PARSED["name"]}"
}
```


&nbsp;


### 4.2 Shared Global Flags & Context Overrides

To prevent code redundancy across distinct commands, flags can be registered 
globally. 
The core scans the variable signature layout dynamically. If a string pointer 
is intercepted instead of a map, it loads the global rule template and merges 
localized behavior using the `_OVERRIDE` convention.

```bash
# A. Centralized Application-Wide Shared Flag Registry Map
declare -gA CMD_XERRORS_GLOBAL_FLAG_scope=(
  ["type"]="enum"
  ["required"]="0"
  ["enum"]="PROJECT_ALLOWED_SCOPES"
  ["description"]="Target project environment scope boundary mapping."
)

# B. Binding via Reference String Pointer within the Command Scope
declare -g CMD_XERRORS_code_add_FLAG_scope="CMD_XERRORS_GLOBAL_FLAG_scope"

# C. Optional Override Map updating properties EXCLUSIVELY for this command context
declare -gA CMD_XERRORS_code_add_FLAG_scope_OVERRIDE=(
  ["required"]="1" # Elevates this specific command flag to be strictly mandatory
)
```


&nbsp;
&nbsp;


________________________________________________________________________________

## QUICK-START AND EXAMPLE

A complete example is available in [docs/EXAMPLE.md](./docs/EXAMPLE.md). The
entrypoint must load [main.sh](./main.sh), define `CORE_CLI_ROOT_PATH`, and then
register command and flag schemas before calling `core_cli_run`.

## RESERVED FLAGS AND INPUT RULES

The framework reserves the following tokens for its own orchestration layer:

* `-h`, `--help`
* `-itr`, `--interactive`

Any other flag must be declared in the command schema. If the user provides a
flag that is not declared, or supplies both long and short aliases for the same
property, the framework halts with an input error formatted as `[ x ]`.

## VALIDATED VALUES STORAGE

The engine does not store validated values in a single global map. Instead, it
writes the final values into command-specific maps named
`CMD_<PKG>_<TREE>_PARSED`. This is the structure that action hooks should read
from.

## REQUIRED BOOTSTRAP VARIABLES

Before calling `core_cli_run`, the caller must define `CORE_CLI_ROOT_PATH` and
point it to an existing directory. The framework also uses the following shared
runtime variables during execution:

* `CORE_CLI_RAW_INPUTS`
* `CORE_CLI_ACTIVE_PKG`
* `CORE_CLI_ACTIVE_COMMAND_TREE`
* `CORE_CLI_TRIGGER_HELP`
* `CORE_CLI_TRIGGER_INTERACTIVE`
* `CORE_CLI_VALIDATED_VALUE`
* `CORE_CLI_VALIDATED_ARRAY`
* `CORE_CLI_VALIDATED_ASSOC`
* `VALIDATION_ERROR_MSG`

These declarations are centralized in [vars.sh](./vars.sh).

&nbsp;
&nbsp;


________________________________________________________________________________

## COMPLEMENTARY TECHNICAL MANUALS

For deep technical insights regarding property variables validation or specific 
data type parsing capabilities, please consult the official documents located 
inside the local framework manual directory tree:

*   **[`core_cli/docs/FLAGS.md`](./docs/FLAGS.md):** Deep technical 
    reference guide explaining the 17 available compilation matrix metadata 
    properties, structural constraints mapping, and logic override behaviors.
*   **[`core_cli/docs/TYPES.md`](./docs/TYPES.md):** Architectural 
    manual detailing the native primitives, structured masks, and system 
    environment types supported by the core verification layer.


&nbsp;
&nbsp;


________________________________________________________________________________

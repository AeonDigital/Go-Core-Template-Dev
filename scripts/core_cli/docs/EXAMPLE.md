Example
================================

This document provides a complete, minimal walkthrough for building a command 
line entrypoint with the core_cli framework.


&nbsp;
&nbsp;


________________________________________________________________________________

## BOOTSTRAP AND ENTRYPOINT

Create a main executable script, load the framework entrypoint, and define the
workspace root before invoking the engine.

```bash
#!/bin/bash

set -e

. core_cli/main.sh

CORE_CLI_ROOT_PATH="$(pwd)"
```

&nbsp;
&nbsp;


________________________________________________________________________________

## COMMAND REGISTRY AND FLAGS

Declare the command metadata, the ordered flag list, and the flag schemas.

```bash
#!/bin/bash

set -e

. core_cli/main.sh

CORE_CLI_ROOT_PATH="$(pwd)"

declare -gA CMD_MYTOOL_ORES_status=(
  ["cmd"]="status"
  ["summary"]="check operational system integrity markers"
  ["description"]="Inspect the current environment stage for the tool"
)

declare -ga CMD_MYTOOL_ORES_status_FLAG_ORDER=("environment")

declare -gA CMD_MYTOOL_ORES_status_FLAG_environment=(
  ["short"]="e"
  ["long"]="environment"
  ["type"]="string"
  ["required"]="1"
  ["regex"]="^(prod|stg|dev)$"
  ["description"]="Target execution environment stage"
  ["tipinput"]="Enter active environment stage (prod/stg/dev)"
)
```

&nbsp;
&nbsp;


________________________________________________________________________________

## BUSINESS HOOKS

Implement any cross-validation and action logic. The validated data will be
available in a command-specific map named `CMD_<PKG>_<TREE>_PARSED`.

```bash
cmd_mytool_ores_status_main_validate() {
  return 0
}

cmd_mytool_ores_status_action() {
  local env_stage="${CMD_MYTOOL_ORES_status_PARSED["environment"]}"

  echo "Evaluating environment stage: ${env_stage}"
}
```

&nbsp;
&nbsp;


________________________________________________________________________________

## ENGINE LAUNCH

Call the runtime controller to start the framework.

```bash
core_cli_run "MYTOOL" "$@"
```

&nbsp;
&nbsp;


________________________________________________________________________________

## USAGE EXAMPLES

```bash
./mytool.sh status --environment=prod
./mytool.sh status -e stg
```

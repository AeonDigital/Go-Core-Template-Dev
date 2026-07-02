Go-Core Template Dev
================================

> [Aeon Digital](http://www.aeondigital.com.br)  
> rianna@aeondigital.com.br

&nbsp;

> Centralized governance repository for Go ecosystem architectural blueprints, rigid coding standards, automated local Git Hooks, and Markdown development utilities.


&nbsp;
&nbsp;


________________________________________________________________________________

## 1. PURPOSE & ARCHITECTURAL ECOSYSTEM

This repository serves as the centralized governance hub for architectural blueprints, coding guidelines, development scripts, and automated quality gates across our entire Go software ecosystem.

By maintaining a single source of truth for engineering standards and local automations, we eliminate environment drift across downstream projects, ensuring that every codebase remains highly predictable, well-formatted, and maintainable.


&nbsp;
&nbsp;


________________________________________________________________________________

## 2. REPOSITORY CONTENTS

This repository organizes foundational guidelines and local development automations into clean, specialized directories:

* **`hooks/`:** Local Git Hooks designed to automate code validation before actions are synchronized with the remote server.
  *   `pre-commit`: Runs `gofmt` to check and fix Go formatting in the staged area.
  *   `pre-push`: Forces local documentation and standards synchronization before a push sequence.
* **`standards/`:** Human-readable engineering standards and blueprints.
  *   `00-MD_RULES.md`: Layout and spacing formatting rules for Markdown files.
  *   `01-ARCHITECTURE.md`: Structural design principles separating `/internal` from `/pkg`.
  *   `02-CODING_STANDARDS.md`: Rigid Go writing guidelines and testing boundary specifications.
* **`scripts/`:** Global utility automation engines.
  *   `createpkg.sh`: Generates and injects structural core blueprints into public or private scopes.
  *   `md_normalize.sh`: Automated linter designed to enforce layout rules onto text files.


&nbsp;
&nbsp;


________________________________________________________________________________

## 3. INTEGRATION AND INSTALLATION

To preserve local disk file presence for local LLMs and AI extensions (e.g., Cursor, Cline) while keeping central governance, this repository must be mounted as a native Git Submodule inside downstream consuming applications.


&nbsp;


### 3.1 Initial Submodule Setup

Run the following command at the root level of your downstream application to mount this development hub directly into an isolated, technical folder named `.dev/`:

```bash
git submodule add https://github.com/AeonDigital/Go-Core-Template-Dev.git .dev
```


&nbsp;


### 3.2 Cloning an Existing Project

If you are cloning a downstream repository that already has this submodule configured, the `.dev/` folder will appear empty by default. 
Run the following command to initialize and download the development files:

```bash
git submodule update --init --recursive
```


&nbsp;


### 3.3 Expected Directory Layout

Once mounted, your downstream application directory tree will instantly mirror this physical configuration:

```text
mainrepo/
└── downstream-app/
    ├── .dev/                       # Mounted Git Submodule Root
    │   ├── hooks/
    │   │   ├── pre-commit
    │   │   └── pre-push
    │   │
    │   ├── linters/
    │   │   └── golinter.yaml
    │   │
    │   ├── scripts/
    │   │   ├── createpkg.sh
    │   │   └── md_normalize.sh
    │   │
    │   ├── standards/
    │   │   ├── 00-MD_RULES.md
    │   │   ├── 01-ARCHITECTURE.md
    │   │   └── 02-CODING_STANDARDS.md
    │   │
    │   └── templatepkgs/
    │       ├── config.tmpl
    │       ├── constants.tmpl
    │       ├── functions.tmpl
    │       ├── interfaces.tmpl
    │       ├── structs.tmpl
    │       └── xerrors.tmpl
    │
    ├── internal/
    ├── pkg/
    └── go.mod
```


&nbsp;
&nbsp;


________________________________________________________________________________

## 4. ACTIVATING AUTOMATED GATES

To enforce ecosystem standards locally without manual script duplication, developers must redirect their local Git Hook execution path to the centralized scripts directory immediately after the submodule initialization.


&nbsp;


### 4.1 Core Hooks Activation

Execute the following native Git configuration command at the root level of the downstream repository:

```bash
git config core.hooksPath .dev/hooks
```

Once executed, local commands like `git commit` and `git push` will seamlessly trigger the centralized governance validation scripts.


&nbsp;
&nbsp;


________________________________________________________________________________

## 5. SYNCHRONIZATION AND LIFE CYCLE

The development hub is updated upstream whenever ecosystem guidelines or automations evolve. Downstream applications are responsible for pulling adjustments on demand.


&nbsp;


### 5.1 How to Pull Upstream Updates

To synchronize and merge the latest global engineering adjustments directly into your local workspace folder, execute:

```bash
git submodule update --remote --merge .dev

#
# If Fails... use brute force with the code below 
cd .dev; git fetch origin --prune; git reset --hard origin/main; cd ..;
```


&nbsp;


### 5.2 Local Documentation Normalization

To format and normalize any local Markdown documentation before submitting code changes, utilize the embedded automation script:

```bash
./.dev/scripts/md_normalize.sh path/to/your/file.md
```


&nbsp;


### 5.3 Instantiating Architecture Blueprints

To dynamically inject any of the foundational architectural packages into your workspace, utilize the centralized creation script. 
The script automatically discovers your project root containing the `go.mod` file, establishes structural constraints, and prevents package naming collisions.

&nbsp;

#### 5.3.1 Discovering Available Blueprints

The script scans your environment dynamically to list which architectural components are ready for usage. 
To trigger the interface helper and print the available blueprints, run:

```bash
./.dev/scripts/createpkg.sh help
```

&nbsp;

#### 5.3.2 Injecting into Private Scope (internal)

To generate a private, unexportable architectural core module:

```bash
./.dev/scripts/createpkg.sh <template_name> internal <pkg_prefix>
```

*Example:*
```bash
./.dev/scripts/createpkg.sh xerrors internal billing
```
This climbs your repository tree, creates `internal/xerrors/xerrors.go` mapping `package xerrors` at the header line, and safely expands all inner context tokens to `billing` and `BILLING`.

&nbsp;

#### 5.3.3 Injecting into Public Scope (pkg)

To generate an exportable, context-prefixed public package contract gateway:

```bash
./.dev/scripts/createpkg.sh <template_name> pkg <pkg_prefix>
```

*Example:*
```bash
./.dev/scripts/createpkg.sh xerrors pkg billing
```
This builds the symmetric path `pkg/billing/billingxerrors/xerrors.go`, enforcing `package billingxerrors` to completely guarantee zero global package descriptor collisions within downstream monorepos.

# Quarkus Insights #330 — Demos

Every demo uses the same app, `spring-boot-todo-app` (Spring MVC + Thymeleaf + Spring
Data JPA + MySQL). All paths assume `<repo_cloned>/scripts/setup.sh` has run as documented hereafter.

## Prerequisites

- Java **>=21**
- Maven **>= 3.9.x**
- jbang - **https://www.jbang.dev/**
- Quarkus Insights project **cloned** (not downloaded as a ZIP !)

```bash
git clone https://github.com/snowdrop/quarkus-insights-330.git
cd quarkus-insights-330
```

> **Note**: Set the environment variables in every terminal tab required for the demo using the script:
> `<repo_cloned>/scripts/setenv.sh`

> **Warning**: Don't forget too to set your AI LLM/Provider API Key before running `acp run` or the coding agent.
> By example: `export ANTHROPIC_API_KEY=<your key>` (plus the base URL if your provider needs one). Never commit it.

Create the different projects, install mcp, acp tools using this script

```bash
<repo_cloned>/scripts/setup.sh
```

## Demo instructions

### Analyze and transform using mtool

Description: During this demo you will use the `mtool` CLI to analyze an application to be migrated, generate a migration plan (= JSON report file) based on rules conditions evaluated against the application and execute the migration using openrewrite recipes defined as instructions part of the rules

Project: `$DEMO_DIR/mtool`

Instructions

- Before to analyze the application, verify that it works
```bash
# TERMINAL 1
cd $DEMO_DIR/mtool/spring-boot-todo-app

podman machine start # use docker alternatively !

podman rm mysql_todo_db --force
podman run --detach \
        --name mysql_todo_db \
        --publish 3306:3306 \
        --env MYSQL_ROOT_PASSWORD=root \
        --env MYSQL_DATABASE=todo \
        mysql:9.5

mvn spring-boot:run
```
- Open the application in your browser using: `http://localhost:8081` and create some tasks
- Stop the Spring Boot application: `ctrl-c`

- We will now use `mtool`
- Within the same terminal, go back to: `cd $DEMO_DIR/mtool`
- Execute the following commands to familiarize yourself with the tool, rule definition

| # | Command | Comment |
|---|---------|-----|
| 1 | `mtool --version` | Must display the version of the cli: 1.0.6. |
| 2 | `less ./cookbook/rules/quarkus-spring/020-springboot-to-quarkus-rest-annotations.yaml` | A rule contains metadata, ID, `when/condition` which are queries like `java.annotation is '…'` parsed by ANTLR). The `instructions` belongs to different providers: `openrewrite`, `manual`, `ai` that the tool can use during the transformation/migration step |
| 3 | `ls ./cookbook/rules/quarkus-spring` | Rules are grouped and ordered: BOM, dependencies, annotations, properties, tests. |
| 4 | `less ./cookbook/rules/quarkus-spring-precondition/010-springboot-replace-bom-quarkus.yaml` | A precondition rule allows to check if an application matches some criteria before to be migrated. |
| 5 | `mtool analyze ./spring-boot-todo-app -r ./cookbook/rules/quarkus-spring-precondition` | Precondition check before any change. See the `ERROR` message |

- To analyze an application and generate the JSON report / migration plan, run the following commands:

| 1 | `mtool analyze ./spring-boot-todo-app -r ./cookbook/rules/quarkus-spring --scanner openrewrite` | Each rule is matched against the code, with the file and line. Scanners: openrewrite (default), TreeSitter4J - https://github.com/roastedroot/treesitter4j, maven. |
| 2 | `mtool analyze ./spring-boot-todo-app -r ./cookbook/rules/quarkus-spring -o html` | Same analysis generating an HTML report.  open the `analysing-openrewrite-report_*.html` file showed on the terminal next to the text: `HTML Report file exported to: file:///`. |
| 3 | `ls ./spring-boot-todo-app/analysing-openrewrite-report_*.json` and `jq . ./spring-boot-todo-app/analysing-openrewrite-report_*.json | less` | The JSON report is the input of `transform` and contains the instructions to perform the migration. |

- And finally migrate the spring boot application using as commands

| 1 | `mtool transform ./spring-boot-todo-app -p openrewrite --dry-run` | Nothing is written: OpenRewrite produces a patch. |
| 2 | `less ./spring-boot-todo-app/target/rewrite/rewrite.patch` | Walk through the diff: BOM, dependencies, annotations, properties created from the execution of the openrewrite recipes. |
| 3 | `mtool transform ./spring-boot-todo-app` | Writes the changes to the project. |

**Key point:** rules are deterministic, reproducible and auditable, but you need a rule for every pattern.

- Launch the migrated app:

```bash
cd spring-boot-todo-app
mvn quarkus:dev
```
- Open the quarkus application in your browser, create tasks, etc: `http://localhost:8080`
> **WARNING**: As you will discover you cannot create Tasks as openrewrite don't provide recipes able to migrate Thymeleaf to Quarkus Qute except to replace the dependency !!

- Uou can nevertheless do some curl requests to access the REST endpoints
```bash
# TERMINAL 2
curl http://127.0.0.1:8080/home
curl -X POST http://localhost:8080/home \
  -H "Content-Type: application/json" \
  -d '{"title": "Prepare migration to Quarkus. Task 1", "description": "Migrating Spring Boot TO DO to Quarkus. Task 1", "dueDate": "2025-12-24"}'
curl -X POST http://localhost:8080/home \
  -H "Content-Type: application/json" \
  -d '{"title": "Prepare migration to Quarkus. Task 2", "description": "Migrating Spring Boot TO DO to Quarkus. Task 2", "dueDate": "2025-12-24"}'
```
---

## TODO: the agent calling quarkit (Aurea)

Project: `$DEMO_DIR/spring-boot-todo-app` (the Spring todo app; `scripts/setup.sh` installed the skill in
`.claude/skills/` and wrote `.quarkus-migration.yml` with `strategy: full-quarkus`).

The skill never modifies its source: `spring-boot-todo-app-live/` is only read (the skill may write
extraction data to `migration-metadata/` there; in our runs it went to the target) and the migrated
project goes to the sibling **`$DEMO_DIR/spring-boot-todo-app-quarkus/`** (default target
`<source-name>-quarkus/`, see `modules/planning/planning.md`). The `-live` suffix keeps it apart
from `spring-boot-todo-app-quarkus/`, the pre-migrated app of blocks c and e.

The rehearsal run took **about 5 minutes** (2026-11-20). Proposal: kick it off at the start of the
"Anatomy of the skill" segment and come back to it when the persistence module has run and
the `quarkit_validate` call is visible.

### Option 1: Claude Code with `--mcp-config`

**Terminal tab: agent**

```bash
cd $DEMO_DIR/spring-boot-todo-app
claude --mcp-config ../mcp-config.json --permission-mode auto \
  "Migrate this Spring Boot project to Quarkus"
```

`--permission-mode auto` lets the agent run its `./mvnw`, `java` and file commands without asking,
while still stopping risky actions. `acceptEdits` only covers file edits, so every Bash command
would ask for approval on screen.

`scripts/mcp-config.json` points the agent at the server already running in the **mcp** tab
(`http://localhost:8080/mcp`), under the name `mtools` that the skill expects.

| # | Say |
|---|-----|
| 1 | One prompt. The skill brings the plan; the strategy comes from `.quarkus-migration.yml`. |
| 2 | Point out `/mcp` (or the startup line): the `mtools` server is connected. |
| 3 | While it runs: open `SKILL.md`, the gate table, the modules loaded on demand, `compile-fix.md`, `references/mtools-mcp.md`. |
| 4 | When persistence is done: find the `quarkit_validate` call in the agent output (`Called mtools`). |

> If the `migrate-spring-to-quarkus` skill is also installed globally (`~/.claude/skills`), that copy
> wins over the project one: check with `/skills` that only one shows up.

### Option 2: ACP client

```bash
acp run -a claude-acp --backup no \
  --wks $DEMO_DIR/quarkit/spring-boot-todo-app \
  -s $SKILL_DIR/quarkus-skills/skills \
  --mcp-server quarkit-http \
  -p "Migrate this Spring Boot project to Quarkus"
```

> ⚠️ Not rehearsed. Flags from `acp run --help` at the time of mtool 2.0.3, and the
> `--mcp-server-config` still uses the old 2.0.3 stdio runner. With the server now registered in acp
> as `quarkit-http`, check with Charles whether `acp run` can reuse it.

**Reset to run it again:**
```bash
rm -rf $DEMO_DIR/spring-boot-todo-app-quarkus $DEMO_DIR/spring-boot-todo-app/migration-metadata
```

---

## e — The todo app on Quarkus (Aurea)

Project: `$DEMO_DIR/spring-boot-todo-app-quarkus` (Spring Boot 3.5.3 → Quarkus 3.40.1.2, full-quarkus),
copied by `scripts/setup.sh` from [fallback/spring-boot-todo-app-quarkus](fallback/spring-boot-todo-app-quarkus/).

It is the agent's output as-is. The only change after the migration is demo seed data
(`import.sql`, loaded in dev mode only), so the app doesn't start empty.

**Terminal tab: quarkit** (`cd $DEMO_DIR`)

| # | Command | Say |
|---|---------|-----|
| 1 | `less spring-boot-todo-app-quarkus/migration-summary.md` | The summary tells you what migrated, what didn't, and why: every applicable module done, messaging skipped, 6/6 verification checks, and the remaining work (point `%prod` at the real MySQL, the unused `jjwt` dependency). |
| 2 | `ls spring-boot-todo-app-quarkus/migration-reports/` | The JSON reports: validation (mtools project-setup and persistence) and reporting. |
| 3 | `(cd spring-boot-todo-app-quarkus && ./mvnw clean test)` | 3 `@QuarkusTest` tests, MySQL started by Dev Services. |
| 4 | `(cd spring-boot-todo-app-quarkus && ./mvnw quarkus:dev -Dquarkus.http.port=8090)` | Open http://localhost:8080: list, add and delete tasks, pagination. |
| 5 | Show `templates/TaskResource/home.html` next to the original Thymeleaf `templates/home.html` | Type-safe Qute templates (`@CheckedTemplate`), checked at build time. |

`-Dquarkus.http.port=8090` because the MCP server holds 8080 (the app's own port is 8081).

**Key point:** about 5 minutes, one prompt, validated at each gate. Not a magic button: the summary
lists the remaining work.

**Plan B:** the same project in this repo, [fallback/spring-boot-todo-app-quarkus](fallback/spring-boot-todo-app-quarkus/),
and the session log [fallback/agent-log.md](fallback/agent-log.md).

---

## b — quarkit MCP server with acp (Charles)

The server runs in the **mcp** tab, registered in acp as `quarkit-http`. `acp mcp` speaks the same
stateless MCP protocol (2026-07-28) the agent uses; add `-v` to any command to show the JSON-RPC
request and response.

**Terminal tab: quarkit** (`cd $DEMO_DIR`), ACP basics first:

```bash
acp registry list            # installed agents
acp registry list -r         # remote ACP registry
acp registry install bob --force
acp run -a claude-acp -p "Say hello in French, Spanish"   # needs the AI API key
```

Project: https://github.com/smallrye/smallrye-acp-client

**Terminal tab: quarkit** (`cd $DEMO_DIR`)

| # | Command | Say |
|---|---------|-----|
| 1 | `acp mcp tools quarkit-http` | Four tools: analyze, validate, references list and lookup. This is what the agent sees. `--schema` adds their parameters. |
| 2 | `acp mcp call quarkit-http quarkit_analyze -p "query=pom dependency all" -p project_path=$DEMO_DIR/quarkit/spring-boot-todo-app` | Deterministic inventory of the Spring app. No LLM involved. |
| 3 | `acp mcp call quarkit-http quarkit_analyze -p "query=java annotation all" -p project_path=$DEMO_DIR/quarkit/spring-boot-todo-app` | Every annotation, per file: `@Controller`, `@Service`, `@Entity`… The app is small, so the list fits on screen. |
| 4 | `acp mcp call quarkit-http quarkit_references_list` | Three maps: annotation, config, dependency, with their sections. |
| 5 | `acp mcp call quarkit-http quarkit_reference_lookup -p map=annotation -p key=@Transactional -p mode=compat` | The agent looks up the mapping instead of guessing it. |
| 6 | `acp mcp call quarkit-http quarkit_reference_lookup '{"map":"annotation","key":"@Transactional","mode":"compat"}'` | Same lookup with a JSON argument instead of `-p`. |

Other lookups that read well live:
```bash
acp mcp call quarkit-http quarkit_reference_lookup -p map=annotation -p "section=Dependency Injection" -p mode=compat
acp mcp call quarkit-http quarkit_reference_lookup -p map=config -p key=spring.datasource.url
```

Tool and parameter names checked in the quarkit `2.0.3` source (`AnalyzeTools`, `ReferenceTools`),
`-p name=value` in `acp mcp call --help`. ⚠️ Not run yet: rehearse them.

**Plan B:** `-v` on the same commands, or the server's log in the **mcp** tab.

---

## c — Break a migrated entity (Charles)

Project: `$DEMO_DIR/spring-boot-todo-app-quarkus` (already migrated), compared with
`$DEMO_DIR/spring-boot-todo-app` (the Spring original).

The break: `Task.id` goes from `GenerationType.AUTO` to `GenerationType.IDENTITY`, the kind of
"simplification" an agent makes for MySQL. It compiles and the tests should still pass (Dev
Services creates a fresh schema), but it no longer matches the existing database: Spring used
`AUTO`, which on MySQL means a sequence table, and the migrated code even says so in the comment
right above. Tests don't catch it; the validator does.

**Terminal tab: quarkit** (`cd $DEMO_DIR`)

| # | Command | Say |
|---|---------|-----|
| 1 | `acp mcp call quarkit-http quarkit_validate -p target=$DEMO_DIR/quarkit/spring-boot-todo-app-quarkus -p source=$DEMO_DIR/quarkit/spring-boot-todo-app -p validator=persistence -p skipCompile=true` | Baseline: all PASS. Entities, tables, fields, ID strategy compared with the Spring source. |
| 2 | `cd spring-boot-todo-app-quarkus && sed -i '' 's/GenerationType\.AUTO/GenerationType.IDENTITY/g' src/main/java/com/todo/app/entity/Task.java )` | Show the one-line diff in the editor. Or edit `Task.java` with `vim` (as in cmds.md): `GenerationType.AUTO` → `GenerationType.IDENTITY`. |
| 3 | (optional, if time) `(cd spring-boot-todo-app-quarkus && ./mvnw -q compile)` | It compiles. |
| 4 | Same command as #1 | One FAIL: `ID generation strategy matches` → `ID strategy changed: AUTO -> IDENTITY`. |
| 5 | `(cd spring-boot-todo-app-quarkus && git apply -R ../break-entity.patch)` | Back to green. |

`skipCompile=true` keeps the call at a few seconds; without it the validator runs `mvn compile` too.
`spring-boot-todo-app-quarkus/` is not a git repo, but `git apply` also works on plain folders.

> ⚠️ To rehearse. The patch applies and reverts cleanly (checked on a copy). The expected FAIL comes
> from the validator source (`PersistenceValidator`, "ID generation strategy matches"); the baseline,
> the FAIL and the tests after the break have not been run yet.

**Key point:** the agent writes the code, the deterministic tool checks it. Green tests are not the
same as a correct migration.

**Plan B:** to capture after the rehearsal: the baseline and the FAIL output, in [fallback/](fallback/).

# Plan B outputs

Saved outputs to show if a live command fails.

| File | Block | What it is |
|------|-------|------------|
| [todo-app-rewrite.patch](scripts/todo-app-rewrite.patch) | a | `mtool transform . -p openrewrite --dry-run` on `spring-boot-todo-app` (`target/rewrite/rewrite.patch`), mtool 2.0.2, 2026-11-16 |
| [spring-boot-todo-app-quarkus/](spring-boot-todo-app-quarkus/) | c, d, e | Full agent migration of `spring-boot-todo-app` (2026-11-20, ~5 min, skill from quarkusio/skills `4e7fa56`). Agent output as-is, plus demo seed data (`import.sql` and `%dev` drop-and-create). Includes `migration-summary.md`, `migration-reports/` and `migration-metadata/`; `target/` excluded. `scripts/setup.sh` copies it to `qi330-demo/` for blocks c and e |
| [agent-log.md](agent-log.md) | d | The Claude Code session of that run (`/export`). The `mtools` persistence validation is at line ~357 (8/8 PASS) |

TODO before the episode:
- [ ] the `mtool analyze` JSON report for the todo app (regenerate on the demo machine, it contains absolute paths)
- [x] the agent session log showing the `quarkit_validate` call (block d): [agent-log.md](agent-log.md). Tool calls are collapsed in the export (`Called mtools`), the result is in the agent's text
- [ ] block c: the `quarkit_validate persistence` output before and after `scripts/break-entity.patch`

## Running the todo app backup

The app uses MySQL through Dev Services, so Podman or Docker must be running. Use port 8090, because
the MCP server holds 8080:

```bash
cd demo/fallback/spring-boot-todo-app-quarkus
./mvnw quarkus:dev -Dquarkus.http.port=8090
```

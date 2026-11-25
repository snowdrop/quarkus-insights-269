# Quarkus Insights #330 — Demos

Every demo uses the same app, `spring-boot-todo-app` (Spring MVC + Thymeleaf + Spring
Data JPA + MySQL). All paths assume `scripts/setup.sh` has run and `export DEMO=<path to qi330-demo>` as documented hereafter.

## Prerequisites

- Java **>=21**
- Maven **>= 3.9.x**
- jbang - **https://www.jbang.dev/**
- Quarkus Insights project **cloned** (not downloaded as a ZIP !)

```bash
git clone https://github.com/snowdrop/quarkus-insights-330.git
```

Run the exports in every terminal tab:

```bash
# Set INSIGHTS_DIR to the folder where you git cloned this repository (quarkus-insights-330)
export INSIGHTS_DIR=/path/to/quarkus-insights-330
export DEMO_DIR=$(dirname "$INSIGHTS_DIR")/qi330-demo
export QUARKIT_ALLOWED_DIRS=$DEMO_DIR//demo/fallback
export SKILL_DIR=$DEMO_DIR/quarkus-skills/
export ANALYZER_RULES_REPO_URL="https://github.com/snowdrop/migration-tool/blob/main/cookbook/rules/quarkus-spring/%s.yaml"
```

> ⚠️ **You must set your AI API key** before running `acp run` or the coding agent, for example
> `export ANTHROPIC_API_KEY=<your key>` (plus the base URL if your provider needs one). Never commit it.

Create the different projects, install mcp, acp tools using the following `scripts/setup.sh` script:

```bash
$INSIGHTS_DIR/demo/setup.sh
```

## Run of show

| Who | Segment | What we show | On screen | Demo |
|---|---|---|---|---|
| Both | The problem | Migrating is not swapping annotations: build, config, DI, persistence, views, tests | 5 Slides Migration is hard! | — |
| Charles | mtool CLI | `mtool analyze` with YAML rules, the query language (ANTLR), scanners (treesitter / openrewrite / maven), the JSON report, `mtool transform --dry-run` on `spring-boot-todo-app` | Terminal + Demo A | [a](#a--mtool-analyze--transform-charles) |
| Aurea | From rules to skills | Rules are reliable but can't cover every Spring pattern; AI covers more but improvises. So AI does the work and deterministic tools check it | Slides high-level: agent ↔ skill ↔ quarkit MCP diagram | — |
| Aurea | Anatomy of the skill | `SKILL.md` critical rules, the decision gate table, modules loaded on demand, the `compile-fix` loop, the reporting module. The agent migrates the todo app live in the background, tool calls visible | Editor + agent tab | [d](#d--the-agent-calling-quarkit-aurea) |
| Aurea | The result | Full Spring Todo App migration (pre-run, ~5 min): 3 tests, Thymeleaf → Qute, `migration-summary.md`, app running | Terminal + browser/fallback if nobody speaks | [e](#e--the-todo-app-on-quarkus-aurea) |
| Charles | quarkit MCP live | `acp mcp tools`, `quarkit_analyze` on the todo app, `quarkit_reference_lookup`. Then break the migrated `Task` entity (`GenerationType.AUTO` → `IDENTITY`: it compiles, tests still pass) and show `quarkit_validate persistence` failing | Terminal - Demo on the fallback premigrated spring-todo-app | [b](#b--quarkit-mcp-server-with-acp-charles), [c](#c--break-a-migrated-entity-charles) |
| Both | What's next + contribute | Roadmap, how to add a validator, a rule or a reference map; issue links | Slide 3: links + QR | — |
| Both + hosts | Q&A | Questions from chat | — | — |

## Prep and fallbacks

The full todo app migration took about 5 minutes in rehearsal, so it can run live during the skill
segment; the pre-run result in [fallback/](fallback/) covers us if it fails. Each demo block below
has its own **Plan B** with the exact files.

| Demo | Owner | Before going live | Plan B |
|---|---|---|---|
| [a](#a--mtool-analyze--transform-charles) mtool analyze / transform | Charles | `scripts/setup.sh` installs mtool 1.0.6 with jbang and clones `spring-boot-todo-app` on a clean `demo` branch | Recorded terminal output or a pre-generated JSON report |
| [d](#d--the-agent-calling-quarkit-aurea) Agent calling quarkit | Aurea | Agent configured with the quarkit MCP server (`--mcp-config` or ACP), so tool calls are visible | Show the tool calls from the pre-run session log |
| [e](#e--the-todo-app-on-quarkus-aurea) Todo app result | Aurea | Pre-migrated project built, Podman/Docker running (Dev Services MySQL), port 8090 free | `fallback/` project and `agent-log.md` |
| [b](#b--quarkit-mcp-server-with-acp-charles) quarkit MCP (acp) | Charles | MCP server running on `localhost:8080/mcp` (`acp mcp serve quarkit-http`), `acp mcp call` commands rehearsed | `-v` output or the server log |
| [c](#c--break-a-migrated-entity-charles) Broken entity → validator FAIL | Charles | Rehearse `scripts/break-entity.patch` (`Task.id` `AUTO` → `IDENTITY`, one FAIL) and the reset with `git apply -R` | Show the saved validator output in `fallback/` |

## Folders in `$DEMO`

| Folder | What it is | Used in |
|---|---|---|
| `mtool-1.x/` | quarkit repo at `1.0.6`: rules (`cookbook/`) and `applications/spring-boot-todo-app` | a |
| `quarkit/` | quarkit repo at `2.0.3`, where `scripts/setup.sh` takes the todo app from | — |
| `quarkus-skills/` | the skill, opened in the editor | d |
| `spring-boot-todo-app-live/` | the Spring todo app, never modified, skill installed | b, c (validator `source`), d |
| `spring-boot-todo-app-live-quarkus/` | created by the agent during the live run | d |
| `spring-boot-todo-app-quarkus/` | the pre-migrated todo app, copied from [fallback/](fallback/spring-boot-todo-app-quarkus/) | c, e |

## Before going live

- [ ] `demo/setup.sh` ran on the demo machine (mtool **1.0.6** and acp installed via jbang, catalog trusted)
- [ ] Podman or Docker running (Dev Services MySQL for block e), and the `mysql_todo_db` container started
- [ ] AI API key exported in the tabs that run the agent (see Environment)
- [ ] Terminal tabs open: **mcp** (server), **todo**, **quarkit**, **agent**
- [ ] quarkit MCP server running in the **mcp** tab (commands below), `acp mcp tools quarkit-http` lists 4 tools
- [ ] `spring-boot-todo-app` clean: `git -C $DEMO/mtool-1.x status` shows nothing
- [ ] `spring-boot-todo-app-live-quarkus/` does not exist (reset of block d)
- [ ] `Task.java` in `spring-boot-todo-app-quarkus` says `GenerationType.AUTO` (reset of block c)
- [ ] Port 8090 free for the todo app (8080 is taken by the MCP server)
- [ ] Editor open on `$DEMO/quarkus-skills/skills/migrate-spring-to-quarkus` (block d)
- [ ] Font size up, `clear` in every tab

**Terminal tab: mcp** (start it before the episode and leave it running; same commands `scripts/setup.sh` prints)

```bash
cd $DEMO
acp mcp add -f -t http quarkit-http http://localhost:8080/mcp -- \
  jbang --deps dev.snowdrop.mtool:references:2.0.3 mcp-http@snowdrop/quarkit

acp mcp serve -e QUARKIT_ALLOWED_DIRS=$DEMO quarkit-http
```

`--deps …references…` loads the reference maps used by `quarkit_reference_lookup`.
`QUARKIT_ALLOWED_DIRS` limits the folders the tools can read: everything the demos use is under `$DEMO`.

---

## a — `mtool` analyze / transform (Charles)

Project: `$DEMO/mtool-1.x/applications/spring-boot-todo-app`, on the `demo` branch.

> ⚠️ These commands were checked with mtool 2.0.3. `scripts/setup.sh` now installs **1.0.6**: rehearse them
> with that version.

**Terminal tab: todo** (the original Spring app; stop it with Ctrl-C before the Quarkus run)

```bash
cd $DEMO/mtool-1.x/applications/spring-boot-todo-app

podman machine start

podman rm mysql_todo_db --force
podman run --detach \
        --name mysql_todo_db \
        --publish 3306:3306 \
        --env MYSQL_ROOT_PASSWORD=root \
        --env MYSQL_DATABASE=todo \
        mysql:9.5
        

mvn spring-boot:run
# http://localhost:8081 in the browser
# less pom.xml
```

**Terminal tab: quarkit** (`cd $DEMO/mtool-1.x/applications/spring-boot-todo-app`; the cookbook is in `$DEMO/mtool-1.x/cookbook`)

| # | Command | Say |
|---|---------|-----|
| 1 | `mtool --version` | Installed with jbang. |
| 2 | `cat ../../cookbook/rules/quarkus-spring/020-springboot-to-quarkus-rest-annotations.yaml` | A rule: `when` is a query (`java.annotation is '…'`, parsed with ANTLR), `instructions` per provider: `openrewrite`, `manual`, `ai`. |
| 3 | `ls ../../cookbook/rules/quarkus-spring` | Rules are ordered: BOM, dependencies, annotations, properties, tests. |
| 4 | `vim ../../cookbook/rules/quarkus-spring-precondition` and `vim ../../cookbook/rules/quarkus-spring` (optional, live) | The precondition rules and the migration rules, in the editor. |
| 5 | `mtool analyze . -r ../../cookbook/rules/quarkus-spring-precondition` | Precondition check before any change. |
| 6 | `mtool analyze . -r ../../cookbook/rules/quarkus-spring --scanner openrewrite` | Each rule is matched against the code, with the file and line. Scanners: openrewrite (default), treesitter, maven. |
| 7 | `mtool analyze . -r ../../cookbook/rules/quarkus-spring -o html` | Same analysis as an HTML report: open the `analysing-openrewrite-report_*.html` file. |
| 8 | `ls analysing-openrewrite-report_*.json` and `jq . analysing-openrewrite-report_*.json \| less` | The JSON report is the input of `transform`. |
| 9 | `mtool transform . -p openrewrite --dry-run` | Nothing is written: OpenRewrite produces a patch. |
| 10 | `less target/rewrite/rewrite.patch` | Walk through the diff: BOM, dependencies, annotations, properties. |
| 11 | `mtool transform . -p openrewrite` | Writes the changes to the project. |

**Key point:** rules are deterministic, reproducible and auditable, but you need a rule for every pattern.

**Terminal tab: todo** (after Ctrl-C on the Spring app), launch the migrated app:

```bash
mvn quarkus:dev -Dquarkus.http.port=8090
# Firefox: http://localhost:8090/q/dev-ui/extensions (no Web UI at the root)
```

`8090` because the MCP server holds 8080. Then exercise the endpoints:

```bash
curl http://127.0.0.1:8090/home
curl -X POST http://localhost:8090/home \
  -H "Content-Type: application/json" \
  -d '{"title": "Prepare migration to Quarkus. Task 1", "description": "Migrating Spring Boot TO DO to Quarkus. Task 1", "dueDate": "2025-12-24"}'
curl -X POST http://localhost:8090/home \
  -H "Content-Type: application/json" \
  -d '{"title": "Prepare migration to Quarkus. Task 2", "description": "Migrating Spring Boot TO DO to Quarkus. Task 2", "dueDate": "2025-12-24"}'
```

**Reset after the block:**
```bash
git -C $DEMO/mtool-1.x checkout -- applications/spring-boot-todo-app
git -C $DEMO/mtool-1.x clean -fdq applications/spring-boot-todo-app
```

**Plan B:** show [fallback/todo-app-rewrite.patch](fallback/todo-app-rewrite.patch).

---

## d — The agent calling quarkit (Aurea)

Project: `$DEMO/spring-boot-todo-app-live` (the Spring todo app; `scripts/setup.sh` installed the skill in
`.claude/skills/` and wrote `.quarkus-migration.yml` with `strategy: full-quarkus`).

The skill never modifies its source: `spring-boot-todo-app-live/` is only read (the skill may write
extraction data to `migration-metadata/` there; in our runs it went to the target) and the migrated
project goes to the sibling **`$DEMO/spring-boot-todo-app-live-quarkus/`** (default target
`<source-name>-quarkus/`, see `modules/planning/planning.md`). The `-live` suffix keeps it apart
from `spring-boot-todo-app-quarkus/`, the pre-migrated app of blocks c and e.

The rehearsal run took **about 5 minutes** (2026-11-20). Proposal: kick it off at the start of the
"Anatomy of the skill" segment and come back to it when the persistence module has run and
the `quarkit_validate` call is visible.

### Option 1: Claude Code with `--mcp-config`

**Terminal tab: agent**

```bash
cd $DEMO/spring-boot-todo-app-live
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
acp run -a claude-acp --backup no --permission-mode allow_always \
  --wks $DEMO/spring-boot-todo-app-live \
  -s $DEMO/quarkus-skills/skills \
  --mcp-server-config '{"type":"stdio","name":"mtools","command":"jbang","args":["-Dquarkit.allowed-dirs='$DEMO'","--deps","dev.snowdrop.mtool:references:2.0.3","dev.snowdrop.mtool:mcp:2.0.3:runner"]}' \
  -p "Migrate this Spring Boot project to Quarkus"
```

> ⚠️ Not rehearsed. Flags from `acp run --help` at the time of mtool 2.0.3, and the
> `--mcp-server-config` still uses the old 2.0.3 stdio runner. With the server now registered in acp
> as `quarkit-http`, check with Charles whether `acp run` can reuse it.

**Reset to run it again:**
```bash
rm -rf $DEMO/spring-boot-todo-app-live-quarkus $DEMO/spring-boot-todo-app-live/migration-metadata
```
(or delete both `spring-boot-todo-app-live*` folders and re-run `scripts/setup.sh`, which recreates the copy).

**Plan B:** [fallback/agent-log.md](fallback/agent-log.md), the session of the rehearsal run
(persistence validation around line 357, 8/8 PASS).

---

## e — The todo app on Quarkus (Aurea)

Project: `$DEMO/spring-boot-todo-app-quarkus` (Spring Boot 3.5.3 → Quarkus 3.40.1.2, full-quarkus),
copied by `scripts/setup.sh` from [fallback/spring-boot-todo-app-quarkus](fallback/spring-boot-todo-app-quarkus/).

It is the agent's output as-is. The only change after the migration is demo seed data
(`import.sql`, loaded in dev mode only), so the app doesn't start empty.

**Terminal tab: quarkit** (`cd $DEMO`)

| # | Command | Say |
|---|---------|-----|
| 1 | `less spring-boot-todo-app-quarkus/migration-summary.md` | The summary tells you what migrated, what didn't, and why: every applicable module done, messaging skipped, 6/6 verification checks, and the remaining work (point `%prod` at the real MySQL, the unused `jjwt` dependency). |
| 2 | `ls spring-boot-todo-app-quarkus/migration-reports/` | The JSON reports: validation (mtools project-setup and persistence) and reporting. |
| 3 | `(cd spring-boot-todo-app-quarkus && ./mvnw clean test)` | 3 `@QuarkusTest` tests, MySQL started by Dev Services. |
| 4 | `(cd spring-boot-todo-app-quarkus && ./mvnw quarkus:dev -Dquarkus.http.port=8090)` | Open http://localhost:8090: list, add and delete tasks, pagination. |
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

**Terminal tab: quarkit** (`cd $DEMO`), ACP basics first:

```bash
acp registry list            # installed agents
acp registry list -r         # remote ACP registry
acp registry install bob --force
acp run -a claude-acp -p "Say hello in French, Spanish"   # needs the AI API key
```

Project: https://github.com/smallrye/smallrye-acp-client

**Terminal tab: quarkit** (`cd $DEMO`)

| # | Command | Say |
|---|---------|-----|
| 1 | `acp mcp tools quarkit-http` | Four tools: analyze, validate, references list and lookup. This is what the agent sees. `--schema` adds their parameters. |
| 2 | `acp mcp call quarkit-http quarkit_analyze -p "query=pom dependency all" -p project_path=$DEMO/spring-boot-todo-app-live` | Deterministic inventory of the Spring app. No LLM involved. |
| 3 | `acp mcp call quarkit-http quarkit_analyze -p "query=java annotation all" -p project_path=$DEMO/spring-boot-todo-app-live` | Every annotation, per file: `@Controller`, `@Service`, `@Entity`… The app is small, so the list fits on screen. |
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

Project: `$DEMO/spring-boot-todo-app-quarkus` (already migrated), compared with
`$DEMO/spring-boot-todo-app-live` (the Spring original).

The break: `Task.id` goes from `GenerationType.AUTO` to `GenerationType.IDENTITY`, the kind of
"simplification" an agent makes for MySQL. It compiles and the tests should still pass (Dev
Services creates a fresh schema), but it no longer matches the existing database: Spring used
`AUTO`, which on MySQL means a sequence table, and the migrated code even says so in the comment
right above. Tests don't catch it; the validator does.

**Terminal tab: quarkit** (`cd $DEMO`)

| # | Command | Say |
|---|---------|-----|
| 1 | `acp mcp call quarkit-http quarkit_validate -p target=$DEMO/spring-boot-todo-app-quarkus -p source=$DEMO/spring-boot-todo-app-live -p validator=persistence -p skipCompile=true` | Baseline: all PASS. Entities, tables, fields, ID strategy compared with the Spring source. |
| 2 | `(cd spring-boot-todo-app-quarkus && git apply ../break-entity.patch)` | Show the one-line diff in the editor. Or edit `Task.java` with `vim` (as in cmds.md): `GenerationType.AUTO` → `GenerationType.IDENTITY`. |
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

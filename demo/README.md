# Demo cheat sheet

Five demo blocks, following [docs/run-of-show.md](../docs/run-of-show.md) (the source of truth).
All paths assume `setup.sh` has run and `DEMO=<path to qi330-demo>`.

Every demo uses the same app, `spring-boot-todo-app` (Spring MVC + Thymeleaf + Spring Data JPA + MySQL).

| Block | Who | What |
|-------|-----|------|
| [a](#a--mtool-analyze--transform-charles) | Charles | `mtool analyze` / `transform --dry-run` on `spring-boot-todo-app` |
| [d](#d--the-agent-calling-quarkit-aurea) | Aurea | Agent + skill + quarkit MCP, live migration, tool calls visible |
| [e](#e--the-todo-app-on-quarkus-aurea) | Aurea | The pre-migrated todo app running on Quarkus |
| [b](#b--quarkit-mcp-server-with-acp-charles) | Charles | quarkit MCP tools: `quarkit_analyze`, `quarkit_reference_lookup` |
| [c](#c--break-a-migrated-entity-charles) | Charles | Break the migrated `Task` entity, `quarkit_validate persistence` fails |

## Folders in `$DEMO`

| Folder | What it is | Used in |
|---|---|---|
| `mtool-1.x/` | quarkit repo at `1.0.6`: rules (`cookbook/`) and `applications/spring-boot-todo-app` | a |
| `quarkit/` | quarkit repo at `2.0.3`, where `setup.sh` takes the todo app from | — |
| `quarkus-skills/` | the skill, opened in the editor | d |
| `spring-boot-todo-app-live/` | the Spring todo app, never modified, skill installed | b, c (validator `source`), d |
| `spring-boot-todo-app-live-quarkus/` | created by the agent during the live run | d |
| `spring-boot-todo-app-quarkus/` | the pre-migrated todo app, copied from [fallback/](fallback/spring-boot-todo-app-quarkus/) | c, e |

## Before going live

- [ ] `demo/setup.sh` ran on the demo machine (mtool **1.0.6** and acp installed via jbang, catalog trusted)
- [ ] Podman or Docker running (Dev Services MySQL for block e)
- [ ] Terminal tabs open: **mcp** (server), **todo**, **quarkit**, **agent**
- [ ] quarkit MCP server running in the **mcp** tab (commands below), `acp mcp tools quarkit-http` lists 4 tools
- [ ] `spring-boot-todo-app` clean: `git -C $DEMO/mtool-1.x status` shows nothing
- [ ] `spring-boot-todo-app-live-quarkus/` does not exist (reset of block d)
- [ ] `Task.java` in `spring-boot-todo-app-quarkus` says `GenerationType.AUTO` (reset of block c)
- [ ] Port 8090 free for the todo app (8080 is taken by the MCP server)
- [ ] Editor open on `$DEMO/quarkus-skills/skills/migrate-spring-to-quarkus` (block d)
- [ ] Font size up, `clear` in every tab

**Terminal tab: mcp** (start it before the episode and leave it running; same commands `setup.sh` prints)

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

> ⚠️ These commands were checked with mtool 2.0.2. `setup.sh` now installs **1.0.6**: rehearse them
> with that version.

**Terminal tab: todo**

| # | Command | Say |
|---|---------|-----|
| 1 | `mtool --version` | Installed with jbang. |
| 2 | `cat ../../cookbook/rules/quarkus-spring/020-springboot-to-quarkus-rest-annotations.yaml` | A rule: `when` is a query (`java.annotation is '…'`, parsed with ANTLR), `instructions` per provider: `openrewrite`, `manual`, `ai`. |
| 3 | `ls ../../cookbook/rules/quarkus-spring` | Rules are ordered: BOM, dependencies, annotations, properties, tests. |
| 4 | `mtool analyze . -r ../../cookbook/rules/quarkus-spring --scanner openrewrite` | Each rule is matched against the code, with the file and line. Scanners: openrewrite (default), treesitter, maven. |
| 5 | `ls analysing-openrewrite-report_*.json` and `jq . analysing-openrewrite-report_*.json \| less` | The JSON report is the input of `transform`. |
| 6 | `mtool transform . -p openrewrite --dry-run` | Nothing is written: OpenRewrite produces a patch. |
| 7 | `less target/rewrite/rewrite.patch` | Walk through the diff: BOM, dependencies, annotations, properties. |

**Key point:** rules are deterministic, reproducible and auditable, but you need a rule for every pattern.

**Reset after the block:**
```bash
git -C $DEMO/mtool-1.x checkout -- applications/spring-boot-todo-app
git -C $DEMO/mtool-1.x clean -fdq applications/spring-boot-todo-app
```

**Plan B:** show [fallback/todo-app-rewrite.patch](fallback/todo-app-rewrite.patch).

---

## d — The agent calling quarkit (Aurea)

Project: `$DEMO/spring-boot-todo-app-live` (the Spring todo app; `setup.sh` installed the skill in
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

`mcp-config.json` points the agent at the server already running in the **mcp** tab
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
  --mcp-server-config '{"type":"stdio","name":"mtools","command":"jbang","args":["-Dquarkit.allowed-dirs='$DEMO'","--deps","dev.snowdrop.mtool:references:2.0.2","dev.snowdrop.mtool:mcp:2.0.2:runner"]}' \
  -p "Migrate this Spring Boot project to Quarkus"
```

> ⚠️ Not rehearsed. Flags from `acp run --help` at the time of mtool 2.0.2, and the
> `--mcp-server-config` still uses the old 2.0.2 stdio runner. With the server now registered in acp
> as `quarkit-http`, check with Charles whether `acp run` can reuse it.

**Reset to run it again:**
```bash
rm -rf $DEMO/spring-boot-todo-app-live-quarkus $DEMO/spring-boot-todo-app-live/migration-metadata
```
(or delete both `spring-boot-todo-app-live*` folders and re-run `setup.sh`, which recreates the copy).

**Plan B:** [fallback/agent-log.md](fallback/agent-log.md), the session of the rehearsal run
(persistence validation around line 357, 8/8 PASS).

---

## e — The todo app on Quarkus (Aurea)

Project: `$DEMO/spring-boot-todo-app-quarkus` (Spring Boot 3.5.3 → Quarkus 3.40.1.2, full-quarkus),
copied by `setup.sh` from [fallback/spring-boot-todo-app-quarkus](fallback/spring-boot-todo-app-quarkus/).

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

**Terminal tab: quarkit** (`cd $DEMO`)

| # | Command | Say |
|---|---------|-----|
| 1 | `acp mcp tools quarkit-http` | Four tools: analyze, validate, references list and lookup. This is what the agent sees. |
| 2 | `acp mcp call quarkit-http quarkit_analyze -p "query=pom dependency all" -p project_path=$DEMO/spring-boot-todo-app-live` | Deterministic inventory of the Spring app. No LLM involved. |
| 3 | `acp mcp call quarkit-http quarkit_analyze -p "query=java annotation all" -p project_path=$DEMO/spring-boot-todo-app-live` | Every annotation, per file: `@Controller`, `@Service`, `@Entity`… The app is small, so the list fits on screen. |
| 4 | `acp mcp call quarkit-http quarkit_references_list` | Three maps: annotation, config, dependency, with their sections. |
| 5 | `acp mcp call quarkit-http quarkit_reference_lookup -p map=annotation -p key=@Transactional -p mode=compat` | The agent looks up the mapping instead of guessing it. |

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
| 2 | `(cd spring-boot-todo-app-quarkus && git apply ../break-entity.patch)` | Show the one-line diff in the editor. |
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

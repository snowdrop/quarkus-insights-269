# Demo cheat sheet

Five demo blocks, following [docs/run-of-show.md](../docs/run-of-show.md) (the source of truth).
All paths assume `setup.sh` has run and `DEMO=<path to qi330-demo>`.

| Block | Min | Who | What |
|-------|-----|-----|------|
| [a](#a--mtool-analyze--transform-charles) | 3–15 | Charles | `mtool analyze` / `transform --dry-run` on `spring-boot-todo-app` |
| [b](#b--quarkit-mcp-server-with-curl-charles) | 30–34 | Charles | quarkit MCP with curl: `tools/list`, `quarkit_analyze`, `quarkit_reference_lookup` |
| [c](#c--break-a-migrated-entity-charles) | 34–40 | Charles | Break a migrated PetClinic entity, `quarkit_validate persistence` fails |
| [d](#d--the-agent-calling-quarkit-aurea) | 18–30 → 40 | Aurea | Agent + skill + quarkit MCP, tool calls visible |
| [e](#e--petclinic-on-quarkus-aurea) | 40–47 | Aurea | The pre-migrated PetClinic |

## Before going live

- [ ] `demo/setup.sh` ran on the demo machine (mtool **2.0.2** installed via jbang, catalog trusted)
- [ ] Terminal tabs open: **mcp** (server), **todo**, **petclinic**, **agent**
- [ ] quarkit MCP server running in the **mcp** tab (command below), `tools/list` returns 4 tools
- [ ] `spring-boot-todo-app` clean: `git -C $DEMO/migration-tool status` shows nothing
- [ ] `spring-petclinic-quarkus` clean: `git -C $DEMO/spring-petclinic-quarkus status` shows nothing
- [ ] Port 8090 free for PetClinic (8080 is taken by the MCP server)
- [ ] Editor open on `$DEMO/quarkus-skills/skills/migrate-spring-to-quarkus` (block d)
- [ ] Font size up, `clear` in every tab

**Terminal tab: mcp** (start it before the episode and leave it running)

```bash
cd $DEMO
jbang -Dquarkit.allowed-dirs=$DEMO \
      --deps dev.snowdrop.mtool:references:2.0.2 \
      dev.snowdrop.mtool:mcp:2.0.2:runner
```

`--deps …references…` loads the reference maps used by `quarkit_reference_lookup`. Traffic logging is
on, so every tool call shows up in this tab: that is what we point at in block d.

---

## a — `mtool` analyze / transform (Charles)

Project: `$DEMO/migration-tool/applications/spring-boot-todo-app`, on the `demo` branch.

**Terminal tab: todo**

| # | Command | Say |
|---|---------|-----|
| 1 | `mtool --version` | `mtool 2.0.2`, installed with jbang. |
| 2 | `cat ../../cookbook/rules/quarkus-spring/020-springboot-to-quarkus-rest-annotations.yaml` | A rule: `when` is a query (`java.annotation is '…'`, parsed with ANTLR), `instructions` per provider: `openrewrite`, `manual`, `ai`. |
| 3 | `ls ../../cookbook/rules/quarkus-spring` | Rules are ordered: BOM, dependencies, annotations, properties, tests. |
| 4 | `mtool analyze . -r ../../cookbook/rules/quarkus-spring --scanner openrewrite` | Each rule is matched against the code, with the file and line. Scanners: openrewrite (default), treesitter, maven. |
| 5 | `ls analysing-openrewrite-report_*.json` and `jq . analysing-openrewrite-report_*.json \| less` | The JSON report is the input of `transform`. |
| 6 | `mtool transform . -p openrewrite --dry-run` | Nothing is written: OpenRewrite produces a patch. |
| 7 | `less target/rewrite/rewrite.patch` | Walk through the diff: BOM, dependencies, annotations, properties. |

**Key point:** rules are deterministic, reproducible and auditable, but you need a rule for every pattern.

**Reset after the block:**
```bash
git -C $DEMO/migration-tool checkout -- applications/spring-boot-todo-app
git -C $DEMO/migration-tool clean -fdq applications/spring-boot-todo-app
```

**Plan B:** show [fallback/todo-app-rewrite.patch](fallback/todo-app-rewrite.patch).

---

## b — quarkit MCP server with curl (Charles)

The server runs in the **mcp** tab. `mcp-call.sh` is a thin wrapper around the curl calls from the
[MCP README](https://github.com/snowdrop/migration-tool/tree/main/mcp#option-1-curl) (stateless MCP:
`MCP-Protocol-Version`, `Mcp-Method`, `Mcp-Name` headers and the `_meta` object).

**Terminal tab: petclinic** (`cd $DEMO`)

| # | Command | Say |
|---|---------|-----|
| 1 | `cat mcp-call.sh` | Plain JSON-RPC over HTTP, nothing hidden. |
| 2 | `./mcp-call.sh tools/list \| jq -r '.result.tools[] \| .name + ": " + .description'` | Four tools: analyze, validate, references list and lookup. This is what the agent sees. |
| 3 | `./mcp-call.sh tools/call quarkit_analyze "{\"query\":\"pom dependency all\",\"project_path\":\"$DEMO/spring-petclinic\"}" \| jq -r '.result.content[0].text'` | Deterministic inventory of PetClinic. No LLM involved. |
| 4 | `./mcp-call.sh tools/call quarkit_references_list \| jq -r '.result.content[0].text'` | Three maps: annotation, config, dependency, with their sections. |
| 5 | `./mcp-call.sh tools/call quarkit_reference_lookup '{"map":"annotation","key":"@Transactional","mode":"compat"}' \| jq -r '.result.content[0].text'` | The agent looks up the mapping instead of guessing it. |

Other lookups that read well live:
```bash
./mcp-call.sh tools/call quarkit_reference_lookup '{"map":"annotation","section":"Dependency Injection","mode":"compat"}' | jq -r '.result.content[0].text'
./mcp-call.sh tools/call quarkit_reference_lookup '{"map":"config","key":"spring.datasource.url"}' | jq -r '.result.content[0].text'
```

Avoid `java annotation all` on PetClinic live: it returns ~300 lines.

**Plan B:** the same calls through the ACP client (block d, option 2), or the server's own log in the **mcp** tab.

---

## c — Break a migrated entity (Charles)

Project: `$DEMO/spring-petclinic-quarkus` (already migrated), compared with `$DEMO/spring-petclinic`.

The break: `Pet.visits` goes from `Set<Visit>` / `LinkedHashSet` to `List<Visit>` / `ArrayList`,
the kind of "simplification" an agent makes. It **compiles and all 82 tests still pass**, but the
collection semantics and the mapping changed. Tests don't catch it; the validator does.

**Terminal tab: petclinic**

| # | Command | Say |
|---|---------|-----|
| 1 | `./mcp-call.sh tools/call quarkit_validate "{\"target\":\"$DEMO/spring-petclinic-quarkus\",\"source\":\"$DEMO/spring-petclinic\",\"validator\":\"persistence\",\"skipCompile\":\"true\"}" \| jq -r '.result.content[0].text'` | Baseline: 31/31 PASS. Entities, tables, fields, ID strategy, relationships compared with the Spring source. |
| 2 | `git -C spring-petclinic-quarkus apply ../break-entity.patch` | Show the 3-line diff in the editor or with `git -C spring-petclinic-quarkus diff`. |
| 3 | (optional, if time) `(cd spring-petclinic-quarkus && ./mvnw -q compile)` | It compiles. |
| 4 | Same command as #1 | `Status: PARTIAL`, two FAILs: `Pet.visits — Type mismatch: Set<Visit> -> List<Visit>` and `Collection type mismatch: Set -> List`. |
| 5 | `git -C spring-petclinic-quarkus checkout -- .` | Back to green. |

**Key point:** the agent writes the code, the deterministic tool checks it. Green tests are not the
same as a correct migration.

`skipCompile: "true"` keeps the call at a few seconds; without it the validator runs `mvn compile` too.

**Plan B:** [fallback/validate-persistence-pass.txt](fallback/validate-persistence-pass.txt) and
[fallback/validate-persistence-fail.txt](fallback/validate-persistence-fail.txt).

---

## d — The agent calling quarkit (Aurea)

Project: `$DEMO/spring-petclinic-live` (a fresh copy of PetClinic; `setup.sh` installed the skill in
`.claude/skills/` and wrote `.quarkus-migration.yml` with `strategy: full-quarkus`).

The skill never modifies its source: `spring-petclinic-live/` is read (only `migration-metadata/` is
written there) and the migrated project goes to the sibling **`$DEMO/spring-petclinic-live-quarkus/`**
(default target `<source-name>-quarkus/`, see `modules/planning/planning.md`). That is why the live run
starts from a copy: started from `spring-petclinic/`, it would write into `spring-petclinic-quarkus/`,
the pre-migrated project used in blocks c and e.

The full migration takes ~19 minutes, so the proposal is to **kick it off at the start of the
"Anatomy of the skill" segment (min 18)** and come back to it around min 40, when the persistence
module has run and the `quarkit_validate` call is visible. To decide with Charles (open question in the run of show).

### Option 1: Claude Code with `--mcp-config`

**Terminal tab: agent**

```bash
cd $DEMO/spring-petclinic-live
claude --mcp-config ../mcp-config.json --permission-mode acceptEdits \
  "Migrate this Spring Boot project to Quarkus"
```

`mcp-config.json` points the agent at the server already running in the **mcp** tab
(`http://localhost:8080/mcp`), under the name `mtools` that the skill expects. Each tool call
appears both in the agent's output and in the **mcp** tab's traffic log.

| # | Say |
|---|-----|
| 1 | One prompt. The skill brings the plan; the strategy comes from `.quarkus-migration.yml`. |
| 2 | Point out `/mcp` (or the startup line): the `mtools` server is connected. |
| 3 | While it runs: open `SKILL.md`, the gate table, the modules loaded on demand, `compile-fix.md`, `references/mtools-mcp.md`. |
| 4 | At min ~40: find the `quarkit_validate` call (persistence) in the agent output and in the **mcp** tab. |

> ⚠️ To verify on the demo machine: Claude Code's HTTP MCP client against the stateless 2026-07-28
> protocol. Fallback: stdio (`"command": "jbang"` with the same args as the **mcp** tab), but then
> stop the server in the **mcp** tab first, because the stdio launch also opens port 8080.
>
> If the `migrate-spring-to-quarkus` skill is also installed globally (`~/.claude/skills`), check
> which version the agent loads.

### Option 2: ACP client

```bash
acp run -a claude-acp --backup no --permission-mode allow_always \
  --wks $DEMO/spring-petclinic-live \
  -s $DEMO/quarkus-skills/skills \
  --mcp-server-config '{"type":"stdio","name":"mtools","command":"jbang","args":["-Dquarkit.allowed-dirs='$DEMO'","--deps","dev.snowdrop.mtool:references:2.0.2","dev.snowdrop.mtool:mcp:2.0.2:runner"]}' \
  -p "Migrate this Spring Boot project to Quarkus"
```

Flags from `acp run --help`; the `--mcp-server-config` shape follows the
[MCP README](https://github.com/snowdrop/migration-tool/tree/main/mcp#tools) examples (stdio, so stop
the **mcp** tab first). ⚠️ To rehearse: the HTTP form of `--mcp-server-config`, which would let us keep
the server in the **mcp** tab.

**Reset to run it again:**
```bash
rm -rf $DEMO/spring-petclinic-live-quarkus $DEMO/spring-petclinic-live/migration-metadata
```
(or delete both `spring-petclinic-live*` folders and re-run `setup.sh`, which recreates the copy).

**Plan B:** show the tool calls from the pre-run session log (to capture, see [fallback/](fallback/)).

---

## e — PetClinic on Quarkus (Aurea)

Project: `$DEMO/spring-petclinic-quarkus` (Spring Boot 4.1.0 → Quarkus 3.40.1.1, full-quarkus).

**Terminal tab: petclinic**

| # | Command | Say |
|---|---------|-----|
| 1 | `less spring-petclinic-quarkus/migration-summary.md` | This is the agent's output as-is, no manual edits. The summary tells you what migrated, what didn't, and why: 9 modules, 6/6 verification checks, and the remaining work (skipped DB container tests, one disabled test, README and `k8s/` still describing Spring). |
| 2 | `ls -lisa spring-petclinic-quarkus/migration-reports/` | One JSON report per module. |
| 3 | `(cd spring-petclinic-quarkus && ./mvnw clean test)` | 82 tests, 0 failures, 5 skipped (4 need a Docker-API runtime for MySQL/Postgres, 1 disabled with a TODO). |
| 4 | `(cd spring-petclinic-quarkus && ./mvnw quarkus:dev -Dquarkus.http.port=8090)` | Open http://localhost:8090: owners, pets, visits, vets, `?lang=es`. |
| 5 | Show one Qute template next to the original Thymeleaf one | 11 templates converted, checked at build time. |

The app uses H2 in memory with Flyway, so no database container is needed to run it.
`-Dquarkus.http.port=8090` because the MCP server holds 8080.

**Key point:** 19 minutes, one prompt, validated at each gate. Not a magic button: the summary lists
the remaining work.

**Plan B:** the video of the full migration (link to add), and the repo
[aureamunoz/spring-petclinic-quarkus](https://github.com/aureamunoz/spring-petclinic-quarkus).

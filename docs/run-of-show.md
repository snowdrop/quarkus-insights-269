# Quarkus Insights #330 — Run of show

Charles Moulliard · Aurea Muñoz · draft 2026-11-16

## Episode description

Proposed update for [quarkus-insights#330](https://github.com/quarkusio/quarkus-insights/issues/330), reflecting what changed since September (mtool 2.0, the quarkit MCP tools, the new skill modules).

**AI-Assisted Migration Tools for Quarkus**

Migrating an application to Quarkus is much more than swapping annotations: build files, dependencies, configuration, persistence, views and tests all need attention. What if AI had superpowers (spoiler: deterministic tools) to handle it?

Charles Moulliard and Aurea Muñoz walk through how this evolved: from `mtool`, a rule-based CLI that analyzes and transforms Spring Boot projects with YAML rules and OpenRewrite, to an open-source agent skill that migrates step by step through gated modules, backed by **quarkit**, a Quarkus MCP server that lets the agent analyze code, look up Spring-to-Quarkus mappings and validate each step instead of improvising.

Mostly live demos: the CLI, the anatomy of the skill, the MCP tools catching a broken migration, and a Spring Boot todo app running on Quarkus. We'll finish with what's next and how you can contribute new validators and mappings.

## Run of show

About 50 minutes of content plus Q&A, three slides in total, everything else live in the terminal or the editor.

| Who | Segment | What we show | On screen |
|---|---|---|---|
| Both | The problem | Migrating is not swapping annotations: build, config, DI, persistence, views, tests | 5 Slides Migration is hard! |
| Charles | mtool CLI | `mtool analyze` with YAML rules, the query language (ANTLR), scanners (treesitter / openrewrite / maven), the JSON report, `mtool transform --dry-run` on `spring-boot-todo-app` | Terminal + Demo A |
| Aurea | From rules to skills | Rules are reliable but can't cover every Spring pattern; AI covers more but improvises. So AI does the work and deterministic tools check it | Slides high-level: agent ↔ skill ↔ quarkit MCP diagram |
| Aurea | Anatomy of the skill | `SKILL.md` critical rules, the decision gate table, modules loaded on demand, the `compile-fix` loop, the reporting module | Editor |
| Aurea | The result | Full Spring Todo App migration (pre-run, ~5 min): 3 tests, Thymeleaf → Qute, `migration-summary.md`, app running | Terminal + browser/fallback if noboday speaks |
| Charles | quarkit MCP live | `acp mcp tools`, `quarkit_analyze` on the todo app, `quarkit_reference_lookup`. Then break the migrated `Task` entity (`GenerationType.AUTO` → `IDENTITY`: it compiles, tests still pass) and show `quarkit_validate persistence` failing | Terminal - Demo on the fallback premigrated spring-todo-app |
| Both | What's next + contribute | Roadmap, how to add a validator, a rule or a reference map; issue links | Slide 3: links + QR |
| Both + hosts | Q&A | Questions from chat | — |

## Demo prep and fallbacks

The full todo app migration took about 5 minutes in rehearsal, so it can run live during the skill segment; the pre-run result in `demo/fallback/` covers us if it fails.

| Demo | Owner | Before going live | Plan B |
|---|---|---|---|
| mtool analyze / transform | Charles | `setup.sh` installs mtool 1.0.6 with jbang and clones `spring-boot-todo-app` on a clean `demo` branch | Recorded terminal output or a pre-generated JSON report |
| quarkit MCP (acp) | Charles | MCP server running on `localhost:8080/mcp` (`acp mcp serve quarkit-http`), `acp mcp call` commands rehearsed | `-v` output or the server log |
| Broken entity → validator FAIL | Charles | Rehearse `demo/break-entity.patch` (`Task.id` `AUTO` → `IDENTITY`, one FAIL) and the reset with `git apply -R` | Show the saved validator output in `demo/fallback/` |
| Agent calling quarkit | Aurea | Agent configured with the quarkit MCP server (`--mcp-config` or ACP), so tool calls are visible | Show the tool calls from the pre-run session log |
| Todo app result | Aurea | Pre-migrated project built, Podman/Docker running (Dev Services MySQL), port 8090 free | `demo/fallback/` project and `agent-log.md` |

## What's next / roadmap

These go on Slide 3 as "what we're working on", not as claims we demo.

- **Measure token cost and time**: run the same migration with and without the quarkit MCP tools and publish the difference. Today the summary says token usage is not available.
- **More validators** beyond `project-setup` and `persistence` (e.g. REST endpoints, templates, tests).
- **Rules as validator config**: reuse the YAML rule / query language to configure validators and define migration plans.
- **Agent-agnostic runs** through ACP, not only Claude.
- **Community contributions**: new reference maps, rules and validators via the two repos.

## Open questions for Charles

- [ ] Which mtool version do we demo: 2.0.2 or today's early-access release?
- [ ] Do you agree with the split (you: CLI + MCP, Aurea: skill + result)?
- [ ] Which agent do we use live: Claude Code or the ACP client?
- [ ] Do we try a live full migration in the background, or only the pre-run?
- [ ] Any roadmap item to add or drop?

## Links

- [snowdrop/quarkit](https://github.com/snowdrop/quarkit)
- [migrate-spring-to-quarkus skill](https://github.com/quarkusio/skills/tree/main/skills/migrate-spring-to-quarkus)
- [spring-boot-todo-app](https://github.com/snowdrop/quarkit/tree/main/applications/spring-boot-todo-app)

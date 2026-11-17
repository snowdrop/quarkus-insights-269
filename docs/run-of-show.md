# Quarkus Insights #330 — Run of show

Charles Moulliard · Aurea Muñoz · draft 2026-11-16

## Episode description

Proposed update for [quarkus-insights#330](https://github.com/quarkusio/quarkus-insights/issues/330), reflecting what changed since September (mtool 2.0, the quarkit MCP tools, the new skill modules).

**AI-Assisted Migration Tools for Quarkus**

Migrating an application to Quarkus is much more than swapping annotations: build files, dependencies, configuration, persistence, views and tests all need attention. What if AI had superpowers (spoiler: deterministic tools) to handle it?

Charles Moulliard and Aurea Muñoz walk through how this evolved: from `mtool`, a rule-based CLI that analyzes and transforms Spring Boot projects with YAML rules and OpenRewrite, to an open-source agent skill that migrates step by step through gated modules, backed by **quarkit**, a Quarkus MCP server that lets the agent analyze code, look up Spring-to-Quarkus mappings and validate each step instead of improvising.

Mostly live demos: the CLI, the anatomy of the skill, the MCP tools catching a broken migration, and Spring PetClinic running on Quarkus. We'll finish with what's next and how you can contribute new validators and mappings.

## Run of show

About 50 minutes of content plus Q&A, three slides in total, everything else live in the terminal or the editor.

| Time (min) | Who | Segment | What we show | On screen |
|---|---|---|---|---|
| 0–3 | Both | The problem | Migrating is not swapping annotations: build, config, DI, persistence, views, tests | Slide 1 |
| 3–15 | Charles | mtool CLI | `mtool analyze` with YAML rules, the query language (ANTLR), scanners (treesitter / openrewrite / maven), the JSON report, `mtool transform --dry-run` on `spring-boot-todo-app` | Terminal + a rule YAML |
| 15–18 | Charles | From rules to skills | Rules are reliable but can't cover every Spring pattern; AI covers more but improvises. So AI does the work and deterministic tools check it | Slide 2: agent ↔ skill ↔ quarkit MCP diagram |
| 18–30 | Aurea | Anatomy of the skill | `SKILL.md` critical rules, the decision gate table, modules loaded on demand, the `compile-fix` loop, the reporting module | Editor |
| 30–40 | Charles | quarkit MCP live | `tools/list` with curl, `quarkit_analyze` on PetClinic, `quarkit_reference_lookup`. Then break a migrated entity (`Pet.visits` from `Set` to `List`: it compiles and the 82 tests still pass) and show `quarkit_validate persistence` failing | Terminal |
| 40–47 | Aurea | The result | Full PetClinic migration (pre-run): 82 tests, Thymeleaf → Qute, `migration-summary.md`, app running | Terminal + browser |
| 47–50 | Both | What's next + contribute | Roadmap, how to add a validator, a rule or a reference map; issue links | Slide 3: links + QR |
| 50–60 | Both + hosts | Q&A | Questions from chat | — |

## Demo prep and fallbacks

The full PetClinic migration takes about 19 minutes, so we show a pre-run result and only kick off a live run if time allows.

| Demo | Owner | Before going live | Plan B |
|---|---|---|---|
| mtool analyze / transform | Charles | Install the version we'll demo (`jbang app install mtool@snowdrop/migration-tool`), pre-clone `spring-boot-todo-app` on a clean git branch | Recorded terminal output or a pre-generated JSON report |
| quarkit MCP (curl) | Charles | MCP server running on `localhost:8080/mcp`, curl commands in a script | Same calls through the ACP client |
| Broken entity → validator FAIL | Charles | Rehearse `demo/break-entity.patch` (`Pet.visits` `Set` → `List`, two FAILs) and the reset with `git checkout -- .` | Show the saved validator output in `demo/fallback/` |
| Agent calling quarkit | Aurea | Agent configured with the quarkit MCP server (`--mcp-config` or ACP), so tool calls are visible | Show the tool calls from the pre-run session log |
| PetClinic result | Aurea | Pre-migrated project built, DB container image pulled, port free | Video of the full migration |

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

- [snowdrop/migration-tool](https://github.com/snowdrop/migration-tool)
- [migrate-spring-to-quarkus skill](https://github.com/quarkusio/skills/tree/main/skills/migrate-spring-to-quarkus)
- [Spring PetClinic](https://github.com/spring-projects/spring-petclinic)

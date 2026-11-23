# AI-Assisted Migration Tools for Quarkus

[Quarkus Insights #330](https://github.com/quarkusio/quarkus-insights/issues/330) — live episode.

Charles Moulliard · Aurea Muñoz

## Abstract

Migrating an application to Quarkus is much more than swapping annotations: build files,
dependencies, configuration, persistence, views and tests all need attention. What if AI had
superpowers (spoiler: deterministic tools) to handle it?

Charles Moulliard and Aurea Muñoz walk through how this evolved: from `mtool`, a rule-based CLI
that analyzes and transforms Spring Boot projects with YAML rules and OpenRewrite, to an
open-source agent skill that migrates step by step through gated modules, backed by **quarkit**,
a Quarkus MCP server that lets the agent analyze code, look up Spring-to-Quarkus mappings and
validate each step instead of improvising.

Mostly live demos: the CLI, the anatomy of the skill, the MCP tools catching a broken migration,
and a Spring Boot todo app running on Quarkus. We'll finish with what's next and how you can contribute
new validators and mappings.

## Contents

| What | Link |
|------|------|
| Run of show: segments, prep and fallbacks, demo blocks command by command | [demo/README.md](demo/README.md) |
| Setup script | [demo/setup.sh](demo/setup.sh) |
| MCP config for the agent | [demo/mcp-config.json](demo/mcp-config.json) |
| The entity we break live | [demo/break-entity.patch](demo/break-entity.patch) |
| The migration prompt | [demo/prompt.md](demo/prompt.md) |
| Saved outputs (plan B) | [demo/fallback/](demo/fallback/) |
| Slides draft (3 slides) | [slides/slides-draft.md](slides/slides-draft.md) |
| Migrated todo app, summary, reports and agent session log | [demo/fallback/spring-boot-todo-app-quarkus](demo/fallback/spring-boot-todo-app-quarkus/) · [agent-log.md](demo/fallback/agent-log.md) |

## What we show

| Who | Segment |
|-----|---------|
| Charles | The problem: Migration is hard |
| Charles | `mtool` CLI: rules, query language, scanners, `analyze` / `transform --dry-run` |
| Aurea | From rules to skills |
| Aurea | Anatomy of the `migrate-spring-to-quarkus` skill |
| Aurea | The result: the todo app on Quarkus |
| Charles | quarkit MCP live: `acp mcp tools`, `quarkit_analyze`, `quarkit_reference_lookup`, a broken entity caught by `quarkit_validate` |
| Both | What's next + contribute |
| Both + hosts | Q&A |

## Tools shown

- [snowdrop/quarkit](https://github.com/snowdrop/quarkit) — `mtool` CLI and the
  [quarkit MCP server](https://github.com/snowdrop/quarkit/tree/main/mcp)
  (`quarkit_analyze`, `quarkit_validate`, `quarkit_references_list`, `quarkit_reference_lookup`)
- [migrate-spring-to-quarkus skill](https://github.com/quarkusio/skills/tree/main/skills/migrate-spring-to-quarkus)
  — `SKILL.md`, gated modules, reference maps, [mtools MCP reference](https://github.com/quarkusio/skills/blob/main/skills/migrate-spring-to-quarkus/references/mtools-mcp.md)
- [spring-boot-todo-app](https://github.com/snowdrop/quarkit/tree/main/applications/spring-boot-todo-app) — the app we migrate
- [smallrye-acp-client](https://github.com/smallrye/smallrye-acp-client) — run the skill with any ACP agent

## What's next

What we are working on. None of this is demoed as a result.

- **Measure token cost and time**: run the same migration with and without the quarkit MCP
  tools and publish the difference. Today the migration summary does not report token usage.
- **More validators** beyond `project-setup` and `persistence` (e.g. REST endpoints, templates, tests).
- **Rules as validator config**: reuse the YAML rules and query language to configure validators
  and define migration plans.
- **Agent-agnostic runs** through ACP, not only Claude.
- **Community contributions**: new reference maps, rules and validators.

## Contribute

- Skill issues: <https://github.com/quarkusio/skills/issues>
- mtool / quarkit issues: <https://github.com/snowdrop/quarkit/issues>

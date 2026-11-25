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

## Presentation

Open the quarkus insight [slides](./slides/reveal/index.html) in a browser.

## How to replay the demos

See demos README [instructions](./demo/README.md)

## Tools shown

- [snowdrop/quarkit](https://github.com/snowdrop/quarkit) — `mtool` CLI and the [quarkit MCP server](https://github.com/snowdrop/quarkit/tree/main/mcp)
  (`quarkit_analyze`, `quarkit_validate`, `quarkit_references_list`, `quarkit_reference_lookup`)
- [migrate-spring-to-quarkus skill](https://github.com/quarkusio/skills/tree/main/skills/migrate-spring-to-quarkus)
  — `SKILL.md`, gated modules, reference maps, [mtools MCP reference](https://github.com/quarkusio/skills/blob/main/skills/migrate-spring-to-quarkus/references/mtools-mcp.md)
- [spring-boot-todo-app](https://github.com/snowdrop/quarkit/tree/main/applications/spring-boot-todo-app) — the app we migrate
- [smallrye-acp-client](https://github.com/smallrye/smallrye-acp-client) — run the skill with any ACP coding agent, manage from the registry the agents, install a MCP Server and query the tools

## Contribute

- Skill issues: <https://github.com/quarkusio/skills/issues>
- mtool / quarkit issues: <https://github.com/snowdrop/quarkit/issues>

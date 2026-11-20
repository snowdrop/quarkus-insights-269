# Plan B outputs

Saved outputs to show if a live command fails.

| File | Block | What it is |
|------|-------|------------|
| [todo-app-rewrite.patch](todo-app-rewrite.patch) | a | `mtool transform . -p openrewrite --dry-run` on `spring-boot-todo-app` (`target/rewrite/rewrite.patch`), mtool 2.0.2, 2026-11-16 |
| [spring-boot-todo-app-quarkus/](spring-boot-todo-app-quarkus/) | c, d, e | Full agent migration of `spring-boot-todo-app` (2026-11-20, ~5 min, skill from quarkusio/skills `4e7fa56`). Agent output as-is, plus demo seed data (`import.sql` and `%dev` drop-and-create). Includes `migration-summary.md`, `migration-reports/` and `migration-metadata/`; `target/` excluded. `setup.sh` copies it to `qi330-demo/` for blocks c and e |
| [agent-log.md](agent-log.md) | d | The Claude Code session of that run (`/export`). The `mtools` persistence validation is at line ~357 (8/8 PASS) |

TODO before the episode:
- [ ] the `mtool analyze` JSON report for the todo app (regenerate on the demo machine, it contains absolute paths)
- [x] the agent session log showing the `quarkit_validate` call (block d): [agent-log.md](agent-log.md). Tool calls are collapsed in the export (`Called mtools`), the result is in the agent's text
- [ ] block c: the `quarkit_validate persistence` output before and after `break-entity.patch`

## Running the todo app backup

The app uses MySQL through Dev Services, so Podman or Docker must be running. Use port 8090, because
the MCP server holds 8080:

```bash
cd demo/fallback/spring-boot-todo-app-quarkus
./mvnw quarkus:dev -Dquarkus.http.port=8090
```

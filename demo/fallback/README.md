# Plan B outputs

Saved outputs to show if a live command fails. Captured with mtool / quarkit **2.0.2** on 2026-11-16.

| File | Block | What it is |
|------|-------|------------|
| [todo-app-rewrite.patch](todo-app-rewrite.patch) | a | `mtool transform . -p openrewrite --dry-run` on `spring-boot-todo-app` (`target/rewrite/rewrite.patch`) |
| [validate-persistence-pass.txt](validate-persistence-pass.txt) | c | `quarkit_validate persistence` on the migrated PetClinic, before breaking it |
| [validate-persistence-fail.txt](validate-persistence-fail.txt) | c | Same call after applying `break-entity.patch` |
| [spring-boot-todo-app-quarkus/](spring-boot-todo-app-quarkus/) | d | Full agent migration of `spring-boot-todo-app` (2026-11-20, skill from quarkusio/skills `4e7fa56`), unedited. Includes `migration-summary.md`, `migration-reports/` and `migration-metadata/`; `target/` excluded |
| [agent-log.md](agent-log.md) | d | The Claude Code session of that run (`/export`). The `mtools` persistence validation is at line ~357 (8/8 PASS) |

TODO before the episode:
- [ ] the `mtool analyze` JSON report for the todo app (regenerate on the demo machine, it contains absolute paths)
- [x] the agent session log showing the `quarkit_validate` call (block d): [agent-log.md](agent-log.md), todo app run. Tool calls are collapsed in the export (`Called mtools`), the result is in the agent's text
- [ ] link to the full migration video (block e)

## Running the todo app backup

The app uses MySQL through Dev Services, so Podman or Docker must be running. Use port 8090, because
the MCP server holds 8080:

```bash
cd demo/fallback/spring-boot-todo-app-quarkus
./mvnw quarkus:dev -Dquarkus.http.port=8090
```

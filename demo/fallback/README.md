# Plan B outputs

Saved outputs to show if a live command fails. Captured with mtool / quarkit **2.0.2** on 2026-11-16.

| File | Block | What it is |
|------|-------|------------|
| [todo-app-rewrite.patch](todo-app-rewrite.patch) | a | `mtool transform . -p openrewrite --dry-run` on `spring-boot-todo-app` (`target/rewrite/rewrite.patch`) |
| [validate-persistence-pass.txt](validate-persistence-pass.txt) | c | `quarkit_validate persistence` on the migrated PetClinic, before breaking it |
| [validate-persistence-fail.txt](validate-persistence-fail.txt) | c | Same call after applying `break-entity.patch` |

TODO before the episode:
- [ ] the `mtool analyze` JSON report for the todo app (regenerate on the demo machine, it contains absolute paths)
- [ ] the agent session log showing the `quarkit_validate` call (block d)
- [ ] link to the full migration video (block e)

# The migration prompt

Run from the root of the Spring todo app copy (`qi330-demo/spring-boot-todo-app-live`).

```
Migrate this Spring Boot project to Quarkus
```

## Pre-configuration

To skip the strategy and version prompts, `setup.sh` drops this `.quarkus-migration.yml` at the
project root (fields documented in the
[skill README](https://github.com/quarkusio/skills/tree/main/skills/migrate-spring-to-quarkus#autonomous-mode)):

```yaml
strategy: full-quarkus
mode: non-interactive
```

Remove `mode: non-interactive` if you want the audience to see the skill ask for the strategy.

## What the skill does with it

1. **prerequisite** — JDK and build tool check
2. **planning** — scans the project, writes `migration-spec.yaml`
3. **build**, **persistence**, **code**, **frontend**, **testing** — each one only if its gate matches
4. **cleanup** and **reporting** — `migration-summary.md` and the module reports
5. After each module, the project is compiled (`compile-fix` loop). After **persistence**, the agent
   calls `quarkit_validate` with `validator: "persistence"`.

# Quarkus Insights #330 — Demos

Every demo uses the same app, `spring-boot-todo-app` (Spring MVC + Thymeleaf + Spring
Data JPA + MySQL). All paths assume `<repo_cloned>/scripts/setup.sh` has run as documented hereafter.

## Prerequisites

- Java **>=21**
- Maven **>= 3.9.x**
- jbang - **https://www.jbang.dev/**
- Quarkus Insights project **cloned** (not downloaded as a ZIP !)

```bash
git clone https://github.com/snowdrop/quarkus-insights-330.git
cd quarkus-insights-330
```

> **Warning**: Don't forget to set your AI LLM/Provider API Key before running `acp run` or the coding agent.
> By example: `export ANTHROPIC_API_KEY=<your key>` (plus the base URL if your provider needs one: `ANTHROPIC_BASE_URL`).

Create the different projects, install mcp, acp tools using this script

```bash
<repo_cloned>/scripts/setup.sh
```

## Demo instructions

**Important**: 

If, the migration fails using `Agent Coding & Quarkit`, look to the folder suffixed with `*-migrated` under: `$DEMO_DIR/quarkit` as it contains the application migrated. You can find the same too for `mtool` !

Set the environment variables in every `TERMINAL` tab required for the demo using the script:
`<repo_cloned>/scripts/setenv.sh`

### Analyze and transform using mtool

**Description** : During this demo you will use the `mtool` CLI to analyze an application to be migrated, generate a migration plan (= JSON report file) based on rules conditions evaluated against the application and execute the migration using openrewrite recipes defined as instructions part of the rules

**Project** : `$DEMO_DIR/mtool`

**Instructions**

- Before to analyze the application, verify that it works
```bash
# TERMINAL 1
cd $DEMO_DIR/mtool/spring-boot-todo-app

podman machine start # use docker alternatively !

podman rm mysql_todo_db --force
podman run --detach \
        --name mysql_todo_db \
        --publish 3306:3306 \
        --env MYSQL_ROOT_PASSWORD=root \
        --env MYSQL_DATABASE=todo \
        mysql:9.5

mvn spring-boot:run
```
- Open the application in your browser using: `http://localhost:8081` and create some tasks
- Stop the Spring Boot application: `ctrl-c`

- We will now use `mtool`
- Within the same terminal, go back to: `cd $DEMO_DIR/mtool`
- Execute the following commands to familiarize yourself with the tool, rule definition

| # | Command | Comment |
|---|---------|-----|
| 1 | `mtool --version` | Must display the version of the cli: 1.0.6. |
| 2 | `less ./cookbook/rules/quarkus-spring/020-springboot-to-quarkus-rest-annotations.yaml` | A rule contains metadata, ID, `when/condition` which are queries like `java.annotation is '…'` parsed by ANTLR. The `instructions` are grouped by different providers: `openrewrite`, `manual`, `ai` that the tool can use during the transformation/migration step |
| 3 | `ls ./cookbook/rules/quarkus-spring` | Rules are grouped by domain to be migrated and ordered: BOM, dependencies, annotations, properties, tests. |
| 4 | `less ./cookbook/rules/quarkus-spring-precondition/010-springboot-replace-bom-quarkus.yaml` | A precondition rule allows to check if an application matches some criteria before to be migrated. |
| 5 | `mtool analyze ./spring-boot-todo-app -r ./cookbook/rules/quarkus-spring-precondition` | Precondition checks before any change and is used at the beginning og a migration. See the `ERROR` message |

- To analyze an application and generate the JSON report / migration plan, run the following commands:

| 1 | `mtool analyze ./spring-boot-todo-app -r ./cookbook/rules/quarkus-spring --scanner openrewrite` | Each rule is matched against the code using the different scanners: openrewrite (default), TreeSitter4J - https://github.com/roastedroot/treesitter4j, maven. End of the command execution an ascii report table is displayed. See the detail |
| 2 | `mtool analyze ./spring-boot-todo-app -r ./cookbook/rules/quarkus-spring -o html` | Same analysis generating an HTML report. Open the `analysing-openrewrite-report_*.html` file name showed on the terminal next to : `HTML Report file exported to: file:///`. When opened in your browser, click on RuleId link to see the rule definition |
| 3 | `ls ./spring-boot-todo-app/analysing-openrewrite-report_*.json` and `jq . ./spring-boot-todo-app/analysing-openrewrite-report_*.json | less` | The JSON report is the input aka migration plan used with `transform` command and contains the instructions to perform the migration. |

- And finally migrate the spring boot application using as commands

| 1 | `mtool transform ./spring-boot-todo-app -p openrewrite --dry-run` | Nothing is written: OpenRewrite produces a patch. |
| 2 | `less ./spring-boot-todo-app/target/rewrite/rewrite.patch` | Walk through the diff: BOM, dependencies, annotations, properties created from the execution of the openrewrite recipes. |
| 3 | `mtool transform ./spring-boot-todo-app` | Writes the changes to the project. |

**Key point:** rules are deterministic, reproducible and auditable, but you need a rule for every pattern.

- Launch the migrated app:

```bash
cd spring-boot-todo-app
mvn quarkus:dev
```
- Open the quarkus application in your browser, create tasks, etc: `http://localhost:8080`

> **WARNING**: As you will discover you cannot create Tasks using the UI as openrewrite don't provide recipes able to migrate Thymeleaf to Quarkus Qute except only replacing the dependency !

- You can nevertheless do some curl requests to access the REST endpoints
```bash
# TERMINAL 2
curl http://127.0.0.1:8080/home
curl -X POST http://localhost:8080/home \
  -H "Content-Type: application/json" \
  -d '{"title": "Prepare migration to Quarkus. Task 1", "description": "Migrating Spring Boot TO DO to Quarkus. Task 1", "dueDate": "2025-12-24"}'
curl -X POST http://localhost:8080/home \
  -H "Content-Type: application/json" \
  -d '{"title": "Prepare migration to Quarkus. Task 2", "description": "Migrating Spring Boot TO DO to Quarkus. Task 2", "dueDate": "2025-12-24"}'
  
# Curl again the home endpoint to see the tasks stored
curl http://127.0.0.1:8080/home
```
- You can now stop the `quarkus` application before to move to the next demo !

---

### Coding agent using skill and quarkit

**Description** : By moving to an AI Coding Agent able to read the skill [instructions]($SKILL_DIR/skills/migrate-spring-to-quarkus) and accessing an MCP server, we will now migrate properly the Spring Boot Application including also the Web layer: Thymeleaf to [Quarkus Qute](https://quarkus.io/guides/qute/). During this demo you will use either the [Java acp CLI](https://github.com/smallrye/smallrye-acp-client) to install your favorite agent or [Claude code](https://claude.com/product/claude-code). We will also introduce some of the key concepts which have been adopted to organize the instructions, process the migration as in a workflow with gated steps and use references to tell to the agent what to migrate.

**Project** : `$DEMO_DIR/quarkit`

**Instructions**

The skill never modifies its source: `$DEMO_DIR/quarkit/spring-boot-todo-app/` is only read (the skill may write
extraction data to `migration-metadata/` there; in our runs it went to the target) and the migrated
project goes to the sibling **`$DEMO_DIR/quarkit/spring-boot-todo-app-quarkus/`** (default target
`<source-name>-quarkus/`, see `modules/planning/planning.md`).

> **Note**: Before to start the migration using AI, please unsure that you set properly the environment variables to access your LLM provider: anthropic, google vertex, azure, etc

- To discover some of the key features of the skill, execute the following commands:

| # | Command | Comment |
|---|---------|-----|
| 1 | `tree $SKILL_DIR/skills/migrate-spring-to-quarkus` | Explore the structure of the folders under the skill. It contains different modules executed in a specific order: prerequisite, planning, build, etc. The references map between the 2 frameworks what should be changed. |
| 2 | `less +'/### Decision Gate Table' $SKILL_DIR/skills/migrate-spring-to-quarkus/SKILL.md` | The decision gate table details the different modules to be evaluated, what to check and the expected result. If it fails, then the coding agent will exit, otherwise it continues. |
| 3 | `less $SKILL_DIR/skills/migrate-spring-to-quarkus/modules/prerequisite/prerequisite.md` | Read the `prerequisite.md` to see how we verify the prerequisites  |
| 4 | `less $SKILL_DIR/skills/migrate-spring-to-quarkus/modules/planning/planning.md` | The `planning.md` file is a central point of the architecture as it will capture under the generated file: `migration-spec.yaml` different metadata used by the modules to migrate the application.  |
| 3 | `cat $DEMO_DIR/quarkit/spring-boot-todo-app/.quarkus-migration.yml` | The skill can use the information of the file `.quarkus-migration.yml` (when created) within the module: planning and prerequisite to execute the instructions according to the user's choices when running in autonmous mode. |

- When you have finished to review the skill folders, files, launch the Quarkit MCP server
```bash
# TERMINAL 1
cd $DEMO_DIR/quarkit

acp mcp add -f -t http quarkit-http http://localhost:8080/mcp -- \
  jbang --deps dev.snowdrop.mtool:references:2.0.3 mcp-http@snowdrop/quarkit

acp mcp serve -e QUARKIT_ALLOWED_DIRS=$QUARKIT_ALLOWED_DIRS quarkit-http
...
2026-11-26 10:55:39,377 INFO  [dev.snowdrop.mtool.mcp.ReferenceRepository] (main) Loaded reference file: annotation-map.json (99 records)
2026-11-26 10:55:39,379 INFO  [dev.snowdrop.mtool.mcp.ReferenceRepository] (main) Loaded reference file: config-map.json (54 records)
2026-11-26 10:55:39,380 INFO  [dev.snowdrop.mtool.mcp.ReferenceRepository] (main) Loaded reference file: dependency-map.json (37 records)
2026-11-26 10:55:39,436 INFO  [io.quarkiverse.mcp.server] (executor-thread-1) MCP HTTP transport endpoints [streamable: http://0.0.0.0:8080/mcp, SSE: http://0.0.0.0:8080/mcp/sse]

MCP server 'quarkit-http' is ready at http://localhost:8080/mcp (http) - press Ctrl-C to stop it
```
**Note**: Verify that the Quarkus Server has been well started and has loaded the reference files

- Next, select one of the two `options` described hereafter to perform the AI migration:

**Option 1**: Use the Smallrye Java ACP client

```bash
# TERMINAL 2
cd $DEMO_DIR/quarkit
acp run -a claude-acp --backup no \
  --wks $DEMO_DIR/quarkit/spring-boot-todo-app \
  -s $SKILL_DIR/skills \
  --mcp-server quarkit-http \
  -p "Migrate this Spring Boot project to Quarkus"
```

- **Option 2** : Use Claude Code 

```bash
# TERMINAL 2
cd $DEMO_DIR/quarkit/spring-boot-todo-app
claude --mcp-config '{"mcpServers":{"mtools":{"type":"http","url":"http://localhost:8080/mcp"}}}' \
  --permission-mode auto \
  "Migrate this Spring Boot project to Quarkus"
```

> **Note**: `--permission-mode auto` lets the agent run its `./mvnw`, `java` and file commands without asking,
while still stopping risky actions. `acceptEdits` only covers file edits, so every Bash command
would ask for approval on screen.

- Check the messages displayed within the terminal like `check`, `compile`, `validation` where the Quarkit MCP server is called
```
Prerequisites passed (JDK 21, Maven 3.9.4 via wrapper, Podman available). Now reading the remaining skill modules before planning the migration.
Planning: setting up the target directory, checking the Quarkus version and the code.quarkus.io streams.
JDK check passes (3.40 stream needs ≥17; JDK 21 is installed). Copying the source into the target and writing the spec.
Build module (Gate PASS: Spring Boot parent, starters and plugin present). Rewriting `pom.xml`:
Compile passes. Now running the persistence validation via the quarkit MCP tool, as the skill requires:
Persistence validation: 8/8 PASS. Messaging module: **SKIPPED** (no Kafka/Rabbit/JMS usage). Now the testing module (Gate PASS: `@SpringBootTest` found):
```

- When the agent code has finished to perform the migration, do a quick check to verify the migration

| 1 | `less $DEMO_DIR/quarkit/spring-boot-todo-app-quarkus/pom.xml` | Review the quarkus dependencies and version of the Quarkus BOM. |
| 2 | `less $DEMO_DIR/quarkit/spring-boot-todo-app-quarkus/migration-summary.md` | The `Overall Status` must be `100% Complete`. |

---

### The Quarkus Todo application and migration summary

**Description** : We will now analyze the migration summary and validate if we can start the Quarkus application and create tasks using the UI.

**Project** : `$DEMO_DIR/quarkit`

**Instructions**

| # | Command | Say |
|---|---------|-----|
| 1 | `less $DEMO_DIR/quarkit/spring-boot-todo-app-quarkus/migration-summary.md` | The summary tells you what migrated, what didn't, and why: every applicable module done, messaging skipped, 6/6 verification checks, and the remaining work (point `%prod` at the real MySQL, the unused `jjwt` dependency). |
| 2 | `ls $DEMO_DIR/quarkit/spring-boot-todo-app-quarkus/migration-reports/` | The JSON reports generated during the `project-setup` and validation steps: `quarkit-validation-report.json` and `reporting-report.json`. |
| 3 | `(cd $DEMO_DIR/quarkit/spring-boot-todo-app-quarkus && ./mvnw clean test)` | 4 Junit tests executed successfully and MySQL started by Dev Services: see messages reported by the logger: `org.testcontainers` and `tc.docker.io/library/mysql:9.5`. |
| 4 | `./mvnw quarkus:dev -Dquarkus.http.port=8090` | Open http://localhost:8090: list, add and delete tasks, pagination. |
| 5 | Compare what changed within the file `templates/TaskResource/home.html` next to the original Thymeleaf `templates/home.html` | Type-safe Qute templates (`@CheckedTemplate`), checked at build time. |

**Note**: We set the property `-Dquarkus.http.port=8090` because the MCP server holds 8080.

---

### Quarkit MCP server with acp

**Description** : Use the commands of the Smallrye acp CLI - https://github.com/smallrye/smallrye-acp-client installed to register an acp agent or use a mcp server, to list the tools and query a tool. 

**Project** : `$DEMO_DIR/quarkit`

**Instructions**:

- Execute the commands defined hereafter to familiarize yourself with different commands:

```bash
# Your installed agents
acp registry list

# List of remote ACP registry
acp registry list -r

# To (re-)install a new ACP coding agent
acp registry install claude-acp --force 

# Execute a prompt message
acp run -a claude-acp -p "Say hello in French, Spanish"

# List the mcp server(s) registered
acp mcp list
```

- Now that you're mastering the acp CLI, you can query the Quarkit MCP Tools as showed hereafter from the `TERMINAL 2`:

**Note**: The Quarkit MCP server (http transport) must still run under the `TERMINAL 1` !

| # | Command | Comment |
|---|---------|-----|
| 1 | `acp mcp tools quarkit-http` | Four tools: `quarkit_analyze`, `quarkit_validate`, `quarkit_references_list` and `quarkit_lookup` are listed. This is what the agent sees. If you pass the parameter: `--schema` then you will see the tool's parameters. |
| 2 | `acp mcp call quarkit-http quarkit_analyze -p "query=pom dependency all" -p project_path=$DEMO_DIR/quarkit/spring-boot-todo-app` | The tool analyze allows to parse an application using a ANTLR query. Verify that you got 8 matches as pom dependencies. |
| 3 | `acp mcp call quarkit-http quarkit_analyze -p "query=java annotation all" -p project_path=$DEMO_DIR/quarkit/spring-boot-todo-app` | We run a new query to search/find all the annotations within the Java classes. The parser used under the hood is TreeSitter4j- https://github.com/roastedroot/treesitter4j. |
| 4 | `acp mcp call quarkit-http quarkit_references_list` | List the references: annotation, config, dependency and their sections/domains. Such data are loaded y the Quarkit MCP server at launch ! |
| 5 | `acp mcp call quarkit-http quarkit_reference_lookup -p map=annotation -p key=@Transactional -p mode=compat` | Look up to search the mapping between Spring and Quarkus using compatibility mode. You should see: `spring" : "@Transactional"` and "quarkus" : "jakarta.transaction.Transactional". |
| 6 | `acp mcp call quarkit-http quarkit_reference_lookup '{"map":"annotation","key":"@Transactional","mode":"compat"}'` | Same lookup using a JSON argument instead of the parameters. |

Other lookups that read well live:
```bash
acp mcp call quarkit-http quarkit_reference_lookup -p map=annotation -p "section=Dependency Injection" -p mode=compat
acp mcp call quarkit-http quarkit_reference_lookup -p map=config -p key=spring.datasource.url
```

---

### Break a migrated Java JPA entity

**Description** : During the following demo, you will modify within the migrated application a Java class (Task.java class by example) to re-run the MCP Tool validation and observe what it happened when a check condition is not correct.

**Project**: `$DEMO_DIR/quarkit/spring-boot-todo-app-quarkus`

**Instructions**: 

The break: `Task.id` goes from `GenerationType.AUTO` to `GenerationType.IDENTITY`, the kind of
"simplification" an agent makes for MySQL. It compiles and the tests should still pass (Dev
Services creates a fresh schema), but it no longer matches the existing database: Spring used
`AUTO`, which on MySQL means a sequence table, and the migrated code even says so in the comment
right above. Tests don't catch it; the validator does.

| # | Command | Comment |
|---|---------|-----|
| 1 | `acp mcp call quarkit-http quarkit_validate -p target=$DEMO_DIR/quarkit/spring-boot-todo-app-quarkus -p source=$DEMO_DIR/quarkit/spring-boot-todo-app -p validator=persistence -p skipCompile=true` | The status is `PASS` and Rules reports: `8 total | 8 passed | 0 failed | 0 warnings`. |
| 2 | `vim $DEMO_DIR/quarkit/spring-boot-todo-app-quarkus/src/main/java/com/todo/app/entity/Task.java`. Change the strategy to generate the key:  `@GeneratedValue(strategy = GenerationType.AUTO)` to `@GenerationType.IDENTITY)`. |
| 3 | Same command as #1 | One FAIL: `ID generation strategy matches` → `ID strategy changed: AUTO -> IDENTITY`. |

---

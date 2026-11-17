# Slides draft (3 slides)

Content only; the format is still to decide. Everything else in the episode is live.

---

## Slide 1 — The problem (min 0–3)

**Title:** Migrating between two frameworks is hard

Six things change at once:

| Build | Config | DI & web |
|---|---|---|
| BOM, starters → extensions, plugins | `spring.*` → `quarkus.*` | `@Autowired`, `@Controller` → CDI, JAX-RS |
| **Persistence** | **Views** | **Tests** |
| Spring Data → Panache, IDs, relationships | Thymeleaf → Qute | `@SpringBootTest` → `@QuarkusTest` |

Bottom line: *Rules are reliable but don't cover everything. AI covers more but improvises.*

**Speaker notes:**
A migration is a big refactoring. And Martin Fowler explained refactoring twenty-five years ago, in three steps. 
Understand the pattern. Apply it everywhere, the same way. Verify that the behavior did not change.
Today, AI does step two for you very well, It applies the pattern, and the code compiles. 
But it does not do step one, and it does not do step three. 
If you don’t know the pattern, you cannot tell a clean migration from well-formatted garbage that happens to compile. 
And if you don’t verify, you don’t know what you broke.
AI is flexible and powerful. But it’s expensive. It’s variable. And it needs context to do a good job.
Our principle is simple. If a change can be written as a rule, automate it with a rule.
Deterministic rules are cheap, zero tokens. 
They are reproducible: same input, same output, every time. There is no decisions. And they are auditable.
To write one you have to know every case in advance, and between two versions of the same framework, you can. 
Between two different frameworks, you can’t. 
A Spring controller can become a JAX-RS resource, or a Qute page, or something else, depending on the project and the strategy.
There are decisions. And decisions don’t fit in a YAML file.
So for that kind of migration we built something different: an AI skill.
---

## Slide 2 — AI does the work, deterministic tools check it (min 15–18)

**Title:** Agent ↔ skill ↔ quarkit MCP

Diagram:

```
                ┌──────────────────────────────┐
                │  Skill: migrate-spring-to-   │
                │  quarkus                     │
                │  SKILL.md · gated modules ·  │
                │  reference maps · compile-fix│
                └──────────────┬───────────────┘
                               │ plan: which module, when, how to check it
                               ▼
  "Migrate this     ┌──────────────────┐   MCP (tools/call)   ┌──────────────────────────┐
   Spring Boot  ──► │   AI agent       │ ───────────────────► │  quarkit MCP server      │
   project…"        │ (Claude Code,    │ ◄─────────────────── │  quarkit_analyze         │
                    │  any ACP agent)  │   PASS / FAIL, rows  │  quarkit_validate        │
                    └────────┬─────────┘                      │  quarkit_references_list │
                             │ edits code                     │  quarkit_reference_lookup│
                             ▼                                └────────────┬─────────────┘
                    ┌──────────────────┐                                   │ reads
                    │ Spring project → │ ◄─────────────────────────────────┘
                    │ Quarkus project  │   (scanners: treesitter, JavaParser, Maven;
                    └──────────────────┘    validators: project-setup, persistence)
```

**Speaker notes:** The full picture looks like this. A deterministic sandwich around the AI.
[AI Skill] In the middle, the skill. It does the work that needs context: controller logic, template conversion, config reasoning, strategy decisions, tests. Tokens, flexible, variable. That’s the price of understanding.
[Validators] Next to it, the validators. They are deterministic: pure Java, zero tokens, same result every time. They compare the Quarkus project against the Spring source: project setup, entities and their relations, ID strategies, table names, REST endpoints, configuration, messaging.
[MCP, nota amarilla] And they live in quarkit, our MCP server. If the server is running, the agent discovers the validators as tools and calls them by itself, during the migration
[feedback loop] When a validator fails, the result goes back to the skill, and the agent fixes it. AI proposes, rules verify.
Verified Quarkus Project] What comes out is not “a Quarkus project”. It’s a verified one.
Let’s see it run.

---

## Slide 3 — What's next + contribute (min 47–50)

**Title:** What we're working on

- Measure token cost and time, with and without the quarkit tools
- More validators: REST endpoints, templates, tests
- YAML rules and query language as validator config and migration plans
- Agent-agnostic runs through ACP
- Resumable state: pick up a migration where it stopped
- New reference maps, rules and validators from the community

**Try it / contribute** (with QR codes):
- github.com/snowdrop/migration-tool
- github.com/quarkusio/skills → `skills/migrate-spring-to-quarkus`
- This repo (demo commands to reproduce everything)

**Speaker notes:** These are things we're working on, not results. Call to action: point the skill at
a small Spring Boot app and open an issue with what broke.

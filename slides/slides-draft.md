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

**Speaker notes, alternative: walking the diagram (~3 min)**

*Transition from Charles (≈20 s)*
"So that's mtool: rules are deterministic, reproducible, auditable. But every Spring pattern needs a rule,
and real apps have patterns nobody wrote a rule for. AI covers far more ground, but it improvises. So the
question became: how do we get the coverage of AI with the reliability of rules?"

*The prompt and the agent, left and centre (≈30 s)*
"It starts with one prompt: *migrate this Spring Boot project*. The agent, Claude Code here but any ACP
agent works, is the one that reads code and writes code. That's what it's good at."

*The skill, top (≈40 s)*
"But we don't let it improvise the plan. The skill gives it one: which modules exist (build, persistence,
code, views, tests), a gate that decides whether each one applies, and the rule that after every module the
project must compile. The modules are loaded only when needed, so the agent isn't carrying the whole
playbook in its context. I'll open it in a minute."

*quarkit, right (≈50 s)*
"And this is the part that changes everything: quarkit, an MCP server built on the same engine as mtool,
the same scanners and the same query language. The agent doesn't *guess* what's in the project: it asks
`quarkit_analyze`. It doesn't guess how a Spring annotation or property maps to Quarkus:
`quarkit_reference_lookup` gives it the answer from a curated map. And it doesn't decide whether the
migration is correct: `quarkit_validate` does, by comparing the migrated project with the original,
entity by entity."

*The loop, bottom (≈30 s)*
"So the loop is: the agent edits the code, quarkit reads both projects and answers PASS or FAIL, and a FAIL
has to be fixed before moving on. AI does the work, deterministic tools check it."

*Bridge to the next segment (≈10 s)*
"Let's look at what's inside that skill box."

*If asked in chat:* today the skill calls `quarkit_validate` only in the persistence module, and the
validators available are `project-setup` and `persistence`. More validators are on the roadmap (slide 3).

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
- github.com/snowdrop/quarkit
- github.com/quarkusio/skills → `skills/migrate-spring-to-quarkus`
- This repo (demo commands to reproduce everything)

**Speaker notes:** These are things we're working on, not results. Call to action: point the skill at
a small Spring Boot app and open an issue with what broke.

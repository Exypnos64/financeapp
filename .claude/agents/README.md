# `.claude/agents/` — Custom Subagents

**No custom agents exist yet, on purpose.** This project is new and no repeatable, specialized
workflow yet justifies encoding one. Fabricating agents before there's a real need would violate
the "don't invent conventions that aren't there" principle this setup is built on.

When a genuine need appears (a recurring sub-task worth delegating), add one `.md` file per agent
here, following the pattern below (derived from the reference repo the setup guide was based on).

## Anatomy of an agent file

Frontmatter (all four fields, in this order):

```markdown
---
name: <kebab-case, matches the filename>
description: "What it does, WHEN to use it, and WHEN to use a sibling agent INSTEAD. This blurb
is dispatch logic — it's how the orchestrating session picks the right agent."
model: <sonnet for authoring/generation | opus for audit/judgment>
color: <cosmetic display color>
---
```

Body: a complete standalone system prompt written in the second person, typically shaped as:
identity → why this agent exists (a real failure that motivates it) → the contract/invariants →
the checks/procedure → "what is NOT a finding" (negative controls) → output format → scope
boundaries ("report only, never edit").

Best practices to carry forward:

- **Pair authoring agents with audit agents.** Generation and verification are separate jobs;
  audit agents are `opus` and strictly report-only.
- **The `description` must say when to pick a sibling instead** — that's how dispatch works.
- **Ground an audit agent's rules in a real past failure**, so the rules are legible, not
  arbitrary.

For the full rationale see `../../CLAUDE-SETUP-GUIDE.md` §4.

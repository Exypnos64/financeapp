# How to Set Up Claude Code Documentation & Tooling for a Repository

A reusable, repo-agnostic how-to for reproducing the Claude Code documentation, agent, and
tooling setup observed in the `Web-ChrisComplete` reference repository. Everything below is
derived from that repo's actual structure; where the reference omits something (hooks, slash
commands, a shared `settings.json`), this guide says so explicitly rather than inventing it.

> The reference repo is a Selenium/Python test-automation project, but the *system* described
> here is domain-agnostic. Substitute your own project's content into the same skeleton.

---

## 1. Philosophy & Architecture

The core idea: **`CLAUDE.md` is a lean router, not an encyclopedia.** It holds only the
always-true rules and a *catalog* of deeper reference docs, each annotated with "**Read when**"
(the trigger) and "**Contains**" (the payload). The heavy detail lives in focused files under
`.claude/docs/`, loaded on demand. This keeps the always-in-context file small while making
comprehensive knowledge reachable.

Five layers, each with a distinct job:

| Layer | Location | Audience | Role |
|---|---|---|---|
| **Router / rulebook** | `CLAUDE.md` (repo root) | Claude, every session | Always-loaded. Critical rules + naming conventions + an annotated index of every reference doc, agent, and tool. |
| **Reference docs** | `.claude/docs/**` | Claude (primary) | Deep, task-specific knowledge loaded on demand via CLAUDE.md's "Read when" triggers. |
| **Subagents** | `.claude/agents/*.md` | Claude (spawns them) | Specialized, single-purpose workers with their own prompt + model. |
| **Tools** | `.claude/tools/**` (+ some in root `tools/`) | Claude (runs via Bash) | Deterministic scripts that replace fragile multi-step manual work; each paired with a `*-guide.md`. |
| **Human docs** | `README.md`, `HANDOFF.md`, `TODO.md`, `docs/**` | Humans (primary) | Onboarding, project status, backlog, and human-facing topic docs. |

Guiding principles observed in the reference repo:

- **The `.claude/` tree is committed to version control** (tracked, not gitignored) — only
  per-machine scratch (`CLAUDE.md_backups/`, `settings.local.json`) and secrets are excluded.
  The stated rationale, quoted from CLAUDE.md: *"Everything in it is instructions and tools
  meant for you and other Claude instances rather than polished human documentation — the
  team's Claude sessions are the primary readers."*
- **Single source of truth per fact.** Each doc names what it is canonical for and *defers*
  to sibling docs for everything else ("**Also the canonical source for X** — other docs
  reference back to this"; "For browser inspector usage, defers to `browser-inspector-design.md`").
  Duplication is actively avoided by cross-linking instead of copying.
- **Docs mirror the work.** When a tool ships, its guide ships with it; when a convention is
  automated into a linter, the manual rule points at the linter. `TODO.md` items are closed
  with a "Done:" note pointing at the artifact and its doc.
- **Notes are disposable.** `.claude/notes/` holds session scratch; durable findings get
  *promoted* into `.claude/docs/` and the note deleted.

---

## 2. Directory & File Layout

```text
<repo-root>/
├── CLAUDE.md                     # Router: critical rules + annotated index (KEEP LEAN)
├── README.md                     # Human: features, install, doc table, project structure
├── HANDOFF.md                    # Human: point-in-time "who takes this over" snapshot
├── TODO.md                       # Human+Claude: backlog; done items keep a "Done:" note
├── .gitattributes                # EOL normalization (see §7)
├── .gitignore                    # Excludes .claude scratch + secrets (see §7)
├── .markdownlint-cli2.jsonc      # Markdown lint config tuned to house line-width rules
├── docs/                         # Human-facing topic docs, indexed by README's table
│   ├── ONBOARDING.md             #   clone → first-success path
│   ├── <TOPIC>.md                #   one file per topic (testing, secrets, known-issues…)
│   └── records/                  #   maintainer-only reference ledgers
└── .claude/                      # Claude-facing setup — COMMITTED to the repo
    ├── settings.local.json       # Per-machine permission allowlist (GITIGNORED)
    ├── agents/                   # Custom subagent definitions (one .md per agent)
    │   └── <agent-name>.md
    ├── docs/                     # On-demand reference docs, grouped by kind
    │   ├── <area>-reference.md
    │   ├── app-references/       #   one doc per sub-component / app / module
    │   ├── tool-references/      #   one *-guide.md per tool in .claude/tools/
    │   └── <workflow-group>/     #   multi-step workflow docs
    ├── tools/                    # Python scripts Claude runs via Bash
    │   ├── <tool>.py
    │   └── <tool>-eval/          #   optional seeded-defect benches for tuning agents
    ├── notes/                    # Disposable session scratch (promote → docs, then delete)
    ├── tool-todo.md              # Backlog specifically for tools to build
    └── CLAUDE.md_backups/        # Version snapshots of CLAUDE.md (GITIGNORED)
```

Notable **absences** in the reference repo (do not assume these exist):

- **No `.claude/commands/`** — there are no custom slash commands. See §5.
- **No shared `.claude/settings.json`** — only the gitignored `settings.local.json`. There is
  no committed team-wide permissions/hooks/env file. See §6.
- **No hooks and no statusline configuration** anywhere.
- **No skills** defined in the repo.

---

## 3. CLAUDE.md — Section-by-Section Template

The reference `CLAUDE.md` is ~67 KB but only ~370 lines: the bulk is one long **annotated
index**, and the actual rules are short. Its structure, top to bottom:

```markdown
# Claude Knowledge Base - <Project Name>

> **Living Document**: Update when <the concrete triggers for this project — new modules
> added, conventions change, structure changes>.

---

## Reference Files

<1–2 sentences: detail is split into focused files under `.claude/docs/`. State the rule:
"Read the relevant file before starting any task that needs it." Then state the tracking
policy: the `.claude/` tree is committed; only scratch/local are gitignored; the primary
readers are Claude sessions. Note what `.claude/notes/` is and that it's non-authoritative.>

### `.claude/docs/<file>.md`

**Read when**: <the precise trigger — the situations that should make Claude open this file>

**Contains**: <a dense one-paragraph inventory of everything inside, so Claude can decide
relevance without opening it, and find the sub-topic once inside>

### `.claude/docs/<next-file>.md`
… (repeat for every reference doc — this is the largest part of the file) …

### `.claude/agents/`

**Use when**: <when to reach for a subagent>

**Contains**: <one clause per agent: name + what it does + when to pick it over a sibling>

### `.claude/tools/`

**Use when**: <when to reach for a tool>

**Contains**: <one clause per tool: name + what it does + pointer to its *-guide.md>

---

## Critical Rules

- <Terse, imperative, always-true invariants. One line each. The "never do X / always do Y"
  list. Reference-repo examples of the FORM (not the content):>
- Never use <fragile pattern> -- <the one-clause reason>
- Always use <correct pattern> for <situation>
- <Architectural boundary, e.g. "layer A must NEVER import from layer B (one-way)">
- <Environment invariant, e.g. which interpreter/venv to always use>
- <Formatting invariant, e.g. line-width limits with exact wrap thresholds>

---

## Naming Conventions

- **<Artifact type>**: `<pattern>` (e.g., `tc*.py`)
- **<Class type>**: `*Suffix`
- **<Docstring policy>**: <what metadata new functions carry, and the exemptions>
```

### CLAUDE.md authoring guidance (as practiced in the reference)

- **Address Claude in the second person, imperative mood.** "Read the relevant file before
  starting…", "Never use…", "Always use…". The whole file talks *to* the assistant.
- **The "Read when / Contains" pair is the load-bearing pattern.** "Read when" is a trigger
  Claude can pattern-match against the task at hand; "Contains" is a dense manifest so Claude
  can judge relevance and locate a sub-topic *without* opening the file. Every reference
  entry uses both.
- **Keep the always-loaded surface small.** Push detail into `.claude/docs/`. The root file
  is a router; if a rule needs a paragraph of explanation, that paragraph belongs in a
  reference doc and the router gets a one-liner pointing at it.
- **Critical Rules are one line each, no prose.** Each is an invariant with a terse `--`
  clause of justification. If it can't be stated in a line, it's not a Critical Rule.
- **Mark it a "Living Document"** at the very top with the concrete update triggers for the
  project, so Claude knows to maintain it.
- **Cross-reference, never duplicate.** Name the canonical owner of each fact and defer to it.
- **Wide lines are fine** (the reference runs prose to 140+ chars); markdownlint is configured
  to permit it (see §7). Don't hand-wrap prose short.

---

## 4. `.claude/agents/` — Anatomy of an Agent Definition

One markdown file per agent. **Frontmatter fields observed (all four present on every agent,
in this order):**

| Field | Required | Notes |
|---|---|---|
| `name` | yes | kebab-case; matches the filename (`fidelity-audit.md` → `fidelity-audit`). |
| `description` | yes | **Double-quoted string.** Written as a *dispatch* blurb — what it does, *when to use it*, and explicitly *when to use a sibling agent instead*. Often long (2–5 sentences). |
| `model` | yes | `opus` or `sonnet` in the reference. Observed pattern: **`sonnet` for authoring/generation** agents, **`opus` for audit/judgment** agents. |
| `color` | yes | A display color (`yellow`, `orange`, `opus`, `cyan`, `green`, `blue`). Cosmetic. |

No other frontmatter fields appear (no `tools:`, no `allowed-tools:` — the reference relies on
the session's own permissions).

### Body structure

After the frontmatter, the body is a **complete standalone system prompt** for that subagent,
written in the second person ("You are the automation author…"). The recurring section pattern
across the reference agents:

```markdown
---
name: <agent-name>
description: "<what it does. WHEN to use it. When to use <sibling> INSTEAD.>"
model: <sonnet|opus>
color: <color>
---

# <Human Title>

<1–2 paragraphs: the agent's identity and its single responsibility, and how it differs
from any sibling agent it could be confused with.>

## What you receive          # (author agents) the exact inputs the orchestrator will hand over
## Your job                   # the one-sentence deliverable + what to report back
## Why this agent exists       # (audit agents) the real failure that motivated it — grounds the rules
## The <domain> contract        # numbered invariants the agent enforces
## When to invoke / Checks      # the concrete step-by-step procedure
## What is NOT a finding        # (audit agents) explicit negative controls to prevent false positives
## Output format               # the exact shape of the report, often a fenced template
## What you do NOT do          # scope boundaries (e.g. "report only, never edit")
```

### Annotated example (skeleton derived from the reference audit agents)

```markdown
---
name: <name>
# Dispatch blurb: note the "use X instead" clause — this is how the orchestrator picks
# the right agent. State the model choice deliberately (opus for judgment, sonnet for authoring).
description: "Audits <artifact> against <authority> at the <level> level — <the specific
misses it catches>. The sibling of <other-agent>. Reports findings; does not fix."
model: opus
color: orange
---

# <Title>

You <identity>. This is a different job from <sibling> (which <does that>): you <do this>.

## Why this agent exists
<A concrete past failure that slipped through everything else. Grounds every rule below in a
real miss so the agent understands the stakes — the reference agents each cite an actual bug.>

## The <domain> contract
The rules below are the invariants every check enforces.
1. **<Rule name>.** <What must hold, with a concrete example of the violation.>
2. …

## Checks
### 1. <Check name>
<What to enumerate, how to judge it, with a ✅/❌ example.>

## What is NOT a finding
- **<Sanctioned pattern>** — <why it's fine, so the agent doesn't flag it.>

## Output format
<A fenced template line the agent must emit per finding, plus ranking/labeling rules.>

## What you do NOT do
- You do not edit <artifacts>. Report only.
```

Best practices seen in the reference agents:

- **Every author agent has an audit counterpart.** Generation and verification are separate
  agents; audit agents are `opus` and explicitly "report only, do not fix."
- **The `description` is a routing decision aid.** It always says when to pick this agent
  *versus* its sibling ("use `test-converter` instead", "the ADO-first sibling of
  `fidelity-diff`"). This is how the orchestrating session dispatches correctly.
- **Ground rules in real failures.** Audit agents open with a "Why this agent exists" section
  citing the actual bug that motivated them — this makes the rules legible, not arbitrary.
- **"What is NOT a finding"** is as important as the checks: it lists sanctioned patterns so
  the agent doesn't raise false positives.

---

## 5. `.claude/commands/` / Slash Commands / Skills

**The reference repo defines none of these.** There is no `.claude/commands/` directory, no
custom slash commands, and no repository-defined skills.

The nearest analog the repo uses instead is **subagents** (§4) for repeatable specialized work
and **plain Python tools** (§6/§8) for deterministic operations. If you want slash commands in
your own repo, the (Claude Code standard, *not* present here) mechanism is a `.claude/commands/`
directory with one markdown file per command — but note that reproducing *this* repo's setup
faithfully means you would **not** add them; it leans entirely on agents + tools + reference docs.

---

## 6. settings / permissions / hooks

### What exists

Only **`.claude/settings.local.json`** — the per-machine, **gitignored** file. It contains a
single `permissions.allow` array (no `deny`, no `env`, no `hooks`). Real excerpt (sanitized):

```json
{
  "permissions": {
    "allow": [
      "Bash(uv sync:*)",
      "WebSearch",
      "WebFetch(domain:github.com)",
      "Bash(gh api *)",
      "Bash(.venv/Scripts/python.exe .claude/tools/tc_app_structure.py *)",
      "Bash(.venv/Scripts/python.exe .claude/tools/azure_devops_query.py *)",
      "Bash(git diff *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(npx markdownlint-cli *)",
      "Bash(npx pyright *)"
    ]
  }
}
```

Observations:

- The allowlist is **granular and tool-path-specific** — it pre-approves the exact commands
  the workflow runs constantly (the repo's own `.claude/tools/*.py` scripts, `git` subcommands,
  the venv interpreter, the linters) so sessions aren't interrupted by prompts. This is the
  file the `fewer-permission-prompts` workflow produces over time.
- It is **gitignored on purpose** (paths are machine-absolute; approvals are personal).
- **No `deny` list, no `env` block, no `hooks` block** — the repo does not automate any
  pre/post behavior through settings.

### What does NOT exist (be explicit)

- **No committed `.claude/settings.json`** (team-shared settings). New machines build their own
  `settings.local.json` by approving prompts.
- **No hooks** (no `PreToolUse`/`PostToolUse`/`Stop`/etc.). All linting/verification is invoked
  explicitly by the session or an agent, never auto-fired by the harness.
- **No environment variables** set via settings.

### If reproducing

Create `.claude/settings.local.json` per machine (leave it gitignored). Seed the allowlist with
your project's constant commands: the interpreter/venv path, your `.claude/tools/*` scripts, the
`git` subcommands you use, and your linters/type-checkers. Add entries as prompts occur.

---

## 7. Supporting Config: markdownlint, gitattributes, gitignore

### `.markdownlint-cli2.jsonc`

Tuned so the linter agrees with the house wide-line convention. Real file (verbatim):

```jsonc
{
    "globs": ["**/*.md"],
    "ignores": [".venv/**", ".pytest_cache/**", "logs/**", "node_modules/**", ".claude/CLAUDE.md_backups/**"],
    "config": {
        "MD013": false,   // line-length: project uses wide lines (140/175); prose follows suit
        "MD060": false,   // table pipe-padding: cosmetic only
        "MD038": false    // spaces inside code spans: deliberate/meaningful here
    }
}
```

Run with `npx -y markdownlint-cli2` (globs are baked in). Key takeaway: **disable `MD013`
(line length)** if you adopt the wide-line convention, and **ignore the `CLAUDE.md_backups/`**
and generated dirs.

### `.gitattributes`

Pins end-of-line so bulk-edit scripts don't have to special-case `\r?\n`:

```gitattributes
* text=auto eol=crlf     # repo stores LF in the index, checks out CRLF on Windows
*.png binary
*.jpg binary
```

### `.gitignore` — the `.claude`-relevant lines

The rest of `.gitignore` is ordinary (venv, caches, build). The lines that encode the
**"commit `.claude/`, exclude only scratch + secrets"** policy:

```gitignore
# Claude knowledge base is tracked; keep only scratch and per-machine local out
.claude/CLAUDE.md_backups/
.claude/settings.local.json

# secrets kept out of version control
.secret.key
.claude/tools/azure_devops_pat.py

# per-job scratch produced by a tool
.claude/tools/browser_service/output/
```

The important inversion: `.claude/` is **not** blanket-ignored. Agents, docs, and tools are
committed; only the enumerated scratch/secret paths are excluded.

---

## 8. `.claude/tools/` — Deterministic Scripts

Not required to reproduce the doc/agent skeleton, but core to the reference's philosophy, so
worth carrying forward as a pattern:

- Each tool is a **Python script Claude invokes via Bash** (pre-approved in
  `settings.local.json`), replacing a fragile multi-step manual operation with one deterministic
  command that returns structured output.
- **Every tool is paired with a `.claude/docs/tool-references/<tool>-guide.md`** and indexed in
  CLAUDE.md's `.claude/tools/` entry.
- **Conventions become linters.** Where a house rule can be checked mechanically (line length,
  trailing commas, step spacing, label drift), the repo builds a `lint`/`fix` tool for it, and
  the audit agents delegate the mechanical part to the tool and keep only the judgment calls.
- Some tools carry a **seeded-defect eval bench** (`<tool>-eval/` with `broken/` fixtures, a
  `manifest.json` of ground truth, and a `score.py`) used to re-tune the audit agents.
- `.claude/tool-todo.md` is a dedicated backlog for tools to build, with a kept EXAMPLE block
  as a template for new entries; done items are struck through with a pointer to the artifact.

---

## 9. Human Docs — README / HANDOFF / TODO / docs/ — Division of Responsibility

These four are for **humans**; `CLAUDE.md` + `.claude/` are for **Claude**. Each human doc has
a sharply distinct role, and they interlink rather than duplicate:

| Doc | Question it answers | Owns | Explicitly does NOT hold |
|---|---|---|---|
| **README.md** | "What is this and how do I install/run it?" | Features, prerequisites, step-by-step install, the **documentation index table**, project-structure tree, dependency list, troubleshooting. | Project status, task backlog, deep topic detail (defers to `docs/`). |
| **docs/*.md** | "How do I do `<topic>` in detail?" | One file per topic (onboarding, testing, secrets, known-issues, etc.). The durable how-to detail. | The at-a-glance index (that's README's table) and current status. |
| **HANDOFF.md** | "I'm taking this over — what's the state and what's next?" | A **dated, point-in-time snapshot**: 30-second picture, what's done, what's in flight, what's blocked (and why), access/credentials, maintenance rhythm, non-obvious gotchas. | Setup steps (defers to onboarding) and per-item detail (points at maintained sources). Explicitly labels itself "a snapshot, not a setup guide." |
| **TODO.md** | "What work is outstanding?" | The backlog. Done items are checked and annotated with a **"Done:"** note naming the artifact + its doc; separate sections for future/"pipedream" and manual/no-AI work. | Narrative status (that's HANDOFF) and how-to (that's docs). |

How they stay in sync / avoid duplication (as practiced):

- **README's documentation table is the single index** of every `docs/` topic — one row per
  file, with location and one-line description. Other docs link to topics; they don't restate
  the index.
- **HANDOFF points, doesn't restate.** Its "Where everything lives" section routes to the
  authoritative sources (a status registry doc, the README doc table, CLAUDE.md + `.claude/docs`
  for Claude workflow, TODO.md for backlog, a known-issues doc for gotchas) instead of copying
  their content. It carries a "Prepared / last updated" date.
- **HANDOFF explicitly bridges to the Claude layer**: it tells a human successor that
  "How Claude should work in this repo → CLAUDE.md and the `.claude/docs/` tree", making the
  two-audience split visible.
- **TODO's "Done:" notes are the changelog** that keeps the backlog honest and links work to
  the docs/tools it produced.
- A per-domain **authoritative registry doc** (in the reference, `docs/TESTED_APPS.md`) holds
  live status with "last verified" dates, so status lives in exactly one place and HANDOFF/README
  link to it.

**Relationship to CLAUDE.md:** CLAUDE.md never duplicates the human docs. It references
`docs/` files (with "Read when/Contains") only where a human topic is *also* useful to Claude
(e.g. the smoke-subset and maintainer ledgers). The two trees are parallel, cross-linked, and
audience-separated.

---

## 10. Conventions, Gotchas & Best Practices to Carry Forward

- **Commit `.claude/`; gitignore only scratch + local + secrets.** This is the keystone
  decision — it makes agents/docs/tools travel with the repo and with every worktree checkout.
- **Two-audience discipline.** Claude-facing content lives in `CLAUDE.md` + `.claude/`;
  human-facing content in `README`/`HANDOFF`/`TODO`/`docs`. Never blur them; cross-link instead.
- **Router + on-demand docs, not one giant file.** Keep CLAUDE.md lean; every deep topic is a
  separate `.claude/docs/` file reached by a "Read when" trigger.
- **One canonical owner per fact; defer everywhere else.** State "this is the canonical source
  for X" and link back instead of duplicating.
- **Author/audit agent pairs**, `sonnet` for authoring and `opus` for judgment, with audit
  agents strictly report-only and grounded in a real past failure.
- **Agent `description` = dispatch logic.** Always include "use `<sibling>` instead when…".
- **Automate conventions into `lint`/`fix` tools**, pair each tool with a guide, and let agents
  delegate the mechanical checks to the tool.
- **Notes are disposable**; promote durable findings into docs and delete the note.
- **EOL + markdownlint gotcha (reference-specific, but general in spirit):** the working tree is
  CRLF via `.gitattributes`; external formatters (e.g. `markdownlint --fix`) can write lone LFs.
  After any bulk rewrite, check for and fix EOL stragglers. Configure markdownlint to match your
  line-width convention (disable `MD013`) and to ignore backups/generated dirs.
- **Keep `CLAUDE.md` a labeled "Living Document"** with explicit update triggers, and snapshot
  old versions into a gitignored `CLAUDE.md_backups/`.
- **What the reference deliberately omits:** no hooks, no statusline, no custom slash commands,
  no committed `settings.json`, no skills. If you don't need them, leaving them out is faithful
  to this setup.

---

## 11. Quickstart Checklist — Bootstrap in a New Repo

Ordered steps to stand up the same system from scratch:

1. **Create the human docs first (or in parallel):**
   - `README.md` with a **documentation index table**, install steps, and a project-structure tree.
   - `docs/` with one file per topic, starting with `docs/ONBOARDING.md` (clone → first success).
   - `TODO.md` (backlog; adopt the checked-item "Done:" note convention).
   - `HANDOFF.md` (dated snapshot that *points* at the above instead of restating them).
2. **Create `.claude/` and its subdirs:** `agents/`, `docs/` (with `app-references/`,
   `tool-references/`, and any workflow-group subfolders), `tools/`, `notes/`.
3. **Write `CLAUDE.md` at the root** using the §3 skeleton:
   - `# Title` + `> Living Document` note with your update triggers.
   - `## Reference Files` — one **Read when / Contains** entry per `.claude/docs/` file, plus
     the `.claude/agents/` and `.claude/tools/` index entries. State the "`.claude/` is tracked;
     read-before-you-act" policy.
   - `## Critical Rules` — one-line invariants with `--` justifications.
   - `## Naming Conventions`.
4. **Configure git & lint:**
   - `.gitignore`: add the "commit `.claude/`, exclude scratch/local/secrets" block
     (`.claude/CLAUDE.md_backups/`, `.claude/settings.local.json`, secret files).
   - `.gitattributes`: pin EOL (`* text=auto eol=crlf` on Windows; images `binary`).
   - `.markdownlint-cli2.jsonc`: set `globs`, `ignores` (backups + generated dirs), and disable
     `MD013` if using wide lines.
5. **Author subagents** in `.claude/agents/<name>.md` — frontmatter (`name`, `description` with
   sibling-dispatch clause, `model`, `color`) + a full system-prompt body (identity → contract →
   checks → what-is-NOT → output format → scope). Pair authoring agents with audit agents.
6. **Build tools** in `.claude/tools/` as needed; pair each with a
   `.claude/docs/tool-references/<tool>-guide.md` and index it in CLAUDE.md. Automate any
   mechanically-checkable convention into a `lint`/`fix` script.
7. **Create `.claude/settings.local.json`** (gitignored) and seed `permissions.allow` with your
   constant commands (interpreter/venv path, your tools, `git` subcommands, linters). Grow it as
   prompts occur.
8. **Maintain:** promote durable notes from `.claude/notes/` into docs and delete them; close
   TODO items with "Done:" notes; keep README's doc table and CLAUDE.md's index in sync as you
   add docs/agents/tools; re-date HANDOFF when project state shifts.

> Note the intentional omissions if you're matching this setup exactly: no `.claude/commands/`,
> no hooks, no statusline, no committed `settings.json`, no skills.

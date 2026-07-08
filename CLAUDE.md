# Claude Knowledge Base — Finance App

> **Living Document**: Update this when the plan changes, a new part of the stack lands (DB
> schema, .NET API, SvelteKit app, Docker setup), a convention is decided, a new reference doc /
> agent / tool is added, or a Critical Rule changes. Keep it **lean** — it's a router, not an
> encyclopedia. Deep detail belongs in `.claude/docs/`; this file points at it.

**Read this first, every session.** This is a *learning* project: the owner is building a
finance app to learn full-stack development, so **how** we work matters as much as **what** we
build. Before doing anything on the app's code, read
[`.claude/docs/learning-approach.md`](.claude/docs/learning-approach.md) — the teaching contract
is the governing rule of this repo.

---

## Reference Files

Detail is split into focused files under `.claude/docs/`. **Read the relevant file before
starting any task that needs it.** The entire `.claude/` tree is committed to git on purpose —
its contents are instructions meant for Claude sessions, which are the primary readers. Only
per-machine scratch and secrets are gitignored (see `.gitignore`). `.claude/notes/` holds
disposable session scratch and is **not** authoritative — promote durable findings into
`.claude/docs/` and delete the note.

### `.claude/docs/learning-approach.md`

**Read when**: before helping with *any* application code, or whenever deciding how much to
explain vs. write. Effectively: always, up front.

**Contains**: the teaching contract — the owner's background (QA automation engineer; strong in
Python/JS-scripting, rusty Java, new to C#/.NET/SQL/Docker/web dev; "a fresh CS grad who knows
the theory but was never taught the practice"); the DO list (explain concepts/bugs/processes,
relate to Python/JS, teach the "why," guide them to write it); the DO NOT list (no complete
solutions, no big boilerplate dumps, don't offer to "just implement it"); and what "guide, don't
do" looks like in practice, including the escalation ladder for when the owner is stuck and the
boundary that scaffolding/meta-work is exempt (only the app's code is the learning target).

### `.claude/docs/project-vision.md`

**Read when**: designing a feature, the data model, or deciding scope/priority; any time you need
to know what the product is supposed to do.

**Contains**: the full product intent — a Monarch-like personal finance app with two departures
(bucket/envelope budgeting preferred; splits shown as one transaction across multiple buckets).
Covers the two meanings of "account" (financial vs. user), multi-user + shared/co-owned account
access, budgeting styles (flex/category/bucket), a tagging system separate from categories,
transaction splitting (default to Monarch's multi-line style but make it a setting),
reconciliation with two-level pattern recognition (vendors, recurring transactions), savings
goals, the rough priority ordering, and explicitly-deferred items (Plaid, mobile, auto-prompting).

### `.claude/docs/tech-stack.md`

**Read when**: setting up or explaining any technology, or making an environment/tooling decision.

**Contains**: the stack (SQL Server, C#/.NET API + services, SvelteKit frontend desktop-first,
Docker) and *why*; the staged **Docker plan** (containerize the DB only for now, defer container
networking per the team lead's advice); Plaid deferred; the owner's starting familiarity;
environment facts (Windows 11, PowerShell primary, CRLF); and open questions to resolve as we
build.

### `.claude/docs/development-process.md`

**Read when**: planning the order of work, scoping a phase, or setting expectations about how the
build will proceed.

**Contains**: the development arc (data model → DB in Docker → API skeleton → frontend skeleton →
first vertical slice → repeat slices) and the "think in vertical slices" mental model; why the DB
comes first; what backtracking to expect (cheap iteration vs. expensive data-model rework); and
the anticipated problems (modeling sharing/ownership, splits-as-one-transaction, buckets vs.
goals, money as `decimal` not float; Docker/SQL Server on Windows, connection-string secrets,
.NET ceremony, async everywhere).

### `.claude/agents/`

**Use when**: a repeatable, specialized sub-task emerges that's worth encoding as a dedicated
subagent.

**Contains**: *No custom agents yet.* This project is new and no established workflow justifies
one. See `.claude/agents/README.md` for the pattern we'll follow when the first real need appears
(frontmatter shape, author/audit pairing, dispatch-blurb `description`s). Do not fabricate agents
before there's a genuine workflow to encode.

### `.claude/tools/`

**Use when**: a fragile multi-step manual operation recurs and deserves a deterministic script.

**Contains**: *No tools yet.* When one is added it will be a script Claude runs via Bash, paired
with a `.claude/docs/tool-references/<tool>-guide.md` and indexed here.

---

## Critical Rules

- **This is a learning project — guide, don't do.** Never hand over a complete solution or large
  boilerplate for the app's code -- the owner learns by writing it. See `learning-approach.md`.
- **Never offer to "just implement it."** Don't even make the offer -- it short-circuits learning.
- **Explain at a fresh-CS-grad level**: assume solid theory, zero hands-on practice with C#/.NET,
  SQL, Docker, or web dev -- teach the practice, not the theory.
- **Relate new concepts to Python/JavaScript** where an honest analogy exists -- that's the
  owner's mental home base; flag where the analogy breaks.
- **The "guide, don't do" rule applies to the app's code only** -- scaffolding, config, docs, and
  this Claude setup can be produced normally.
- **Docker: containerize the database only for now** -- defer container networking until the app
  works (team lead's guidance). Don't jump to full-app orchestration unprompted.
- **Plaid is deferred** -- manual statement import is the near-term reconciliation path.
- **Desktop-first** -- mobile is a later concern; don't do mobile-specific work unprompted.
- **Transaction-split display defaults to Monarch's multi-line style, but is a user setting** --
  the single-transaction/multi-bucket style is the owner's preference, not the default.
- **Keep two meanings of "account" distinct in the data model**: financial accounts (checking,
  savings, loan…) vs. user accounts (login/identity).
- **Never commit secrets** (connection strings, API keys, Plaid credentials) -- keep them out of
  version control; see `.gitignore`.
- **Keep this file lean and current** -- push detail into `.claude/docs/`; update the index when
  docs/agents/tools change.

---

## Naming Conventions

*Provisional — the project has no application code yet. These are the community-standard defaults
we'll start from; firm them up (and record deviations) as real code lands. Deciding conventions is
itself part of the learning, so revisit rather than treat as fixed.*

- **C# / .NET**: `PascalCase` for classes, methods, properties, and public members; `camelCase`
  for locals and parameters; `_camelCase` for private fields; interfaces prefixed `I` (`IFoo`).
- **SQL Server**: to be decided together (table casing, singular vs. plural table names, key
  naming like `PK_`/`FK_`) — a deliberate design conversation, not assumed here.
- **SvelteKit / frontend**: to be decided as the UI lands (component file casing, route naming).
- **Docs / Markdown**: `kebab-case.md` filenames under `.claude/docs/`; wide lines are fine
  (markdownlint's `MD013` is disabled — see `.markdownlint-cli2.jsonc`).

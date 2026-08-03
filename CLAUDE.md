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
Covers the two meanings of "account" (financial vs. user); **group-based ownership** (settled: a
`UserGroup` owns accounts and lists; a solo user is a group of one) and the still-open
account master-ownership problem; the **two-tier merchant/category model** (curated master list +
per-group customization, inherit-by-NULL for merchants vs. copy-on-provision for categories) and why
they differ; the **sign convention** and the **date/time-zone** decision; budgeting styles
(flex/category/bucket), a tagging system separate from categories, transaction splitting (default to
Monarch's multi-line style but make it a setting), reconciliation with two-level pattern recognition
(vendors, recurring transactions), savings goals, the rough priority ordering, and
explicitly-deferred items (everything auth-dependent, Plaid, mobile, auto-prompting).

### `.claude/docs/tech-stack.md`

**Read when**: setting up or explaining any technology, or making an environment/tooling decision.

**Contains**: the stack (SQL Server, C#/.NET API + services, SvelteKit frontend desktop-first,
Docker) and *why*; the staged **Docker plan** (containerize the DB only for now, defer container
networking per the team lead's advice); Plaid deferred; the owner's starting familiarity;
environment facts (Windows 11, PowerShell primary, CRLF); and open questions to resolve as we
build.

### `.claude/docs/api.md`

**Read when**: working on anything in `Api/` — the .NET web API, EF Core entities/context,
endpoints, connection strings, or NuGet packages.

**Contains**: the API layer as built — single-project layout (`Api/`, minimal APIs, .NET 10); how
to run it (ports, `curl`/`Invoke-RestMethod`); **EF Core in read/map mode with the dacpac as the
sole schema authority (never generate EF migrations)**; entity/context conventions (namespaces,
one file per entity in `Api/Entities/`, nullability mirrors the schema, singular `DbSet`s,
composite-key config, map `DbSet`s per slice, navigation properties, and DTOs/projections in
`Api/Contracts/`); connection-string + User-Secrets handling and the `,`-vs-`;`
and `TrustServerCertificate` gotchas; and NuGet audit/pin notes.

### `.claude/docs/frontend.md`

**Read when**: working on anything in `SvelteKit/` — the SvelteKit app, routes/pages, components,
data loading against the API, styling, or frontend tooling (npm scripts, Vite, prettier/eslint).

**Contains**: the frontend layer as built — single-app layout (`SvelteKit/`, `sv` CLI minimal
template, TypeScript, Svelte 5, Vite); package-manager choice (**npm**; yarn/pnpm rationale);
how to run it (`npm run dev`/`build`/`check`/`lint`/`format`, the `npm run` front-door and the
`svelte-check`-not-`tsc` gotcha); filesystem routing and the `+`-prefixed special files;
conventions (TS everywhere, `camelCase`/`PascalCase`, TS inference, **Svelte 5 `$state` runes for
reactivity**, scoped styles); **plain-CSS-before-Tailwind** and **testing-deferred** decisions;
and the open first-slice work (data loading against `/accounts`, CORS).

### `SETUP.md` (repo root)

**Read when**: standing up the local environment from scratch — installing the toolchain, running
SQL Server in Docker, and publishing the database — or updating any of those steps.

**Contains**: the human-facing setup runbook. Prerequisites (.NET SDK, Docker Desktop, sqlpackage);
building the dacpac; creating `db.env` from the committed `db.env.example` (secret stays out of
git); the once-only `docker run` (afterward `docker start financedb`); publishing via
`MSSQL\PublishSqlPackage.ps1`; SSMS connection settings (`localhost,1433` + trust the self-signed
cert); and a verify query. All commands run from the repo root.

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
  savings, loan…) vs. user accounts (login/identity). **Same rule for "group"**: `UserGroup` is the
  ownership/sharing unit; a *category* grouping is a `CategorySet` — never "CategoryGroup".
- **The ownership unit is a `UserGroup`, not a user.** Financial accounts, merchant lists, and
  category lists all belong to a group; a solo user is a group of one. **No authentication exists
  yet**, so writes hardcode the seeded dev group (`GroupId = 1`). Don't design membership, roles, or
  account master-ownership until auth lands — see `project-vision.md`.
- **Sign convention: spending is negative, transfers in are positive.** Credit/loan accounts flip
  **cosmetically at the display layer only** — never in the API or the DB.
- **Never commit secrets** (connection strings, API keys, Plaid credentials) -- keep them out of
  version control; see `.gitignore`.
- **Keep this file lean and current** -- push detail into `.claude/docs/`; update the index when
  docs/agents/tools change.

---

## Naming Conventions

*Firm these up (and record deviations) as real code lands; deciding conventions is itself part of
the learning, so revisit rather than treat as fixed. **SQL Server** conventions below are settled
from the `MSSQL/` schema and **C#/.NET** conventions are now settling from the `Api/` project (see
`api.md`); **frontend** conventions are now settling from the `SvelteKit/` project (see
`frontend.md`).*

- **C# / .NET** (settling — see `Api/` and [`api.md`](.claude/docs/api.md)): `PascalCase` for
  classes, methods, properties, and public members; `camelCase` for locals and parameters;
  `_camelCase` for private fields; interfaces prefixed `I` (`IFoo`). File-scoped `namespace`
  matching the folder path (`Api.Entities`, `Api.Data`, `Api.Contracts`); one public type per file
  (pragmatic exception: a small cluster of tightly-related DTOs may share a file named for the
  concept). EF entities (`Api/Entities/`) mirror their table one-for-one, including column
  nullability **and datetime kind** (`DATETIMEOFFSET` → `DateTimeOffset`, `DATETIME2` → `DateTime`) —
  mismatches surface at runtime on the first query, never at build; DTOs (`Api/Contracts/`, suffixed
  `…Dto`/`…Li`) are the API's response shapes, kept distinct from entities and built per-slice.
- **SQL Server** (settled — see `MSSQL/`):
  - *Names*: `PascalCase` tables and columns; **singular** table names (`Account`, `LedgerEntry`).
    Rename around reserved words (`EndUser` not `User`, `LedgerEntry` not `Transaction`). UTC
    datetime columns take a `Utc` suffix (`LastModifiedUtc`) — and **only** those, so a column
    carrying an offset must *not* (`UserDate`, not `UserDateUtc`). Curated/global tier tables are
    prefixed `Default` (`DefaultCategory`); per-group tables carry `GroupId`.
  - *Keys*: surrogate `Id INT IDENTITY(1,1)`; composite PK for pure junction tables (`GroupMember`).
    A redundant-looking `UNIQUE (GroupId, Id)` exists purely to be a legal **composite FK target** —
    SQL Server only accepts FK targets it can prove unique.
  - *Constraints (always named, never auto-named)*: `PK_<Table>`, `FK_<Child>_<Parent>` (add
    `_<Column>` when a table has multiple FKs to one parent), `UQ_<Table>_<Column(s)>`,
    `DF_<Table>_<Column>`, `CK_<Table>_<Column>`. Unique **indexes** take the same `UQ_` prefix as
    unique constraints (intent over mechanism) — and a *filtered* unique index has to be an index,
    since constraints can't carry a `WHERE`. **When renaming a table, rename its constraints too**;
    they've drifted twice.
  - *Types*: money `DECIMAL(19,4)`; booleans `BIT`; `NVARCHAR(n)` for human-entered text,
    `VARCHAR(n)` for ASCII-only (email, hashes); always explicit `NULL`/`NOT NULL`. Small, fixed,
    code-owned enums as `TINYINT` + a `CHECK` range constraint (not a lookup table); use a lookup
    table + FK only when the set is user-editable data.
  - *Two kinds of datetime, and the distinction is load-bearing*: **user-meaningful** times
    (when a transaction happened) are `DATETIMEOFFSET`; **system/audit** timestamps are `DATETIME2`
    in UTC. An offset is not a time zone — see `project-vision.md`.
  - *Seeding*: `Script.PostDeployment.sql` runs **top-to-bottom imperatively** (unlike the schema
    build, which resolves dependency order itself), and is **not** semantically validated at build
    time — a stale seed script compiles fine and fails at publish. Never reference an
    `IDENTITY`-assigned id by a hardcoded literal; look rows up by a stable business key
    (`(GroupId, DefaultId)`), because `INSERT … SELECT` assigns ids in arbitrary join-output order.
  - *Project*: schema-as-code via a `Microsoft.Build.Sql` project, built to a dacpac and published
    with `sqlpackage`; one file per object under `Tables/`; idempotent seed/reference rows in
    `Script.PostDeployment.sql` (ensure-exists for sentinels, seed-if-empty for starter content).
- **SvelteKit / frontend** (settling — see `SvelteKit/` and [`frontend.md`](.claude/docs/frontend.md)):
  **TypeScript** everywhere (`<script lang="ts">`); `camelCase` for variables/functions,
  `PascalCase` for components and types; let TS infer obvious literals. Reactivity is explicit via
  **Svelte 5 runes** — mutable UI state uses `$state()`, unchanging values stay `const`. Routing is
  filesystem-based; `+`-prefixed files (`+page`, `+layout`) are SvelteKit-special. Component
  `<style>` is scoped by default. Plain CSS before Tailwind.
- **Docs / Markdown**: `kebab-case.md` filenames under `.claude/docs/`; wide lines are fine
  (markdownlint's `MD013` is disabled — see `.markdownlint-cli2.jsonc`).

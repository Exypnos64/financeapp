# TODO / Backlog

Outstanding work, roughly priority-ordered. This is the backlog; narrative status lives in the
README, product detail in `.claude/docs/project-vision.md`.

**Convention**: when an item is finished, check it off and append a **`Done:`** note pointing at
what was produced (the code/doc/artifact). That turns this file into a lightweight changelog.

## Project setup

- [x] Establish Claude Code working setup (`CLAUDE.md`, `.claude/docs/`, git & lint config).
  Done: `CLAUDE.md`, `.claude/docs/{project-vision,tech-stack,learning-approach}.md`, `.gitignore`,
  `.gitattributes`, `.markdownlint-cli2.jsonc`, `CLAUDE-SETUP-GUIDE.md`.

## Foundations (learn-as-we-go, roughly in order)

- [ ] **Database design** — model financial accounts + transactions, multi-user-aware from the
  start (keep "financial account" vs. "user account" distinct). Decide SQL naming conventions.
- [ ] **Docker: containerize SQL Server** — DB only for now; API/frontend stay on the host. Defer
  container networking (team lead's guidance).
- [x] **.NET API skeleton** — stand up the C# web API and connect it to the containerized DB.
  Done: `Api/` project (single project, minimal APIs, .NET 10); EF Core read/map against the dacpac
  schema; `GET /accounts` returns `Account` rows from the containerized DB as JSON. See
  `.claude/docs/api.md`.
- [x] **SvelteKit frontend skeleton** — desktop-first; talk to the .NET API.
  Done: `SvelteKit/` app (`sv` CLI minimal template, TypeScript, Svelte 5, Vite; npm; prettier +
  eslint). Renders the default page with working HMR via `npm run dev`; does not call the API yet.
  See `.claude/docs/frontend.md`. (Talking to the API is the next item.)
- [ ] **Show transaction data** end-to-end (DB → API → UI).

## Core features

- [ ] **Manual statement import** — bring bank report/export data in.
- [ ] **Reconciliation** — match imported bank data against manually-entered transactions.
- [ ] **Budgeting — bucket/envelope first** (owner's preference), then category, then flex.
- [ ] **Vendor pattern recognition** — canonicalize vendors from transaction descriptions.
- [ ] **Tagging system** — independent of categories/buckets.
- [ ] **Transaction splitting** — one transaction, multiple buckets; setting to toggle Monarch-style
  multi-line display (default) vs. single-line (preferred).
- [ ] **Multi-user + shared/co-owned account access** — group-based access, temporary/permanent
  grants, co-ownership of shared accounts.
- [ ] **Savings goals** — resolve how they differ from buckets technically; work under all/none
  budgeting types.

## Later / deferred (not now)

- [ ] **Recurring-transaction expectation & look-ahead**, then auto-anticipation + prompting.
- [ ] **Plaid integration** (replace manual import) — pending clarity on free-tier limits.
- [ ] **Mobile** support.

# TODO / Backlog

Outstanding work, roughly priority-ordered. This is the backlog; narrative status lives in the
README, product detail in `.claude/docs/project-vision.md`.

**Convention**: when an item is finished, check it off and append a **`Done:`** note pointing at
what was produced (the code/doc/artifact). That turns this file into a lightweight changelog.

## Project setup

- [x] Establish Claude Code working setup (`CLAUDE.md`, `.claude/docs/`, git & lint config).
  Done: `CLAUDE.md`, `.claude/docs/{project-vision,tech-stack,learning-approach}.md`, `.gitignore`,
  `.gitattributes`, `.markdownlint-cli2.jsonc`, `CLAUDE-SETUP-GUIDE.md`.
- [x] **One-key local startup** — start the DB container, API, and frontend dev server together with
  debuggers attached, instead of three terminals.
  Done: committed `.vscode/launch.json` (`API (.NET)`, `Web (SvelteKit)`, `Full stack` compound) and
  `.vscode/tasks.json` (`db: start`, `api: build`, `api: prelaunch`). See
  `.claude/docs/editor-debugging.md`; `SETUP.md` step 14.

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
- [x] **Show transaction data** end-to-end (DB → API → UI).
  Done: `/transactions` and `/accounts` render API data; `/transactions/new` writes back through a
  `+page.server.ts` form action, closing the loop in both directions. Supporting work:
  `GET /merchants` + `GET /categories` picker endpoints, `Merchant`/`Category`/`CategorySet`
  frontend types, and seeded `GroupMerchant` rows. See `.claude/docs/{api,frontend}.md`.
- [x] **Scope read endpoints to the owning group.** `GET /transactions` and `GET /accounts` returned
  every group's rows — no `GroupId` filter — and `const int DevGroupId = 1;` was duplicated across
  three handlers.
  Done: `OwnedBy(groupId)`, a generic `IQueryable<T>` extension (`Api/Data/GroupOwnedQuery.cs`)
  constrained to a new `IGroupOwned` marker interface (`Api/Entities/IGroupOwned.cs`, implemented by
  the six group-owned entities), applied by all four read endpoints and by the three ownership guards
  in `POST /transactions`; the duplicated constant collapsed into `Api/Data/TempDefaults.cs`. See
  `.claude/docs/api.md` → Current state.
- [ ] **Edit + delete a transaction** — the next slice. `GET /transactions/{id}`,
  `PUT /transactions/{id}` and `DELETE /transactions/{id}`, plus an edit page on the frontend. First
  use of EF **change tracking** (every query so far is read-only), route parameters, and the
  `404`-vs-`422` split — keeping "doesn't exist" and "isn't yours" indistinguishable to the caller,
  as the POST guards already do. Completes CRUD, which the later features all build on. Open design
  call: one form component shared by create *and* edit, or two separate pages.
- [ ] **Move the API base URL out of the source.** `http://localhost:5046` is now a hand-declared
  `API_BASE` constant in three frontend files. SvelteKit's `$env/static/public` is the home for it —
  note the server-only load could use `$env/static/private`, but the universal loads in `+page.ts`
  run in the browser too and therefore need the `PUBLIC_` prefix.
- [ ] **Progressively enhance the entry form** with `use:enhance` (submit without a full page
  reload). Blocked on a real trap: the form's `$state` initializers read `form?.values?.…`, which
  only works today *because* a native POST is a full navigation that rebuilds the component.
  `use:enhance` updates props in place, so those initializers stop re-running — which is exactly
  what the seven `state_referenced_locally` warnings were pointing at.
- [ ] **Decide whether duplicate category-set names are allowed.** `CategorySet.Name` has no unique
  constraint, so one group can hold two sets called "Bills" — which would merge into a single
  `<optgroup>` if the UI ever grouped by name. The dropdown groups by `SetId` specifically to avoid
  depending on the answer. If duplicates *are* a data-entry mistake, `UQ_CategorySet_GroupId_Name`
  is the constraint that says so.
- [ ] **Styling pass.** Every page is unstyled HTML; the entry form lays out with `<br>` tags. Plain
  scoped CSS first (per `frontend.md`), once the screens settle.

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

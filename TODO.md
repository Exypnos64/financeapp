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
- [x] **Edit + delete a transaction** — completes CRUD.
  Done: `GET`/`PUT`/`DELETE /transactions/{id}` in `Api/Endpoints/TransactionEndpoints.cs`, the
  first use of EF **change tracking**; an `ITransactionInput` interface and a shared
  `ValidateTransaction` reused by POST and PUT; `TransactionDto` (the full row, for the edit form)
  and `UpdateTransactionRequest` (editable fields only) in `Api/Contracts/`. Frontend:
  `/transactions/[id]` with `?/update` and `?/delete` named actions, `formaction` +
  `formnovalidate` on the Delete button, and an Edit link on every list row. See
  `.claude/docs/{api,frontend}.md`.
- [ ] **Extract a shared `TransactionForm` component.** `/transactions/new` and
  `/transactions/[id]` are now near-identical — the same selects, inputs and `<optgroup>` logic in
  two files, so every styling change would land twice. **Settled**: the component owns the `<form>`
  element and takes an `action` prop; the read-only block (`originalStatement`, `originalDate`,
  `lastModifiedUtc`) and the submit/delete button group toggle **separately** — one flag would do
  today, but two keeps the pages independently customizable. Lives at
  `src/lib/components/TransactionForm.svelte`. Carries the trap below.
- [ ] **Re-initialize the form when the transaction id changes.** Same root cause as the
  `use:enhance` item: `$state(data.transaction.accountId)` captures a value **once**. Today every
  arrival is a full page load, so it works. Once the fields live in one component, navigating
  `/transactions/2` → `/transactions/3` reuses the instance and only updates props — the
  initializers never re-run, so you would edit transaction 3 with transaction 2's values loaded. A
  `{#key}` block around the component is the Svelte answer; settle it when the component lands.
- [ ] **Extract the duplicated form-action logic.** `new/+page.server.ts` and `[id]/+page.server.ts`
  share their `formData` parsing, number coercion and `userDate` guard verbatim. Belongs under
  `src/lib/server/`, which SvelteKit refuses to let client code import.
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

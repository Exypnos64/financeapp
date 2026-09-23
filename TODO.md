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

- [x] **Database design** — model financial accounts + transactions, multi-user-aware from the
  start (keep "financial account" vs. "user account" distinct). Decide SQL naming conventions.
  Done: `MSSQL/` schema-as-code (`FinanceDb.sqlproj`, one file per object under `Tables/`) — eleven
  tables covering group ownership (`UserGroup`, `EndUser`, `GroupMember`), financial accounts
  (`Account`), transactions (`LedgerEntry`), and the two-tier merchant/category model
  (`Merchant`/`GroupMerchant`, `Category`/`CategorySet` over `DefaultCategory`/`DefaultCategorySet`),
  plus idempotent seed/reference rows in `Script.PostDeployment.sql`. The two meanings of "account"
  stay distinct (`Account` vs. `EndUser`), as do the two meanings of "group" (`UserGroup` vs.
  `CategorySet`). SQL naming conventions are settled and recorded in `CLAUDE.md` → Naming
  Conventions → SQL Server.
- [x] **Docker: containerize SQL Server** — DB only for now; API/frontend stay on the host. Defer
  container networking (team lead's guidance).
  Done: the `financedb` container (`mcr.microsoft.com/mssql/server:2022-CU14-ubuntu-22.04`, port
  1433, named volume `financedb-data`, SA password supplied from the gitignored `db.env`), created
  once per `SETUP.md` step 6 and started with `docker start financedb` thereafter; the dacpac
  publishes into it via `MSSQL\PublishSqlPackage.ps1`. VS Code's `db: start` task brings it up as an
  F5 prelaunch step — see `.claude/docs/editor-debugging.md`. The API and frontend still run on the
  host; container networking remains deliberately deferred.
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
- [x] **Extract a shared `TransactionForm` component.** `/transactions/new` and
  `/transactions/[id]` were near-identical — the same selects, inputs and `<optgroup>` logic in two
  files, so every styling change would land twice.
  Done: `src/lib/components/TransactionForm.svelte` owns the `<form>` and takes `accounts`,
  `categories`, `merchants`, an optional `transaction`, `form`, an `action` prop, and **separate**
  `showReadOnly`/`showDelete` flags. The two pages dropped to 12 and 17 lines. The edit route was
  renamed `[id]` → `[id]/edit` in the same pass so the directory tree names the page for the next
  dev; `resolve()` turned the stale list-page link into a compile error rather than a runtime 404.
  See `.claude/docs/frontend.md`.
- [x] **Re-initialize the form when the transaction id changes.** `$state(prop)` captures a
  value **once**, so navigating `/transactions/2/edit` → `/transactions/3/edit` reused the component
  instance and only updated props — the initializers never re-ran, and you would edit transaction 3
  through transaction 2's values.
  Done: `{#key data.transaction.id}` wraps `<TransactionForm />` in `[id]/edit/+page.svelte`.
  Reproduced first with temporary prev/next links (the UI offers no id→id navigation), then
  confirmed fixed and the links removed. Keyed on the **id**, not the `transaction` object — `load`
  parses a fresh object per navigation, so keying on identity would remount on every visit.
- [x] **Extract the duplicated form-action logic.** `new/+page.server.ts` and
  `[id]/edit/+page.server.ts` shared their `formData` parsing, number coercion and `userDate` guard
  verbatim.
  Done: `src/lib/server/transactions.ts` holds `validateTransaction` (returns a discriminated
  `{ ok: true, body } | { ok: false, failure }`, because `fail()` only works when the **action**
  returns it) and `handleTransactionResponse` (redirect on success, `fail` otherwise). Imported as
  `$lib/server/transactions` and deliberately **not** re-exported through `$lib/index.ts` — the
  barrel is client-reachable, so routing server code through it would defeat SvelteKit's guard. The
  shared types stay in `src/lib/types.ts`, since `TransactionForm.svelte` imports
  `TransactionFormFailure`.
- [x] **Move the API base URL out of the source.** `http://localhost:5046` was a hand-declared
  `API_BASE` constant in four frontend files.
  Done: `PUBLIC_API_BASE` in a **committed** `SvelteKit/.env`. It is non-secret by construction —
  `PUBLIC_` values are inlined into the client bundle — and `$env/static/public` resolves at *build*
  time, so a fresh clone without the file fails to build rather than merely misconfiguring. Read in
  exactly one place (`src/lib/api.ts`); all nine call sites go through the new `ApiLoader`, which
  owns the base URL and the request-scoped `fetch`. Anything genuinely private belongs in
  `.env.local`, already gitignored. Gotcha worth remembering: the negation had to go in
  `SvelteKit/.gitignore`, because a nested `.gitignore` overrides its parents — `git check-ignore -v
  <path>` names the deciding file and line.
- [x] **Progressively enhance the entry form** with `use:enhance` (submit without a full page
  reload).
  Done: one import and `use:enhance` on the `<form>` in `TransactionForm.svelte` — two lines, the
  whole code change. The anticipated trap **was not one**. The worry was that the `$state`
  initializers reading `form?.values?.…` would stop re-running once a failed submit no longer
  remounts the component; in fact the fields are `bind:value`-bound, so on the enhanced path the
  typed values never leave the DOM and there is nothing to restore. Those reads are now live for the
  **no-JS path only**, where the browser genuinely does discard the form — which also turns the
  seven `svelte-ignore state_referenced_locally` comments into accurate descriptions ("read once, at
  mount") rather than suppressions. The real finding was elsewhere: an enhanced `fail()` comes back
  **HTTP 200** wrapping the status in a JSON envelope. Both submit paths and both buttons verified
  with DevTools’ "Disable JavaScript". See `.claude/docs/frontend.md`.
- [x] **Make transaction creates idempotent** — the prerequisite `project-vision.md` set for
  statement import, since a failed response does not mean a failed write and a retried POST
  double-entered the transaction.
  Done: `LedgerEntry.IdempotencyKey` (`UNIQUEIDENTIFIER NOT NULL`, no default,
  `UQ_LedgerEntry_GroupId_IdempotencyKey`); `CreateTransactionRequest.IdempotencyKey` is a required
  `Guid`. `POST /transactions` looks the key up first, then catches the unique violation (2627) for
  the concurrent case. Same key and body returns the original row, a different body is a `409`. The
  frontend mints the key in `new/+page.server.ts`'s `load` and a failed submit keeps its old key.
  `Api/Api.http` sends `{{$guid}}` on every POST, plus a fixed-key replay/conflict suite. The slice
  also fixed a **pre-existing no-JS date bug**: the hidden field now carries only the browser's offset
  and the server builds the date in `src/lib/dates.ts`, falling back to the server's offset without
  JS. See `.claude/docs/{api,frontend}.md`.
- [ ] **Decide whether duplicate category-set names are allowed.** `CategorySet.Name` has no unique
  constraint, so one group can hold two sets called "Bills" — which would merge into a single
  `<optgroup>` if the UI ever grouped by name. The dropdown groups by `SetId` specifically to avoid
  depending on the answer. If duplicates *are* a data-entry mistake, `UQ_CategorySet_GroupId_Name`
  is the constraint that says so.
- [ ] **Styling pass.** Every page is unstyled HTML; the entry form lays out with `<br>` tags. Plain
  scoped CSS first (per `frontend.md`), once the screens settle.

## Core features

- [ ] **Manual statement import** — bring bank report/export data in. Imported rows need an
  idempotency key **derived from the source line** (deterministic), not a random one — otherwise
  importing the same file twice duplicates every row. See `project-vision.md`.
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

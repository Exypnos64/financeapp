# API — .NET Backend

The C#/.NET web API. This is the layer between the SQL Server database (`MSSQL/`) and the
(future) SvelteKit frontend. Reflects what actually landed in the `api-skeleton` work; update it
as the API grows.

> The API is **the owner's learning target** — C#/.NET/EF are new to them. Read
> [`learning-approach.md`](learning-approach.md) before touching `Api/` code: guide, don't do.
> (This doc itself is meta/scaffolding and may be edited normally.)

## Project layout

- **Single project**, `Api/`, a root-level sibling of `MSSQL/`. Created with
  `dotnet new webapi` (minimal APIs, **not** controllers) targeting **.NET 10**.
- Deliberately started as one project rather than a multi-project solution — splitting into
  layers later is cheap backtracking, and the skeleton didn't justify the ceremony. Revisit if/when
  a domain/data separation earns its keep.
- **Minimal APIs** over controllers for the same reason: less ceremony, closest to the owner's
  FastAPI mental model. Endpoints are mapped in `Program.cs`.
- Folders: `Api/Entities/` (EF entities — POCOs mirroring tables), `Api/Data/` (the `DbContext`),
  `Api/Contracts/` (DTOs — the API's outward-facing response shapes).

## Running it

From `Api/`:

```powershell
dotnet run          # starts the server (holds the terminal)
dotnet build        # compile-check only
```

- Ports (see `Api/Properties/launchSettings.json`): `http://localhost:5046`,
  `https://localhost:7016`. `launchSettings.json` is dev-only, never deployed.
- Hit endpoints from **Bash** with `curl http://localhost:5046/accounts`, or from **PowerShell**
  with `Invoke-RestMethod` (note: `curl` in PowerShell is an alias for `Invoke-WebRequest`, not real
  curl). Use the **http** port for local calls to dodge the self-signed-cert trust prompt.
- `dotnet run <file>.cs` inside a project folder is swallowed by the project — for a file-based
  scratch app use `dotnet run --file <file>.cs` (see `learning-approach.md`).

## Data access: EF Core in read/map mode

- ORM is **Entity Framework Core** with the `Microsoft.EntityFrameworkCore.SqlServer` provider.
- **CRITICAL — the dacpac owns the schema, not EF.** The `MSSQL/` project is the single source of
  truth for the schema, published via `sqlpackage`. EF is used **only to map to and query** the
  existing tables. **Never generate or run EF migrations** — that would create a second, conflicting
  schema authority. (This is why `Microsoft.EntityFrameworkCore.Design` and the `dotnet ef` tools
  are intentionally *not* installed.)

### Entity + context conventions

- **Entities** live in `Api/Entities/`, namespace `Api.Entities`, one class per file (mirrors the
  `MSSQL/Tables/` one-file-per-object convention). Each entity is a plain POCO whose properties
  mirror its table's columns. (Folder was renamed from `Models/` → `Entities/`: these classes are
  EF *entities*, and the name should say so rather than the generic MVC "Models".)
- **Nullability must match the schema exactly.** A `NULL` column → a nullable property (`int?`,
  `DateTime?`, `decimal?`, `string?`, no `required`); a `NOT NULL` column → non-nullable (and
  `required` is fine for `string`). Mismatches surface as materialization errors at read time, not
  at build.
- **Money is `decimal`** (never `double`/`float`), matching the DB's `DECIMAL(19,4)`.
- **Decimal precision must be configured, or money is silently truncated.** `decimal` carries no
  precision in the CLR, and EF defaults to `decimal(18,2)` on SQL Server — so with no configuration
  it sends **scale-2** parameters into `DECIMAL(19,4)` columns and drops the last two digits on
  write. Nothing throws; the row just stores a rounded value behind a successful `201`. Configured
  once for the whole model in `FinanceDbContext.ConfigureConventions`:
  `configurationBuilder.Properties<decimal>().HavePrecision(19, 4);` — which also covers `decimal?`,
  so `CashBack` is included. A blanket convention is correct here because *every* `decimal` in this
  schema is `DECIMAL(19,4)` money, and it can't be forgotten when a column is added; per-property
  `[Precision(19, 4)]` is the alternative. Note the naming: the **convention** builder uses `Have…`
  (`HavePrecision`, `HaveMaxLength`), while `OnModelCreating`'s builder uses `Has…`.
  EF logs a `Model.Validation[30000]` warning per unconfigured decimal property at startup — worth
  reading rather than tuning out, since it is the *only* notice you get.
- **Dates split by kind, and the CLR type must follow the column type.** User-meaningful times
  (`LedgerEntry.UserDate`, `OriginalDate`) are `DATETIMEOFFSET` → **`DateTimeOffset`**;
  system/audit timestamps (`LastModifiedUtc`, `GrantedAtUtc`) are `DATETIME2` UTC → **`DateTime`**.
  Mapping a `DATETIMEOFFSET` column to `DateTime` silently discards the offset.
- **The pattern behind the three rules above — this is the standing cost of "the dacpac owns the
  schema."** EF never reverse-engineered these tables and has no migrations to read, so it knows only
  the CLR type. **Wherever the CLR type is less specific than the SQL type, EF must be told
  explicitly**, and the failure is silent at runtime rather than loud at build: `string` doesn't say
  nullable (→ materialization error), `DateTime` doesn't say offset-bearing (→ offset discarded),
  `decimal` doesn't say precision (→ truncated money). A fair price for a single schema authority, but
  only if the mapping is audited whenever a column type is more specific than its CLR counterpart —
  expect a fourth instance and look for it.
- **Context** is `FinanceDbContext` in `Api/Data/`, namespace `Api.Data`, deriving from `DbContext`
  with a `DbContextOptions`-accepting constructor (options supplied by DI).
- **`DbSet` property names are singular** (`DbSet<Account> Account`) so EF's table-name convention
  (table name = `DbSet` property name) resolves to the singular tables. Alternative is `[Table("…")]`
  on the entity.
- **Map `DbSet`s incrementally, per vertical slice.** The model builds all-or-nothing, so only
  register entities that are fully, correctly modeled. Junction tables with **composite keys**
  (e.g. `Access`) need an explicit `[PrimaryKey(nameof(A), nameof(B))]` — EF can't infer composite
  keys by convention.
- **Navigation properties** express relationships in object terms: alongside a scalar FK
  (`int MerchantId`) an entity carries a reference to the *related entity* (`GroupMerchant Merchant`),
  so a query can traverse `entry.Merchant.Name` and EF turns it into a SQL JOIN. Initialize a required
  (non-null) reference navigation with `= null!;` (EF populates it on load) — **not** `required`,
  since you set the scalar FK, not the whole object, when creating a row. A **nullable** FK
  (`int? DefaultId`) takes a nullable navigation (`DefaultCategory?`). Navigations are
  **mapping-only**: they map onto the FK constraints the dacpac already defines and do **not** change
  the schema (still no migrations).
- **A navigation pairs with the FK property named `<NavigationName>Id`.** Naming a navigation
  `Default` when the FK column is `SetId` makes EF invent a *shadow* `DefaultId` property and try to
  map a column that doesn't exist — a runtime model error, not a compile error. Name the navigation
  after its FK (`SetId` → `Set`), or configure the pairing explicitly.
- **Composite FKs in the DB are deliberately mapped as single-column relationships in EF.** Four
  foreign keys (`LedgerEntry` → `Account`/`GroupMerchant`/`Category`, and `Category` → `CategorySet`)
  are composite on `(GroupId, <Id>)` in the schema, enforcing that a row's references all belong to
  the same group. EF is left to infer plain single-column relationships from `AccountId → Account.Id`
  etc., which generates correct JOINs because the target ids are unique. The composite constraint is
  an **integrity** concern the database owns; EF's mapping is a **query** concern — consistent with
  "the dacpac owns the schema." Consequence: assigning a navigation does **not** populate `GroupId`,
  so a write path must set it explicitly (from the validated account lookup). Modelling the composite
  form in EF is possible but fluent-API-only — `HasForeignKey(e => new { e.GroupId, e.AccountId })`
  plus `HasPrincipalKey(a => new { a.GroupId, a.Id })`, the latter required because the target is an
  alternate key, not the PK. There is no attribute equivalent.

### DTOs & projections (`Api/Contracts/`)

- **Entity vs DTO — two shapes for two audiences.** An **entity** (`Api/Entities/`) mirrors a table
  for EF; a **DTO** (`Api/Contracts/`, namespace `Api.Contracts`) is the API's outward contract. Keep
  them apart — a `using Api.Entities;` inside a `Contracts/` file is a **smell** that the DB shape has
  leaked into the wire shape. A simple read endpoint may still return an entity directly (as
  `/accounts` does), but introduce a DTO the moment the response needs a *different shape* than the
  table: to expose related **names** instead of FK ids, to drop internal/audit columns
  (`LastModifiedUtc`, `EndUser.PasswordHash`), or to flatten a graph for one screen.
- **Naming & files**: `PascalCase` with a role suffix — `…Dto` for a full/detail shape, `…Li` for a
  lean list-item shape (`TransactionLi`, `TransactionDto`), and **`Create…Request` for a request
  body** (`CreateTransactionRequest`), since the response-shape suffixes don't describe inbound data.
  One public type per file, as elsewhere —
  with a pragmatic exception for a small cluster of tightly-related contracts sharing a file named
  for the *concept* (never a catch-all `Dtos.cs`). Build DTOs **for the slice in front of you**, not
  speculatively.
- **A request DTO is a whitelist, not a mirror.** Never bind a request body straight onto an entity —
  that's **over-posting** (Rails/Django "mass assignment"), letting a client set anything the table
  has a column for. A request DTO carries *only* the fields a client is allowed to supply, so
  everything else is structurally unreachable rather than defended by a check you have to remember.
  Excluded by category: DB-assigned (`Id`), identity-derived (`GroupId` — see below),
  server-stamped (`LastModifiedUtc`), and import-provenance (`OriginalStatement`, `OriginalDate`,
  which belong to the future statement-import DTO, not manual entry).
- **In a request DTO, nullability means "may be omitted" — not "mirrors the column."** That rule holds
  for *entities*, whose job is to describe the table; a request DTO describes the **contract**, and the
  two can legitimately diverge. `UserDate`'s column is `NOT NULL` yet the field is client-optional in
  principle; `Notes` is optional *and* `NULL`-able. So: **every field the client must supply gets
  `required`** (`AccountId`, `MerchantId`, `CategoryId`, `Amount`, `UserDate`), and **only genuinely
  optional fields are nullable without it** (`decimal? CashBack`, `string? Notes`). Reading the DTO
  then tells you exactly what is mandatory.
  - `required` enforces **presence**, not non-nullness — which is why it is the only thing that works
    on a value type. A `DateTimeOffset` is a **struct**: omit it from the JSON and it binds to
    `default` (`0001-01-01T00:00:00+00:00`), which `DATETIMEOFFSET` accepts, so you get a `201` and a
    transaction dated year 1. `System.Text.Json` honours `required` (.NET 7+) and rejects both an
    absent property and an explicit `null`.
  - Omitting `required` on an `int` FK is subtler: the field binds to `0`, the existence guard finds no
    row, and the client gets `422 "Account 0 not found."` — technically true, but it misdiagnoses a
    *missing* field as a *bad* one.
- **Two error codes, two owners.** Model binding runs **before** the handler, so a malformed body, an
  unconvertible value, or a missing `required` field is a **400** the framework produces for free — no
  handler code, and none of your guards execute. The handler's own guards return **422** for input that
  parsed fine but fails semantically (unknown `AccountId`, over-length `Notes`, negative `CashBack`).
  Keeping that line clean means the framework owns *shape* and the endpoint owns *meaning*. It also
  means a test must isolate which one it is exercising: malformed JSON, `"userDate": ""`, and an absent
  `userDate` all surface as 400 for three different reasons, and a test that conflates them proves
  nothing about `required`.
- **Order guards cheap-local-first, then expensive-remote.** In-memory checks (`Notes` length,
  `CashBack` sign) cost nothing and should run before any `AnyAsync` round trip, so a bad request fails
  without touching the database. Pin literals that mirror the schema to a named constant carrying the
  column definition (`const int NoteLengthMax = 1000; // NVARCHAR(1000)`) rather than repeating the
  number — and interpolate the constant into the message so the text can't drift from the check.
- **`GroupId` is derived from the authenticated identity, never accepted from the request.** Anything
  that answers *"whose data is this?"* is server-derived; a client-supplied `GroupId` lets the caller
  choose whose books it writes into. The **composite FKs do not save you here**: `FK_LedgerEntry_Account`
  on `(GroupId, AccountId)` proves a row's references are *internally consistent* (all in one group) —
  it cannot know whether the caller *belongs* to that group. Integrity constraint ≠ authorization
  check. Trust flows: `GroupId` from identity (**hardcoded `1` until auth lands**), then the request's
  `AccountId` is validated *against* it (`Id == req.AccountId && GroupId == groupId`) — one lookup
  serving as both existence and authorization check. Once `GroupId` is trustworthy the composite FKs
  become genuinely useful, catching a `MerchantId`/`CategoryId` from another group.
- **Projection is how you fill a DTO**: shape it inside the query with LINQ
  `.Select(e => new TransactionLi { Category = e.Category.Name, … })`. EF translates the projection
  plus navigation traversals into a single SQL statement that JOINs and selects **only** the
  projected columns — the server-side "only what's needed crosses the wire" path. Preferred over
  `Include`, which eager-loads whole related rows. LINQ is lazy: nothing hits the DB until
  `.ToListAsync()` materializes the query.
- **The projection must sit *inside* the queryable chain — where `.Select()` goes decides whether it
  becomes SQL or C#.** A terminal operator (`ToListAsync`, `FirstOrDefaultAsync`, `SingleAsync`,
  `AnyAsync`) is a hard boundary: everything chained **before** it is an expression tree translated to
  SQL and run on the server; anything done **after** it is ordinary C# over materialized objects.
  `db.LedgerEntry.Where(…).Select(… new TransactionLi …).SingleAsync()` emits one JOINed statement.
  Materialising first and *then* building the DTO throws **`NullReferenceException`**, because
  **EF Core does not lazy-load** — without the proxies package an unloaded navigation is simply `null`,
  it is not fetched on access. (Django and Hibernate *would* silently issue a second query here; the
  instinct does not carry over.) The `= null!;` on required navigations is what withholds the
  compiler warning, so "is this navigation actually loaded?" is a question only the query can answer —
  verify by reading the generated SQL for the expected `INNER JOIN`s, not by reading the response.
- **EF logs every statement it executes** at `Information` level to the console. That log is the
  primary tool for "what did my LINQ actually do": absent JOINs mean a projection ran client-side,
  `SELECT` of all columns where a `CASE WHEN EXISTS` was intended means `FirstOrDefaultAsync` was used
  for an existence check, and the parameter list reveals precision/type mapping (`(Precision = 19)
  (Scale = 4)`). The ORM is not a black box; checking its SQL is the habit that catches the silent bugs.
- **Resolving an inherited merchant name takes a two-hop traversal and `??`.**
  `GroupMerchant.Name` is the group's *override* and is `NULL` when the group hasn't customized, so
  the display name is `e.Merchant.Name ?? e.Merchant.Merchant.Name` — the group's merchant, falling
  back to the master row. EF translates `??` to SQL `COALESCE` and each hop to a JOIN, so it stays
  one statement. (The doubled `.Merchant.Merchant` is forced by the naming convention above:
  `MerchantId` pairs with `Merchant` on both entities. Cosmetic, fixable with fluent config.)
  `PicPath` needs the same treatment. Getting this wrong doesn't throw — it projects `null` into a
  non-nullable DTO property and renders as a blank cell.

### Writes (the insert path)

- **Inserting is two steps.** `db.LedgerEntry.Add(entry)` marks the object `Added` in the change
  tracker — no SQL yet, the same laziness as a queryable — and `await db.SaveChangesAsync()` emits the
  `INSERT`. EF appends `OUTPUT INSERTED.[Id]` and **writes the `IDENTITY` value back onto `entry.Id`**,
  so the new id is available immediately with no follow-up query.
- **Three return values that are not what you want**, each of which compiles and "works":
  - `SaveChangesAsync()` returns `Task<int>` — the **rows-affected count**. Returning it from a handler
    serialises `1` with a **200**, no `Location`, no id. Await it as a statement; return separately.
  - `Add(entry)` returns `EntityEntry<T>`, EF's tracking handle, whose `.Context` reaches the whole
    `DbContext`. Serialising it throws `JsonException: A possible object cycle was detected` via
    `EntityEntry.Context → ChangeTracker.Context → …`. **Read the exception's `Path:` line** — its first
    segment names what was actually serialised. Do **not** take the message's advice to enable
    `ReferenceHandler.Preserve`: that is generic guidance for the wrong problem, and it would ship the
    context and connection state to the browser instead of throwing. **Never serialise an EF type** —
    entities cycle through navigations by design, infrastructure types point at everything.
  - `Results.Created("", value)` does **not** throw on an empty URI — it silently emits a 201 with **no
    `Location` header**, i.e. "I created something" while declining to say where. Always pass the real
    path (`$"/transactions/{entry.Id}"`), even if that GET endpoint doesn't exist yet.
- **A failed response does not mean a failed write.** The `INSERT` commits before serialisation runs, so
  a 500 from the response path leaves a real row behind. See the write-path idempotency entry in
  [`project-vision.md`](project-vision.md) — unmitigated, and it must be settled before statement import.
- **Returning the created resource costs an extra query, deliberately.** Existence guards use
  `AnyAsync`, which yields `bool`s, not names — so building a `TransactionLi` means re-querying by
  `entry.Id` with the same projection the list endpoint uses (`SingleAsync`, since the row was just
  inserted and must exist and be unique). Preferred over resolving names by hand in the guards: the POST
  response is then guaranteed identical to what a subsequent `GET` would return.

## Connection string & secrets

- Config key: `ConnectionStrings:DefaultConnection`, read via
  `builder.Configuration.GetConnectionString("DefaultConnection")` and passed to `UseSqlServer(...)`
  in `AddDbContext<FinanceDbContext>(...)`.
- **The secret never touches `appsettings.json`** (committed). In development it lives in **.NET User
  Secrets** (`dotnet user-secrets set …`, keyed by the `<UserSecretsId>` in `Api.csproj`), stored
  outside the repo. Config layering merges it over `appsettings*.json` at startup; for real
  deployment the same slot comes from an environment variable instead.
- Working connection-string shape (password from `db.env`):
  `Server=localhost,1433;Database=FinanceDb;User Id=sa;Password=…;TrustServerCertificate=True;Encrypt=True;Application Name=FinanceApp`
  - **`,` vs `;`**: a comma separates host from port *inside* `Server=host,port`; semicolons
    separate the key=value pairs. A stray comma before `Database=` folds it into the `Server` value,
    silently dropping the database → connects to `sa`'s default (`master`) → error 208
    `Invalid object name`.
  - **`TrustServerCertificate=True`** is required because the container uses a self-signed cert and
    the driver encrypts by default — same as SSMS's "Trust server certificate" checkbox.
  - Config is read once at **startup** — restart `dotnet run` after changing a secret.

## CORS

- The browser blocks the SvelteKit dev server (`http://localhost:5173`) from *reading* API responses
  at a different origin (`http://localhost:5046`) unless the API opts in — a browser-enforced
  same-origin-policy protection that only the server can relax (via an `Access-Control-Allow-Origin`
  response header).
- Wired in `Program.cs` the usual two-step way: **register** a named policy with
  `builder.Services.AddCors(...)` (a `WithOrigins("http://localhost:5173")` policy), then **use** it
  with `app.UseCors(<policy>)` in the pipeline — placed after `UseHttpsRedirection` and **before** the
  endpoint mappings so the header is attached to the response on the way out. Pipeline **order**
  matters, and config is read once at startup (same restart gotcha as the connection string).
- **The allowed origin is hardcoded to the dev URL** — revisit via config when a real deployment
  origin exists.

## NuGet notes

- Packages live in `Api/Api.csproj`. `dotnet list package --vulnerable --include-transitive` and
  `--outdated` are the audit commands.
- `Microsoft.OpenApi` is pinned directly (a **transitive pin**) to patch CVE-2026-49451, because the
  parent `Microsoft.AspNetCore.OpenApi` had no fixed release yet. Revisit — the pin can be dropped
  once the parent ships a version that pulls in `Microsoft.OpenApi` ≥ 2.7.5 transitively.

## Current state

- `GET /accounts` returns `Account` entities directly (first vertical slice). `GET /transactions`
  (second slice) projects `LedgerEntry` + its `Account`/`Merchant`/`Category` navigations into a
  `TransactionLi` DTO, so the response carries related **names**, not FK ids. Both are consumed
  end-to-end by the SvelteKit `/accounts` and `/transactions` pages (see `frontend.md`). CORS allows
  the dev frontend origin.
- All **11** tables are mapped as entities (`Account`, `Category`, `CategorySet`, `DefaultCategory`,
  `DefaultCategorySet`, `EndUser`, `GroupMember`, `GroupMerchant`, `LedgerEntry`, `Merchant`,
  `UserGroup`) and registered on `FinanceDbContext`. EF builds its model **all-or-nothing at first
  query**, so a mapping mistake surfaces as a runtime exception on the first request, *not* as a
  build error — `dotnet build` passing proves nothing about the model. Hit `/accounts` first when
  verifying: no projection, no navigations, so it isolates "does the model bind."
- Only `Account`, `LedgerEntry`, `GroupMerchant`, `Merchant`, and `Category` are exercised by an
  endpoint; the rest are mapped but not yet driven by one.
- **No authentication yet.** Group is the ownership unit, but there's no current-user concept, so
  writes will hardcode the seeded dev group (`GroupId = 1`) until auth lands.
- **Done: the transaction-entry slice** — `POST /transactions` takes a `CreateTransactionRequest`,
  guards it, inserts, and returns `201` with a `Location` header and the created row projected into a
  `TransactionLi`. Guard order is cheap-local-first (`Notes` length, `CashBack` sign) then three
  `AnyAsync` existence-and-ownership checks against `(Id, GroupId)`, each returning `422` with a message
  that does **not** distinguish "doesn't exist" from "isn't yours" (a different response would let a
  caller enumerate real ids). Exercised by a named `.http` suite in `Api/Api.http` covering the happy
  path, a bad account id, 4-decimal precision, negative cash back, the `Notes` 1000/1001 boundary pair,
  and an absent `userDate`. Decisions settled while scoping it:
  - **Merchant/category creation is a separate resource call, not a fat endpoint.** Rejected the
    XOR-style "id *or* name, create-if-name" body in favour of the client POSTing to `/merchants`
    (or `/categories`) first and submitting the returned id — each resource owns its own creation and
    this endpoint stays one insert. Consequence: `MerchantId`/`CategoryId` are **required, non-null**,
    the write path needs no sentinel lookup (the caller sends a resolved id, including the seeded
    `'Unknown'`/`'Uncategorized'` rows), and `GET /merchants` + `GET /categories` become blocking
    dependencies for the *frontend* form rather than for the API.
  - **Sign is a user assertion** — a manually-entered amount has no ground truth to validate against,
    so the API stores the sign as sent (display-layer flipping is unchanged).
  - **`LastModifiedUtc` is stamped in the API, not left to the DB default.** `DF_LedgerEntry_LastModifiedUtc`
    only fires when the column is *absent* from the `INSERT`, and EF includes every mapped property it
    isn't told is store-generated — so an unset `DateTime` writes `DateTime.MinValue` (year 0001) with
    no error and a successful `201`.
  - **`UserDate` is `required`, not defaulted server-side.** Considered defaulting an omitted date to
    now, and rejected it: only the client knows the user's offset, so a server default could only stamp
    `DateTimeOffset.UtcNow` (`+00:00`, claiming no local context) or — worse —
    `DateTimeOffset.Now`, which attaches the *server's* offset and is wrong the moment the API is
    deployed anywhere but the user's own machine. Requiring the field forces the value to come from the
    browser, which is the only party that knows it. Note `DateTimeOffset.Now`/`UtcNow` describe the same
    instant and differ only in attached offset — unlike `DateTime`, where they differ in value *and*
    `Kind`.
  - **`CashBack` must be non-negative** (`422` otherwise) — cash back is money coming back, so under
    the sign convention it is positive. Unlike `Amount`, this one *is* checkable without ground truth.
- Next, before the next feature slice — two refactors the slice earned:
  1. **Move the endpoints out of `Program.cs` into their own files.** Three endpoints inline is already
     the ceiling; porting gets more expensive per endpoint added. Minimal APIs are grouped with
     extension methods on `IEndpointRouteBuilder` (`app.MapTransactionEndpoints()`), optionally with
     `MapGroup("/transactions")` for a shared prefix.
  2. **Extract the shared `TransactionLi` projection.** It is currently duplicated verbatim between
     `GET /transactions` and the POST's re-query, and `GET /transactions/{id}` would make three copies.
     A `static Expression<Func<LedgerEntry, TransactionLi>>` passed to `.Select(…)` composes, because an
     expression tree is data.
- Then: **`GET /transactions/{id}`**, the natural place a fuller `TransactionDto` earns its keep, and
  **`GET /merchants` + `GET /categories`**, which the entry form needs in order to send resolved ids —
  see the category-id note below. Merchant find-or-insert against the master list moves to
  `POST /merchants` when that slice lands.
- **Gotcha worth remembering when hand-writing test requests: a group's `Category` ids are not the
  `DefaultCategory` ids.** Provisioning inserts via `INSERT … SELECT` with no `ORDER BY`, so `IDENTITY`
  assigns ids in arbitrary join-output order — group 1's category `1` is `'Paycheck'`, not
  `'Uncategorized'`. `GroupMerchant` id `1` *is* `'Unknown'` only because it was seeded under
  `SET IDENTITY_INSERT`. Same-looking literal, one reliable and one not; look rows up by business key
  `(GroupId, DefaultId)`. This is why the picker endpoints are a real dependency rather than a nicety.

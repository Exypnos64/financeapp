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
- **Dates split by kind, and the CLR type must follow the column type.** User-meaningful times
  (`LedgerEntry.UserDate`, `OriginalDate`) are `DATETIMEOFFSET` → **`DateTimeOffset`**;
  system/audit timestamps (`LastModifiedUtc`, `GrantedAtUtc`) are `DATETIME2` UTC → **`DateTime`**.
  Mapping a `DATETIMEOFFSET` column to `DateTime` silently discards the offset.
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
  lean list-item shape (`TransactionLi`, `TransactionDto`). One public type per file, as elsewhere —
  with a pragmatic exception for a small cluster of tightly-related contracts sharing a file named
  for the *concept* (never a catch-all `Dtos.cs`). Build DTOs **for the slice in front of you**, not
  speculatively.
- **Projection is how you fill a DTO**: shape it inside the query with LINQ
  `.Select(e => new TransactionLi { Category = e.Category.Name, … })`. EF translates the projection
  plus navigation traversals into a single SQL statement that JOINs and selects **only** the
  projected columns — the server-side "only what's needed crosses the wire" path. Preferred over
  `Include`, which eager-loads whole related rows. LINQ is lazy: nothing hits the DB until
  `.ToListAsync()` materializes the query.
- **Resolving an inherited merchant name takes a two-hop traversal and `??`.**
  `GroupMerchant.Name` is the group's *override* and is `NULL` when the group hasn't customized, so
  the display name is `e.Merchant.Name ?? e.Merchant.Merchant.Name` — the group's merchant, falling
  back to the master row. EF translates `??` to SQL `COALESCE` and each hop to a JOIN, so it stays
  one statement. (The doubled `.Merchant.Merchant` is forced by the naming convention above:
  `MerchantId` pairs with `Merchant` on both entities. Cosmetic, fixable with fluent config.)
  `PicPath` needs the same treatment. Getting this wrong doesn't throw — it projects `null` into a
  non-nullable DTO property and renders as a blank cell.

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
- Next: the transaction-entry slice — a request DTO (needs a naming suffix decision; `…Li`/`…Dto`
  don't cover request bodies), `MapPost` returning `201` via `Results.Created`, validating
  `AccountId` rather than letting an FK violation become a 500, find-or-insert against the master
  merchant list, and setting `GroupId` from the account lookup. A `GET /transactions/{id}` detail
  endpoint remains the natural place a fuller `TransactionDto` would earn its keep.

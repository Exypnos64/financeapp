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
- Folders: `Api/Models/` (entities), `Api/Data/` (the `DbContext`).

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

- **Entities** live in `Api/Models/`, namespace `Api.Models`, one class per file (mirrors the
  `MSSQL/Tables/` one-file-per-object convention). Each entity is a plain POCO whose properties
  mirror its table's columns.
- **Nullability must match the schema exactly.** A `NULL` column → a nullable property (`int?`,
  `DateTime?`, `decimal?`, `string?`, no `required`); a `NOT NULL` column → non-nullable (and
  `required` is fine for `string`). Mismatches surface as materialization errors at read time, not
  at build.
- **Money is `decimal`** (never `double`/`float`), matching the DB's `DECIMAL(19,4)`.
- **Context** is `FinanceDbContext` in `Api/Data/`, namespace `Api.Data`, deriving from `DbContext`
  with a `DbContextOptions`-accepting constructor (options supplied by DI).
- **`DbSet` property names are singular** (`DbSet<Account> Account`) so EF's table-name convention
  (table name = `DbSet` property name) resolves to the singular tables. Alternative is `[Table("…")]`
  on the entity.
- **Map `DbSet`s incrementally, per vertical slice.** The model builds all-or-nothing, so only
  register entities that are fully, correctly modeled. Junction tables with **composite keys**
  (e.g. `Access`) need an explicit `[PrimaryKey(nameof(A), nameof(B))]` — EF can't infer composite
  keys by convention.
- Entities are currently returned **directly** from endpoints. This is a known skeleton shortcut;
  introduce **DTOs** when an endpoint would otherwise leak internal fields (e.g. `EndUser.PasswordHash`).

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

## NuGet notes

- Packages live in `Api/Api.csproj`. `dotnet list package --vulnerable --include-transitive` and
  `--outdated` are the audit commands.
- `Microsoft.OpenApi` is pinned directly (a **transitive pin**) to patch CVE-2026-49451, because the
  parent `Microsoft.AspNetCore.OpenApi` had no fixed release yet. Revisit — the pin can be dropped
  once the parent ships a version that pulls in `Microsoft.OpenApi` ≥ 2.7.5 transitively.

## Current state

- Skeleton complete: `GET /accounts` returns `Account` rows from the containerized DB as JSON.
- Only `Account` is exercised end-to-end; the other six entities exist as files and are mapped but
  not yet driven by an endpoint.
- Next: the SvelteKit frontend skeleton that calls `/accounts`.

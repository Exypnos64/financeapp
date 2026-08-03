# Finance App Setup

> All commands as written work from the root of this project.

### 1. Ensure you have .NET 10 installed

To be done in an administrator powershell terminal:

```powershell
Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile "./dotnet-install.ps1"
./dotnet-install.ps1 -Channel 10.0
```

### 2. Ensure you have Docker installed and running

```powershell
winget install Docker.DockerDesktop
```

Be sure to open Docker Desktop after it's installed.

### 3. Ensure you have sqlpackage installed

```powershell
dotnet tool install --global Microsoft.SqlPackage
```

### 4. Build the dacpac

```powershell
dotnet build MSSQL\FinanceDb.sqlproj
```

### 5. Create your environment password

Make a copy of `db.env.example` and change the password to your own. It needs to have at least 8 characters and 3 of the 4 following categories.:

- Uppercase letter
- Lowercase letter
- Number
- Special Character

### 6. Setup Docker

This is only to be run once, and `-d` leaves the container running afterward. In later sessions you start it again with the next step (`start` can be swapped for `stop` or `restart` to control the container).

```powershell
docker run -d --name financedb -e "ACCEPT_EULA=Y" --env-file db.env -p 1433:1433 -v financedb-data:/var/opt/mssql mcr.microsoft.com/mssql/server:2022-CU14-ubuntu-22.04
```

### 7. Start the database server

Step 6 already started the container on first-time setup, so you can skip ahead. Every session after that — a new terminal, after a reboot, or any time the container is stopped — start it before publishing or connecting:

```powershell
docker start financedb
```

The publish script and SSMS are just clients: they connect to a server that's already listening on `localhost,1433`, so the container has to be running first. Confirm it's up with `docker ps` (a stopped container won't be listed; `docker ps -a` shows it regardless). Give the SQL Server engine a few seconds after starting before it accepts connections.

### 8. Publish the package to the Docker server

```powershell
.\MSSQL\PublishSqlPackage.ps1
```

This [publishing script](MSSQL\PublishSqlPackage.ps1) idempotently publishes your script to the Docker server.

The first command in the script stores your password in an environment variable so it doesn't get stored as plaintext in your shell history. The second publishes it.

> If you are unable to run the script, you can copy and paste the commands manually or run the following to enable running powershell scripts on your system:  
`Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

### 9. Open MSSQL

Connect to the server with the following settings:
    - Server name: localhost,1433
    - Authentication: SQL Server Authentication
    - Login: sa
    - Password: *your environment password*
    - Encryption: Mandatory
    - Trust server certificate: True

### 10. Verify everything is up and running

You can run the following selects to ensure that setup was successful. All of these are populated by
`MSSQL\Script.PostDeployment.sql` — the first two are the curated defaults, the last two are the
seeded dev group's own copies.

```sql
SELECT * FROM dbo.DefaultCategorySet;   -- 14 rows
SELECT * FROM dbo.Merchant;             -- 67 rows (curated master list)
SELECT * FROM dbo.CategorySet;          -- 14 rows, GroupId = 1
SELECT * FROM dbo.Category;             -- 51 rows, GroupId = 1
```

Note that `Category.Id` values are **not** expected to line up with `DefaultCategory.Id` — the
copy-into-group insert lets `IDENTITY` assign ids in join-output order, so e.g. "Uncategorized"
lands wherever it lands. Look rows up by `(GroupId, DefaultId)`, never by a hardcoded id.

---

> The steps above stand up the database. The steps below set up and run the SvelteKit frontend. The
> dev server itself starts and hot-reloads without the database or API. But the frontend now talks
> to the .NET API (the first feature slice), so to see **real data** — e.g. the `/accounts` page —
> the database must be up **and** the API running (`dotnet run` from `Api/`; see
> [`.claude/docs/api.md`](.claude/docs/api.md)).

### 11. Ensure you have Node.js installed

The frontend runs on Node.js (which also provides `npm`). Install the current LTS:

```powershell
winget install OpenJS.NodeJS.LTS
```

Confirm it's available (open a fresh terminal first so `PATH` picks it up):

```powershell
node --version
npm --version
```

### 12. Install the frontend dependencies

Dependencies aren't committed (`node_modules/` is gitignored), so restore them on a fresh clone.
Run from the `SvelteKit/` directory:

```powershell
cd SvelteKit
npm install
```

### 13. Run the dev server

```powershell
npm run dev
```

Vite prints a local URL (usually `http://localhost:5173`) — open it in your browser. The dev server
watches your files and hot-reloads on save; press `Ctrl+C` to stop it.

With the database up and the API running (see the note above), browse to `/accounts`
(`http://localhost:5173/accounts`) to see live account data fetched from the API — the first
end-to-end vertical slice.

Other useful scripts (all run from `SvelteKit/`):

```powershell
npm run build     # produce a production bundle
npm run preview   # serve the production build locally
npm run check     # type-check (.svelte files included) via svelte-check
npm run lint      # prettier --check + eslint
npm run format    # auto-format with prettier
```

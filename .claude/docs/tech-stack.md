# Tech Stack & Environment

The canonical record of *which technologies we're using and why*, plus the staged plan for
adopting them. Product features live in [`project-vision.md`](project-vision.md); the teaching
contract lives in [`learning-approach.md`](learning-approach.md).

> Everything here is **new-to-the-owner** except general programming. Treat each technology as a
> learning target, not just a dependency. See `learning-approach.md` before explaining any of it.

## The chosen stack

| Layer | Technology | Notes |
|---|---|---|
| **Database** | **SQL Server** | Relational store for accounts, transactions, budgets, users. |
| **API / backend** | **C# / .NET** | The web API, and likely any background services we run. |
| **Frontend** | **SvelteKit** | The web interface. **Desktop-first**; mobile is deferred. |
| **Containers** | **Docker** | Adopted *incrementally* — see the Docker plan below. |
| **Bank data (later)** | **Plaid** | Deferred; manual import first. See `project-vision.md` → Later. |

## Docker adoption plan (staged, deliberate)

The team lead's guidance, adopted here: **containerize the database first, and only the database,
to start.** Reasoning: it lets the owner learn Docker basics without also having to learn
container *networking* on day one. Everything else (API, frontend) runs on the host against the
containerized DB until the owner is ready to go further.

- **Now**: DB in a container; API and frontend run locally on the host, connecting to the
  container's published port. **Implemented** — the database runs in Docker and the `MSSQL/` schema
  publishes to it; see [`SETUP.md`](../../SETUP.md) at the repo root for the full stand-up steps.
- **Later**: containerize the API and frontend and wire up container networking — only once the
  app works and the owner wants to take that step.
- **Later (owner-initiated learning goal)**: stand the app up on **Kubernetes** as a deliberate
  ops/deployment learning exercise. Kubernetes does *not* replace Docker Desktop — it's an
  orchestrator that layers on top of a container runtime (Docker Desktop even bundles a single-node
  cluster). For a single dev-box database it's overkill (pods, deployments, services, PVCs,
  manifests, `kubectl` to learn before a table ships), so it stays deferred until the app exists
  and the owner wants to learn deployment. The owner raised interest 2026-07-13; parked here so we
  don't lose the thread.

Do **not** jump ahead to multi-container networking, compose orchestration of the whole app, or
Kubernetes-style concerns unprompted.

## Owner's starting familiarity (informs how to explain things)

Summarized here; full detail in [`learning-approach.md`](learning-approach.md).

- **Comfortable**: Python, JavaScript — but JS as *blackbox QA automation scripting*, **not** web
  development.
- **Rusty**: Java, from a long time ago.
- **New**: C#, .NET, relational database design, SQL, API design/hosting, Docker, front-end web
  development.

Practical implication: relate C#/.NET, SQL, and Docker concepts back to Python/JS analogies where
honest ones exist, and don't assume any prior web-dev or DB-design practice.

## Environment facts

- **OS**: Windows 11. Primary shell is **PowerShell**; a Bash tool is also available (POSIX
  syntax). Windows path separators and CRLF apply — see `.gitattributes`.
- **Working directory**: `C:\DevOps\financeapp`.
- The foundation stack has landed: the DB (`MSSQL/`, containerized), the .NET API (`Api/`), and the
  SvelteKit frontend (`SvelteKit/`). As each new piece lands, record concrete setup steps (SDK
  versions, connection-string pattern, how to run each piece) in dedicated docs under
  `.claude/docs/` and index them in `CLAUDE.md`.

## Decisions made (resolved as we built)

- **SQL Server image/edition**: `mcr.microsoft.com/mssql/server:2022-CU14-ubuntu-22.04` — the
  container's default **Developer** edition. Runs on the WSL2 Linux backend.
- **Secret handling (DB)**: the SA password lives in a gitignored `db.env`, with a committed
  `db.env.example` template. Passed to the container via `docker run --env-file`, and read into a
  PowerShell variable (never a literal) for `sqlpackage`. App-level connection-string secrets are
  handled via **.NET User Secrets** in development (see the API-layer decision below and `api.md`).
- **.NET version**: **.NET 10** (see `SETUP.md`). Also enables single-file "file-based apps"
  (`dotnet run --file scratch.cs`) for learning snippets — see `learning-approach.md`.
- **API layer** (skeleton landed — full detail in [`api.md`](api.md)): a **single** `Api/` project
  (minimal APIs, not controllers), not a multi-project solution. Data access is **EF Core in
  read/map mode** — the `MSSQL/` dacpac stays the sole schema authority and **EF migrations are
  never used**. App connection-string secret lives in **.NET User Secrets** for development
  (`ConnectionStrings:DefaultConnection`), sourced from an env var for deployment later.
- **Frontend layer** (skeleton landed — full detail in [`frontend.md`](frontend.md)): a
  **SvelteKit** app in `SvelteKit/`, scaffolded with the `sv` CLI (minimal template),
  **TypeScript**, Svelte 5, Vite. **Package manager: npm** (yarn Classic is frozen; the owner will
  learn yarn on the team project; pnpm is the modern-fast alternative if ever wanted). Add-ons kept
  minimal (**prettier + eslint**); **Tailwind and testing deferred** deliberately. Renders and
  hot-reloads (`npm run dev`); does not talk to the API yet.

## Open questions to resolve as we build

- SvelteKit data-loading approach for talking to the .NET API.
- Whether Plaid's free tier can actually serve a single personal user's needs (revisit later).

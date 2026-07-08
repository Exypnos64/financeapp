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
  container's published port.
- **Later**: containerize the API and frontend and wire up container networking — only once the
  app works and the owner wants to take that step.

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
- This is early days: **no application code exists yet** at the time of writing. As the stack
  lands, record concrete setup steps (SDK versions, connection strings pattern, how to run each
  piece) in dedicated docs under `.claude/docs/` and index them in `CLAUDE.md`.

## Open questions to resolve as we build

- SQL Server edition/image to run in Docker (Developer/Express) and how connection strings are
  managed without committing secrets.
- .NET version and project layout (single API project vs. solution with service projects).
- SvelteKit data-loading approach for talking to the .NET API.
- Whether Plaid's free tier can actually serve a single personal user's needs (revisit later).

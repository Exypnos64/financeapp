# Finance App

A personal-finance application in the spirit of [Monarch Money](https://www.monarchmoney.com/),
built as a hands-on way to learn full-stack development. It stores multiple financial accounts and
their transactions, reconciles bank statements against manually-entered data, and supports
budgeting — with bucket (envelope) budgeting and single-transaction splitting as the headline
departures from how Monarch works.

> **This is a learning project.** The goal is as much about the owner becoming a stronger
> full-stack engineer as it is about the app itself. See the docs below for the full vision.

## Tech stack

| Layer | Technology |
|---|---|
| Database | SQL Server (containerized via Docker) |
| Backend / API | C# / .NET |
| Frontend | SvelteKit (desktop-first) |
| Containers | Docker (database first; more later) |
| Bank data | Manual statement import now; Plaid later |

## Documentation index

Human-facing docs live at the repo root. Claude-facing working docs live under `.claude/` (and
are committed to the repo on purpose — Claude sessions are their primary readers).

| Doc | Location | What it holds |
|---|---|---|
| This README | `README.md` | What the app is, the stack, the doc index, project structure. |
| User setup guide | `SETUP.md` | Software and package requirements; setup commands and files. |
| Backlog | `TODO.md` | Outstanding work, priority-ordered; done items keep a "Done:" note. |
| Claude router | `CLAUDE.md` | Always-loaded rules + an annotated index of the `.claude/docs` tree. |
| Product vision | `.claude/docs/project-vision.md` | Full feature intent: accounts, users/sharing, budgeting, tagging, splitting, reconciliation, savings goals. |
| Tech stack | `.claude/docs/tech-stack.md` | Technology choices, the staged Docker plan, environment facts. |
| Development process | `.claude/docs/development-process.md` | How the build proceeds: order of work, backtracking to expect, anticipated problems. |
| API layer | `.claude/docs/api.md` | The .NET API as built: layout, EF Core read/map mode, endpoints, connection string + secrets. |
| Frontend layer | `.claude/docs/frontend.md` | The SvelteKit app as built: layout, tooling, how to run it, conventions, styling/testing decisions. |
| Learning approach | `.claude/docs/learning-approach.md` | The teaching contract that governs how Claude helps on this project. |
| Claude setup guide | `CLAUDE-SETUP-GUIDE.md` | How this whole `CLAUDE.md` + `.claude/` setup was built (reusable). |

## Project structure

```text
financeapp/
├── CLAUDE.md                 # Claude router: rules + reference index
├── CLAUDE-SETUP-GUIDE.md     # How the Claude setup works (reusable guide)
├── README.md                 # This file
├── SETUP.md                  # Local-environment stand-up runbook
├── TODO.md                   # Backlog
├── db.env.example            # Template for the gitignored db.env (SA password)
├── .gitignore  .gitattributes  .markdownlint-cli2.jsonc
├── MSSQL/                    # SQL Server schema-as-code (dacpac project, one file per object)
├── Api/                      # .NET web API (minimal APIs, EF Core read/map against the dacpac)
├── SvelteKit/                # SvelteKit frontend (TypeScript, Vite)
└── .claude/                  # Claude-facing setup (committed)
    ├── docs/                 # On-demand reference docs
    │   ├── project-vision.md
    │   ├── tech-stack.md
    │   ├── development-process.md
    │   ├── learning-approach.md
    │   ├── api.md
    │   └── frontend.md
    ├── agents/               # Custom subagents (none yet — see README there)
    ├── tools/                # Deterministic helper scripts (none yet)
    ├── notes/                # Disposable session scratch
    └── settings.local.json   # Per-machine permissions (gitignored)
```

## Status

The foundation stack is in place and **data flows end-to-end in both directions**. The SQL Server
schema (`MSSQL/`) publishes to a Docker container. The .NET API (`Api/`) serves `GET /accounts`,
`GET /transactions` — which projects a transaction plus its account, merchant and category into a
DTO carrying related **names** rather than foreign keys — and `POST /transactions`, a validated
insert returning `201` with the created row. The SvelteKit frontend (`SvelteKit/`) renders the
accounts and transactions lists from the API, with money and dates formatted for display.

Next is the **transaction-entry** slice: the API accepts a POST, so what remains is the form that
drives it, plus the `GET /merchants` and `GET /categories` endpoints it needs to submit resolved ids.
There is still **no authentication**, so writes are scoped to the seeded development group. Styling
is deliberately minimal until the screens settle. See `TODO.md` for the full backlog.

> A `HANDOFF.md` (a dated "picking this up" snapshot) will be added if/when the project reaches a
> point where someone else — or a future self after a long gap — needs to take it over.

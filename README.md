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
| User setup guide | `SETUP.MD` | Software and package requirements; setup commands and files. |
| Backlog | `TODO.md` | Outstanding work, priority-ordered; done items keep a "Done:" note. |
| Claude router | `CLAUDE.md` | Always-loaded rules + an annotated index of the `.claude/docs` tree. |
| Product vision | `.claude/docs/project-vision.md` | Full feature intent: accounts, users/sharing, budgeting, tagging, splitting, reconciliation, savings goals. |
| Tech stack | `.claude/docs/tech-stack.md` | Technology choices, the staged Docker plan, environment facts. |
| Development process | `.claude/docs/development-process.md` | How the build proceeds: order of work, backtracking to expect, anticipated problems. |
| Learning approach | `.claude/docs/learning-approach.md` | The teaching contract that governs how Claude helps on this project. |
| Claude setup guide | `CLAUDE-SETUP-GUIDE.md` | How this whole `CLAUDE.md` + `.claude/` setup was built (reusable). |

## Project structure

```text
financeapp/
├── CLAUDE.md                 # Claude router: rules + reference index
├── CLAUDE-SETUP-GUIDE.md     # How the Claude setup works (reusable guide)
├── README.md                 # This file
├── TODO.md                   # Backlog
├── .gitignore  .gitattributes  .markdownlint-cli2.jsonc
└── .claude/                  # Claude-facing setup (committed)
    ├── docs/                 # On-demand reference docs
    │   ├── project-vision.md
    │   ├── tech-stack.md
    │   └── learning-approach.md
    ├── agents/               # Custom subagents (none yet — see README there)
    ├── notes/                # Disposable session scratch
    └── settings.local.json   # Per-machine permissions (gitignored)
```

*Application code (the .NET solution, the SvelteKit app, the DB/Docker setup) does not exist yet —
it will be added here as the project gets built.*

## Status

Just getting started. No application code yet; the current commit establishes the project
documentation and Claude Code working setup. See `TODO.md` for what's next.

> A `HANDOFF.md` (a dated "picking this up" snapshot) will be added if/when the project reaches a
> point where someone else — or a future self after a long gap — needs to take it over.

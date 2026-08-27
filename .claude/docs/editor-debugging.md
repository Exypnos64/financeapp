# Editor & Debugging (`.vscode/`)

How the whole stack starts from VS Code with **F5**, instead of three manual commands in three
terminals. The manual commands still work and remain the documented baseline —
[`SETUP.md`](../../SETUP.md) at the repo root, plus the "Running it" sections of
[`api.md`](api.md) and [`frontend.md`](frontend.md). This file records the debug wiring only.

`.vscode/` is **committed on purpose** (like the rest of the Claude-facing setup) — the debug
configuration is part of the project, not per-machine preference. Only `.vscode/settings.json`
would be a candidate for gitignoring if per-machine editor settings ever appear; there is none yet.

## What's there

| File | Holds |
|---|---|
| `.vscode/launch.json` | Debug configurations: `API (.NET)`, `Web (SvelteKit)`, and the `Full stack (DB + API + Web)` compound. |
| `.vscode/tasks.json` | Build/shell tasks: `db: start`, `api: build`, the `api: prelaunch` composite, and `web: install`. |

Relies on two extensions already installed: **C# Dev Kit** (`ms-dotnettools.csdevkit`, which
provides the `coreclr` debug type) and **Svelte for VS Code** (`svelte.svelte-vscode`). The
SvelteKit config uses `node`, which is built into VS Code — no extension needed. Docker needs no
extension either; it's driven through the CLI by a shell task.

## The F5 workflow

Press **F5**, pick **Full stack (DB + API + Web)**. That:

1. Runs `api: prelaunch` → `docker start financedb`, then `dotnet build`.
2. Launches the API on `http://localhost:5046` with the debugger attached.
3. Launches the Vite dev server, and opens a browser once it prints its `Local:` line.

Breakpoints work in C# **and** in server-side SvelteKit code (`+page.server.ts`, `hooks.server.ts`)
because the dev server runs under the Node debugger. `stopAll: true` on the compound means stopping
either session tears down both.

## Three things that bite

- **The API config bypasses `launchSettings.json`.** Pointing `program` at the built `Api.dll`
  launches the assembly directly, so the `http`/`https` profiles are never read. `ASPNETCORE_URLS`
  and `ASPNETCORE_ENVIRONMENT` are therefore **duplicated** into the launch config's `env` block.
  **Change the port in one place and the other silently keeps the old value** — `dotnet run` reads
  `launchSettings.json`, F5 reads `launch.json`. Keep them in sync. (The C# extension's
  `"launchSettingsProfile": "http"` key would read the profile instead and remove the duplication;
  it was passed over deliberately in favor of explicit, visible wiring.)
- **Compounds have no ordering.** Every configuration in a compound starts *simultaneously*; there
  is no "wait until the API is healthy" primitive. This is the real reason Docker is a
  `preLaunchTask` and not a compound entry — a task is guaranteed to complete before the
  configuration launches, and `dependsOrder: "sequence"` orders the steps within it. Omit that key
  and `dependsOn` entries run in parallel, racing the build against Docker.
- **SQL Server isn't ready when `docker start` returns.** The command exits as soon as the container
  is up, not when the engine accepts connections. EF Core connects lazily on the first query, so a
  cold-start request can fail with a connection error even though every launch step succeeded —
  retry it. A real readiness probe (`sqlcmd` in a retry loop) is deferred until this actually hurts.

`docker start` on an already-running container is a no-op that exits 0, so re-launching is safe. If
the container doesn't exist at all the task fails and blocks the launch — the intended behavior;
create it once per `SETUP.md` step 6.

# Frontend — SvelteKit

The SvelteKit web frontend — the layer between the .NET API (`Api/`) and the browser. Reflects
what actually landed in the `sveltekit-skeleton` work; update it as the UI grows.

> The frontend is **the owner's learning target** — SvelteKit, web dev, and front-end CSS are all
> new to them (their JS background is blackbox QA scripting, not web development). Read
> [`learning-approach.md`](learning-approach.md) before touching `SvelteKit/` code: guide, don't
> do. (This doc itself is meta/scaffolding and may be edited normally.)

## Project layout

- **Single app**, `SvelteKit/`, a root-level sibling of `Api/` and `MSSQL/` (named by technology,
  matching the `MSSQL/` precedent). Scaffolded with the **`sv` CLI** (`npx sv create SvelteKit`),
  **SvelteKit minimal** template — barebones, not the demo app.
- **TypeScript** (not JSDoc): the owner knows TS and wants the compile-time checking; it also keeps
  the same strongly-typed discipline they use in the C# API.
- **Svelte 5** + **Vite** (the build tool / dev server under SvelteKit).
- **Add-ons: prettier + eslint only.** Tailwind, vitest, and playwright were **deliberately
  deferred** — see Styling and Testing below.
- **Package manager: npm.** Yarn Classic (1.x) was rejected as frozen/maintenance-mode; the owner's
  team uses it, so they'll learn it in that context instead. npm ships with Node (nothing extra to
  install). If a "modern fast" manager is ever wanted on a personal project, that's **pnpm**, not
  yarn Berry.

Key paths:

- `SvelteKit/src/routes/` — the app's pages. **Filesystem-based routing**: a folder's path *is* its
  URL, and a `+page.svelte` inside it is the page shown at that URL (`src/routes/accounts/+page.svelte`
  → `/accounts`, no route table). The `+` prefix marks a file as SvelteKit-**special** (`+page`,
  `+layout`, later `+page.ts`/`+server.ts`) versus a plain component.
- `SvelteKit/src/lib/` — reusable modules, importable via the **`$lib`** alias.
- `SvelteKit/src/app.html` — the outer HTML shell; `%sveltekit.body%` is where the app renders.
- `SvelteKit/static/` — files served as-is (favicon, images).
- `SvelteKit/package.json` — manifest + `scripts` (see below).
- `node_modules/`, `.svelte-kit/` — generated, gitignored; never edited by hand.

## Running it

From `SvelteKit/`:

```powershell
npm run dev       # Vite dev server + hot-module reload (HMR); prints a localhost URL (~5173)
npm run build     # production bundle
npm run preview   # serve the production build locally
npm run check     # TypeScript check (svelte-check — see gotcha below)
npm run lint      # prettier --check + eslint
npm run format    # prettier --write (auto-format)
```

- **`npm run <name>` is the front door** to these. Running the underlying tool raw (`vite dev`)
  fails because tools install into `node_modules/.bin/`, which isn't on `PATH`; npm scripts prepend
  it. `npx vite dev` works because `npx` looks there first.
- **TS gotcha**: `tsc` can't see inside `.svelte` files. The checker is **`svelte-check`**, wired to
  `npm run check`. "Does it type-check?" = `npm run check`, not `tsc`.

## Conventions (settling)

- **TypeScript everywhere** — `<script lang="ts">`.
- **Casing**: `camelCase` for variables/functions (JS/TS idiom — *not* Python `snake_case`);
  `PascalCase` for components and types (aligns with the C# side).
- **Let TS infer** obvious literals (`const appName = "…"` — no `: string`); annotate only the
  non-obvious (params, empty arrays, API response shapes).
- **Svelte 5 runes**: reactivity is **explicit**. A plain `let` is *not* reactive — mutable state
  that drives the UI must be declared with the **`$state()`** rune (`let count = $state(0)`), then
  reassigned normally. Values that never change stay `const` (no rune).
- **Scoped styles**: a component's `<style>` block applies only to that component by default.

## Styling

- **Plain CSS / Svelte scoped styles first.** Tailwind was deferred on purpose: the owner is new to
  web styling, and learning CSS fundamentals and a utility-class framework simultaneously muddies
  both. Revisit Tailwind later as a **deliberate** choice, not a default.

## Testing

- **None yet, on purpose** — add tests when there's logic worth testing. The owner is a QA
  automation engineer, so this is home turf; the plan is to introduce it deliberately, not scaffold
  it empty. **vitest** for unit tests and **playwright** for end-to-end (the owner comes from
  Selenium; Playwright manages its own browser binaries, no separate driver) are the intended tools
  when that time comes.

## Talking to the API (open — first vertical slice)

- Not wired yet. The **first vertical slice** is making a page fetch `GET /accounts` from the .NET
  API and render it (DB → API → screen, end-to-end).
- The **SvelteKit data-loading approach** is still an open question (`load` functions in `+page.ts`
  vs. client-side `fetch` in the component) — see `tech-stack.md`. Also expect to deal with **CORS**
  (the API on `http://localhost:5046`, the dev server on `~5173` — different origins).

## Current state

- Skeleton complete: the default SvelteKit page renders and HMR works. Verified via `npm run dev`.
- Does **not** call the API yet, has no styling, no routes beyond `/`.
- Next: the first vertical slice — `/accounts` fetching from the API.

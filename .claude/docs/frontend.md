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

## Talking to the API

The **first vertical slice** is done: the `/accounts` page fetches `GET /accounts` from the .NET
API and renders the rows (DB → API → screen, end-to-end). What settled:

- **Data-loading approach: a universal `load` function in `+page.ts`** (not client-side `fetch` in
  the component). It runs on the server during SSR *or* in the browser on client-side navigation,
  and receives SvelteKit's **wrapped `fetch`** (a superset of the standard `fetch` — handles
  relative URLs and SSR). Whatever object `load` returns reaches the component as the `data` prop;
  a **throw** in `load` (e.g. a rejected fetch) fails the whole page to SvelteKit's error page.
- **Typing**: annotate `load` with `PageLoad` from the generated `./$types` (SvelteKit writes those
  per-route under `.svelte-kit/` — run `npm run dev` once if the editor can't find them). Type the
  parsed JSON as an app shape (`Account` in `src/lib/types.ts`, re-exported from `$lib`). The page
  component reads props via `let { data }: PageProps = $props()` (also from `./$types`).
- **API JSON gotchas** when writing response types: .NET serializes properties as **camelCase**
  (`Name` → `name`) and `DateTime` as an **ISO-8601 string** (JSON has no date type);
  `decimal`/`int`/`byte` all map to TS `number` (watch `decimal`→`number` precision for money later).
  A nullable column (`decimal?`) serializes as JSON `null` (never `undefined` — JSON has no
  `undefined` token), so its TS type is `… | null`, not `… | undefined`.
- **The response type is an unverified promise.** TS can't check a hand-written response type against
  a live server, so when the API's shape changes (e.g. returning names via a DTO instead of FK ids)
  the frontend type *and* the template must change in lockstep — otherwise you get silent
  `undefined`s (blank cells), not a compile error.
- **CORS is handled on the API side** (see `api.md`); the frontend needs no CORS code.
- **Still hardcoded** (dev convenience — revisit with config when a second environment exists): the
  API base URL (`http://localhost:5046`) in `load`.

## Display formatting

Formatting raw API values for humans is a **frontend** job (the API sends raw data — `505.0000`,
`2025-02-21T00:00:00`):

- **Money** → `Intl.NumberFormat("en-US", { style: "currency", currency: "USD" })`, constructed
  **once** as a `const` in `<script>` and reused via `.format(n)` per row (building a formatter is
  comparatively costly). It handles sign, 2-decimal padding, and grouping — don't hand-roll
  `"$" + n.toFixed(2)`. `Intl.DateTimeFormat` is the same tool for dates.
- **Nullish display**: prefer `?? 0` (nullish coalescing — only `null`/`undefined`) over `|| 0`
  (any falsy) when substituting for a possibly-null number; decide whether "no value" should render
  as `$0.00` or a blank cell.
- **Known issue — timezone-less dates.** `DATETIME2` columns serialize with **no zone marker**
  (`"2025-02-21T00:00:00"`, no trailing `Z`), and JS parses a zone-less datetime as **local** time,
  which can shift the displayed *day*. Currently dodged by showing date-only midnight values; give
  this a proper fix (how dates are stored/represented UTC-wise) when transaction **entry** (writing
  dates back) lands.

## Current state

- **Two vertical slices complete**, same shape (`+page.ts` universal `load` → typed `data` prop →
  `+page.svelte` table): `/accounts` renders `GET /accounts`; `/transactions` renders
  `GET /transactions` with related **names** (not ids), money via `Intl.NumberFormat`, and
  date-only formatting. Both verified end-to-end against the containerized DB and running API.
- `/` is still the default skeleton page; no styling yet (plain tables, per plain-CSS-first) — a
  scoped `<style>` pass (e.g. right-aligning numeric columns) is the deferred next polish.
- Next: styling pass; the timezone-less-date fix when transaction entry lands; move the hardcoded
  dev URL (`http://localhost:5046`) to config when a second environment appears.

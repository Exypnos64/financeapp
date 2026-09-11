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
- **Or press F5 in VS Code** — the `Web (SvelteKit)` configuration runs `npm run dev` under the Node
  debugger (so breakpoints work in `+page.server.ts` / `hooks.server.ts`, not just via browser
  devtools) and opens the browser when Vite is ready. The `Full stack` compound starts the DB
  container and API alongside it. See [`editor-debugging.md`](editor-debugging.md).

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
  API base URL (`http://localhost:5046`), now a hand-declared `API_BASE` constant in three files.
  `$env/static/public` is where it belongs; tracked in `TODO.md`. Note the constant was first named
  `URL`, which **shadows the global `URL` class** inside that module — legal, invisible to
  TypeScript, and a landmine for whoever later wants `new URL(...)`.

## Writing to the API — form actions

The transaction-entry slice writes back through a **form action** in `+page.server.ts`, chosen over
a client-side `fetch` because it works without JS and because server-to-server calls sidestep CORS
entirely.

- **`+page.server.ts` is server-only**, and that is visible in the generated types: its `./$types`
  exports `PageServerLoad`, `Actions`, and `ActionData` — and **no `PageLoad`**. The `$types` file is
  generated per route from the files you actually created, so it mirrors your folder rather than
  offering a fixed menu. A universal `load` in `+page.ts` runs on the server *and* again in the
  browser; a server `load` runs only on the server, which is what keeps the API URL off the client.
- **Shape**: `export const actions = { default: async ({ request, fetch }) => … } satisfies Actions;`
  A `POST` to the route with no `?/name` lands on `default`, so `<form method="POST">` needs no
  `action` attribute. Put `satisfies Actions` on the **object**, not on the handler.
- **`await request.formData()`** returns `FormData`. Three things bite:
  - `.get()` returns `FormDataEntryValue | null` — every value arrives as a **string**; form data has
    no numbers.
  - Blank optional inputs arrive as **`""`, not `null`** — the field is present, just empty. Sending
    `""` where the API expects `decimal?` is a 400.
  - **`Number("")` is `0`.** A blank cash-back field silently becomes `$0.00` — exactly the "zero
    cashback vs. none recorded" distinction flagged under Display formatting. Convert to `null`
    *first*, then to a number.
- **`fetch` takes the URL first and everything else in an options object** — `method`, `headers`,
  `body`. Omitting `Content-Type: application/json` gets **415 Unsupported Media Type** from ASP.NET,
  which is a confusing error to chase because the body looks fine.
- **`fail(status, payload)` is `return`ed; `redirect(303, location)` is called bare** (SvelteKit 2
  does not use `throw`). 303 is the POST-then-GET convention, so a refresh doesn't resubmit.
  **Never wrap the redirect in a `try`/`catch`** — it signals *by* throwing, so a `try` around the
  action body catches its own redirect and turns a successful save into a mysterious 500.
- **`ActionData` is the union of every value the action can return**, so two `fail` calls with
  different payload shapes make `form.values` a type error on the page (`Property 'values' does not
  exist on type '{ message: string; }'`). Keep every `fail` payload the same shape.
- **The `fail` payload is the only thing that survives the round trip.** On failure SvelteKit re-runs
  `load` and rebuilds the page, so anything not in that payload is gone and the user retypes the
  form. `Object.fromEntries(formData)` grabs every submitted field in one line. Two traps when
  feeding it back: the values are **strings** while `<option value={x.id}>` are **numbers**, so
  `bind:value` compares strictly and silently blanks the select unless you `Number()` them — and the
  `??` fallback has to come *before* the conversion, since `Number(undefined)` is `NaN`.
- **`response.ok` beats a `switch` on status codes** — it's true for any 2xx, and enumerating codes
  means everything unanticipated falls into `default`.

### Timezones on write — the load-bearing part

`<input type="datetime-local">` submits `"2026-09-11T14:30"` with **no offset**, but `UserDate` is
`DATETIMEOFFSET` and `project-vision.md` requires the offset to be captured from the device. A
server action cannot recover it — it's a different machine.

The mechanism: the **visible picker** carries its own `name` (round-trips its own format on a failed
submit) and a **hidden field** carries the value actually sent, one-way `value={derived}`. A `$state`
holds the picker's value; a `$derived` builds the submitted string. This is the one place
`bind:value` genuinely earns itself — the selects don't need it, since `name` is what submits.

The conversion needs no date arithmetic at all: `"2026-09-11T14:30"` is **already local wall-clock in
ISO field order**, so you only append seconds and an offset to get
`"2026-09-11T14:30:00-05:00"`. The `Date` object exists solely to ask for the offset. Four traps:

- **`getTimezoneOffset()` returns minutes to *add* to local to reach UTC** — US Central in summer
  returns `300` and the string you want is `-05:00`. The sign is inverted.
- **Take `Math.abs` of both hours and minutes** before padding; `padStart` only adds characters and
  can't strip a `-`.
- **Zones like `+05:30` and `+12:45` exist** — build from minutes, never assume whole hours.
- **Ask the transaction's date for its offset, not `new Date()`.** Offsets are DST-dependent, so
  entering a January transaction in September stamps `-05:00` on a date that was `-06:00`.

**The failure mode that makes this worth documenting**: System.Text.Json does *not* reject an
offset-less string. It parses it and silently applies the **server's** offset — and DST-correctly for
that date (`"2026-01-15T14:30"` → `-06:00`, `"2026-07-15T14:30"` → `-05:00`). So while the browser and
the API share a machine, sending the raw picker value and sending the correct offset produce
**byte-identical rows for every date**. The bug is invisible locally and only appears once the API
runs in another zone — a UTC container, or a deployed host. Inspecting stored rows cannot verify this
code; only reading the request body can. A parser that fills in a default for ambiguous input is more
dangerous than one that rejects it.

**No-JS consequence**: the hidden field can only be populated by JS, so a no-script submit sends
`""`. The action guards for it explicitly and returns its own `fail` — a message you wrote beats
whatever .NET says about an unparseable `DateTimeOffset`.

## Display formatting

Formatting raw API values for humans is a **frontend** job (the API sends raw data — `505.0000`,
`2025-02-21T00:00:00`):

- **Money** → `Intl.NumberFormat("en-US", { style: "currency", currency: "USD" })`, constructed
  **once** as a `const` in `<script>` and reused via `.format(n)` per row (building a formatter is
  comparatively costly). It handles sign, 2-decimal padding, and grouping — don't hand-roll
  `"$" + n.toFixed(2)`. `Intl.DateTimeFormat` is the same tool for dates.
- **Nullish display**: prefer `?? 0` (nullish coalescing — only `null`/`undefined`) over `|| 0`
  (any falsy) when substituting for a possibly-null number; decide whether "no value" should render
  as `$0.00` or a blank cell. **Open**: `cashBack` is `NULL` on every current row and renders as
  `$0.00`, which reads as "zero cashback" rather than "none recorded". A blank cell is probably
  truer; decide deliberately rather than inheriting it.
- **Timezone-less dates — resolved by the schema, not by frontend code.** This used to be a known
  bug: `DATETIME2` columns serialized with no zone marker (`"2025-02-21T00:00:00"`), and JS parses a
  zone-less datetime as **local**, which could shift the displayed *day*. User-meaningful columns are
  now `DATETIMEOFFSET`, so they serialize *with* the offset (`"2025-02-21T00:00:00-06:00"`) and JS
  parses them unambiguously. System timestamps (`lastModifiedUtc`) are still zone-less `DATETIME2` —
  fine, since they're never displayed as a calendar date.
- **Still worth knowing for transaction entry**: `Intl.DateTimeFormat` formats an instant in the
  *viewer's* zone. For a transaction date you usually want the date as it was **in the offset it was
  recorded in** — otherwise a late-evening purchase can display a day off for a viewer in another
  zone. Storing the offset makes that possible; it doesn't happen automatically.

## Current state

- **Two vertical slices complete**, same shape (`+page.ts` universal `load` → typed `data` prop →
  `+page.svelte` table): `/accounts` renders `GET /accounts`; `/transactions` renders
  `GET /transactions` with related **names** (not ids), money via `Intl.NumberFormat`, and
  date-only formatting. Both verified end-to-end against the containerized DB and running API,
  including after the merchant-ownership schema refactor.
- The refactor renamed `userDateUtc` → `userDate` on the transaction shape. A reminder of why that
  mattered: the response type is hand-written, so a server-side rename produces **blank cells**, not
  a compile error — the type and the template have to move in lockstep.
- `/` is still the default skeleton page; no styling yet (plain tables, per plain-CSS-first) — a
  scoped `<style>` pass (e.g. right-aligning numeric columns) is the deferred next polish.
- **Done: the transaction-entry slice** — `/transactions/new`, the first page that *writes*. A
  `+page.server.ts` holds both halves: a `PageServerLoad` that fetches `/accounts`, `/categories`
  and `/merchants` concurrently, and a `default` form action that POSTs to `/transactions` and then
  `redirect`s to the list. See *Writing to the API — form actions* above for the mechanics; the
  decisions worth remembering:
  - **`Promise.all` over a literal tuple, not `.map()` over a URL list.** Both fetch concurrently,
    but `Promise.all([a(), b()])` infers a **tuple** so each destructured result keeps its own type,
    whereas `.map()` collapses to `Promise<any>[]` and the results become positionally
    interchangeable with nothing to catch a swap.
  - **The category `<select>` groups with `<optgroup>`**, built from `Map.groupBy(categories, c =>
    c.set.id)` in a `$derived` (not a function called from the template, which recomputes every
    render). Grouping by the `set` **object** does not work — `Map.groupBy` compares keys by
    identity and every row's `set` is a distinct object after `JSON.parse`.
  - **Hand-written response types are still unverified** — `Merchant`, `Category` and `CategorySet`
    in `src/lib/types.ts` mirror the API by assertion, including `CategoryLi`'s nesting. Same
    silent-`undefined` exposure as the read slices.
  - **`npm run check` is the tool that catches this class of bug** — it found the `ActionData` union
    error and seven `state_referenced_locally` warnings that `dotnet build`-style confidence would
    have missed entirely.
- Next: the **edit/delete slice** — an edit page backed by `GET`/`PUT`/`DELETE /transactions/{id}`,
  which raises a real design call: one form component shared by create *and* edit, or two pages.
  After that a **styling pass** (plain scoped CSS; the entry form currently lays out with `<br>`
  tags), then `use:enhance` for progressive enhancement — which will break the form's `$state`
  initializers in the way those warnings describe. All tracked in `TODO.md`.

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
- **Form inputs use `bind:value`, never one-way `value={x}`.** A one-way `value=` sends state to the
  DOM and never back, so what the user typed lives *only* in the DOM and any re-render can overwrite
  it from stale state. This cost two debugging sessions and survived a commit: typing an amount, then
  touching the date picker, silently blanked the amount — the date field was bound, so changing it
  triggered the render that re-asserted the unbound fields. Unlike React, where `value=` plus an
  `onChange` is the normal controlled input, in Svelte **`bind:` *is* the controlled input**.
- **Never seed `$state` with `Number(undefined)`** — that is `NaN`, not `0` or empty. `NaN` is also
  the one value not equal to itself, so any "has this changed?" guard always reports a change. Put
  the `??` fallback *before* the conversion.
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
- **The API base URL is `PUBLIC_API_BASE`**, read from a **committed** `SvelteKit/.env` and
  referenced in exactly one file (`src/lib/api.ts`). See *Shared modules* below for why it is
  committed and why the constant no longer appears in route files. Historical note: it was first
  named `URL`, which **shadows the global `URL` class** inside that module — legal, invisible to
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

The mechanism: each piece of information has **one source**. The **visible picker** (`datePicker`)
carries the local wall-clock time; a **hidden field** (`userOffset`) carries *only* the browser's
offset in minutes, one-way `value={derived}` from `new Date(setDate).getTimezoneOffset()`. The
**server** combines them in `transformDate` (`src/lib/dates.ts`, called from
`$lib/server/transactions.ts`), so every submit path formats the date the same way.

An earlier version had the hidden field carry the whole pre-formatted date. That sent the date twice
and made the no-JS path depend on a value only JS could compute — see *No-JS consequence* below.

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

**No-JS consequence — never let the no-JS path depend on a value JS computes.** Without JS, component
code runs only during the server render, so a `$derived` hidden field is frozen at whatever the server
computed. With the old full-date hidden field, a fresh page rendered it as `""`, so a no-JS create
*always* failed its first submit and a no-JS edit silently saved the **old** date. Now the guard runs
on `datePicker` (what the user actually picked), and the offset has a fallback:

- **A fresh no-JS page sends `userOffset="NaN"`, not an empty field** — the server render evaluated
  `new Date('').getTimezoneOffset()`. So `transformDate` uses the sent offset only if it is a real
  number and otherwise falls back to the **server's** offset for that date. That fallback is a
  degraded approximation — correct only while server and browser share a zone — and the price of
  working without JS at all.
- **`||` is the wrong fallback operator for an offset.** `0` is falsy, so `offset || fallback`
  discards a real UTC user's offset (London in winter) and stamps the server's. `??` is no better —
  it never falls back on `NaN`. Test it with DevTools → Sensors → a London location on a winter date.
- **`Number()` turns a *missing* field into `0`** (`Number(null)`, `Number('')`), which then reads as
  UTC. The form always sends the field, so only a non-form client hits it today; if it matters, the
  place to turn "missing" into `NaN` is `validateTransaction`, before `transformDate` sees it.
- The fully correct answer is the user's **IANA time zone** as a preference, not an offset per
  submit — see `project-vision.md` → Dates and time zones.

## Shared modules — `$lib` and `$lib/server`

Everything reusable lives under `src/lib/`, and **which subtree it lives in is a boundary, not a
filing preference**:

- **`$lib/`** — importable by anything, including code that runs in the browser: `types.ts`,
  `api.ts`, `components/`.
- **`$lib/server/`** — SvelteKit **refuses to let client code import it** and fails the build if you
  try. Server-only logic goes here: `server/transactions.ts` holds the form parsing and the response
  handling shared by the create and edit actions.
- **Do not re-export `$lib/server` through `$lib/index.ts`.** The barrel is imported by components
  for types, so routing server code through it puts it straight back into the client graph and
  silently defeats the guard. Import server modules by full path (`$lib/server/transactions`).

`ApiLoader` (`src/lib/api.ts`) is the only thing that knows where the API is. It takes the
request-scoped `fetch` in its constructor and prefixes `PUBLIC_API_BASE` onto every path, so route
files pass paths (`"/accounts"`), never URLs.

- **The event `fetch` must be passed in**, not reached for globally — SvelteKit's wrapped `fetch`
  forwards cookies, resolves relative URLs, and lets SSR reuse responses. A new instance per event is
  correct, not wasteful; a module-scope singleton would be the bug.
- **Naming the parameter `fetch` shadows the global**, so the annotation is `typeof globalThis.fetch`
  — plain `typeof fetch` is self-referential and won't compile.
- **Reads and writes want opposite failure handling, so they are separate methods.** `getJson` throws
  `error(status, await response.text())` — a failed *load* should render an error page and there is
  nothing left to say. `sendJson` returns the raw `Response` — a failed *action* must `return
  fail(...)` so the page re-renders with the user's input intact; throwing `error()` there would
  render an error page and discard everything they typed.
- `Accept: application/json` goes on every request; `Content-Type` only when there is a body, via a
  conditional spread — spreading `false` into an object literal contributes nothing.

**Env vars.** `PUBLIC_`-prefixed values are inlined into the client bundle, so they are non-secret by
construction, and `$env/static/public` resolves at **build** time, so a clone missing the file fails
to build rather than merely misconfiguring. Both reasons are why `SvelteKit/.env` is committed — a
deliberate departure from the `db.env` / `db.env.example` pattern, which guards a real password. Keep
it to `PUBLIC_` vars; anything private goes in `.env.local`, already excluded by the template's
`.gitignore`. Getting the committed `.env` past git needed the negation in **`SvelteKit/.gitignore`**,
not the root one: a nested `.gitignore` overrides its parents for files beneath it, and
`git check-ignore -v <path>` names the exact file and line that decided.

## Routing conventions

- **The route tree is the documentation.** `/transactions/[id]/edit` tells a new dev where the edit
  page is; `[id]` alone reads as a detail view and hides the fact that it is a form. It matches the
  Rails/Django convention (`/things/:id` shows, `/things/:id/edit` edits) and leaves `[id]` free for
  the detail view that splits and attachments will eventually want.
- **Build internal links with `resolve()` from `$app/paths`.** It is typed against the generated
  route union, so a path that no longer exists is an `npm run check` error rather than a 404 found by
  clicking. The `[id]` to `[id]/edit` rename was caught exactly this way.

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
- **Done: the edit/delete slice** — `/transactions/[id]`, backed by `GET`/`PUT`/`DELETE
  /transactions/{id}`, plus an Edit link on every row of the list. The decisions worth remembering:
  - **Named form actions are HTTP endpoints, not functions.** The first attempt imported `actions`
    from `./proxy+page.server` (a Vite build artifact, not an importable module) and wired it to
    `onclick` — `+page.server.ts` never ships to the browser, which is the whole point of `.server`
    in the filename. A named action is addressed by **query string**: `POST /transactions/2?/delete`.
  - **`formaction` is what lets one form have two destinations.** Plain HTML: the `<form>` carries
    `action="?/update"` and the Delete button overrides it with `formaction="?/delete"`. No JS, and
    it works before any JS loads.
  - **SvelteKit refuses to mix a `default` action with named ones** — it 500s on page load, and the
    error names neither the button nor the action you just added. Renaming `default` to `update` is
    mandatory, not stylistic.
  - **`formnovalidate` on Delete.** The form's `required` fields are validated on *any* submit
    button, so without it the browser silently blocks a delete whenever a field is blank — "throw
    this away" shouldn't require the form to be valid first.
  - **`[id]`, not `[slug]`.** The directory name *is* the property name (`params.id`), and a "slug"
    means a URL-friendly text key, not an integer primary key. Renaming is cheapest immediately.
  - **Edit is a link, not a button.** `<a href={resolve(...)}>` is navigation, so middle-click,
    open-in-new-tab and the back button all work for free; a `<button>` would need a handler to do
    the same job worse.
  - **`reduceDate` is the inverse of `transformDate`.** A `datetime-local` input cannot accept an
    offset, so a stored `DATETIMEOFFSET` has to be stripped back to `YYYY-MM-DDTHH:mm` to prefill the
    picker, then have the offset reattached on submit. **Still duplicated**: `transformDate` and
    `categoryGroups` exist in both pages. A first pass extracted them to `src/lib/dates.ts`, but
    neither page was switched over to import from it, so the file was dropped rather than landed
    unused — pure functions with no markup and no state don't belong in a `.svelte` file, and the
    extraction happens for real alongside the shared component.
- **Done: the shared-form refactor slice** — no new features; four `TODO.md` items closed. The
  create and edit pages collapsed to 12 and 17 lines behind
  `src/lib/components/TransactionForm.svelte`, the edit route became `[id]/edit`, the duplicated
  server logic moved to `$lib/server/transactions.ts`, and the API base URL became `PUBLIC_API_BASE`
  behind `ApiLoader`. The decisions worth remembering:
  - **A component declares its own props type — `./$types` is route-only.** `$types` is generated per
    *route* by `svelte-kit sync`, so a component under `src/lib/` importing it fails outright. Even
    where it would resolve, `PageProps` describes the page's contract, not the component's.
  - **Ask for the narrowest props, not the page's whole `data` blob.** The two pages return different
    shapes (only the edit page has `transaction`), so a single `data` prop forces the optionality
    onto the entire object. Flat props put it on the one field that actually varies.
  - **`x?: T` and `x: T | undefined` are different contracts.** The first may be omitted; the second
    must be passed, possibly as `undefined`. A default in the `$props()` destructuring does **not**
    make the declared type optional — callers are checked against the type, not the default.
  - **`ReturnType<typeof fail>` silently erases the payload.** `fail` is generic in its data, so
    `ReturnType` with no type argument gives `ActionFailure<unknown>`. SvelteKit unwraps that to
    `unknown`, and **`unknown` absorbs a union** — one poisoned member collapsed the whole of
    `ActionData` to `{}`. It appeared in *two* declarations, so fixing either one alone left the
    error byte-identical and looking unfixed. Name the payload type and use `ActionFailure<That>`.
  - **Narrow, don't coerce, when parsing `FormData`.** `.get()` returns `string | File | null`, so
    `String(x)` silences the type error by converting everything — `String(null)` is the *truthy*
    string `"null"`, and a `File` becomes `"[object File]"`. `typeof x === "string"` excludes those
    cases instead of stringifying them.
  - **`{#key expr}` is how a form re-initializes.** `$state(prop)` is an initializer, not a binding —
    it runs once per instance. `{#key data.transaction.id}` destroys and rebuilds the component when
    the id changes. Key on the **id**, not the object: `load` parses a fresh object every navigation,
    so keying on identity would remount on every visit. `$derived` cannot substitute (read-only, so
    the fields stop being editable), and an `$effect` copying props into state is the classic
    anti-pattern — it runs after render and invites loops.
  - **Latent bugs need a reproduction before a fix.** Nothing in the UI navigates id-to-id, so the
    `{#key}` bug was unreachable by clicking; temporary prev/next links reproduced it, and were
    removed once the fix was confirmed.
  - **A lost edit looks exactly like a regression.** The `bind:value` fix was made, verified, and
    then lost before the commit, so the cleared-amount bug resurfaced later looking new.
    `git show HEAD:<file>` answers "was this ever actually committed?" in one command.
- **Done: progressive enhancement.** `import { enhance } from '$app/forms'` plus `use:enhance` on
  the `<form>` in `TransactionForm.svelte` — two lines, no change to either `+page.server.ts`. That
  is the point of the feature: it is *additive*, so the server action and the no-JS path are
  untouched. The decisions and surprises worth remembering:
  - **An enhanced `fail()` returns HTTP 200.** This is the one that will waste an afternoon if it is
    not written down. `handle_action_json_request` builds the failure response as
    `action_json({ type: 'failure', status, data })` with **no** `init` argument, so the HTTP status
    defaults to 200 and the real status rides inside the JSON body. Redirects behave the same way
    (`action_json_redirect` returns 200 carrying `{type:'redirect', status:303, location}`) — a real
    303 would be followed by the browser before `enhance` could intercept it. The contrast that
    explains the rule: when an action *throws*, SvelteKit **does** pass a status, so "the action
    failed to run" is a transport-level error while "the action ran and returned a failure" is an
    expected outcome in an envelope. The .NET API still returns its genuine 422; only SvelteKit's
    action layer wraps it, so anything asserting on a status code has to know which of the two
    layers it is talking to.
  - **The anticipated `$state` trap never materialized.** The prediction was that
    `$state(form?.values?.… ?? …)` would break once a failed submit stopped remounting the component.
    It did stop re-running — and nothing broke, because `bind:value` means the typed values were
    still sitting in the DOM. Restoring them is only necessary when the browser has thrown them
    away.
  - **The two submit paths need opposite mechanisms, and one line serves both.** JS on: no remount,
    initializers never re-run, `bind:value` holds the values. JS off: fresh mount, `bind:value` holds
    nothing, `form.values` is the only surviving record of what was typed. Deleting the
    `form?.values?.…` reads as "dead code" would silently wipe a filled-out form for every no-JS
    user on every validation failure. Test progressive enhancement with DevTools’
    **Disable JavaScript** — the enhanced path is the easy one to check and the only one most people
    check.
  - **`svelte-ignore state_referenced_locally` turned out to be correct, not a workaround.** The
    warning says "this is read once, at mount"; that is now precisely the intent on both paths.
  - **One `use:enhance` on the `<form>` covers the Delete button too.** `enhance` resolves the target
    from `event.submitter`, honouring `formaction`/`formmethod`/`formenctype` when the submitter
    carries them (`app/forms.js:129`), and passes the submitter into
    `new FormData(form_element, event.submitter)` so the button’s own `name` is still submitted. The
    action does **not** have to be hoisted onto each button. The source comment there is worth
    knowing: it cannot read `submitter.formAction` directly, because that property is *always*
    populated — it falls back to the form’s action — so it has to test `hasAttribute('formaction')`
    first to tell "overridden" from "inherited". `formnovalidate` is unaffected: native validation
    runs before the `submit` event, so it never reaches `enhance` either way.
- **Done: idempotent create** (the frontend half; the API half is in `api.md`). The create form
  sends a hidden `uuid`, forwarded as `idempotencyKey`. The decisions worth remembering:
  - **Mint the key when the page loads, not when the form submits.** A key minted per submit is new
    on every retry, which protects nothing. It is minted once in `new/+page.server.ts`'s `load` and
    passed to `TransactionForm` as an optional `uuid` prop; the hidden input renders only when there
    is one, so the edit page sends none. (Minting inside the component also works, but runs twice —
    once in the server render, again when the browser takes over.)
  - **After a failed submit, the old key must win.** `load` re-runs after a failed action and mints a
    *fresh* key, but the failed attempt may already have been written (the 500-after-commit case), so
    `form?.values?.uuid ?? uuid` — the submitted key first. Put the prop first and a resubmit becomes
    exactly the duplicate this slice exists to prevent.
  - **`a ?? b ? x : y` parses as `(a ?? b) ? x : y`.** `??` binds tighter than the conditional, so the
    first version regenerated the key whenever one came back from a failed submit. Parenthesise any
    `??` that sits next to a `?:`.
  - **Excess properties from a spread are not type-checked.** `...(cond && { idempotencyKey })` onto
    a `ValidatedTransaction` that lacked the field passed `npm run check` silently; the field had to be
    added to the type for the checker to see it.
  - The **no-JS date bug** this slice uncovered (it predated the slice) is written up under
    *Timezones on write* → *No-JS consequence*. `transformDate` finally lives in `src/lib/dates.ts`,
    imported only by server code.
- Also landed alongside: a **New** link on the transactions list and a **Cancel** link on the form.
- Next: the **styling pass** (plain scoped CSS; the forms still lay out with `<br>` tags), and the
  category-set uniqueness question. `npm run format` has been run across the app, so prettier's
  output is now the formatting baseline. All tracked in `TODO.md`.

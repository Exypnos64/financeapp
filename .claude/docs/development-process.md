# Development Process & Roadmap

How building this app is expected to *proceed* — the order of work, what backtracking to expect,
and the problems to watch for. This is the "how we'll work" companion to
[`project-vision.md`](project-vision.md) (what we're building),
[`tech-stack.md`](tech-stack.md) (what we're building it with), and
[`learning-approach.md`](learning-approach.md) (how Claude teaches while we build).

> This is a compass, not a contract. Because the point is learning, detours that teach something
> valuable are fine even when they don't follow the order below.

## The overall arc

For this stack (SQL Server → .NET API → SvelteKit) development goes **bottom-up to lay the
foundation, then in thin vertical slices**:

1. **Data model first (the DB).** Decide what "things" exist (accounts, transactions, users,
   buckets…) and how they relate. Everything else sits on this.
2. **Get the DB running in Docker.** A container you can start, connect to, and poke at.
3. **API skeleton.** A .NET project that connects to the DB and exposes a couple of endpoints
   (e.g. "list accounts").
4. **Frontend skeleton.** A SvelteKit app that calls the API and renders something.
5. **First vertical slice.** One feature working end-to-end: DB → API → screen. Likely candidate:
   *"show a list of transactions."*
6. **Repeat slices.** Each new feature (import, budgeting, splitting…) is another slice through
   all three layers.

**The mental model that matters:** after the foundation, stop thinking "finish the DB, then the
API, then the UI." Think in **vertical slices** — one small feature dragged through all three
layers at once. That's what prevents building a large backend with nothing to show and no way to
know if it's right.

## Why the database comes first

It's the hardest thing to change later and the easiest to get subtly wrong. Code is cheap to
rewrite; a database with real data in it is not, because changing the schema means **migrations**
(versioned, ordered changes to a live database — like git commits, but for table structure, and
they must preserve the data already there). (QA-world analogy: the schema is like the fixture data
every test depends on — if its shape is wrong, everything downstream inherits the wrongness.)

## How much backtracking to expect

A fair amount — and that's normal, not failure. Two kinds that feel very different:

- **Cheap backtracking (constant):** renaming things, reshaping an API response, restructuring a
  component. Minutes to an hour. This is just iteration.
- **Expensive backtracking (what we design to avoid):** discovering the *data model* is wrong
  after features and real data are built on top of it. This ripples up through the API and UI and
  forces migrations.

So early DB work will feel slow and talky on purpose — that investment is what keeps the expensive
rework rare. Some rework simply means we're **learning what we actually need**, which can't be
fully known up front. The goal isn't zero rework; it's keeping the expensive rework rare.

## Problems anticipated

### Conceptual (the interesting ones)

- **Modeling sharing / ownership.** *(Largely resolved — see `project-vision.md`.)* Settled on a
  `UserGroup` as the ownership unit rather than per-user grants. Worth noting how this one actually
  played out, because it's the canonical example of the "expensive backtracking" this doc warns
  about: it surfaced sideways, while designing per-user **merchant** lists, when the question "whose
  merchant does a *shared* account's transaction point at?" turned out to have no good answer. The
  sharing model and the merchant-ownership model were the same problem. It got reworked before any
  real data existed, which is the only reason it was cheap. Still open: **master ownership** of an
  account (whoever contributes an account can currently be ejected by the group).
- **Splits-as-one-transaction.** The owner's preferred behavior is *harder* to model than
  Monarch's: a transaction that pulls from multiple buckets but shows as one row needs a
  parent/child structure underneath.
- **Buckets vs. savings goals.** Unsettled whether they're one thing or two — a real design
  question to resolve, not assume.
- **Representing money.** Never store money as floating point (`float`/`double`) — rounding errors
  silently corrupt balances. Use an exact type (e.g. SQL `decimal`). This trips up nearly everyone
  once.

### Practical / environmental (the annoying ones)

- **Docker + SQL Server on Windows.** Getting the container running, published on a port, and
  connecting with the right connection string is a classic first-day slog — very learnable,
  occasionally maddening.
- **Connection strings & secrets.** Connecting without committing passwords to git. There's a
  standard approach; set it up early. (See the secrets rule in `CLAUDE.md`.)
- **.NET's ceremony.** Coming from Python/JS, .NET has more up-front structure (projects,
  solutions, dependency injection, async everywhere). Feels heavy at first, then clicks.
- **Async everywhere.** Database and web calls in C# are almost all `async`/`await` — familiar in
  spirit from JS, stricter in practice.

The two to watch hardest: **data-model design** (expensive to backtrack) and
**Docker/connection setup** (most likely place to lose an afternoon to something small).

## What sessions will feel like

Per the teaching contract, the DB phase especially will be **a lot of questions** — "what's the
relationship between a transaction and an account?", "what happens to a split when you delete one
of its buckets?" — with the owner working out the schema and Claude explaining the *why* behind
each decision and catching problems. Slower than being handed a schema, but it builds real
understanding, which is the point.

**Good first move in a fresh session:** *"let's design the database — start with accounts and
transactions."* Build up from there.

# Project Vision — Finance App

The canonical description of *what we are building and why*. Feature-level product intent lives
here; technology choices live in [`tech-stack.md`](tech-stack.md); how Claude should teach while
building it lives in [`learning-approach.md`](learning-approach.md).

> This is a personal project greenlit at work. The dual goal: (1) ship a finance app the owner
> actually wants to use, and (2) learn full-stack development along the way. When product scope
> and learning value conflict, learning value usually wins — see `learning-approach.md`.

## The elevator pitch

A personal-finance app in the spirit of **Monarch Money**, with two deliberate departures from
how Monarch works:

1. **Bucket (envelope) budgeting** as the preferred budgeting model.
2. **Transaction splitting** that keeps a split as *one* transaction drawing from multiple
   buckets/categories, rather than displaying it as several separate transactions.

At minimum the app must store multiple accounts' worth of transaction data in a database, let the
owner **reconcile bank statements** against manually-entered data, show transaction data, and
support **budgeting**.

## Core concepts

### Accounts — two meanings, keep them distinct

The word "account" is overloaded on purpose; the data model must separate the two:

- **Financial accounts**: the individual real-world accounts — checking, savings, credit card,
  car loan, retirement, etc. A person has several. Transactions belong to these.
- **User accounts**: the login/identity of a person using the app.

### Users, ownership, and shared access

Build with multi-user capability from the start, even though single-user is the only near-term
usage. Requirements:

- Multiple **users** can exist.
- A group of users can **share access to a set of financial accounts** (the classic
  husband-and-wife shared-finances case).
- Sharing is granular: some financial accounts are shared by a group; others are private to one
  user. Example: a couple shares a savings account, a retirement account, and a car loan, but each
  keeps a private checking account the other need not see.
- A user can **grant another user access** to an account, **temporarily or permanently**.
- Prefer a model where a shared account can have **more than one owner** (co-ownership), because
  that better mirrors how a bank treats a joint account, rather than forcing a single owner who
  delegates. One speculative shape: users form a group, access is granted within the group, and
  ownership can be shared. This is a design discussion to have when we get there — not settled.

### Budgeting

Support multiple budgeting styles; the user picks one (or none):

- **Flex budgeting**
- **Category budgeting**
- **Bucket budgeting** — the owner's preferred model; mentally an **envelope** system (the terms
  "bucket" and "envelope" are interchangeable here).

### Tagging

A **tagging system that is separate from** the category/bucket system. Tags are an independent
axis of organization, not a rename of categories.

### Transaction splitting

A single transaction can draw from **more than one bucket/category** while still appearing as
**one transaction** in the list (the owner's preferred behavior). Monarch instead shows a split as
multiple line-items.

- Make the display behavior a **user setting**.
- **Default to Monarch's multi-line style** (so it's familiar), but support the single-line,
  multi-bucket style as the preferred alternative.

### Reconciliation & import

Reconciliation is more than importing a statement. The owner sometimes enters transactions
manually and later needs to reconcile those against the bank's records. The system needs:

- **Statement import** (manually, from bank reports/exports to start — see Plaid under "Later").
- **Reconciliation** that matches imported bank data against manually-entered transactions rather
  than blindly duplicating them.
- **Pattern recognition at two levels:**
  1. **Vendors** — recognize patterns in a transaction's title/description to map it to a single
     canonical vendor, so we don't accumulate many duplicate spellings of the same vendor.
  2. **Recurring transactions** — let the user *expect* recurring transactions, enabling
     look-ahead. Anticipating a recurring transaction and prompting the user is desirable but can
     come later.

### Savings goals

Savings goals are wanted. Open question worth resolving during design: **how a savings goal
differs from a bucket at a technical level** — they may be the same underlying thing with
different presentation. Savings buckets should work under **all budgeting types and under none**.

## Later / deferred (explicitly not now)

- **Plaid integration** to replace manual report import. Deferred because it's unclear how much a
  free Plaid tier actually permits for personal use. Revisit once the manual flow works.
- **Mobile.** Desktop-first; mobile is a down-the-road concern.
- **Auto-anticipating recurring transactions and prompting** — nice-to-have after the core
  recurring-expectation feature exists.
- **Two-tier merchants & categories (public + private, shareable).** The eventual model splits
  both `Merchant` and `Category` into a **public tier** — a vetted, canonical list (merchants with
  properly-sourced logos, pulled from a public source) shared by everyone — and a **private tier**
  each user adds to. Private entries must be **shareable to co-users of a financial account**, so
  their visibility rule has to *mirror* the account-sharing model. This is deferred deliberately:
  it's an **additive** change (a nullable owner column where `NULL` = public, plus a visibility
  rule), so today's single global `Merchant`/`Category` tables don't block it. Build it *alongside*
  (and reusing the pattern of) the account sharing/ownership work — designing it before that model
  exists would mean designing the hard sharing logic twice. Implication for now: keep the seeded
  merchant list minimal/transitional (a public source will supersede it); the seeded default
  category taxonomy is safe to keep (it becomes the public-tier defaults).

## Priority ordering (rough)

1. Data model for financial accounts + transactions (multi-user-aware from the start).
2. Store/display transaction data.
3. Manual statement import + reconciliation against manual entries.
4. Budgeting (bucket first, since it's preferred; then category/flex).
5. Vendor pattern recognition; tagging; transaction splitting.
6. Recurring-transaction expectation & look-ahead.
7. Savings goals.
8. Later: Plaid, mobile, auto-prompting.

> This ordering is a starting compass, not a contract. Because the point is learning, it's fine to
> take a detour that teaches something valuable even if it isn't the next item on the list.

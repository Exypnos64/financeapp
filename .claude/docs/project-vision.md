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
  delegates.

**Settled: the unit of ownership is a *group*, not a user.** A solo user is a group of one; groups
are what own financial accounts and what own the customizable merchant/category lists (below).
`GroupMember` records a user's membership and permission level (read / write / owner). This replaced
an earlier design where users held per-account grants directly — the group model resolves a
collision the per-user version couldn't: a shared account has exactly one merchant list, so
"whose merchant does this shared transaction point at?" has a well-defined answer.

Still open (needs authentication to exist first): **master ownership of an account.** If groups own
accounts, whoever contributed an account can be ejected from the group while the others keep access.
Framing for when we get there — "contributed/owns this account" and "is a member of this group" are
two separate facts; store both rather than deriving one from the other.

### Merchants and categories — a curated tier plus per-group customization

Both are two-tier, and the tiers work differently on purpose.

**Merchants** use a global curated master list (`Merchant`: canonical name, logo path, plus
`Reviewed`/`Approved` flags) with a per-group link table (`GroupMerchant`) whose customization
columns are **nullable — NULL means "inherit from the master row."** Groups start with no adopted
merchants and adopt as they go.

- Customizing is per-group and affects nobody else; resetting to default is simply setting those
  columns back to `NULL`.
- The payoff of inheritance-by-NULL is **propagation**: fixing a name or logo in the master list
  reaches every group that hasn't overridden it.
- A user-created merchant enters the master list unapproved, so only reviewed-and-approved rows are
  offered in search. This is what allows custom merchants without a separate table.
- Duplicate and differently-capitalized names across groups are **expected, not a bug** — two
  businesses may share a name, and a user may want to split one business into several.
- A merchant must have at least one transaction to survive. That can't be expressed as a SQL
  constraint, so it's an application-maintained rule, not a database-enforced one.

**Categories** are copied into the group on provisioning (`DefaultCategorySet`/`DefaultCategory` →
`CategorySet`/`Category`) rather than inherited by NULL. Rationale: merchants are a shared namespace
worth converging on — Amazon is Amazon for everyone — whereas category taxonomy is personal and has
no correct list to converge toward. A group can add, rename, and delete freely, or wipe its
categories and take a fresh copy of the defaults.

### Money and sign convention

- **Spending is negative; transfers in are positive.** Chosen because it keeps backend arithmetic
  uniform — summing a month is just a sum.
- Credit cards, loans, and other liability accounts are **flipped cosmetically at the display
  layer only**. A sign flip must never leak into the API or the database, or there'd be two
  conventions and no way to tell which one a given number follows.

### Dates and time zones

Transaction times are worth keeping, not just dates — so a transaction records the *instant* it
happened along with the offset in effect (`DATETIMEOFFSET`). System/audit timestamps stay plain UTC.

- The offset is captured from the device, and must be **overridable** when it's wrong.
- An offset is not a time zone: `-05:00` doesn't say "Chicago." If a future feature needs the
  *rule* rather than the instant (e.g. "recurs at 9am local, forever"), that wants an IANA zone id
  stored as a **user preference**, not stamped on every row.

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
- **Everything that depends on authentication.** The two-tier ownership *schema* is built (see
  "Merchants and categories" above), but no login, session, or current-user concept exists yet, so
  the API hardcodes a seeded dev group. Blocked until then: group membership and invitations;
  master ownership of accounts; the merchant review-queue workflow; merchant search and
  recommendation UI; link-and-reset-to-default UI; per-group category reseed; and orphan-merchant
  cleanup.
- **Merchant privacy review.** User-created merchants land in a globally-visible, human-reviewed
  table, which means a user-typed merchant name becomes visible to reviewers. Needs an answer
  before real users exist.
- **Same-group foreign-key integrity for the remaining tables.** `LedgerEntry` and `Category`
  carry composite FKs that force their references to belong to the same group. The pattern could be
  extended further, but it's safe to defer: a group id is always derivable from the account, so
  backfilling it later is cheap.
- **The seeded merchant list is transitional.** A public/curated source will eventually supersede
  the 67 hand-entered rows; the default category taxonomy is safe to keep as-is.

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

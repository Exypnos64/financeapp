# Session note — merchant/category ownership redesign

Scratch. Promote the settled parts into `project-vision.md` / `CLAUDE.md` and delete this.

## Settled

- **Amount sign**: spending negative, transfers-in positive. Credit/loan sign flip is **cosmetic,
  frontend-only** — never in the API or DB.
- **Datetimes**: user-meaningful times (`UserDate`, `OriginalDate`) become `DATETIMEOFFSET`; drop the
  `Utc` suffix. System/audit timestamps (`LastModifiedUtc`, `GrantedAtUtc`) stay `DATETIME2` UTC.
  Existing filler rows backfill to Central via `AT TIME ZONE 'Central Standard Time'` (resolves DST
  per row). IANA zone id, if ever needed, belongs on the user as a preference — not per row.
- **Ownership unit is a GROUP, not a user.** A solo user is a group of one. Groups share accounts.
  This replaces the per-user merchant list idea and supersedes the original `Access` design.
- **Merchant model**: global curated master list + a `GroupMerchant` link table carrying *nullable*
  customization columns. NULL = inherit from master. Reset-to-default = set them back to NULL.
- **Categories do NOT use the sparse pattern.** Copy the defaults into the group on provisioning.
  Rationale: merchants are a shared namespace worth converging on (Amazon is Amazon); category
  taxonomy is personal and has no correct answer to converge toward.
- **Orphan cleanup is procedural, not declarative** — SQL can't express "must have ≥1 child".
  Application code deletes merchants that drop to zero transactions.

- **`LedgerEntry.MerchantId` points at `GroupMerchant.Id`**, not at the master `Merchant`.
  `GroupMerchant` carries a surrogate `Id` PK plus a UNIQUE on `(GroupId, MerchantId)`. Display name
  is `COALESCE(gm.Name, m.Name)` — one inner join, no group hop, and an un-adopted merchant can't be
  referenced by a transaction.
- **`Access` renamed `GroupMember`** — it models group membership, not account access.

## Parked — do not design until auth exists

- Group membership, roles, invitations.
- **Master ownership of accounts.** Problem: if groups own accounts, whoever contributed an account
  can be ejected from the group while others retain access. Framing for later: "contributed/owns
  this account" and "is a member of this group" are two separate facts — store both, don't derive
  one from the other. Much of the old `Access` design (PermissionLevel, GrantedByUserId,
  ExpireAtUtc) transfers to group membership.
- Merchant review queue workflow (the `IsReviewed`/`IsApproved` flags can go in the schema now;
  the workflow around them is later).
- Merchant search / recommendation UI, link-and-reset-to-default UI, category reseed.
- Privacy question: user-created merchants land in a globally-visible, human-reviewed table. A
  user-typed merchant name becomes visible to reviewers. Needs an answer before real users exist.

## Deferred: same-group FK integrity (safe to defer — see why)

Nothing stops a `LedgerEntry` on group 5's account from referencing group 9's `GroupMerchant` or
`Category`. Same class of hole for `Category.SetId` → another group's `CategorySet`.

The declarative fix: denormalize `GroupId` onto `LedgerEntry`, add `UNIQUE (GroupId, Id)` to
`Account` / `GroupMerchant` / `Category`, then make each FK composite — `(GroupId, AccountId)` →
`Account (GroupId, Id)`, and so on. One redundant column then forces all three FKs to agree, and the
composite FK is itself what stops the redundant column from drifting.

**Deferrable because `GroupId` is always derivable from `AccountId`.** Backfilling it later is a
one-line UPDATE, so this is cheap backtracking, not the expensive kind. Do it as its own focused
pass.

## Open, small, needed for the next slice

- Keep `LedgerEntry` — decided, no rename.
- `Category.DefaultId` exists but categories were settled as copy-on-provision. Is it provenance
  tracking ("which have I customized") or leftover? Decide before touching categories.
- Index naming convention (`UQ_` vs `IX_` for unique indexes) — add to `CLAUDE.md`.
- `Reviewed`/`Approved` need `DF_` defaults of 0; the 66 seeded merchants get both set to 1.
  Consider `CK_Merchant_Approved` so a row can't be approved without being reviewed.
- Per-group sentinel rows ("Unknown" merchant, "Uncategorized" category) move out of
  `Script.PostDeployment.sql` into group-provisioning code.

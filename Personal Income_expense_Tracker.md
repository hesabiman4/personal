# Personal Income Tracker — Android MVP Development Plan

## 1. App Summary from the Mockups

All **eight supplied images** inform this plan: seven detailed screen mockups and one broader HesabiMan design board.

The detailed screens show a personal finance app with:

- **Home:** balance visibility toggle, income/expense shortcuts, clients who owe money with due dates, recent transactions, and bottom navigation.
- **Transaction entry:** income/expense selection, large amount input, numeric keypad, categories, date, account, notes, and optional client linking.
- **Transactions:** search, filters, date groups, account labels, signed amounts, synchronization indicators, and swipe-to-delete.
- **Clients:** search, All/Owes You/Paid/Overdue filters, payment status, avatars, and client creation.
- **Client details:** contact information, billed/paid/outstanding totals, payment progress, invoice/payment history, reminders, and invoice creation.
- **Settings:** local profile, synchronization controls, CSV export, clearing data, dark mode, and currency.
- **Design board:** typography, icons, introductory screens, separate income/expense lists, reports, and broader multilingual HesabiMan branding.

The main flow is **record money → update balances → review transactions**. The client flow is **create client → record invoice → receive partial/full payment → reduce outstanding balance**.

**Assumptions and ambiguity resolutions**

| Decision | Default for this plan |
|---|---|
| Product | A separate Android app named Personal Income Tracker; reuse HesabiMan’s technology, with independent app data. |
| Audience | One freelancer or small-business owner using one device. |
| Visual priority | Detailed teal/navy screens take precedence over the purple design board. Use the board for typography and otherwise missing report details. |
| Backend | No backend or login in Phase 1. Cloud synchronization is an optional Phase 2 project. |
| Language | English first. Dari/Pashto and RTL are Phase 2 additions. |
| Currency | One currency per installation: USD by default; USD, AFN, or EUR selectable before financial records exist. No conversion. |
| Accounting | Cash basis: income means money received; unpaid invoices are receivables and do not increase cash balance. |
| Invoices | A local, single-amount receivable record. No invoice line items, taxes, or document generation in v1. |
| Sample content | Names, dates, amounts, and statuses are illustrative. All production totals are calculated from stored records. |

The mockups conflict on tab placement and transaction-form details. The choices below resolve those conflicts consistently.

## 2. Recommended Tech Stack

The existing [Flutter manifest](<C:/02. Notification/01. Masoud/New folder (2)/accountant_app/frontend/pubspec.yaml>) confirms Flutter/Dart, Provider, encrypted SQLite, and related utilities. The [backend manifest](<C:/02. Notification/01. Masoud/New folder (2)/accountant_app/backend/package.json>) confirms Node.js, Express, and PostgreSQL.

| Choice | Justification |
|---|---|
| **Flutter + Dart**, using HesabiMan’s compatible toolchain | Matches the requested stack and supports these custom Android layouts well. |
| **Material widgets with a custom theme** | Supplies dialogs, navigation, accessibility, and controls without another UI framework. |
| **Provider + ChangeNotifier** | Already used by HesabiMan; sufficient for shared finance data and settings. Keep temporary form state inside widgets. |
| **SQLite through `sqflite_sqlcipher`** | Matches HesabiMan and provides durable, encrypted local storage with transactions and relational queries. |
| **`flutter_secure_storage`** | Stores the database key using Android’s secure storage rather than preferences or source code. |
| **`shared_preferences`** | Stores presentation preferences such as theme and balance visibility; financial data stays in SQLite. |
| **`intl`, bundled Poppins font, Material icons** | Provides consistent number/date formatting and an offline-capable visual foundation. |
| **`uuid`, `path_provider`, `share_plus`** | Supports stable record IDs, local export files, and user-initiated CSV/reminder sharing. |
| **Flutter Navigator** | Handles this small navigation structure without a routing dependency. |
| **Flutter test tools** | Covers money calculations, database behavior, widgets, and device flows without additional testing frameworks. |
| **Optional v2: Node.js + Express + PostgreSQL** | Preserves backend stack familiarity if cloud synchronization becomes worthwhile. |

Keep the implementation to **screens/widgets → a small finance controller → one database service with focused query methods**. Add a settings controller separately. Avoid generic repositories, service locators, and additional architectural layers.

## 3. Data Model

Use five financial tables. All have a UUID `id` and UTC `created_at`/`updated_at` timestamps. Nullable fields are marked `?`.

Money is stored as **integer minor units**: `$24.50 = 2450`. Never use floating-point values for stored amounts or financial calculations.

| Table | Minimum fields |
|---|---|
| `accounts` | `name`, `kind` (`cash/card/bank`), `opening_balance_minor` |
| `categories` | `name`, `type` (`income/expense`), `icon_key` |
| `clients` | `name`, `service_description?`, `phone?`, `email?`, `is_archived` |
| `receivables` | `client_id`, `reference`, `description`, `amount_minor`, `issued_on`, `due_on?` |
| `transactions` | `type`, `amount_minor`, `account_id`, `category_id`, `occurred_on`, `occurred_time`, `note?`, `client_id?`, `receivable_id?` |

Store the selected currency and local owner name/email in a small singleton settings record. There is no user/authentication table in v1.

**Rules that prevent accounting errors**

- Seed **Cash, Card, and Bank Account**, initially with zero opening balances. Allow opening-balance entry during setup; these balances are not income.
- Balance = account opening balances + received income − expenses.
- An invoice increases receivables only.
- A payment is **one income transaction** linked to one receivable. Do not create a second payment table.
- Outstanding per invoice = invoice amount − linked payments.
- Client billed, paid, outstanding, and payment percentage are derived rather than stored.
- Client linking alone does not settle an invoice. Income linked to a client can be unbilled income, or explicitly assigned to an unpaid invoice.
- Partial payments are allowed. Overpayment and splitting one payment across multiple invoices are deferred; the user records separate payments.
- “Overdue” means an invoice has an unpaid balance and a due date before today. It is a subset of “Owes You.”
- Prevent invoice reductions below payments already received. An invoice with payments cannot be deleted until those payments are removed or reassigned.
- Archive clients with history instead of deleting their financial records.

Enable foreign keys. Index transaction dates, client references, and invoice references. Store the selected transaction calendar date separately from audit timestamps so timezone changes do not move entries into different date groups.

## 4. Screen & Feature Breakdown

Use one consistent bottom bar: **Home / Transactions / + / Reports / More**. Clients are accessible through Home’s “View All” and More. The central `+` opens transaction entry; it is an action, not a tab.

| Mockup | Components, interactions, and navigation |
|---|---|
| **Home — `client.png`** | Greeting from the local profile; balance card with persistent hide/show control; Add Income/Add Expense open the form with the matching type selected. Show five clients with outstanding balances, nearest due dates first, and five latest transactions. Client cards open details; transaction rows open editing; both “View All” actions open their lists. |
| **Income form — `incom_expense_form.png`** | Implement as the income state of the shared transaction form. Include amount, date, category, account, optional client, and notes. Selecting a client exposes an unpaid-invoice picker with an “Unbilled income” option. |
| **Expense form — `income_expense_form.png`** | Use its category strip, details layout, and bottom “Save Locally” button for both transaction types. Expense fields are amount, category, date, account, and note. Switching type updates categories and clears incompatible invoice/client selections. |
| **Shared keypad behavior** | Use digits, decimal, and backspace from the simpler income mockup. Defer arithmetic operators. Default date to today and account to the last-used account. Preserve entered values while opening pickers. Show save success only after the database commit. |
| **Transactions — `transactions.png`** | Search note/category and exact formatted amount; filter by type, date range, category, and account. Group actual dates in descending order. Tap to edit. Swipe reveals Delete, followed by confirmation; provide the same action in the edit screen for accessibility. |
| **Clients — `cleint.png`** | Search name/service; calculate filter counts from data. Show outstanding amounts for owing clients and total settled payments for paid clients, with explicit labels. Clients without invoices show “No activity.” Initials replace unavailable photos. Green dots mean active client, not online presence. Filter button offers name/balance sorting and archived clients. |
| **Client details — `client profile.png`** | Show contact details and calculated billed/paid/outstanding totals; handle zero billed without dividing by zero. Merge invoices and payments into a date-sorted history. “View All Invoices/Payments” changes its filter. “Create Invoice” opens a small amount/description/date/due-date form. Add “Record Payment” to an invoice’s details. |
| **Reminder action** | “Send Reminder” opens an editable message containing outstanding amount and due date, then Android’s share sheet. The user chooses the destination and sends it. Record no “sent” status merely because sharing was opened. |
| **Settings — `settings.png`** | Edit local name/email, opening balances before account activity, dark mode, and currency before financial activity. Export CSV through the share sheet. Clear Local Data requires a confirmation explaining permanent deletion, then resets local setup. |
| **Design board — `system desing.png`** | Build a basic Reports page with its 7D/30D/3M/6M/1Y selectors, income-versus-expense bars, and income/expense/net totals. Use ordinary Flutter drawing/layout; no interactive chart library. Separate Income/Expense pages become filtered transaction lists. Skip the promotional onboarding carousel and login. |

For the Home comparison, compare current balance with balance 30 days earlier. Show a percentage only when the earlier balance is positive; otherwise show the absolute change.

**Intentional v1 differences:** replace sync promises and pending indicators with **“Stored on this device.”** Settings explains that cloud sync is unavailable in this version. Local invoices show **“Recorded”**, not **“Sent.”** Do not display nonfunctional sync buttons or invented synchronization states.

## 5. Phased Implementation Plan

Estimates assume one developer familiar with Flutter, working full-time. They exclude store-review time.

**Phase 1 — Core MVP: approximately 17–23 working days**

| Order | Task checklist | Effort |
|---|---|---:|
| 1 | [ ] Create an independent Flutter Android project under `Personal/app`, with application ID `com.hesabiman.personaltracker`. Configure theme, bundled font, icons, shared cards, and the navigation shell. | 1–2 days |
| 2 | [ ] Implement database/key initialization, versioned migrations, the five tables, currency setup, account/category seeds, money parsing, and aggregate queries. Add focused financial/database tests. | 2–3 days |
| 3 | [ ] Build minimal local-profile/currency/opening-balance setup and reusable date/category/account selection sheets. | 1 day |
| 4 | [ ] Build shared income/expense entry, keypad, validation, save/edit behavior, and transaction search/filter/delete. Disable repeated submission while saving. | 3–4 days |
| 5 | [ ] Build client creation/editing/archive, client filters, invoice creation, payment assignment, partial payments, and client history. Wire client selection into transaction entry. | 3–4 days |
| 6 | [ ] Connect Home balance, visibility toggle, quick actions, outstanding clients, recent transactions, and 30-day comparison. | 1–2 days |
| 7 | [ ] Build basic Reports using the same database queries and cash-basis calculations. | 1 day |
| 8 | [ ] Complete dark mode, CSV export, reminder sharing, clear-data confirmation, and accurate local-storage messaging. Export transactions, clients, receivables, and accounts as separate CSV files with stable IDs and currency. | 2 days |
| 9 | [ ] Compare every screen against the mockups; test small devices and large text; run offline/restart/error scenarios; produce and install a signed release APK. | 3–4 days |

**MVP acceptance tests**

- Create an `$850` invoice: cash balance stays unchanged; outstanding becomes `$850`.
- Receive `$400`, then record a `$24.50` expense: with zero opening balances, cash becomes `$375.50`; outstanding becomes `$450`.
- Receive the remaining `$450`: cash becomes `$825.50`; invoice becomes paid. Editing or deleting a payment updates every affected total.
- Save in airplane mode, force-stop, and reopen: all committed records remain available.
- Double-tapping Save creates one record. A failed write preserves the form and displays a retryable error.
- Reject zero/negative transaction input, excess decimal digits, missing required selections, category/type mismatches, and invoice overpayments. Negative account balances remain valid.
- Verify due today versus overdue, no-due-date invoices, midnight grouping, filter counts, and date ordering.
- Verify CSV quoting, Unicode, money precision, and safe handling of user text that spreadsheet applications could interpret as formulas.
- Verify 48dp touch targets, readable dark mode, screen-reader labels, and no overflow on a narrow phone with enlarged text.
- Confirm app upgrades preserve data and database/key failures never silently reset the database.

**Phase 2 — Worthwhile additions, separately scheduled**

| Order | Optional task | Effort |
|---|---|---:|
| 1 | [ ] Add versioned full-data export/import for device replacement; validate the complete file before restoring atomically. CSV remains an analysis export. | 2–3 days |
| 2 | [ ] Add Dari/Pashto localization and RTL layouts, with appropriate bundled fonts and financial-format checks. | 3–5 days |
| 3 | [ ] If cloud access is needed, implement the limited synchronization model in Section 6, including authentication, retries, restoration, and failure tests. | 8–12 days |

## 6. Offline-First & Sync Strategy

**Phase 1: SQLite is the source of truth.**

1. Validate input locally.
2. Commit the complete change inside a database transaction.
3. Notify the relevant controller and reload affected queries.
4. Show “Saved locally.”

Every screen reads local data. Internet availability never blocks entry, search, reports, or client management. No network monitor, background worker, or sync queue is needed in v1.

Keep the encrypted database in app-private storage and its key in secure storage. Exclude the database/key combination from Android’s automatic backup mechanisms until a tested restoration path exists. If opening the database fails, show a recoverable error; never recreate it automatically.

CSV is useful for analysis and retaining readable records, but **is not a complete restorable backup**.

**Optional Phase 2: one writable device per account.**

Use one Express service and PostgreSQL. Start with foreground synchronization on launch/resume and “Sync Now”; defer reliable app-closed synchronization.

- Add an outbox and deletion tombstones through a migration. Each local mutation and its queued operation commit together.
- Give operations unique IDs. Server retries must acknowledge an already-applied operation without applying it twice.
- Expose authenticated push and cursor-based pull operations, scoped to the owner’s data.
- Upload related records in dependency order and acknowledge only operations actually accepted.
- Bootstrap existing local records when cloud sync is enabled; support downloading them during an explicit device replacement.
- Keep one writable device to avoid automatic merging of financial edits. Device replacement retires the previous writer.
- Show pending/error/success states from actual acknowledgements. Network availability alone is not proof of synchronization.
- Respect the cellular-data preference. Failed attempts remain queued for a later foreground retry.

Multi-device editing, background workers, conflict-resolution screens, and real-time updates remain deferred because they materially increase reliability work without improving the local MVP.

## 7. Recommended Improvements

**Optional additions only; none expands the Phase 1 estimate.** Essential validation, empty states, accessible controls, and correct currency formatting are already part of the base plan.

| Improvement | Why it is worthwhile | Complexity |
|---|---|---|
| Portable full-data backup and restore | Protects against device replacement and reinstall; complements CSV. | Medium; 2–3 days |
| Dari/Pashto and RTL | Makes the product suitable for the audience suggested by the design board. | Medium; 3–5 days |
| Local draft recovery | Recovers an unfinished transaction after interruption or process termination. | Low; ½–1 day |
| Biometric app lock using Android authentication | Adds privacy on shared or temporarily borrowed phones without custom PIN recovery. | Low–medium; 1–2 days |
| Local client photos through Android’s photo picker | Matches avatar-based client recognition without contact access or cloud storage. | Low; ½–1 day |
| Duplicate-entry warning | Warns about a matching amount/account/date while still allowing legitimate repeated payments. | Low; ½–1 day |

## 8. Over-Engineering Guardrails

- **No microservices:** one local application is sufficient; one backend service is enough if sync arrives.
- **No existing HesabiMan production-database migration:** this is a separate app with its own records.
- **No login, roles, subscriptions, or admin panel in v1:** a single local owner needs none of them.
- **No generic clean-architecture framework or extra state library:** Provider and focused database methods cover the application.
- **No cloud infrastructure or dormant sync machinery in v1:** build it when its behavior can actually ship.
- **No multi-currency ledger or exchange rates:** one currency avoids misleading combined balances.
- **No double-entry bookkeeping, reconciliation, or credit-card billing cycles:** accounts are simple money buckets.
- **No invoice line items, tax rules, PDFs, or automatic email delivery:** a single receivable amount supports the visible client workflow.
- **No payment-allocation engine, client credit, or overpayments:** one payment links to one invoice.
- **No budgets, recurring transactions, bank feeds, receipt OCR, or forecasting:** these are outside the demonstrated core workflow.
- **No calculator expression parser:** basic numeric entry meets the simpler mockup.
- **No online-presence tracking, remote avatars, or live client portals:** client records work entirely offline.
- **No elaborate charting or promotional onboarding:** simple reports and short setup get the user to useful work sooner.

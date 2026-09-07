# Non-Profit Member & Donation Management — Flutter App + Laravel API Plan

## 1. Project Goal

Build a **Flutter mobile app** and a **Laravel REST API** for a non-profit organization.

### Delivery rule (critical)

> **There is no backend/admin web panel.**  
> The Flutter app is the only UI. Admins, collectors, and members manage everything from the app.  
> Laravel provides the API, business rules, validation, and data storage only.

### Product pillars

The system must support these pillars:

1. **Member Join** — people apply/join through the app; admins approve in-app
2. **Monthly Donation (Collection)** — manage each member’s **due** months and **advance** months (partial, multi-month, and advance payments)
3. **Fundraising Event** — admin creates fundraising events; donations accepted from **members and non-members**
4. **Member referral (optional boost)** — members can share an event link/code so non-member donations are attributed to them

### Also manage

- Organization members and profiles
- Monthly donation obligations (**dues** + **advance**)
- Cash payments and mobile-wallet payment entries
- Payments collected by assigned members/collectors
- Advance payments covering future months
- Partial payments against current dues
- Payment history and outstanding dues
- Collector-wise collection records
- Fundraising event donations (members + non-members)
- Referral links / referral codes for events
- Digital receipts
- Basic organization reports (in-app only)

The app should be:

- Green
- Clean
- Smart
- Comfortable
- Trustworthy
- Modern
- Subtly Islamic-inspired
- Very easy for ordinary members and collectors to operate

Avoid excessive Islamic decoration. Use subtle Islamic geometric patterns, arch-inspired shapes, and elegant visual details rather than making the entire interface ornamental.

---

# 1A. System Architecture Overview

```text
┌─────────────────────────────┐
│     Flutter Mobile App      │
│  (only UI for all roles)    │
│  Admin · Collector · Member │
└──────────────┬──────────────┘
               │ HTTPS / JSON
               ▼
┌─────────────────────────────┐
│       Laravel REST API      │
│  Auth · Domain · Validation │
│  Jobs · Notifications       │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│     MySQL / MariaDB         │
└─────────────────────────────┘
```

Explicitly out of scope:

- Laravel Blade / Filament / Nova / any admin web panel
- Separate CMS for content management
- Desktop-only management tools

All create/edit/approve/report flows live in the Flutter app and hit Laravel endpoints.

---

# 2. Core Business Concept

The most important domain rule is:

> **A payment represents money received. A monthly allocation represents what that money is paying for.**

Never model a payment as simply "one payment = one month."

Example:

Monthly donation:

```text
৳500
```

Member pays:

```text
৳3,000
```

The system should create:

```text
1 Payment
    ↓
6 Monthly Allocations

September 2026   ৳500
October 2026     ৳500
November 2026    ৳500
December 2026    ৳500
January 2027     ৳500
February 2027    ৳500
```

Total payment:

```text
৳3,000
```

Total allocation:

```text
৳3,000
```

The member's six months are therefore marked as paid by one ৳3,000 transaction.

### Two money domains

Keep these separate:

| Domain | What it is | Who pays |
|---|---|---|
| **Monthly Donation (Collection)** | Recurring member obligation — tracks **due** and **advance** months | Active members only |
| **Fundraising Event** | One-off / time-bound event donation drive | **Members and non-members** |

Do not mix event donations into monthly dues allocations. Paying an event never clears a member’s monthly due (and vice versa).

### Monthly due vs advance (critical)

For monthly donations the system must always know:

```text
DUE months      → unpaid or partial months that should be paid first
ADVANCE months  → future months paid ahead of schedule
```

Payment allocation should prefer clearing **dues first**, then allow remaining money as **advance** on future months (with user confirmation).

### Event donation audience

> A Fundraising Event accepts donations from **members and non-members**.  
> Non-members may donate via a public event link, or via a member’s referral link (attribution optional but recommended).

### Referral attribution rule

> When a non-member donates through a member referral, store `referred_by_member_id`.  
> Attribution is for reporting/credit only — the money belongs to the organization/event. Referral is not required for every non-member donation if the event allows open public donate.

---

# 3. User Roles

Initially support three roles. **All roles use the Flutter app only.** There is no separate admin website.

## 3.1 Admin (in-app)

Admin can:

- Approve / reject member join requests
- Manage members (add/edit/deactivate)
- Define monthly donation amounts and organization settings
- Create and manage **Fundraising Events**
- View all monthly collections and event donations
- Correct payment records through controlled correction/reversal
- Assign collectors
- View reports and financial summaries
- Manage referral settings (enable/disable, optional rewards display)

## 3.2 Collector

Collector can:

- See assigned members
- Record monthly collection payments
- Record cash received
- Record mobile-wallet payments
- Record payments made to their personal wallet
- Optionally record **Fundraising Event** donations received in person (member or non-member donor)
- View collection history
- See unpaid members
- Generate/show payment confirmation

## 3.3 Member

Member can:

- Complete / track own join application (if pending)
- View own profile
- View monthly payment status and outstanding dues
- View payment history and receipts
- Record/make monthly payment where applicable
- Select months being paid
- Donate to **Fundraising Events**
- Share event referral link/code so non-members can donate
- View own referral donation summary (how many referred donors / amount attributed)

## 3.4 Guest / Non-Member (limited app or deep-link flow)

Non-members are **not** organization members. They can:

- Open a **Fundraising Event** link (public or member-referred)
- Enter donor name, phone, amount, and payment details
- Donate to the event
- Receive a digital receipt

They cannot access monthly dues, collector tools, or admin features.

Laravel authorization (policies/gates + middleware) must enforce roles. Do not rely on Flutter UI restrictions alone.

---

# 4. Recommended Flutter Architecture

Use feature-based modular architecture.

```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── routing/
│   ├── network/
│   ├── storage/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── join/              # member join / application
│   ├── dashboard/
│   ├── members/
│   ├── collections/       # monthly dues collection
│   ├── payments/
│   ├── collectors/
│   ├── fundraising/       # fundraising events
│   ├── referrals/         # share event link + referred donations
│   ├── donations/         # guest/non-member event donate flow
│   ├── reports/
│   ├── notifications/
│   ├── settings/          # in-app org settings (admin)
│   └── profile/
│
├── models/
├── services/
└── main.dart
```

Keep:

- UI
- State management
- Business logic
- API integration
- Models
- Local persistence

separated.

Do not place API calls directly inside widgets.

---

# 4A. Recommended Laravel Architecture

Laravel is the **only backend**. No admin panel packages for day-to-day management.

Suggested structure:

```text
app/
├── Models/
├── Http/
│   ├── Controllers/Api/
│   ├── Requests/
│   ├── Resources/
│   └── Middleware/
├── Policies/
├── Services/              # payment allocation, join, referral, event donation
├── Actions/               # single-purpose use cases
├── Enums/
├── Jobs/
├── Notifications/
└── Support/

database/
├── migrations/
├── seeders/
└── factories/

routes/
└── api.php
```

Rules:

- Version the API (`/api/v1/...`)
- Use Form Requests for validation
- Use API Resources for response shaping
- Use Policies for authorization
- Keep financial writes inside DB transactions
- Prefer Actions/Services for payment allocation, join approval, event donation, referral attribution
- Queue notifications (FCM / SMS later)
- Do **not** install Filament/Nova/Backpack for product management UI

---

# 5. Recommended Technology Stack

### Mobile

```text
Flutter
Dart

State Management:
Riverpod

Networking:
Dio

Routing:
GoRouter

Local Database:
Drift / SQLite

Secure Storage:
flutter_secure_storage

Serialization:
json_serializable

Immutable Models:
Freezed

Charts:
fl_chart

PDF:
pdf

Sharing:
share_plus
```

### Backend (Laravel API)

```text
Laravel (current LTS / supported version)
PHP 8.2+
MySQL / MariaDB

Auth:
Laravel Sanctum (token auth for mobile)

Authorization:
Policies + Gates

Queue:
Database / Redis

Storage:
Local / S3-compatible for receipts/avatars

Testing:
PHPUnit / Pest
```

Keep dependencies minimal. Do not add a package unless there is a clear technical reason.

---

# 6. Main Navigation

For normal members:

```text
Home
Monthly
Events
Refer
Profile
```

For collectors:

```text
Home
My Members
Collect
Events
Profile
```

For admin (in-app only):

```text
Dashboard
Members
Monthly
Events
More (Reports / Settings / Join Requests)
```

Avoid putting too many items into primary navigation.

---

# 7. Dashboard

The dashboard should immediately answer:

> "What is happening with our collections and fundraising?"

## Admin dashboard (in-app)

Show:

```text
This Month — Collection

Expected
৳50,000

Collected
৳37,500

Due
৳12,500
```

Member status:

```text
Members
125

Paid
92

Partial
13

Unpaid
20
```

Fundraising snapshot:

```text
Active Events
2

Event Raised (this month)
৳18,400

Pending Join Requests
5
```

Additional useful information:

- Collection percentage
- Today's collection
- Recent payments
- Outstanding members
- Collector performance
- Referral donations attributed this month

## Collector dashboard

Show:

```text
My Members       35
Collected Today  ৳4,500
This Month       ৳28,000
Outstanding      ৳7,500
```

Quick actions:

```text
+ Collect Payment
Due Members
Payment History
```

## Member dashboard

Show:

```text
My Collection Status
Due / Paid / Advance

Active Events
Event cards with progress

My Referrals
Donors referred · Amount attributed
```

---

# 8. Member Join

Member onboarding is an in-app flow. Admins approve joins inside the app — no web panel.

## 8.1 Join application

Guest or invited person can apply:

```text
Join Organization

Full Name
Phone
Email (optional)
Address (optional)
Photo (optional)
Monthly capacity / preferred amount (optional)
Referral code (optional — if invited by a member)
[ Submit Application ]
```

Statuses:

```text
DRAFT
SUBMITTED
UNDER_REVIEW
APPROVED
REJECTED
CANCELLED
```

## 8.2 Admin approval (in-app)

Admin sees Join Requests list:

```text
Pending Join Requests

Nazmul Hossain
01XXXXXXXXX
Submitted 6 Sep 2026
Referred by: Abdul Karim (optional)

[ Review ]
```

On approval, Laravel should:

1. Create / activate `user` + `member`
2. Set monthly donation amount (default org amount or custom)
3. Assign collector (optional)
4. Generate first monthly dues as needed
5. Notify applicant

On rejection, store reason and notify applicant.

## 8.3 Member self-registration vs admin-created

Support both:

- **Self join** via app → admin approval
- **Admin creates member** directly in app (for offline paper applications)

Do not require a web panel for either path.

---

# 9. Member Management

Member list should support:

- Search
- Pagination
- Pull-to-refresh
- Filters
- Status
- Collector
- Member ID

Example:

```text
┌──────────────────────────────┐
│ 🔍 Search members            │
├──────────────────────────────┤
│                              │
│ Abdul Karim                  │
│ Member #1024                 │
│ ৳500 / month                 │
│ ● Paid                       │
│                              │
│ Rahim Ahmed                  │
│ Member #1025                 │
│ ৳500 / month                 │
│ ● 2 Months Due               │
│                              │
└──────────────────────────────┘
```

Filters:

```text
All
Paid
Partial
Due
Inactive
```

---

# 10. Member Profile

Show:

```text
Member Profile

[Avatar]

Abdul Karim
Member ID: M-1024

Phone
01XXXXXXXXX

Monthly Donation
৳500

Assigned Collector
Rahim Ahmed

Referral Code
AK-1024
```

Payment summary:

```text
Current Year

Paid Months      8
Due Months       2
Advance Months   2

Total Paid
৳5,000
```

Also show:

```text
Event Donations
৳2,200

Referred Event Donors
7

Attributed Referral Amount
৳9,500
```

Payment history:

```text
September 2026    ৳500    Paid
August 2026       ৳500    Paid
July 2026         ৳500    Paid
June 2026         ৳500    Paid
```

Also show a monthly calendar/timeline view where useful.

---

# 10A. Fundraising Event

Admin creates a **Fundraising Event** in the app. Event donations are separate from monthly collection.

> Events accept donations from **members and non-members**.

## Event lifecycle

```text
DRAFT → ACTIVE → PAUSED → CLOSED → ARCHIVED
```

## Create Event (admin, in-app)

```text
Create Fundraising Event

Title
Winter Relief Drive 2026

Goal Amount
৳100,000

Venue / Location (optional)
Start Date / Time
End Date / Time (optional)

Description
Cover photo (optional)

Who can donate
☑ Members
☑ Non-members (public event link)
☑ Track member referrals on non-member donations

[ Save Draft ]  [ Publish Event ]
```

## Event home

```text
Winter Relief Drive 2026

Raised ৳62,400 of ৳100,000
62%

[ Donate as Member ]
[ Share Public Link ]
[ Share My Referral Link ]
```

## Who donates how

| Donor | How they donate |
|---|---|
| **Member** | In-app Donate on the event (logged in) |
| **Non-member** | Public event link, or member referral link |
| **Either (cash)** | Collector/admin records donation in-app with donor name/phone |

## Event donation rules

- Event donations do **not** clear monthly dues
- Store as `event_donations`
- Track: `donor_type` (`MEMBER` / `NON_MEMBER`), amount, method, `fundraising_event_id`, optional `referred_by_member_id`
- Support cash-to-collector and mobile-wallet entry
- Show progress toward goal; close when admin closes (do not auto-close only because goal is met unless configured)

## Admin event report (in-app)

```text
Event: Winter Relief Drive 2026

Total Raised          ৳62,400
From Members          ৳41,000
From Non-Members      ৳21,400
  of which referred   ৳12,200
Donors                86
Top Referring Members
```

---

# 10B. Non-Member Event Donation (Public + Referral)

Non-members can donate to an active Fundraising Event without becoming members.

## Paths

1. **Public event link** — `https://app.example.com/e/{event-slug}`
2. **Member referral link** — `https://app.example.com/e/{event-slug}/r/{referral-code}`

## Referral identity

Each active member gets:

```text
referral_code          e.g. AK-1024
event referral link    https://app.example.com/e/winter-relief/r/AK-1024
```

Member screen:

```text
Invite & Refer

Event: Winter Relief Drive 2026
Your code: AK-1024

[ Share Referral Link ]

This event
Referred donors: 4
Attributed: ৳3,200
```

## Non-member donate flow

```text
Donate — Winter Relief Drive 2026

Your Name
Phone
Amount
Payment Method
Transaction details (if wallet)

Referred by: Abdul Karim   (if opened via referral; else blank)

[ Confirm Donation ]
```

Laravel must:

1. Resolve active `fundraising_event`
2. Optionally resolve `referral_code` → referring member
3. Create `event_donations` with `donor_type = NON_MEMBER`
4. Store donor snapshot (name, phone) — do **not** create a member
5. Attribute amount when referral is present
6. Issue receipt

## Attribution vs membership

```text
Event donor ≠ member

Non-member remains a donor only
Unless they later submit a Join application
```

## Fraud / abuse basics

- Rate-limit public donation endpoints
- Idempotency key on donation create
- Admin can reverse fraudulent donations in-app
- If event disables public donate, require a valid referral code
---

# 11. Monthly Donation — Due & Advance Management

Monthly donation is for **members only**. Each month is an explicit due record. The system must manage both **outstanding dues** and **advance payments**.

Each member should have monthly dues containing:

```text
member_id
billing_month
amount_due
amount_paid
status
```

Status:

```text
UNPAID      → due (nothing paid)
PARTIAL     → due (part paid)
PAID        → current/past month cleared
            → or future month prepaid (advance)
```

Do not use only a boolean `paid`.

## Due months

A month is **due** when it is current or past and not fully paid.

```text
Monthly Donation = ৳500

September 2026
Paid      ৳300
Required  ৳500
Remaining ৳200
Status    PARTIAL (due)
```

## Advance months

A month is **advance** when it is in the future and money has already been allocated to it.

```text
Today: September 2026
Member prepaid October–December

October 2026   PAID (advance)
November 2026  PAID (advance)
December 2026  PAID (advance)
```

## Allocation priority (required behavior)

When a member/collector enters a monthly payment:

```text
1. Clear oldest unpaid / partial DUE months first
2. If money remains, offer ADVANCE allocation to future months
3. User confirms the advance months before save
4. Never silently dump leftover money as advance without confirmation
```

## Member summary must show both

```text
Due
2 months · ৳700 remaining

Advance
3 months prepaid

Next due month
November 2026
```

This allows:

```text
Monthly Donation = ৳500

Paid = ৳300
Remaining = ৳200
Status = PARTIAL
```

---

# 12. Critical Feature — Multi-Month Collection Payment

This is the central **monthly donation** workflow for dues and advance.

Suppose:

```text
Monthly donation = ৳500
Payment amount = ৳3,000
```

The payment screen should allow the user to allocate the ৳3,000 to six months.

Example:

```text
New Payment

Member
Abdul Karim

Amount
৳3,000

Payment Method
○ Mobile Wallet
○ Cash to Collector
○ Hand Cash

Allocate Payment

☑ September 2026   ৳500
☑ October 2026     ৳500
☑ November 2026    ৳500
☑ December 2026    ৳500
☑ January 2027     ৳500
☑ February 2027    ৳500

Allocated
৳3,000

Remaining
৳0

[ Confirm Payment ]
```

Do not make the user manually type all months.

---

# 12. Smart Month Selection

If the member has unpaid months:

```text
July
August
September
```

and the member pays:

```text
৳1,500
```

automatically suggest:

```text
July + August + September
```

If the member has no outstanding dues and pays in advance:

```text
Current dues are fully paid.

Allocate remaining ৳2,000
to future months?

October
November
December
January
```

Allow manual selection.

The UI should clearly show:

```text
Selected months: 6
Monthly amount: ৳500
Allocated: ৳3,000
Remaining: ৳0
```

---

# 13. Partial Payments

Support partial payment against a monthly due.

Example:

```text
Monthly Donation
৳500

Payment
৳300
```

Show:

```text
September 2026

Paid      ৳300
Required  ৳500
Remaining ৳200

● Partial
```

Later the member pays:

```text
৳200
```

Then:

```text
September 2026

Paid
৳500 / ৳500

● Paid
```

The system must calculate this from allocation records.

---

# 14. Advance Payments (Monthly Donation)

Advance is a first-class part of monthly donation management — not an edge case.

If current dues are fully paid and a member pays extra, allocate to future months.

Example:

```text
Current dues: ৳0
Payment: ৳2,000
Monthly amount: ৳500
```

Suggest:

```text
October 2026   (advance)
November 2026  (advance)
December 2026  (advance)
January 2027   (advance)
```

Rules:

- Do not silently classify leftover money as advance — user must confirm future months
- Advance months appear as `PAID` on the member calendar with an **Advance** label
- When that calendar month becomes current, it stays paid (no second charge)
- Reports should separate: **Due collected this month** vs **Advance collected this month**
- Laravel must create future `monthly_dues` rows if they do not exist yet before allocating advance

Mixed payment example (due + advance in one transaction):

```text
Payment ৳1,200
Monthly ৳500

August due remaining   ৳200  → clear due
September due          ৳500  → clear due
October                ৳500  → advance

Total allocated ৳1,200
```

---

# 15. Payment Data Model

Do not store only:

```text
member_id
amount
payment_date
```

Use two primary entities.

## Payment

Represents the actual money transaction.

```text
Payment
-------
id
member_id
amount
payment_method
collector_id
transaction_reference
payment_date
status
created_at
updated_at
```

Example:

```text
Payment #P-10025

Member: Abdul Karim
Amount: ৳3,000
Method: Cash
Collector: Rahim
Date: 7 Sep 2026
```

## Payment Allocation

Represents what the payment covers.

```text
PaymentAllocation
-----------------
id
payment_id
member_id
monthly_due_id
billing_month
amount
status
created_at
```

Example:

```text
P-10025
│
├── June 2026       ৳500
├── July 2026       ৳500
├── August 2026     ৳500
├── September 2026  ৳500
├── October 2026    ৳500
└── November 2026   ৳500
```

This allows the system to answer exactly which months have been paid.

---

# 16. Payment Methods

Initially support three methods.

## 16.1 Mobile Wallet

Example:

```text
Payment Method

Mobile Wallet

Wallet Provider
[ bKash ▼ ]

Sender Number
01XXXXXXXXX

Transaction ID
ABC123XYZ

Amount
৳3,000
```

If wallet API verification is not available, do not automatically mark the payment as confirmed merely because a transaction ID was entered.

Use:

```text
PENDING_VERIFICATION
```

until verified.

## 16.2 Cash to Assigned Collector

```text
Payment Method

Cash to Collector

Collector
Rahim Ahmed

Amount
৳3,000
```

## 16.3 Direct Hand Cash

```text
Payment Method

Hand Cash

Received By
Rahim Ahmed

Amount
৳3,000
```

The system should preserve who physically received the cash.

---

# 17. Collector Management

Admin can assign members to collectors.

Example:

```text
Collector

Rahim Ahmed

Assigned Members
35

Expected Monthly
৳17,500

Collected
৳14,500

Outstanding
৳3,000
```

Member assignment:

```text
Member
Abdul Karim

Collector
Rahim Ahmed
```

Initially allow one active collector per member.

Keep assignment history where practical.

---

# 18. Collector Dashboard

Collector sees:

```text
Good Morning, Rahim

September Collection

৳14,500
of ৳17,500

83% collected
```

Member status:

```text
✓ 28 Paid
◐ 3 Partial
! 4 Due
```

Quick actions:

```text
[ + Collect Payment ]

[ Due Members ]

[ Payment History ]
```

---

# 19. Fast Payment Entry

Optimize collector workflow for speed.

Ideal flow:

```text
Find Member
     ↓
Select Member
     ↓
Enter Amount
     ↓
Select Payment Method
     ↓
Select Months
     ↓
Review
     ↓
Confirm
     ↓
Receipt
```

A normal payment should be recordable in under 30 seconds.

Use:

- Large touch targets
- Search-first member selection
- Numeric amount input
- Suggested month allocation
- Minimal steps
- Clear confirmation

---

# 20. Payment Confirmation

After successful payment:

```text
✓ Payment Recorded

Abdul Karim

৳3,000

September 2026
October 2026
November 2026
December 2026
January 2027
February 2027

Payment Method
Cash

Collector
Rahim Ahmed

Receipt #P-10025

[ View Receipt ]

[ Share Receipt ]
```

For pending wallet verification:

```text
Payment Submitted

৳3,000

Status:
Pending Verification
```

Do not display pending transactions as confirmed.

---

# 21. Receipt

Generate a clean digital receipt.

```text
┌─────────────────────────────┐
│        ORGANIZATION         │
│                             │
│       PAYMENT RECEIPT       │
│                             │
│ Receipt: P-10025            │
│ Date: 07 Sep 2026           │
│                             │
│ Member                      │
│ Abdul Karim                 │
│                             │
│ Amount                      │
│ ৳3,000                      │
│                             │
│ Covers                      │
│ Sep 2026                    │
│ Oct 2026                    │
│ Nov 2026                    │
│ Dec 2026                    │
│ Jan 2027                    │
│ Feb 2027                    │
│                             │
│ Method: Cash                │
│ Collector: Rahim Ahmed      │
│                             │
│ Thank you                   │
└─────────────────────────────┘
```

Support:

- View
- Share
- Download
- Print where supported

---

# 22. Payment History

Global payment history:

```text
Payments

Today

Abdul Karim
৳3,000
Cash
6 months

Rahim Ahmed
৳500
Mobile Wallet
September

Yesterday

...
```

Filters:

```text
Date
Member
Collector
Payment Method
Status
```

Member payment history should also show allocations.

---

# 23. Reports

All reports are available **in the Flutter app** for admin (and limited collector views). There is no web reporting panel.

## 23.1 Monthly Collection

```text
September 2026

Expected       ৳50,000
Collected      ৳42,500
Outstanding    ৳7,500

Collection Rate
85%
```

## 23.2 Payment Method

```text
Mobile Wallet     ৳20,000
Cash Collector    ৳15,000
Hand Cash         ৳7,500
```

## 23.3 Collector Performance

```text
Collector      Members    Collected

Rahim           35        ৳14,500
Karim           30        ৳12,000
Hasan           25        ৳10,500
```

## 23.4 Member Dues

Provide:

- Total due
- Paid members
- Partial members
- Unpaid members
- Advance-paid members

## 23.5 Fundraising Events

Per event:

- Goal vs raised
- Member donations vs non-member donations
- Referred non-member subset
- Donor count
- Top referring members

## 23.6 Referrals & Join

- Referral attributed amounts by member
- Join requests submitted / approved / rejected
- Optional: referred donors who later joined

---

# 24. Financial Integrity

The app manages real money, so financial records must be treated carefully.

Do not allow normal users to silently edit confirmed payments.

Preferred model:

```text
Payment
   ↓
CONFIRMED
```

If something is wrong:

```text
Original Payment
   ↓
Correction / Reversal
   ↓
New Corrected Record
```

Maintain an audit trail.

Example:

```text
Original Payment
৳3,000

Correction
-৳500

Corrected Allocation
৳2,500
```

Do not delete confirmed financial transactions.

---

# 25. Financial Validation Rules

When creating a payment:

```text
payment.amount
=
SUM(payment_allocations.amount)
```

unless the business rules explicitly support an unallocated balance.

Example:

```text
Payment = ৳3,000

Allocations:
৳500
৳500
৳500
৳500
৳500
৳500

Total = ৳3,000
```

Reject inconsistent requests.

Also prevent:

- Duplicate allocation
- Double payment of the same monthly due
- Allocation to inactive member
- Unauthorized collector payment entry
- Negative amounts
- Zero-value payment
- Invalid payment dates
- Duplicate wallet transaction references where uniqueness is required
- Payment amount exceeding permitted allocation without explicit handling
- Allocation against a fully paid monthly due

All critical validation must happen on the server.

---

# 26. Recommended Database Structure

Core tables (Laravel migrations):

```text
users
personal_access_tokens          # Sanctum

members
member_join_requests
member_assignments
collectors

monthly_dues                    # collection obligations

payments                        # money received (collection + optional shared payment table)
payment_allocations             # only for monthly collection allocations

fundraising_events
event_donations                 # member + non-member event donations
referral_codes                  # or store referral_code on members
referral_attributions           # optional explicit attribution log

payment_methods
wallet_transactions

organization_settings

audit_logs
notifications
device_tokens                   # FCM later
```

## member_join_requests

```text
id
user_id (nullable until approved)
full_name
phone
email
address
photo_path
preferred_monthly_amount
referred_by_member_id (nullable)
status
rejection_reason
reviewed_by
reviewed_at
created_at
updated_at
```

## monthly_dues

```text
id
member_id
billing_month
amount_due
amount_paid
status
created_at
updated_at
```

## payments

```text
id
member_id (nullable for pure guest if using shared table — prefer event_donations for guests)
purpose                # MONTHLY_COLLECTION | FUNDRAISING_EVENT (if shared)
fundraising_event_id (nullable)
amount
payment_method
collector_id
transaction_reference
payment_date
status
idempotency_key
created_by
created_at
updated_at
```

Prefer **separate** `event_donations` for Fundraising Event clarity:

## fundraising_events

```text
id
title
slug
description
goal_amount
raised_amount          # maintained carefully / or computed
cover_path
venue (nullable)
starts_at
ends_at
status
accept_members         # true
accept_non_members     # true
require_referral_for_guests  # false by default (open public donate allowed)
created_by
created_at
updated_at
```

## event_donations

```text
id
fundraising_event_id
donor_type             # MEMBER | NON_MEMBER
member_id (nullable)
donor_name
donor_phone
donor_email (nullable)
referred_by_member_id (nullable)
amount
payment_method
collector_id (nullable)
transaction_reference
payment_date
status
idempotency_key
receipt_number
created_by (nullable)
created_at
updated_at
```

## payment_allocations

```text
id
payment_id
member_id
monthly_due_id
billing_month
amount
status
created_at
updated_at
```

Use foreign keys, unique constraints (e.g. unique `idempotency_key`), and appropriate indexes (`referral_code`, `fundraising_event_id`, `billing_month`, `status`).

---

# 27. Laravel API Design

Base: `/api/v1`

Auth via Laravel Sanctum bearer tokens.

## Auth & profile

```text
POST   /auth/register-intent     # optional pre-join
POST   /auth/login
POST   /auth/logout
GET    /me
PUT    /me
POST   /me/device-token
```

## Member Join

```text
POST   /join-requests
GET    /join-requests                 # admin
GET    /join-requests/{id}
POST   /join-requests/{id}/approve    # admin
POST   /join-requests/{id}/reject     # admin
GET    /me/join-request               # applicant status
```

## Members & collectors

```text
GET    /members
GET    /members/{id}
POST   /members                       # admin create
PUT    /members/{id}
PATCH  /members/{id}/status

GET    /members/{id}/dues
GET    /members/{id}/payments
GET    /members/{id}/referrals

GET    /collectors
POST   /collectors/{id}/members
DELETE /collectors/{id}/members/{memberId}
```

## Collection payments (monthly dues)

```text
POST   /payments
GET    /payments
GET    /payments/{id}
POST   /payments/{id}/verify
POST   /payments/{id}/reverse

# allocations created atomically with payment create (preferred)
# or:
POST   /payments/{id}/allocations
```

Payment create payload should include months/allocations in one request so Laravel can commit atomically.

## Fundraising Events

```text
GET    /events
GET    /events/{id}
POST   /events                        # admin create event
PUT    /events/{id}                   # admin
PATCH  /events/{id}/status            # admin

POST   /events/{id}/donations         # member / collector / admin entry
GET    /events/{id}/donations
GET    /events/{id}/report            # admin
```

## Referral / non-member event donations (public + member)

```text
GET    /referrals/me
GET    /referrals/me/summary
POST   /referrals/me/regenerate       # admin-controlled if needed

# Public / guest (throttled)
GET    /public/referrals/{code}
GET    /public/events/{slug}
POST   /public/events/{slug}/donations
       # body: donor info, amount, method, optional referral_code, idempotency_key
```

## Reports & settings (in-app admin)

```text
GET    /reports/monthly-collection
GET    /reports/collectors
GET    /reports/payment-methods
GET    /reports/member-dues
GET    /reports/fundraising-events
GET    /reports/referrals

GET    /settings
PUT    /settings                      # admin
```

## Laravel implementation notes

- Controllers stay thin; put allocation math in `PaymentAllocationService` (dues first, then advance)
- Wrap payment + allocations + dues updates in `DB::transaction()`
- Enforce idempotency on `payments` and `event_donations`
- Policies: Admin / Collector / Member / Guest abilities
- Form Requests for every mutating endpoint
- API Resources for consistent Flutter parsing
- Do not build Blade CRUD screens for these resources

Adapt endpoint names if a contract already exists in the repo; otherwise implement this contract.

---

# 28. API and State Management Rules

Use:

```text
UI
 ↓
Riverpod Provider / Notifier
 ↓
Repository
 ↓
API Service
 ↓
Dio
 ↓
Laravel /api/v1
```

Do not:

```text
Widget
 ↓
Dio directly
```

Repositories should expose business-oriented methods such as:

```text
submitJoinRequest()
approveJoinRequest()
getMembers()
getMemberDues()
createCollectionPayment()
getPaymentHistory()
getCollectorMembers()
getEvents()
donateToEvent()
getMyReferralSummary()
createEventDonation()
getMonthlyReport()
```

Providers should manage:

- Loading
- Data
- Error
- Refresh
- Pagination
- Mutation state

# 29. Error Handling

Every screen must handle:

- Loading
- Empty
- Error
- Success
- Retry

API errors should be converted into friendly messages.

Do not expose raw backend exceptions.

Example:

Instead of:

```text
DioException: 422 Unprocessable Entity
```

show:

```text
Unable to record this payment.

Please check the selected months and amount.
```

---

# 30. Payment Idempotency

Payment creation must be idempotent.

For every payment submission:

```text
Client
 ↓
Generate idempotency key
 ↓
POST payment
 ↓
Server stores key
 ↓
Retry with same key
 ↓
Server returns original result
```

A network retry must never create two financial transactions.

The backend should enforce idempotency.

---

# 31. Money Handling

Never use floating-point arithmetic for financial calculations.

Prefer integer smallest-unit representation where possible.

For Bangladeshi Taka:

```text
৳500
```

can be stored as:

```text
50000 poisha
```

if the backend supports smallest-unit representation.

If the backend uses decimal values, use an appropriate decimal-safe representation.

Never use `double` for authoritative financial calculations.

---

# 32. UI Theme

Use a green-centered palette.

Suggested colors:

```text
Primary Green
#16803C

Dark Green
#0B5D2A

Light Green
#EAF7EE

Background
#F7FAF8

Card
#FFFFFF

Text
#17231B

Secondary Text
#66736A

Success
#16803C

Warning
#D89B00

Error
#C0392B
```

Do not make every UI element green.

Use green mainly for:

- Primary buttons
- Selected states
- Important amounts
- Success indicators
- Active navigation
- Progress indicators

Use white/off-white surfaces for comfort.

---

# 33. Islamic Visual Direction

Use subtle Islamic-inspired visual language.

Recommended:

- Light geometric Islamic pattern in selected headers
- Soft arch shapes
- Minimal ornamental separators
- Subtle geometric background texture
- Clean rounded cards
- Modern Material icons

Avoid:

- Excessive mosque imagery
- Heavy ornamentation
- Large decorative Arabic calligraphy
- Overly dark green screens
- Excessive gold decoration

The overall feeling should be:

> Modern fintech + community organization + subtle Islamic identity.

---

# 34. Typography

Recommended:

```text
English:
Inter or Poppins

Bangla:
Noto Sans Bengali
```

Typography hierarchy:

```text
Screen Title
24–28 px

Section Title
18–20 px

Body
14–16 px

Secondary
12–14 px

Large Financial Amount
28–36 px
```

Prioritize readability on small screens.

---

# 35. Home Screen Direction

Concept (role-aware; admin example):

```text
┌────────────────────────────────┐
│ ☰       Organization       🔔 │
│                                │
│ Assalamu Alaikum               │
│ Welcome back                   │
│                                │
│ ┌────────────────────────────┐ │
│ │ Monthly Collection         │ │
│ │ ৳37,500 of ৳50,000         │ │
│ │ ███████████████░░░ 75%     │ │
│ └────────────────────────────┘ │
│                                │
│ ┌────────────────────────────┐ │
│ │ Active Events              │ │
│ │ Relief Drive ৳62k / ৳100k  │ │
│ └────────────────────────────┘ │
│                                │
│ Quick Actions                  │
│ + Collect · Join Requests ·    │
│   Share Referral               │
│                                │
│ Recent Activity                │
└────────────────────────────────┘
```

Member home emphasizes: dues vs advance status, active events, share referral.
Collector home emphasizes: due members, collect payment, today's total.

Use this only as a conceptual direction. The final UI should be implemented with reusable Flutter widgets.

---

# 36. Smart UX Features

After core payment functionality works, add:

## Smart month suggestion

Automatically identify unpaid months and suggest them first.

## Advance payment detection

If the payment exceeds outstanding dues, suggest future months.

## Payment allocation preview

Before confirmation:

```text
Payment
৳3,000

Monthly amount
৳500

6 months

September → February

Allocated
৳3,000

Remaining
৳0
```

## Duplicate protection

Warn if the user tries to pay a month that is already fully paid.

## Due reminders

Example:

```text
4 members have not paid September donation.
```

---

# 37. Notifications

Potential notifications:

## Member payment confirmation

```text
September donation received.

৳500
September 2026
```

## Due reminder

```text
Your September donation of ৳500 is still due.
```

## Collector notification

```text
4 assigned members have outstanding donations.
```

## Admin notification

```text
৳42,500 collected this month.
```

Notification infrastructure should be designed so push notifications can be added without restructuring the application.

---

# 38. Offline Consideration

Collectors may operate in areas with poor connectivity.

Initially implement:

```text
Online-first
```

but structure the payment module so offline support can be added.

Potential architecture:

```text
Payment Entry
     ↓
Local Pending Record
     ↓
API Sync
     ↓
Server Confirmation
```

Financial transactions must not be shown as confirmed while they are only stored locally.

Use:

```text
Pending Sync
```

until the server accepts the transaction.

Later add:

- Local SQLite/Drift queue
- Retry
- Sync status
- Conflict detection
- Server reconciliation

---

# 39. Security

Implement:

- Laravel Sanctum authentication
- Secure token storage on device
- Role-based access (Policies + Flutter role-aware UI)
- API authorization on every mutating route
- Form Request validation
- Audit logs for financial and membership changes
- Payment / donation idempotency
- Unique transaction references
- Throttling on public referral donation endpoints
- No sensitive information in logs
- Session / token expiry
- Server-side permission checks

Do not store authentication tokens in insecure preferences.

Do not expose admin capabilities through unauthenticated or member-only routes.

---

# 40. Development Phases

Build **Laravel API and Flutter app in parallel** per phase. API contract first (or OpenAPI stub), then Flutter screens against real endpoints. No admin web UI in any phase.

## Phase 0 — Laravel Foundation

Implement:

- Laravel project setup
- Sanctum auth
- Roles / permissions (Admin, Collector, Member)
- Base API versioning (`/api/v1`)
- Organization settings
- Audit log foundation
- Seeders for roles and sample admin
- Pest/PHPUnit smoke tests

---

## Phase 1 — Flutter Foundation

Implement:

- Flutter project setup
- Theme
- Routing
- API client (Dio → Laravel)
- Authentication
- Secure storage
- Base components
- Role-aware navigation (in-app admin included)
- Error handling
- Loading/empty/error components

---

## Phase 2 — Member Join + Members

### Laravel

- `member_join_requests` migrations/models
- Join submit / approve / reject endpoints
- Member CRUD endpoints
- Collector assignment endpoints
- Policies

### Flutter

- Join application screens
- Admin join-request review (in-app)
- Member list / search / filters / pagination
- Member profile
- Add/edit member
- Member status
- Collector assignment

---

## Phase 3 — Monthly Donation (Due & Advance)

### Laravel

- Monthly dues generation job/command
- Dues endpoints
- Status computation helpers (UNPAID / PARTIAL / PAID)
- Advance month creation when allocating to future months
- Report split: due collected vs advance collected

### Flutter

- Monthly obligation views
- Due vs advance labels on calendar
- Paid/partial/unpaid status
- Outstanding dues
- Advance month confirmation UI

---

## Phase 4 — Collection Payment System

### Laravel

- Payment + allocation atomic create
- Idempotency
- Partial / multi-month / **due-first then advance** validation
- Verify / reverse endpoints
- Server-side money rules

### Flutter

- Payment entry
- Cash / cash-to-collector / mobile-wallet entry
- Allocation UI (dues first, then advance)
- Multi-month / partial / advance
- History

This is the highest-priority money module.

---

## Phase 5 — Collector

### Laravel + Flutter

- Collector dashboard aggregates
- Assigned members / due members
- Fast payment entry
- Collection history
- Daily collection summary

---

## Phase 6 — Fundraising Events

### Laravel

- `fundraising_events` CRUD
- `event_donations` endpoints (member + non-member)
- Progress aggregation
- Event reports

### Flutter

- Admin **Create Fundraising Event** (in-app)
- Event list / detail / progress
- Member donate to event
- Non-member donate via public / referral link
- Collector in-person event donation entry (member or non-member donor)

---

## Phase 7 — Referral Attribution for Events

### Laravel

- Referral codes on members
- Public event resolve endpoint
- Public/throttled donation create with optional attribution
- Referral summary reports

### Flutter

- Member refer/share screens per event
- Deep link / event donate guest flow
- Attribution summary for members
- Admin referral report

---

## Phase 8 — Receipts

Implement:

- Receipt generation (collection + event)
- Share / download
- Print where supported

---

## Phase 9 — Reports & In-app Settings

Implement:

- Monthly collection reports
- Outstanding
- Collector report
- Payment-method report
- Fundraising event + referral reports
- Organization settings (admin, in-app only)

---

## Phase 10 — Notifications

Implement:

- Join approved/rejected
- Payment confirmation
- Due reminders
- Event updates
- Collector / admin alerts

---

## Phase 11 — Offline Enhancement (optional)

Implement:

- Local database
- Pending transactions
- Sync queue
- Retry / conflict handling
- Sync status

---

# 41. MVP Scope

Do not overbuild the first release.

## Must Have

- Laravel API (Sanctum) — **no admin web panel**
- Login / roles in Flutter
- Member join request + in-app admin approval
- Dashboard (admin / collector / member)
- Members + member profile
- Monthly collection dues with **due + advance** management
- Collection payment entry (cash + mobile-wallet record)
- Collector payment flow
- Multi-month allocation, partial, advance (dues first)
- Payment history + receipt
- **Create Fundraising Event** (admin in-app)
- Event donations by **members and non-members**
- Optional member referral attribution on non-member event donations
- Referral attribution summary
- Basic in-app reports
- Role permissions enforced on Laravel

## Later

- Direct mobile-wallet API verification
- Automated wallet verification
- Offline mode
- Push notifications
- Advanced analytics
- SMS / WhatsApp
- QR member identification
- Automated monthly reminders
- Online payment gateway checkout
- Referral reward points (if org wants incentives)

---

# 42. AI Agent Development Rules

The coding agent MUST follow these rules.

1. First inspect the existing project before modifying anything.

2. Do not rewrite working architecture unnecessarily.

3. Follow feature-based Flutter architecture and Laravel Action/Service patterns.

4. Keep UI, business logic, API and data models separated.

5. Never put API calls directly inside widgets.

6. **Do not build a Laravel admin panel / Filament / Nova / Blade CRUD for product management.** All management UI is Flutter.

7. Never hard-code monthly donation amounts.

8. Never assume one payment equals one month.

9. Payment and payment allocation must remain separate concepts for **collection**.

10. Monthly dues must be represented explicitly.

11. Keep **monthly collection payments** and **fundraising event donations** conceptually separate.

12. Event donations must support `donor_type` MEMBER and NON_MEMBER; store `referred_by_member_id` when a referral is used.

13. Support partial payments, multi-month allocation, and advance payment for monthly donation — **clear dues first, then advance**.

14. Never allow duplicate month allocation.

15. Never silently modify confirmed financial transactions.

16. Use reversal/correction records for financial corrections.

17. Validate all financial calculations on the Laravel server.

18. Never use floating-point arithmetic for authoritative money calculations.

19. Display Bangladeshi currency using the ৳ symbol.

20. Design for small mobile screens first.

21. Keep primary actions obvious.

22. Avoid unnecessary animations.

23. Use green as the primary visual identity.

24. Keep Islamic visual elements subtle and professional.

25. Every screen must have loading, empty, error and success states.

26. Every form must have validation.

27. Convert API errors into user-friendly messages.

28. Never expose backend exceptions to users.

29. Use reusable components for:
    - Member cards
    - Payment cards
    - Event cards
    - Status badges
    - Amount display
    - Month selector
    - Empty states
    - Confirmation dialogs

30. Write unit tests for payment allocation logic (Flutter + Laravel).

31. Write tests for partial payment calculations.

32. Write tests for advance payment allocation.

33. Write tests for duplicate month prevention.

34. Write tests for payment amount vs allocation total.

35. Write tests for idempotent payment and donation submission.

36. Write tests for join approve/reject side effects.

37. Write tests for referral attribution on non-member donations.

38. Before considering the payment module complete, test:
    - One-month payment
    - Multi-month payment
    - Partial payment
    - Advance payment
    - Duplicate month
    - Wrong amount
    - Network retry
    - Duplicate request
    - Payment reversal
    - Pending wallet verification
    - Event donation (member + non-member)
    - Referred non-member event donation

39. Do not mark a payment as confirmed based only on local UI state.

40. Never delete confirmed financial records.

41. Keep audit information for financial changes.

42. Use server-provided IDs and timestamps rather than generating authoritative financial IDs only on the client.

43. Do not invent API fields or endpoints if an existing backend contract is available. Inspect and follow the existing API.

44. Prefer implementing missing Laravel endpoints over faking business rules only in Flutter.

---

# 43. Payment Algorithm

The payment allocation algorithm should conceptually work as follows.

## Input

```text
Member
Monthly donation amount
Payment amount
Selected months
```

## Validate

```text
Member exists
Member is active
Payment amount > 0
Selected months are valid
Selected months are not fully paid
Dues are allocated before advance months (unless user explicitly overrides with confirmation)
```

## Calculate

```text
allocation_total = sum(selected allocation amounts)
```

Then verify:

```text
allocation_total == payment_amount
```

unless the product explicitly supports an unallocated balance.

## Save transaction

Create:

```text
Payment
```

Then create:

```text
PaymentAllocation[]
```

inside one backend database transaction.

## Update monthly dues

For each allocation:

```text
amount_paid += allocation.amount
```

Then calculate:

```text
if amount_paid == amount_due:
    PAID

if amount_paid > 0 && amount_paid < amount_due:
    PARTIAL

if amount_paid == 0:
    UNPAID
```

All related financial writes should be atomic.

---

# 44. Payment Allocation Example

Example member:

```text
Monthly donation = ৳500
```

Current dues:

```text
June       ৳500 unpaid
July       ৳500 unpaid
August     ৳500 partial (৳200)
September  ৳500 unpaid
```

Member pays:

```text
৳1,300
```

The smart allocator should consider existing partial balances.

Suggested allocation:

```text
August     ৳300
June       ৳500
July       ৳500
```

Total:

```text
৳1,300
```

After payment:

```text
June       PAID
July       PAID
August     PAID
September  UNPAID
```

This is preferable to simply assigning the payment to three arbitrary future months.

---

# 45. Important UX Rule for Payment Allocation

Always show exactly what the payment is doing before confirmation.

Example:

```text
Payment Summary

Member
Abdul Karim

Payment
৳1,300

Allocation

August 2026
৳300 remaining balance

June 2026
৳500

July 2026
৳500

────────────────

Total
৳1,300

Remaining
৳0

[ Confirm Payment ]
```

The user should never have to guess which months are being paid.

---

# 46. Definition of Done

A feature is not complete merely because the screen exists.

For every feature:

```text
Laravel endpoint + policy + validation
✓

Flutter UI
✓

API integration
✓

Loading state
✓

Empty state
✓

Error state
✓

Validation
✓

Permission handling
✓

Success state
✓

Unit/feature tests where applicable
✓
```

No feature is "done" if it only works by editing the database or a web admin tool. It must be operable from the Flutter app (except intentionally public referral donate links).

For the collection payment module additionally require:

```text
✓ Atomic transaction handling
✓ Idempotency
✓ Duplicate allocation protection
✓ Partial payment support
✓ Multi-month allocation
✓ Advance payment
✓ Reversal/correction
✓ Audit trail
✓ Server-side validation
```

For fundraising events + referral additionally require:

```text
✓ Create/manage Fundraising Event in-app
✓ Member event donation
✓ Non-member event donation (public and/or referral)
✓ Referral attribution stored and reportable
✓ Receipt for event donations
✓ Public endpoint throttling
```

---

# 47. Final Product Principle

The product is a **Flutter + Laravel** system with **no backend panel**.

It should feel like a **modern fintech/community management application**, not a complicated accounting system.

Primary daily flows:

```text
1) Member Join
   Apply → Admin approves in app → Member active

2) Monthly Donation (Due & Advance)
   Find member → Enter amount → Clear dues first → Confirm advance months → Receipt

3) Fundraising Event
   Admin creates event → Members and non-members donate → Track progress

4) Optional Referral Boost
   Member shares event link → Non-member donates → Attribution + receipt
```

Everything else should remain secondary.

Domain principles that must stay consistent:

> **Money received for monthly collection is a Payment. What that money covers is Payment Allocations against Monthly Dues (due months first, then advance).**

> **Fundraising Event money is an Event Donation from members or non-members. It does not pay monthly dues.**

> **A non-member event donation may optionally be attributed to a referring member, without making the donor a member.**

> **Laravel owns rules and data. Flutter owns all management UI.**

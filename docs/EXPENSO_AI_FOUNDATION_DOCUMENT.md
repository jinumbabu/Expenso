# 1. Product Requirements Document (PRD)

## 1.1 Product Overview

**Product Name:** Expenso AI
**Tagline:** Your AI Financial Assistant — talk about money, don't fill out forms.

**Vision Statement:** Expenso AI helps users manage expenses, budgets, savings, and financial decisions through natural language conversation, while guaranteeing complete user ownership and privacy of their financial data.

**Target Platforms:** Android (Flutter), Web (Flutter Web)

**Primary Users:**
- Individuals tracking personal expenses who find traditional expense apps tedious
- Privacy-conscious users unwilling to upload financial data to third-party servers
- Users who want proactive financial guidance, not just historical reports

---

## 1.2 Goals & Success Metrics

| Goal | Metric |
|---|---|
| Reduce friction in expense logging | Avg. time to log a transaction < 5 seconds via NLP/voice |
| Drive AI engagement | % of transactions entered via natural language vs. forms |
| Build trust through privacy | % of users using Local/Hybrid AI mode |
| Financial behavior improvement | % of users staying within budget month-over-month |
| Retention | 30-day retention rate, weekly active AI chat sessions |

---

## 1.3 Functional Requirements

### FR1 — Authentication
- Google Sign-In on Android and Web
- JWT-based sessions with refresh token rotation
- Audit log of login/logout events

### FR2 — Expense & Income Tracking
- Manual add/edit/delete/search of transactions
- Natural language entry: amount, category, date, payment method auto-detected
- Voice entry
- Receipt OCR with review-before-save

### FR3 — Categorization
- Rule-based categorization (MVP fallback)
- AI/NLP-based categorization (primary, post-Phase 3)
- Frequency-ranked category suggestions (short list, not exhaustive)

### FR4 — Budgeting
- Monthly/weekly/daily budgets per category
- Budget violation detection and alerts

### FR5 — AI Conversational Assistant
- Natural language Q&A about spending, affordability, savings projections
- Context-aware memory (preferences, behavioral patterns, conversation history)
- User-visible transparency: view/delete AI memory
- Cost-managed: rate limits, quotas, graceful degradation to rule engine when cloud unavailable

### FR6 — AI Financial Advisor
- Spending analysis (overspending, category spikes)
- Budget recommendations
- Financial health score
- Forecasting (month-end spend, savings trajectory, upcoming bills)

### FR7 — Recurring Expenses
- Define recurring bills/subscriptions/EMIs
- Reminders and auto-entry

### FR8 — Sync & Backup
- Offline-first local storage (SQLite)
- Encrypted backup to user's own Google Drive
- Delta sync with offline queue
- Conflict resolution via user review (no silent overwrites)

### FR9 — Reporting
- Export PDF, Excel, CSV

### FR10 — Privacy Controls
- Three AI modes: Local, Hybrid, Cloud
- Full audit log visibility to user

---

## 1.4 Non-Functional Requirements

- **Privacy:** No financial data sold or shared; no mandatory centralized database
- **Security:** AES-256 at rest, TLS in transit, platform keystores for key management
- **Offline-first:** All core features (add/edit/view transactions, budgets, dashboard) work without network
- **Performance:** NLP parsing < 2s (cloud), dashboard load < 1s from local DB
- **Scalability:** Backend stateless and horizontally scalable (Cloud Run)
- **Accessibility:** Material 3 compliance, dark mode, screen-reader support

---

## 1.5 Out of Scope (v1)
- SMS/bank transaction auto-import
- Investment tracking
- Multi-currency
- Family/shared accounts
- Full local LLM inference (Ollama deferred to v2)

---

## 1.6 Assumptions & Constraints
- User has a Google account (required for sign-in and Drive backup)
- Gemini API used for cloud AI; subject to rate limits and per-user quotas
- Local AI feasibility on Android pending Phase 0 spike; MVP ships with Gemini + rule engine regardless

---
---

# 2. Database Schema

> SQLite (local, per-device) — mirrored conceptually on backend for sync metadata only. Backend does **not** store plaintext financial data; it relays encrypted blobs and sync metadata. All monetary values stored as integers (minor units, e.g., paise/cents) to avoid floating-point errors.

## 2.1 Core Tables

### `users`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| google_id | TEXT | Unique, from Google Sign-In |
| email | TEXT | |
| display_name | TEXT | |
| currency | TEXT | ISO 4217, e.g., INR |
| country | TEXT | |
| created_at | INTEGER | Unix timestamp |
| updated_at | INTEGER | |

### `accounts`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| name | TEXT | e.g., "Cash", "SBI Savings" |
| type | TEXT | cash / bank / card / wallet |
| balance | INTEGER | minor units |
| is_default | BOOLEAN | |
| created_at | INTEGER | |
| updated_at | INTEGER | |

### `categories`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| name | TEXT | e.g., "Food", "Fuel" |
| type | TEXT | expense / income |
| icon | TEXT | |
| usage_count | INTEGER | for frequency ranking |
| last_used_at | INTEGER | |
| is_system_default | BOOLEAN | seeded categories |
| created_at | INTEGER | |

### `payment_methods`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| name | TEXT | e.g., "SBI Credit Card", "UPI" |
| type | TEXT | cash / card / upi / netbanking / wallet |
| account_id | TEXT | FK → accounts.id, nullable |
| usage_count | INTEGER | |
| created_at | INTEGER | |

### `cards`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| payment_method_id | TEXT | FK → payment_methods.id |
| last_four_digits | TEXT | encrypted |
| network | TEXT | Visa/MasterCard/etc., optional |
| created_at | INTEGER | |

### `transactions`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| account_id | TEXT | FK → accounts.id |
| category_id | TEXT | FK → categories.id |
| payment_method_id | TEXT | FK → payment_methods.id, nullable |
| type | TEXT | expense / income |
| amount | INTEGER | minor units |
| currency | TEXT | |
| description | TEXT | raw user input, e.g., "Spent 250 on tea" |
| merchant | TEXT | extracted/optional |
| date | INTEGER | transaction date (unix) |
| source | TEXT | manual / nlp / voice / ocr / recurring |
| confidence_score | REAL | AI categorization confidence, nullable |
| is_recurring | BOOLEAN | |
| recurring_id | TEXT | FK → recurring_expenses.id, nullable |
| created_at | INTEGER | |
| updated_at | INTEGER | |
| sync_status | TEXT | synced / pending / conflict |
| deleted_at | INTEGER | soft delete, nullable |

### `budgets`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| category_id | TEXT | FK → categories.id, nullable (null = overall budget) |
| period | TEXT | daily / weekly / monthly |
| amount | INTEGER | minor units |
| start_date | INTEGER | |
| end_date | INTEGER | nullable, for recurring budgets |
| created_at | INTEGER | |
| updated_at | INTEGER | |

### `goals`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| name | TEXT | e.g., "Emergency Fund" |
| target_amount | INTEGER | minor units |
| current_amount | INTEGER | |
| target_date | INTEGER | nullable |
| created_at | INTEGER | |
| updated_at | INTEGER | |

### `recurring_expenses`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| category_id | TEXT | FK → categories.id |
| name | TEXT | e.g., "Rent", "Netflix" |
| amount | INTEGER | minor units |
| frequency | TEXT | daily / weekly / monthly / yearly |
| next_due_date | INTEGER | |
| payment_method_id | TEXT | FK → payment_methods.id, nullable |
| is_active | BOOLEAN | |
| created_at | INTEGER | |
| updated_at | INTEGER | |

### `subscriptions`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| recurring_expense_id | TEXT | FK → recurring_expenses.id |
| service_name | TEXT | e.g., "Netflix", "Spotify" |
| renewal_date | INTEGER | |
| status | TEXT | active / cancelled / paused |

### `income_sources`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| name | TEXT | e.g., "Salary", "Freelance" |
| expected_amount | INTEGER | minor units, nullable |
| frequency | TEXT | monthly / weekly / irregular |
| last_received_date | INTEGER | nullable |

---

## 2.2 AI-Related Tables

### `ai_memory`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| memory_type | TEXT | preference / behavioral / conversational |
| key | TEXT | e.g., "preferred_currency", "frequent_merchant_tea_stall" |
| value | TEXT | encrypted JSON |
| confidence | REAL | nullable |
| created_at | INTEGER | |
| last_accessed_at | INTEGER | |
| expires_at | INTEGER | nullable, per retention policy |

### `ai_insights`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| insight_type | TEXT | overspend_alert / budget_recommendation / forecast / health_score |
| title | TEXT | |
| content | TEXT | encrypted JSON |
| severity | TEXT | info / warning / critical |
| related_category_id | TEXT | FK → categories.id, nullable |
| generated_at | INTEGER | |
| dismissed | BOOLEAN | |

### `chat_history`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| role | TEXT | user / assistant |
| message | TEXT | encrypted |
| ai_mode | TEXT | local / hybrid / cloud |
| token_count | INTEGER | nullable, for cost tracking |
| created_at | INTEGER | |

### `receipt_scans`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| transaction_id | TEXT | FK → transactions.id, nullable until confirmed |
| image_path | TEXT | local encrypted file path |
| extracted_data | TEXT | encrypted JSON (merchant, amount, tax, date) |
| status | TEXT | pending_review / confirmed / rejected |
| created_at | INTEGER | |

---

## 2.3 System Tables

### `audit_logs`
*(Shared schema — used by Auth, AI Memory, Sync Conflicts, Security events)*

| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| event_type | TEXT | login / logout / sync_conflict / ai_memory_access / data_export / key_rotation |
| event_category | TEXT | auth / sync / ai / security |
| description | TEXT | |
| metadata | TEXT | JSON, event-specific details |
| ip_address | TEXT | nullable, backend-side only |
| device_id | TEXT | nullable |
| created_at | INTEGER | |

### `sync_metadata`
| Column | Type | Notes |
|---|---|---|
| id | TEXT (UUID) | PK |
| user_id | TEXT | FK → users.id |
| table_name | TEXT | which table the record belongs to |
| record_id | TEXT | UUID of the record |
| operation | TEXT | insert / update / delete |
| local_updated_at | INTEGER | |
| synced_at | INTEGER | nullable |
| sync_status | TEXT | pending / synced / conflict |
| conflict_resolution | TEXT | nullable, JSON of resolution decision |
| device_id | TEXT | originating device |

---

## 2.4 Indexing Notes
- `transactions`: composite index on (user_id, date), (user_id, category_id), (sync_status)
- `categories`: index on (user_id, usage_count DESC) for frequency-ranked suggestions
- `ai_memory`: index on (user_id, memory_type, key)
- `sync_metadata`: index on (user_id, sync_status)

---
---

# 3. System Architecture

## 3.1 High-Level Architecture Diagram (Textual)

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Client (App)                     │
│              (Android + Web, Material 3, Riverpod)            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐    │
│  │ Presentation │  │   Domain     │  │       Data        │    │
│  │  (UI/Widgets)│←→│ (UseCases,   │←→│ (Repositories,    │    │
│  │              │  │  Entities)   │  │  Local DB, API)   │    │
│  └──────────────┘  └──────────────┘  └──────────────────┘    │
│         │                                     │                │
│         │                          ┌──────────┴──────────┐     │
│         │                          │   SQLite (Drift)     │     │
│         │                          │  Encrypted at rest   │     │
│         │                          └──────────┬──────────┘     │
└─────────┼────────────────────────────────────┼────────────────┘
          │ HTTPS (JWT)                        │ Encrypted Sync
          ▼                                     ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│      FastAPI Backend          │    │   User's Google Drive        │
│  (Stateless, Cloud Run)        │    │  (Encrypted backup blobs)     │
│                                │    └─────────────────────────────┘
│  ┌──────────────────────────┐ │
│  │ Auth Service (JWT, OAuth) │ │
│  ├──────────────────────────┤ │
│  │ Sync Relay Service        │ │ ← relays encrypted blobs only
│  ├──────────────────────────┤ │
│  │ AI Orchestration Service  │─┼──────┐
│  ├──────────────────────────┤ │      │
│  │ Audit Logging Service     │ │      │
│  └──────────────────────────┘ │      │
└────────────────────────────────┘      │
                                          ▼
                          ┌───────────────────────────────┐
                          │      AI Engine Layer            │
                          │                                  │
                          │  ┌──────────┐   ┌─────────────┐ │
                          │  │  Rule    │   │  Gemini API  │ │
                          │  │  Engine  │   │  (Cloud AI)  │ │
                          │  └──────────┘   └─────────────┘ │
                          │  ┌──────────────────────────┐   │
                          │  │ Ollama (Local AI, v2)     │   │
                          │  └──────────────────────────┘   │
                          └───────────────────────────────┘
```

---

## 3.2 Component Breakdown

### 3.2.1 Flutter Client (Clean Architecture)

**Presentation Layer**
- Widgets, screens, Riverpod providers/notifiers for state management
- Chat UI, dashboard, transaction forms, voice/OCR capture screens

**Domain Layer**
- Use cases: `AddTransactionUseCase`, `ParseNaturalLanguageExpenseUseCase`, `GenerateInsightsUseCase`, `SyncDataUseCase`
- Entities: pure Dart models (Transaction, Budget, Category, etc.)

**Data Layer**
- Repositories implementing domain interfaces
- Local data source: Drift (SQLite) — encrypted via SQLCipher
- Remote data source: REST client (Dio/http) for backend communication
- Sync engine: queue manager, delta calculator, conflict detector

### 3.2.2 FastAPI Backend (Stateless Services)

| Service | Responsibility |
|---|---|
| **Auth Service** | Google OAuth verification, JWT issuance/refresh, session management |
| **Sync Relay Service** | Receives/serves encrypted data blobs for Drive backup coordination; stores only `sync_metadata` (no plaintext financial data) |
| **AI Orchestration Service** | Routes requests to Rule Engine / Gemini based on user's AI mode setting; enforces rate limits and quotas |
| **Audit Logging Service** | Centralized audit event ingestion, writes to `audit_logs` |
| **Export Service** | Generates PDF/Excel/CSV reports (server-side or on-device, TBD per data sensitivity — local generation preferred) |

> **Key principle:** Backend is a thin orchestration/relay layer. Financial data lives primarily on-device and in the user's Drive. Backend never persists plaintext transaction data.

### 3.2.3 AI Engine Layer

- **Rule Engine:** keyword/regex-based categorization (MVP, always-available fallback)
- **Gemini API:** NLP parsing, conversational assistant, insights generation (cloud, optional per user)
- **Ollama (v2):** local LLM inference for users in Local/Hybrid mode, runs on-device or user's own server

**AI Mode Routing Logic:**
```
User Mode = Local   → Rule Engine only (+ Ollama in v2)
User Mode = Hybrid  → Ollama/Rule Engine first, Gemini for complex queries
User Mode = Cloud   → Gemini primary, Rule Engine fallback on failure/quota exceeded
```

---

## 3.3 Authentication Flow

1. User taps "Sign in with Google" → Flutter triggers Google Sign-In SDK (platform-native for Android, OAuth redirect for Web)
2. Client receives Google ID token → sends to FastAPI `/auth/google`
3. Backend verifies ID token with Google, creates/retrieves `users` record
4. Backend issues JWT access token (short-lived, ~15min) + refresh token (long-lived, stored securely)
5. Client stores tokens in platform-secure storage (Keystore/Web Crypto)
6. Subsequent requests: `Authorization: Bearer <access_token>`
7. On 401, client uses refresh token at `/auth/refresh` → new token pair issued (rotation)
8. All auth events logged to `audit_logs`

---

## 3.4 Sync & Backup Architecture

1. **Local-first writes:** all transactions written to local SQLite immediately, marked `sync_status = pending`
2. **Sync trigger:** on network availability, periodic background sync, or manual trigger
3. **Encryption:** local DB encrypted (SQLCipher); backup payload additionally encrypted with user-derived key before upload
4. **Backup destination:** app-specific folder in user's Google Drive (via Drive API, scoped access)
5. **Delta sync:** only `sync_metadata`-flagged pending records transmitted
6. **Conflict detection:** compares `local_updated_at` timestamps and record hashes; conflicts marked in `sync_metadata.sync_status = conflict`
7. **Conflict resolution:** surfaced in-app review screen; user chooses keep-mine/keep-other/merge; resolution logged to `audit_logs`

---

## 3.5 AI Request Flow (Conversational Query Example)

```
User: "How much did I spend on food this month?"
  │
  ▼
Flutter Chat UI → Domain UseCase (ProcessChatQueryUseCase)
  │
  ▼
Local query: aggregate transactions (category=Food, date=current month) from SQLite
  │
  ▼
Send to AI Orchestration Service:
  - Aggregated summary (NOT raw transaction list, minimizes data exposure)
  - User AI mode preference
  - Relevant ai_memory context (encrypted, decrypted client-side, sent only as needed)
  │
  ▼
AI Orchestration routes per mode → Gemini/Rule Engine generates response
  │
  ▼
Response returned → stored in chat_history (encrypted) → displayed to user
  │
  ▼
ai_memory updated if new behavioral pattern detected
```

---

## 3.6 Security Architecture Summary

| Layer | Mechanism |
|---|---|
| Data at rest (local) | SQLCipher (AES-256) on SQLite |
| Data in transit | TLS 1.3 |
| Backup payload | Client-side encryption before Drive upload, key derived from user credentials, never sent to backend |
| Key storage | Android Keystore / Web Crypto API |
| Auth tokens | JWT (short-lived access + rotating refresh) |
| Audit trail | All security-relevant events (login, key rotation, sync conflicts, data export, AI memory access) logged |
| AI data minimization | Only aggregated/necessary data sent to cloud AI, never full transaction history |

---

## 3.7 Deployment Topology

- **Backend:** Dockerized FastAPI, deployed on Cloud Run (auto-scaling, stateless)
- **Frontend Web:** Flutter Web build → Firebase Hosting / CDN
- **Mobile:** Flutter Android build → Google Play Store
- **Monitoring:** Sentry (error tracking), structured JSON logging, uptime alerts
- **AI Provider:** Gemini API via secure backend proxy (API keys never exposed to client)
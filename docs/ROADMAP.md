# Expenso AI — Final Production Roadmap

## Product Vision
Expenso AI is a privacy-first AI Financial Assistant that helps users manage money through natural language conversations, intelligent expense tracking, budgeting, forecasting, and financial guidance. The primary interface is conversation, not forms.

**Core Principles:** AI-first experience · Privacy-first architecture · Offline-first functionality · User-owned data · Google Drive encrypted backup · Minimal UI, maximum intelligence

---

## Technology Stack

**Frontend:** Flutter (Android + Web) · Material 3 · Riverpod · Drift (SQLite ORM)
**Backend:** FastAPI · Python 3.12 · JWT Authentication · REST APIs
**Storage:** SQLite (local primary) · Google Drive (encrypted backup, user-owned)
**AI:** Gemini API (cloud, optional) · Rule-based engine (MVP fallback) · Ollama/Llama 3/Mistral/Gemma (post-launch local AI)
**Security:** AES-256 encryption · TLS · Android Keystore · Web Crypto API

**Monorepo Structure:**
```
expenso/
├── app/
├── backend/
├── ai-engine/
├── shared/
├── infrastructure/
├── docs/
├── tests/
└── deployments/
```

---

## Phase 0 – Foundation, Architecture & Feasibility (Weeks 1–3)

**Architecture**
- Clean Architecture, Repository Pattern, Dependency Injection, offline-first design
- Database schema: users, accounts, transactions, categories, payment_methods, cards, budgets, goals, recurring_expenses, subscriptions, income_sources, ai_memory, ai_insights, chat_history, receipt_scans, audit_logs, sync_metadata
- Single shared `audit_logs` schema designed now, reused by auth (Phase 1), AI memory (Phase 4), and sync conflicts (Phase 5)

**Security Design**
- AES-256 encryption strategy, TLS, Android Keystore, Web Crypto API
- Privacy modes defined: Local-only AI, Hybrid AI, Cloud AI

**AI Memory Architecture** (design only, implemented in Phase 4)
- Memory types: user preferences, behavioral memory (merchants, categories, salary dates), conversation memory
- User-configurable retention policy, automatic cleanup, deletion controls
- All AI memory encrypted locally

**Local AI Feasibility Spike** *(runs in parallel with architecture work, not sequentially)*
- Validate Ollama on Flutter desktop, Android performance, quantized models
- Decision gate: MVP uses Gemini Cloud + rule-based AI regardless of outcome; full Ollama support deferred to Version 2

---

## Phase 1 – Authentication & User Profile (Weeks 3–4)
- Google Sign-In (Android + Web)
- JWT authentication, refresh token rotation, session management
- User profile: name, currency, country, financial goals
- Audit logging: login, logout, sync events, security actions (writes to shared audit_logs schema)

---

## Phase 2 – Core MVP (Weeks 4–7)

**Goal:** Release first usable AI-powered product.

- Transaction CRUD (add/edit/delete/search)
- Income tracking
- Basic monthly budgeting (Food, Fuel, Entertainment, etc.)
- **Rule-based AI categorization** (Tea→Food, Petrol→Fuel, EB Bill→Utilities, Amazon→Shopping) — designed to coexist as a confidence-fallback layer once NLP categorization arrives in Phase 3
- Smart category suggestions (frequency-ranked, short list)
- Dashboard: income, expenses, savings, budget status, spending trends

---

## Phase 3 – NLP Expense Engine (Weeks 7–10)
- Natural language parsing: amount, category, date, payment method extraction ("Spent 250 on tea", "Paid 1200 electricity bill using SBI card")
- AI categorization replaces rule engine as primary path; rule engine remains as low-confidence fallback
- AI suggestion engine: predictive expense prompts ("You usually buy tea around this time")
- Transaction normalization into structured records

---

## Phase 4 – Conversational Financial Assistant (Weeks 10–14)
- AI chat interface for spending queries and financial Q&A
- Context-aware memory using expense history, budgets, recurring bills, preferences (implements Phase 0 memory architecture)
- **Basic transparency features** (pulled forward from Phase 8): users can view what AI remembers about them
- AI cost management: rate limiting, daily token quotas, usage tracking, cost analytics
- Fallback: cloud unavailable → rule engine

---

## Phase 5 – Google Drive Sync & Backup (Weeks 14–16)
- Encrypted, user-owned backup to Google Drive
- Offline sync engine: delta sync, offline queue, incremental uploads
- **Financial conflict resolution**: no blind last-write-wins; same-transaction edits and duplicates routed to user review screen with merge suggestions; full audit trail (shared audit_logs schema)

> **Beta risk note:** users accumulate real financial data in Phases 2–4 before backup exists. If running early beta testing before Phase 5 completes, communicate this gap explicitly to testers.

---

## Phase 6 – AI Financial Advisor (Weeks 16–20)
- Spending analysis: overspending, category spikes, budget violations
- Budget recommendation engine (daily/weekly/monthly)
- Financial health score (savings rate, budget compliance, debt ratio, expense stability)
- Forecasting: month-end expenses, savings growth, upcoming bills

---

## Phase 7 – Voice & Receipt Intelligence (Weeks 20–22)
- Voice expense entry ("Add fuel expense 1500")
- Receipt OCR: merchant, amount, tax, date extraction with review-before-save

---

## Phase 8 – Privacy & Security Hardening (Weeks 22–24)
- Security audit: encryption review, key management review, API penetration testing
- Privacy mode finalization: Local (no cloud AI), Hybrid (local + cloud), Cloud (Gemini only)
- Full transparency dashboard: AI memory, stored data, sync history, audit logs

---

## Phase 9 – Testing & Production Launch (Weeks 24–26)
- Unit tests: Flutter, FastAPI
- Integration tests: AI engine, sync engine, authentication
- E2E tests: critical workflows
- Load tests: API scalability, AI throughput
- Deployment: Docker + Cloud Run (backend), Flutter Web, Google Play Store (mobile)
- Monitoring: Sentry, structured logging, alerts

---

## Version 2 – Post Launch
- SMS banking parser (UPI, debit/credit card, ATM transaction detection → draft entries)
- Full local AI: Ollama, Llama 3, Mistral, Gemma
- Investment tracking: mutual funds, stocks, crypto, fixed deposits
- Multi-currency support
- Family accounts with shared budgets, privacy-preserving
- Advanced financial planning ("Can I buy a ₹50,000 laptop?", "How long until I save ₹5 lakh?")
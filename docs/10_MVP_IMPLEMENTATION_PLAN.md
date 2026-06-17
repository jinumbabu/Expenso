# Expenso AI

## MVP Implementation Plan

**Version:** 1.0

---

# 1. Purpose

This document converts the roadmap, architecture, database design, API specification, and AI design into an executable development plan.

Goal:

Deliver a production-ready MVP in approximately:

```text id="p1"
12–16 Weeks
```

for a solo developer or small team.

---

# 2. MVP Scope

## Included

✅ Google Sign-In

✅ Expense Tracking

✅ Income Tracking

✅ Budget Tracking

✅ Dashboard

✅ NLP Expense Parsing

✅ AI Chat Assistant

✅ AI Memory

✅ Google Drive Backup

✅ Offline-First Storage

---

## Excluded

❌ SMS Parsing

❌ Investment Tracking

❌ Family Accounts

❌ Multi-Currency

❌ Full Local AI

❌ Real-Time Sync

---

# 3. Development Strategy

Development Order:

```text id="p2"
Foundation
    ↓
Database
    ↓
Authentication
    ↓
Expenses
    ↓
Dashboard
    ↓
NLP
    ↓
AI Assistant
    ↓
Backup
    ↓
Testing
    ↓
Launch
```

---

# 4. Sprint 0 – Project Setup

Duration:

```text id="p3"
3 Days
```

Tasks:

### Repository

```text id="p4"
Create Monorepo

GitHub Setup

Branch Protection
```

---

### Flutter

```text id="p5"
Create Flutter Project

Riverpod Setup

GoRouter Setup
```

---

### Backend

```text id="p6"
FastAPI Setup

Docker Setup

Project Structure
```

---

Deliverable:

```text id="p7"
Project Bootstrapped
```

---

# 5. Sprint 1 – Database Foundation

Duration:

```text id="p8"
1 Week
```

Tasks:

### SQLite

Implement:

```text id="p9"
users

accounts

categories

transactions

budgets
```

---

### Drift

Create:

```text id="p10"
Tables

DAO Layer

Repositories
```

---

### Seed Data

Insert:

```text id="p11"
Food

Fuel

Shopping

Utilities

Salary
```

---

Deliverable:

```text id="p12"
Local Database Working
```

---

# 6. Sprint 2 – Authentication

Duration:

```text id="p13"
1 Week
```

Tasks:

### Google Sign-In

Implement:

```text id="p14"
Android

Web
```

---

### JWT

Implement:

```text id="p15"
Access Token

Refresh Token
```

---

### User Profile

Create:

```text id="p16"
Name

Currency

Country
```

---

Deliverable:

```text id="p17"
Login Complete
```

---

# 7. Sprint 3 – Expense Tracking

Duration:

```text id="p18"
2 Weeks
```

Tasks:

### CRUD

Create:

```text id="p19"
Add Expense

Edit Expense

Delete Expense

Search Expense
```

---

### Categories

Implement:

```text id="p20"
Category Picker

Usage Ranking
```

---

### Payment Methods

Implement:

```text id="p21"
Cash

UPI

Cards
```

---

Deliverable:

```text id="p22"
Expense Tracking Functional
```

---

# 8. Sprint 4 – Dashboard & Budgets

Duration:

```text id="p23"
1 Week
```

Tasks:

### Dashboard

Show:

```text id="p24"
Income

Expenses

Savings

Budget Status
```

---

### Budgets

Create:

```text id="p25"
Monthly Budget

Category Budget
```

---

Deliverable:

```text id="p26"
Financial Overview Screen
```

---

# 9. Sprint 5 – NLP Expense Engine

Duration:

```text id="p27"
2 Weeks
```

Tasks:

### Rule Engine

Implement:

```text id="p28"
Tea → Food

Fuel → Fuel

Amazon → Shopping
```

---

### Gemini Parsing

Implement:

```text id="p29"
Natural Language Parsing
```

---

Example:

```text id="p30"
Spent 250 on tea
```

↓

```json id="p31"
{
  "amount":250,
  "category":"Food"
}
```

---

Deliverable:

```text id="p32"
AI Expense Entry Working
```

---

# 10. Sprint 6 – AI Chat Assistant

Duration:

```text id="p33"
2 Weeks
```

Tasks:

### Chat UI

Create:

```text id="p34"
Chat Screen
```

---

### Financial Queries

Support:

```text id="p35"
How much did I spend?

Budget Status

Savings Questions
```

---

### AI Memory

Implement:

```text id="p36"
Preferences

Behavior Patterns

Conversation Memory
```

---

Deliverable:

```text id="p37"
AI Financial Assistant MVP
```

---

# 11. Sprint 7 – Google Drive Backup

Duration:

```text id="p38"
1 Week
```

Tasks:

### Backup

Implement:

```text id="p39"
Export Database

Encrypt

Upload
```

---

### Restore

Implement:

```text id="p40"
Download

Decrypt

Restore
```

---

Deliverable:

```text id="p41"
User-Owned Backup System
```

---

# 12. Sprint 8 – Security Hardening

Duration:

```text id="p42"
1 Week
```

Tasks:

### SQLCipher

Enable:

```text id="p43"
Database Encryption
```

---

### Secure Storage

Implement:

```text id="p44"
JWT Storage

Key Storage
```

---

### Audit Logging

Enable:

```text id="p45"
Authentication

Backup

AI Memory
```

---

Deliverable:

```text id="p46"
Security Baseline Complete
```

---

# 13. Sprint 9 – Testing

Duration:

```text id="p47"
1 Week
```

Tasks:

### Unit Tests

```text id="p48"
Repositories

Use Cases

AI Logic
```

---

### Widget Tests

```text id="p49"
Screens

Forms

Chat UI
```

---

### Integration Tests

```text id="p50"
Login

Expense Flow

Backup Flow
```

---

Deliverable:

```text id="p51"
Stable MVP
```

---

# 14. Sprint 10 – Launch Preparation

Duration:

```text id="p52"
1 Week
```

Tasks:

### Android Build

```text id="p53"
Release APK

Play Store Assets
```

---

### Web Build

```text id="p54"
Production Build
```

---

### Monitoring

```text id="p55"
Sentry

Logs
```

---

Deliverable:

```text id="p56"
Release Candidate
```

---

# 15. MVP Success Criteria

Users can:

✅ Login

✅ Add Expenses

✅ Track Budgets

✅ Use Natural Language

✅ Chat With AI

✅ Backup Data

✅ Restore Data

✅ Work Offline

---

# 16. Technical Debt Deferred

Move to Version 2:

```text id="p57"
SMS Parsing

OCR

Voice Input

Local AI

Multi-Currency

Family Accounts
```

---

# 17. MVP Release Checklist

Before Launch:

```text id="p58"
Database Encrypted

Backup Tested

AI Tested

Offline Tested

Authentication Tested

Crash-Free Build
```

All must pass.

---

# Approval

Document:
10_MVP_IMPLEMENTATION_PLAN.md

Version:
1.0

Status:
Approved

Next Document:
11_TESTING_STRATEGY.md

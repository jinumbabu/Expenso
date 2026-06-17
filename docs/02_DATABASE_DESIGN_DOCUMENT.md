# Expenso AI

## Database Design Document

**Version:** 1.0

---

# 1. Purpose

This document defines the complete database architecture for Expenso AI.

The database is designed to support:

* Offline-first operation
* AI-powered financial analysis
* Natural language expense tracking
* User-owned data
* Google Drive backup
* Future PostgreSQL migration
* Multi-device synchronization

---

# 2. Database Architecture

## Primary Database

```text
SQLite (Drift ORM)
```

Purpose:

* Local storage
* Offline-first operations
* Fast response times
* User-controlled data

---

## Backup Storage

```text
Google Drive App Folder
```

Purpose:

* Encrypted backups
* Device restoration
* User ownership

---

## Future Database

```text
PostgreSQL
```

Purpose:

* Enterprise scaling
* Shared accounts
* Multi-user collaboration

---

# 3. Design Principles

## Offline First

All operations must work without internet.

---

## Encryption First

Sensitive data must be encrypted.

---

## Auditability

Every critical operation must be traceable.

---

## AI Ready

Database supports:

* AI memory
* Chat history
* Financial insights
* Behavioral patterns

---

# 4. Entity Relationship Overview

```text
users
│
├── accounts
│
├── transactions
│     ├── categories
│     ├── payment_methods
│     └── recurring_expenses
│
├── budgets
│
├── goals
│
├── ai_memory
│
├── ai_insights
│
├── chat_history
│
├── receipt_scans
│
├── audit_logs
│
└── sync_metadata
```

---

# 5. Core Tables

---

# 5.1 users

Stores user profile information.

| Column       | Type    | Constraint |
| ------------ | ------- | ---------- |
| id           | TEXT    | PK         |
| google_id    | TEXT    | UNIQUE     |
| email        | TEXT    | UNIQUE     |
| display_name | TEXT    | NOT NULL   |
| currency     | TEXT    | NOT NULL   |
| country      | TEXT    | NULL       |
| created_at   | INTEGER | NOT NULL   |
| updated_at   | INTEGER | NOT NULL   |

Indexes:

```sql
CREATE INDEX idx_users_email
ON users(email);
```

---

# 5.2 accounts

Stores user financial accounts.

Examples:

* Cash
* SBI Savings
* HDFC Credit Card

| Column     | Type    |
| ---------- | ------- |
| id         | TEXT    |
| user_id    | TEXT    |
| name       | TEXT    |
| type       | TEXT    |
| balance    | INTEGER |
| is_default | INTEGER |
| created_at | INTEGER |

Foreign Keys:

```text
user_id → users.id
```

---

# 5.3 categories

Expense and income categories.

Examples:

* Food
* Fuel
* Grocery
* Salary

| Column       | Type    |
| ------------ | ------- |
| id           | TEXT    |
| user_id      | TEXT    |
| name         | TEXT    |
| type         | TEXT    |
| icon         | TEXT    |
| usage_count  | INTEGER |
| last_used_at | INTEGER |

Indexes:

```sql
CREATE INDEX idx_categories_usage
ON categories(user_id, usage_count);
```

---

# 5.4 payment_methods

Examples:

* Cash
* UPI
* SBI Credit Card

| Column      | Type    |
| ----------- | ------- |
| id          | TEXT    |
| user_id     | TEXT    |
| account_id  | TEXT    |
| name        | TEXT    |
| type        | TEXT    |
| usage_count | INTEGER |

---

# 5.5 transactions

Most important table.

Stores all income and expenses.

| Column            | Type    |
| ----------------- | ------- |
| id                | TEXT    |
| user_id           | TEXT    |
| account_id        | TEXT    |
| category_id       | TEXT    |
| payment_method_id | TEXT    |
| type              | TEXT    |
| amount            | INTEGER |
| currency          | TEXT    |
| description       | TEXT    |
| merchant          | TEXT    |
| date              | INTEGER |
| source            | TEXT    |
| confidence_score  | REAL    |
| created_at        | INTEGER |
| updated_at        | INTEGER |
| sync_status       | TEXT    |

Transaction Sources:

```text
manual
nlp
voice
ocr
recurring
```

Indexes:

```sql
CREATE INDEX idx_transactions_user_date
ON transactions(user_id,date);

CREATE INDEX idx_transactions_category
ON transactions(user_id,category_id);
```

---

# 5.6 budgets

Stores budget limits.

| Column      | Type    |
| ----------- | ------- |
| id          | TEXT    |
| user_id     | TEXT    |
| category_id | TEXT    |
| period      | TEXT    |
| amount      | INTEGER |
| start_date  | INTEGER |
| end_date    | INTEGER |

Periods:

```text
daily
weekly
monthly
```

---

# 5.7 goals

Financial goals.

Examples:

```text
Emergency Fund
New Bike
Vacation
```

Columns:

```text
id
user_id
name
target_amount
current_amount
target_date
created_at
```

---

# 5.8 recurring_expenses

Examples:

```text
Rent
Netflix
Internet Bill
```

Columns:

```text
id
user_id
category_id
amount
frequency
next_due_date
is_active
```

---

# 5.9 income_sources

Examples:

```text
Salary
Freelance
Business
```

Columns:

```text
id
user_id
name
expected_amount
frequency
last_received_date
```

---

# 6. AI Tables

---

# 6.1 ai_memory

Stores long-term AI memory.

Memory Types:

```text
preference
behavioral
conversation
```

Examples:

```text
Preferred Currency

Frequent Merchant

Salary Date

Budget Goal
```

Columns:

```text
id
user_id
memory_type
key
value
confidence
expires_at
created_at
```

Encryption:

```text
AES-256 encrypted JSON
```

---

# 6.2 ai_insights

Stores AI-generated recommendations.

Examples:

```text
Overspending Alert

Food Budget Warning

Savings Recommendation
```

Columns:

```text
id
user_id
insight_type
title
content
severity
generated_at
```

---

# 6.3 chat_history

Stores conversations.

Columns:

```text
id
user_id
role
message
ai_mode
token_count
created_at
```

Roles:

```text
user
assistant
```

AI Modes:

```text
local
hybrid
cloud
```

---

# 7. OCR Tables

---

# receipt_scans

Stores OCR results.

Columns:

```text
id
user_id
transaction_id
image_path
extracted_data
status
created_at
```

Statuses:

```text
pending_review
confirmed
rejected
```

---

# 8. System Tables

---

# 8.1 audit_logs

Single centralized audit table.

Tracks:

```text
Authentication
AI Memory
Sync
Security
Backup
Exports
```

Columns:

```text
id
user_id
event_type
event_category
description
metadata
created_at
```

Example Events:

```text
LOGIN

LOGOUT

BACKUP_CREATED

SYNC_CONFLICT

AI_MEMORY_UPDATED
```

---

# 8.2 sync_metadata

Tracks synchronization.

Columns:

```text
id
user_id
table_name
record_id
operation
local_updated_at
synced_at
sync_status
device_id
```

Statuses:

```text
pending
synced
conflict
```

---

# 9. Encryption Strategy

## Encrypt Entire Database

Technology:

```text
SQLCipher
AES-256
```

---

## Encrypt Sensitive Fields

Fields:

```text
ai_memory.value

chat_history.message

receipt_scans.extracted_data

audit_logs.metadata
```

---

## Key Storage

Android:

```text
Android Keystore
```

Web:

```text
Web Crypto API
```

---

# 10. Indexing Strategy

High Priority Indexes

```sql
transactions(user_id,date)

transactions(user_id,category_id)

transactions(sync_status)

categories(user_id,usage_count)

ai_memory(user_id,memory_type)

sync_metadata(sync_status)
```

---

# 11. Backup Strategy

Backup Target:

```text
Google Drive App Folder
```

Backup Content:

```text
Encrypted Database

Encrypted Metadata

Sync State
```

Backup Frequency:

```text
Manual (MVP)

Automatic (Future)
```

---

# 12. Migration Strategy

Current:

```text
SQLite
```

Future:

```text
PostgreSQL
```

Requirements:

* UUID Primary Keys
* ISO Currency Support
* Database Abstraction Layer
* Drift Migration Support

---

# 13. Database Performance Goals

Dashboard Load:

```text
< 1 second
```

Expense Search:

```text
< 500 ms
```

AI Query Preparation:

```text
< 1 second
```

Database Size:

```text
Support 10+ years
of personal financial data
```

---

# Approval

Document:
02_DATABASE_DESIGN_DOCUMENT.md

Version:
1.0

Status:
Approved

Next Document:
03_SYSTEM_ARCHITECTURE_DOCUMENT.md

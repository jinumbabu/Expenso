# Expenso AI

## SQL Schema & Migration Document

**Version:** 1.0

---

# 1. Purpose

This document contains:

* SQLite schema definitions
* Drift ORM mapping requirements
* Index definitions
* Migration strategy
* Triggers
* Seed data
* Future PostgreSQL compatibility

Database Engine:

```text id="s1h7d5"
SQLite + SQLCipher
```

---

# 2. Database Standards

## Primary Key Standard

All tables use UUIDs.

Example:

```sql
id TEXT PRIMARY KEY NOT NULL
```

---

## Timestamp Standard

All timestamps stored as Unix Epoch.

Example:

```sql
created_at INTEGER NOT NULL
updated_at INTEGER NOT NULL
```

---

## Money Standard

Never use:

```sql
REAL
FLOAT
DOUBLE
```

Use:

```sql
INTEGER
```

Example:

```text
₹100.50
```

Stored as:

```text
10050
```

(paise)

---

# 3. Users Table

```sql
CREATE TABLE users (
    id TEXT PRIMARY KEY NOT NULL,
    google_id TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'INR',
    country TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
```

Indexes:

```sql
CREATE INDEX idx_users_email
ON users(email);
```

---

# 4. Accounts Table

```sql
CREATE TABLE accounts (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    balance INTEGER NOT NULL DEFAULT 0,
    is_default INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
);
```

---

# 5. Categories Table

```sql
CREATE TABLE categories (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    icon TEXT,
    usage_count INTEGER DEFAULT 0,
    last_used_at INTEGER,
    is_system_default INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
);
```

Indexes:

```sql
CREATE INDEX idx_categories_usage
ON categories(user_id, usage_count);
```

---

# 6. Payment Methods Table

```sql
CREATE TABLE payment_methods (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL,
    account_id TEXT,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    usage_count INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id),

    FOREIGN KEY(account_id)
    REFERENCES accounts(id)
);
```

---

# 7. Transactions Table

```sql
CREATE TABLE transactions (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,
    account_id TEXT,
    category_id TEXT,
    payment_method_id TEXT,

    type TEXT NOT NULL,

    amount INTEGER NOT NULL,

    currency TEXT NOT NULL,

    description TEXT,

    merchant TEXT,

    date INTEGER NOT NULL,

    source TEXT NOT NULL,

    confidence_score REAL,

    is_recurring INTEGER DEFAULT 0,

    sync_status TEXT DEFAULT 'pending',

    created_at INTEGER NOT NULL,

    updated_at INTEGER NOT NULL,

    deleted_at INTEGER,

    FOREIGN KEY(user_id)
    REFERENCES users(id),

    FOREIGN KEY(account_id)
    REFERENCES accounts(id),

    FOREIGN KEY(category_id)
    REFERENCES categories(id),

    FOREIGN KEY(payment_method_id)
    REFERENCES payment_methods(id)
);
```

Indexes:

```sql
CREATE INDEX idx_transactions_user_date
ON transactions(user_id,date);

CREATE INDEX idx_transactions_category
ON transactions(user_id,category_id);

CREATE INDEX idx_transactions_sync
ON transactions(sync_status);
```

---

# 8. Budgets Table

```sql
CREATE TABLE budgets (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,

    category_id TEXT,

    period TEXT NOT NULL,

    amount INTEGER NOT NULL,

    start_date INTEGER NOT NULL,

    end_date INTEGER,

    created_at INTEGER NOT NULL,

    updated_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id),

    FOREIGN KEY(category_id)
    REFERENCES categories(id)
);
```

---

# 9. Goals Table

```sql
CREATE TABLE goals (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,

    name TEXT NOT NULL,

    target_amount INTEGER NOT NULL,

    current_amount INTEGER DEFAULT 0,

    target_date INTEGER,

    created_at INTEGER NOT NULL,

    updated_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
);
```

---

# 10. Recurring Expenses Table

```sql
CREATE TABLE recurring_expenses (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,

    category_id TEXT NOT NULL,

    name TEXT NOT NULL,

    amount INTEGER NOT NULL,

    frequency TEXT NOT NULL,

    next_due_date INTEGER NOT NULL,

    is_active INTEGER DEFAULT 1,

    created_at INTEGER NOT NULL,

    updated_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id),

    FOREIGN KEY(category_id)
    REFERENCES categories(id)
);
```

---

# 11. AI Memory Table

```sql
CREATE TABLE ai_memory (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,

    memory_type TEXT NOT NULL,

    memory_key TEXT NOT NULL,

    memory_value TEXT NOT NULL,

    confidence REAL,

    expires_at INTEGER,

    created_at INTEGER NOT NULL,

    last_accessed_at INTEGER,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
);
```

Indexes:

```sql
CREATE INDEX idx_ai_memory_lookup
ON ai_memory(user_id,memory_type);
```

---

# 12. AI Insights Table

```sql
CREATE TABLE ai_insights (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,

    insight_type TEXT NOT NULL,

    title TEXT NOT NULL,

    content TEXT NOT NULL,

    severity TEXT NOT NULL,

    generated_at INTEGER NOT NULL,

    dismissed INTEGER DEFAULT 0,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
);
```

---

# 13. Chat History Table

```sql
CREATE TABLE chat_history (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,

    role TEXT NOT NULL,

    message TEXT NOT NULL,

    ai_mode TEXT NOT NULL,

    token_count INTEGER,

    created_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
);
```

---

# 14. Receipt Scans Table

```sql
CREATE TABLE receipt_scans (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,

    transaction_id TEXT,

    image_path TEXT NOT NULL,

    extracted_data TEXT,

    status TEXT NOT NULL,

    created_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id),

    FOREIGN KEY(transaction_id)
    REFERENCES transactions(id)
);
```

---

# 15. Audit Logs Table

```sql
CREATE TABLE audit_logs (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT,

    event_type TEXT NOT NULL,

    event_category TEXT NOT NULL,

    description TEXT,

    metadata TEXT,

    created_at INTEGER NOT NULL,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
);
```

Indexes:

```sql
CREATE INDEX idx_audit_logs_event
ON audit_logs(event_type);

CREATE INDEX idx_audit_logs_date
ON audit_logs(created_at);
```

---

# 16. Sync Metadata Table

```sql
CREATE TABLE sync_metadata (
    id TEXT PRIMARY KEY NOT NULL,

    user_id TEXT NOT NULL,

    table_name TEXT NOT NULL,

    record_id TEXT NOT NULL,

    operation TEXT NOT NULL,

    local_updated_at INTEGER NOT NULL,

    synced_at INTEGER,

    sync_status TEXT NOT NULL,

    device_id TEXT,

    FOREIGN KEY(user_id)
    REFERENCES users(id)
);
```

---

# 17. Triggers

## Auto Update Timestamp

```sql
CREATE TRIGGER update_transaction_timestamp
AFTER UPDATE ON transactions
BEGIN
    UPDATE transactions
    SET updated_at = unixepoch()
    WHERE id = NEW.id;
END;
```

---

## Category Usage Counter

```sql
CREATE TRIGGER increment_category_usage
AFTER INSERT ON transactions
BEGIN
    UPDATE categories
    SET usage_count = usage_count + 1
    WHERE id = NEW.category_id;
END;
```

---

# 18. Seed Data

Default Categories:

```text
Food
Fuel
Grocery
Utilities
Shopping
Entertainment
Salary
Freelance
Investment
Transfer
```

Default Payment Methods:

```text
Cash
UPI
Credit Card
Debit Card
Net Banking
```

---

# 19. Migration Strategy

## Version 1

```text
Core Tables
```

## Version 2

```text
AI Memory
AI Insights
```

## Version 3

```text
OCR
Voice
Forecasting
```

## Version 4

```text
Investment Tracking
```

---

# 20. Drift Migration Example

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (migrator, from, to) async {
    if (from < 2) {
      await migrator.createTable(aiMemory);
    }
  },
);
```

---

# 21. Performance Targets

Transaction Insert:

```text
< 50ms
```

Dashboard Query:

```text
< 500ms
```

AI Data Preparation:

```text
< 1 second
```

Database Size:

```text
Support 10+ years
of financial records
```

---

# Approval

Document:
06_SQL_SCHEMA_AND_MIGRATIONS.md

Version:
1.0

Status:
Approved

Next Document:
07_AI_ENGINE_SPECIFICATION.md

# Expenso AI

## API Specification Document

**Version:** 1.0

---

# 1. Overview

This document defines all REST API endpoints used by Expenso AI.

## API Standards

### Base URL

Development

```text
http://localhost:8000/api/v1
```

Production

```text
https://api.expenso.ai/api/v1
```

---

## Authentication

Protected endpoints require:

```http
Authorization: Bearer <jwt_token>
```

---

## Response Format

Success

```json
{
  "success": true,
  "data": {}
}
```

Error

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid request"
  }
}
```

---

# 2. Authentication APIs

---

## POST /auth/google

Authenticate using Google Sign-In.

### Request

```json
{
  "google_token": "google-id-token"
}
```

### Response

```json
{
  "success": true,
  "data": {
    "access_token": "jwt-token",
    "refresh_token": "refresh-token",
    "user": {
      "id": "uuid",
      "name": "Jinu",
      "email": "user@example.com"
    }
  }
}
```

---

## POST /auth/refresh

Refresh expired access token.

### Request

```json
{
  "refresh_token": "token"
}
```

### Response

```json
{
  "success": true,
  "data": {
    "access_token": "new-token"
  }
}
```

---

## POST /auth/logout

Logout user.

### Response

```json
{
  "success": true
}
```

---

# 3. User APIs

---

## GET /users/me

Get current user profile.

### Response

```json
{
  "id": "uuid",
  "name": "Jinu",
  "currency": "INR",
  "country": "IN"
}
```

---

## PUT /users/me

Update profile.

### Request

```json
{
  "display_name": "Jinu",
  "currency": "INR"
}
```

---

# 4. Account APIs

---

## GET /accounts

List accounts.

### Response

```json
[
  {
    "id": "uuid",
    "name": "SBI Savings",
    "balance": 25000
  }
]
```

---

## POST /accounts

Create account.

### Request

```json
{
  "name": "SBI Savings",
  "type": "bank"
}
```

---

## PUT /accounts/{id}

Update account.

---

## DELETE /accounts/{id}

Delete account.

---

# 5. Category APIs

---

## GET /categories

Get categories.

---

## POST /categories

Create category.

### Request

```json
{
  "name": "Food",
  "type": "expense"
}
```

---

## PUT /categories/{id}

Update category.

---

## DELETE /categories/{id}

Delete category.

---

# 6. Transaction APIs

---

## GET /transactions

List transactions.

### Query Parameters

```text
?page=1
&limit=20
&category=food
&from=2026-01-01
&to=2026-01-31
```

---

## GET /transactions/{id}

Get transaction details.

---

## POST /transactions

Create transaction.

### Request

```json
{
  "type": "expense",
  "amount": 250,
  "category_id": "uuid",
  "description": "Tea",
  "date": "2026-01-10"
}
```

### Response

```json
{
  "success": true,
  "data": {
    "id": "uuid"
  }
}
```

---

## PUT /transactions/{id}

Update transaction.

---

## DELETE /transactions/{id}

Soft delete transaction.

---

# 7. Budget APIs

---

## GET /budgets

Get budgets.

---

## POST /budgets

Create budget.

### Request

```json
{
  "category_id": "uuid",
  "amount": 5000,
  "period": "monthly"
}
```

---

## PUT /budgets/{id}

Update budget.

---

## DELETE /budgets/{id}

Delete budget.

---

# 8. Goals APIs

---

## GET /goals

Get savings goals.

---

## POST /goals

Create goal.

### Request

```json
{
  "name": "Emergency Fund",
  "target_amount": 100000
}
```

---

## PUT /goals/{id}

Update goal.

---

## DELETE /goals/{id}

Delete goal.

---

# 9. AI Expense Parsing APIs

---

## POST /ai/parse-expense

Convert natural language into transaction.

### Request

```json
{
  "text": "Spent 250 on tea"
}
```

### Response

```json
{
  "amount": 250,
  "category": "Food",
  "merchant": "Tea",
  "date": "today",
  "confidence": 0.95
}
```

---

## POST /ai/categorize

Categorize transaction.

### Request

```json
{
  "description": "Petrol"
}
```

### Response

```json
{
  "category": "Fuel",
  "confidence": 0.97
}
```

---

# 10. AI Chat APIs

---

## POST /chat

Main conversational endpoint.

### Request

```json
{
  "message": "How much did I spend on food this month?"
}
```

### Response

```json
{
  "reply": "You spent ₹8,450 on food this month."
}
```

---

## GET /chat/history

Get conversation history.

---

## DELETE /chat/history

Clear conversation history.

---

# 11. AI Memory APIs

---

## GET /ai-memory

List AI memories.

### Response

```json
[
  {
    "key": "salary_date",
    "value": "1st"
  }
]
```

---

## DELETE /ai-memory/{id}

Delete memory.

---

## POST /ai-memory/disable

Disable AI memory.

---

# 12. AI Insights APIs

---

## GET /insights

Get financial insights.

### Response

```json
[
  {
    "title": "Food Spending Alert",
    "severity": "warning"
  }
]
```

---

# 13. Receipt OCR APIs

---

## POST /ocr/upload

Upload receipt image.

### Request

```json
{
  "image": "base64-data"
}
```

### Response

```json
{
  "merchant": "Store",
  "amount": 540
}
```

---

## POST /ocr/confirm

Confirm OCR extraction.

---

# 14. Recurring Expense APIs

---

## GET /recurring-expenses

List recurring expenses.

---

## POST /recurring-expenses

Create recurring expense.

### Request

```json
{
  "name": "Netflix",
  "amount": 649,
  "frequency": "monthly"
}
```

---

## PUT /recurring-expenses/{id}

Update recurring expense.

---

## DELETE /recurring-expenses/{id}

Delete recurring expense.

---

# 15. Backup APIs

---

## POST /backup/create

Create encrypted backup.

### Response

```json
{
  "backup_id": "uuid"
}
```

---

## POST /backup/restore

Restore backup.

---

## GET /backup/list

List backups.

---

# 16. Sync APIs

---

## POST /sync/upload

Upload pending changes.

---

## POST /sync/download

Download updates.

---

## GET /sync/status

Get sync status.

### Response

```json
{
  "pending": 4,
  "synced": 240
}
```

---

# 17. Audit Log APIs

---

## GET /audit-logs

Get audit events.

### Filters

```text
event_type
date
category
```

---

# 18. Health APIs

---

## GET /health

Service health check.

### Response

```json
{
  "status": "healthy"
}
```

---

## GET /version

Current API version.

---

# 19. Error Codes

| Code             | Meaning           |
| ---------------- | ----------------- |
| VALIDATION_ERROR | Invalid request   |
| UNAUTHORIZED     | Missing token     |
| FORBIDDEN        | Permission denied |
| NOT_FOUND        | Resource missing  |
| RATE_LIMITED     | Too many requests |
| SYNC_CONFLICT    | Data conflict     |
| AI_UNAVAILABLE   | AI service down   |
| BACKUP_FAILED    | Backup error      |
| INTERNAL_ERROR   | Server error      |

---

# 20. API Versioning Strategy

Current Version:

```text
v1
```

Future:

```text
/ api / v2
/ api / v3
```

Backward compatibility maintained.

---

# Approval

Document:
04_API_SPECIFICATION.md

Version:
1.0

Status:
Approved

Next Document:
05_FLUTTER_PROJECT_STRUCTURE.md

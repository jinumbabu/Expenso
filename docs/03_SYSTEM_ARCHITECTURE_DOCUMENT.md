# Expenso AI

## System Architecture Document

**Version:** 1.0

---

# 1. Purpose

This document defines the complete technical architecture of Expenso AI.

It serves as the primary reference for:

* Backend Development
* Flutter Development
* AI Integration
* Security Implementation
* Sync Architecture
* Deployment Planning

---

# 2. Architecture Principles

## AI First

Conversation is the primary interface.

---

## Privacy First

User owns all financial data.

---

## Offline First

Core functionality works without internet.

---

## Secure By Default

Encryption at every layer.

---

## Scalable

Support future migration from:

```text
SQLite → PostgreSQL

Single Device → Multi Device

Single User → Millions of Users
```

---

# 3. High Level Architecture

```text
┌─────────────────────────────┐
│       Flutter Client        │
│   Android + Web Application │
└─────────────┬───────────────┘
              │
              ▼
┌─────────────────────────────┐
│       Local Database        │
│     SQLite + SQLCipher      │
└─────────────┬───────────────┘
              │
     ┌────────┼────────┐
     │                 │
     ▼                 ▼
┌─────────────┐  ┌─────────────┐
│ FastAPI API │  │Google Drive │
│   Backend   │  │   Backup    │
└──────┬──────┘  └─────────────┘
       │
       ▼
┌─────────────────────────────┐
│      AI Orchestrator        │
└──────┬───────────────┬──────┘
       │               │
       ▼               ▼
┌─────────────┐  ┌─────────────┐
│Rule Engine  │  │ Gemini API  │
└─────────────┘  └─────────────┘

Future:

┌─────────────┐
│   Ollama    │
└─────────────┘
```

---

# 4. System Components

## Flutter Application

Responsibilities:

* UI Rendering
* State Management
* Local Database Access
* Authentication
* AI Chat Interface
* Backup Management

Technology:

```text
Flutter
Riverpod
Go Router
Drift ORM
```

---

## SQLite Database

Responsibilities:

* Local Data Storage
* Offline Support
* Fast Queries
* AI Memory Storage

Technology:

```text
SQLite
SQLCipher
```

---

## FastAPI Backend

Responsibilities:

* Authentication
* AI Routing
* Sync Coordination
* Usage Tracking
* Rate Limiting

Technology:

```text
FastAPI
Python 3.12
JWT
```

---

## Gemini API

Responsibilities:

* Natural Language Understanding
* Expense Parsing
* Financial Advice
* Spending Analysis

---

## Google Drive

Responsibilities:

* Backup Storage
* Data Recovery
* User Ownership

---

# 5. Clean Architecture

## Flutter Layers

```text
Presentation
     │
     ▼
Domain
     │
     ▼
Data
```

---

## Presentation Layer

Contains:

```text
Screens

Widgets

Providers

Controllers
```

Examples:

```text
DashboardScreen

ChatScreen

BudgetScreen
```

---

## Domain Layer

Contains:

```text
Entities

Use Cases

Repositories
```

Examples:

```text
AddExpenseUseCase

GenerateInsightUseCase

SyncDataUseCase
```

---

## Data Layer

Contains:

```text
Database

API Clients

Repositories

Services
```

---

# 6. Authentication Flow

## Google Login Flow

```text
User
  │
  ▼
Google Sign-In
  │
  ▼
Google ID Token
  │
  ▼
FastAPI Verify Token
  │
  ▼
JWT Access Token
  │
  ▼
Store Securely
```

---

## Token Storage

Android:

```text
Android Keystore
```

Web:

```text
Web Crypto API
```

---

# 7. Expense Creation Flow

Example:

```text
Spent ₹250 on tea
```

Flow:

```text
User
 │
 ▼
Chat Input
 │
 ▼
Rule Engine
 │
 ▼
NLP Parser
 │
 ▼
Expense Object
 │
 ▼
SQLite Save
 │
 ▼
Dashboard Update
```

Generated:

```json
{
  "amount":250,
  "category":"Food",
  "merchant":"Tea",
  "source":"nlp"
}
```

---

# 8. AI Processing Flow

## User Question

```text
How much did I spend on food this month?
```

Flow:

```text
User
 │
 ▼
Chat Interface
 │
 ▼
Local Data Query
 │
 ▼
Prepare Summary
 │
 ▼
AI Orchestrator
 │
 ▼
Gemini API
 │
 ▼
Response
 │
 ▼
Chat History
```

---

## Data Minimization

Never send:

```text
Full Database

Complete Financial History
```

Send:

```text
Aggregated Statistics
```

Only.

---

# 9. AI Memory Architecture

## Memory Types

### Preference Memory

Examples:

```text
Currency

Budget Preference

Theme Preference
```

---

### Behavioral Memory

Examples:

```text
Frequent Merchant

Salary Date

Food Spending Pattern
```

---

### Conversation Memory

Examples:

```text
Recent Financial Questions

AI Recommendations
```

---

# 10. AI Mode Architecture

## Local Mode

```text
Rule Engine Only
```

No Cloud.

---

## Hybrid Mode

```text
Rule Engine
+
Gemini
```

---

## Cloud Mode

```text
Gemini
```

Primary.

---

# 11. Sync Architecture

## Sync Flow

```text
SQLite
   │
Pending Changes
   │
   ▼
Sync Queue
   │
   ▼
Encryption
   │
   ▼
Google Drive
```

---

## Sync States

```text
pending

synced

conflict
```

---

# 12. Conflict Resolution

Never overwrite automatically.

Example:

```text
Device A:
₹500

Device B:
₹700
```

Result:

```text
Conflict Screen
```

Options:

```text
Use A

Use B

Merge
```

---

# 13. Backup Architecture

## Backup Content

```text
Encrypted Database

AI Memory

Settings

Sync Metadata
```

---

## Backup Types

### Manual Backup

MVP

### Automatic Backup

Future

---

# 14. Security Architecture

## Data At Rest

```text
SQLCipher
AES-256
```

---

## Data In Transit

```text
TLS 1.3
```

---

## Sensitive Fields

Encrypt:

```text
AI Memory

Chat History

Receipt OCR Data

Audit Metadata
```

---

# 15. Audit Logging Architecture

Single audit system.

```text
audit_logs
```

Tracks:

```text
Authentication

Sync

AI Access

Backups

Security Events
```

---

# 16. API Architecture

## Authentication APIs

```http
POST /auth/google

POST /auth/refresh
```

---

## Transaction APIs

```http
GET /transactions

POST /transactions

PUT /transactions/{id}

DELETE /transactions/{id}
```

---

## AI APIs

```http
POST /chat

POST /parse-expense
```

---

## Sync APIs

```http
POST /sync

POST /backup
```

---

# 17. Deployment Architecture

## Frontend

```text
Flutter Web
```

Hosted on:

```text
Firebase Hosting
```

---

## Backend

```text
FastAPI
Docker
Cloud Run
```

---

## Monitoring

```text
Sentry

Structured Logs

Health Checks
```

---

# 18. Scalability Strategy

Current:

```text
SQLite
Single User
```

Future:

```text
PostgreSQL

Horizontal Scaling

Microservices
```

---

# 19. Disaster Recovery

Recovery Sources:

```text
Google Drive Backup

Local Database

Audit Logs
```

Recovery Steps:

```text
Install App

Google Login

Restore Backup

Resume Usage
```

---

# 20. Performance Targets

Dashboard:

```text
< 1 second
```

Expense Entry:

```text
< 5 seconds
```

AI Response:

```text
< 3 seconds
```

Sync:

```text
< 10 seconds
```

---

# 21. Future Architecture

Version 2:

```text
Ollama

Llama 3

Mistral

Gemma
```

Version 3:

```text
Bank Integrations

Investment Tracking

Family Accounts
```

---

# Approval

Document:
03_SYSTEM_ARCHITECTURE_DOCUMENT.md

Version:
1.0

Status:
Approved

Next Document:
04_API_SPECIFICATION.md

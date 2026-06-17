# Expenso AI

## Security & Encryption Design Document

**Version:** 1.0

---

# 1. Purpose

This document defines the complete security architecture for Expenso AI.

Objectives:

* Protect user financial data
* Ensure privacy-first design
* Prevent unauthorized access
* Secure AI interactions
* Secure backups and sync
* Support future compliance requirements

---

# 2. Security Principles

## Principle 1

User owns all financial data.

---

## Principle 2

Encrypt everything sensitive.

---

## Principle 3

Least privilege access.

---

## Principle 4

Never trust client input.

---

## Principle 5

AI only receives minimum required context.

---

# 3. Security Architecture Overview

```text
┌───────────────────────────┐
│      Flutter Client       │
└────────────┬──────────────┘
             │
             ▼
┌───────────────────────────┐
│     Encryption Layer      │
└────────────┬──────────────┘
             │
             ▼
┌───────────────────────────┐
│ SQLite + SQLCipher        │
└────────────┬──────────────┘
             │
      ┌──────┴───────┐
      │              │
      ▼              ▼
 Google Drive     FastAPI
 (Encrypted)      Backend
                     │
                     ▼
                Gemini API
```

---

# 4. Data Classification

## Public Data

Examples:

```text
App Version
Theme Preference
Language
```

No encryption required.

---

## Sensitive Data

Examples:

```text
Transactions
Income
Budgets
Goals
AI Memory
Chat History
```

Must be encrypted.

---

## Critical Secrets

Examples:

```text
Encryption Keys
JWT Tokens
Google Access Tokens
```

Must never be stored in plaintext.

---

# 5. Encryption Standards

## Algorithm

```text
AES-256-GCM
```

Benefits:

* Strong encryption
* Authenticated encryption
* Industry standard

---

## Hashing

```text
SHA-256
```

Uses:

* Backup verification
* Integrity checks

---

## Transport Security

```text
TLS 1.3
```

All API communication.

---

# 6. Database Encryption

## Technology

```text
SQLCipher
```

Encrypts:

```text
Entire SQLite Database
```

Includes:

* Transactions
* Categories
* Budgets
* AI Memory
* Chat History

---

# 7. Field-Level Encryption

Additional encryption for highly sensitive fields.

Fields:

```text
ai_memory.memory_value

chat_history.message

receipt_scans.extracted_data

audit_logs.metadata
```

---

Encryption Flow:

```text
Data
 │
 ▼
AES-256 Encrypt
 │
 ▼
Database Storage
```

---

# 8. Key Management

## Master Key

Generated during first login.

Used to:

```text
Encrypt Database

Encrypt Backups

Encrypt Sensitive Fields
```

---

## Android

Store key using:

```text
Android Keystore
```

Benefits:

* Hardware-backed security
* Non-exportable keys

---

## Web

Store key using:

```text
Web Crypto API
```

---

# 9. Authentication Security

## Login Method

```text
Google Sign-In
```

No password storage.

---

## Session Management

Uses:

```text
JWT Access Token

Refresh Token
```

---

Access Token Lifetime:

```text
15 Minutes
```

---

Refresh Token Lifetime:

```text
30 Days
```

---

# 10. JWT Security

Store securely.

Android:

```text
Encrypted Storage
```

Web:

```text
Secure Browser Storage
```

---

Never store:

```text
JWT in Plain Text Files
```

---

# 11. API Security

## Authorization

Protected endpoints require:

```http
Authorization: Bearer <token>
```

---

## Rate Limiting

Per User:

```text
100 Requests / Minute
```

---

AI Endpoints:

```text
20 Requests / Minute
```

---

# 12. Input Validation

Validate:

```text
Amount

Date

Currency

Category

File Uploads
```

---

Reject:

```text
Malformed Input

Invalid JSON

Oversized Requests
```

---

# 13. AI Privacy Controls

## Data Minimization

Never send:

```text
Full Database

Entire Chat History

Google Tokens

Encryption Keys
```

---

Send:

```text
Aggregated Data

Required Context

Relevant Memories
```

Only.

---

# 14. AI Memory Security

Store:

```text
Behavior Patterns

Preferences

Goals
```

---

Never Store:

```text
Passwords

Tokens

Secrets

Bank Credentials
```

---

User Controls:

```text
View Memory

Delete Memory

Disable Memory
```

---

# 15. Backup Encryption

Before Upload:

```text
SQLite Database
      │
      ▼
AES-256 Encryption
      │
      ▼
Google Drive
```

---

Backup File:

```text
expenso_backup_v1.enc
```

---

# 16. Sync Security

Every sync request:

```text
Authenticated

Encrypted

Audited
```

---

Sync metadata stored separately.

---

# 17. Audit Logging

Track:

```text
Login

Logout

Backup

Restore

AI Memory Changes

Sync Events

Security Events
```

---

Do NOT log:

```text
Passwords

Tokens

Encryption Keys
```

---

# 18. Device Security

Each device receives:

```text
device_id
```

Used for:

```text
Sync Tracking

Conflict Resolution

Audit Logs
```

---

# 19. Threat Model

## Threat 1

Device Theft

Mitigation:

```text
Database Encryption

Biometric Lock (Future)
```

---

## Threat 2

Network Interception

Mitigation:

```text
TLS 1.3
```

---

## Threat 3

Cloud Provider Breach

Mitigation:

```text
Encrypted Backups
```

---

## Threat 4

Prompt Injection

Mitigation:

```text
Input Sanitization

Prompt Validation
```

---

## Threat 5

Malicious Sync Data

Mitigation:

```text
Integrity Verification

Conflict Review
```

---

# 20. Security Headers

Backend must enforce:

```text
Content-Security-Policy

X-Frame-Options

X-Content-Type-Options

Strict-Transport-Security
```

---

# 21. Compliance Readiness

Designed to support:

```text
GDPR

CCPA

Indian DPDP Act
```

Future enhancements may be required.

---

# 22. Security Monitoring

Monitor:

```text
Failed Logins

API Abuse

Sync Failures

Backup Failures

AI Errors
```

---

Tools:

```text
Sentry

Structured Logs

Alerting
```

---

# 23. Incident Response

If breach detected:

1. Disable affected tokens
2. Notify users
3. Audit logs review
4. Force re-authentication
5. Rotate encryption keys if required

---

# 24. Security Testing

Perform:

```text
Static Analysis

Dependency Scanning

Penetration Testing

Encryption Validation

API Security Testing
```

Before production release.

---

# 25. Security Performance Targets

Encryption:

```text
< 100ms
```

---

Database Unlock:

```text
< 500ms
```

---

Backup Encryption:

```text
< 5 seconds
```

---

# Approval

Document:
09_SECURITY_AND_ENCRYPTION_DESIGN.md

Version:
1.0

Status:
Approved

Next Document:
10_MVP_IMPLEMENTATION_PLAN.md

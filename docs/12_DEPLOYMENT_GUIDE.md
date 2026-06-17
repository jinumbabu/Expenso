# Expenso AI

## Deployment Guide

**Version:** 1.0

---

# 1. Purpose

This document defines the deployment architecture, environments, infrastructure, monitoring, release process, rollback procedures, and operational guidelines for Expenso AI.

Goals:

* Reliable deployments
* Zero data loss
* Secure infrastructure
* Automated releases
* Production monitoring
* Disaster recovery

---

# 2. Deployment Strategy

Expenso AI uses a multi-environment deployment model.

```text id="d1"
Development
      ↓
Staging
      ↓
Production
```

Each environment is isolated.

---

# 3. Infrastructure Overview

```text id="d2"
┌─────────────────────┐
│ Flutter Android App │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Flutter Web App     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ FastAPI Backend     │
│ Docker Container    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Google Cloud Run    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Gemini API          │
└─────────────────────┘
```

---

# 4. Environment Configuration

## Development

Purpose:

```text id="d3"
Local Development
```

Components:

```text id="d4"
Flutter Local

FastAPI Local

SQLite Local
```

---

## Staging

Purpose:

```text id="d5"
Pre-production Testing
```

Components:

```text id="d6"
Flutter Web

Cloud Run

Test Gemini Keys
```

---

## Production

Purpose:

```text id="d7"
Live Users
```

Components:

```text id="d8"
Production Backend

Production API Keys

Monitoring
```

---

# 5. Flutter Deployment

## Android Deployment

Build Command:

```bash
flutter build appbundle --release
```

Output:

```text id="d9"
app-release.aab
```

---

## Play Store Release

Steps:

1. Build release bundle
2. Upload to Play Console
3. Internal Testing
4. Closed Beta
5. Production Release

---

# 6. Flutter Web Deployment

Build Command:

```bash
flutter build web --release
```

Output:

```text id="d10"
build/web/
```

---

## Hosting

Recommended:

```text id="d11"
Firebase Hosting
```

Deploy:

```bash
firebase deploy
```

---

# 7. Backend Deployment

## Docker Build

Build:

```bash
docker build -t expenso-api .
```

Run:

```bash
docker run -p 8000:8000 expenso-api
```

---

## Container Requirements

CPU:

```text id="d12"
1 vCPU Minimum
```

Memory:

```text id="d13"
1 GB Minimum
```

Recommended:

```text id="d14"
2 vCPU

2 GB RAM
```

---

# 8. Cloud Run Deployment

Deploy:

```bash
gcloud run deploy expenso-api
```

Configuration:

```text id="d15"
Autoscaling Enabled

HTTPS Only

Managed SSL
```

---

# 9. Environment Variables

Required:

```env
GOOGLE_CLIENT_ID=
JWT_SECRET=
JWT_REFRESH_SECRET=
GEMINI_API_KEY=
APP_ENV=
```

---

## Security Rule

Never commit:

```text id="d16"
.env files
```

Use:

```text id="d17"
Secret Manager
```

---

# 10. Database Deployment

## MVP

Database:

```text id="d18"
SQLite + SQLCipher
```

Stored on:

```text id="d19"
User Device
```

---

## Future

Migration:

```text id="d20"
PostgreSQL
```

For shared features.

---

# 11. Google Drive Integration

Required OAuth Scope:

```text id="d21"
drive.appdata
```

---

Store:

```text id="d22"
Encrypted Backups Only
```

---

Never Store:

```text id="d23"
Tokens

Keys

Secrets
```

---

# 12. Monitoring

## Error Monitoring

Tool:

```text id="d24"
Sentry
```

Track:

```text id="d25"
Crashes

Exceptions

Performance Issues
```

---

## Application Logs

Use:

```text id="d26"
Structured JSON Logs
```

Example:

```json
{
  "event":"backup_created",
  "user":"uuid"
}
```

---

# 13. Health Checks

Endpoint:

```http
GET /health
```

Response:

```json
{
  "status":"healthy"
}
```

---

Cloud Run checks every:

```text id="d27"
30 Seconds
```

---

# 14. CI/CD Pipeline

## GitHub Actions

Pipeline:

```text id="d28"
Lint
  ↓
Unit Tests
  ↓
Integration Tests
  ↓
Build
  ↓
Deploy
```

---

## Flutter Pipeline

Run:

```text id="d29"
Analyze

Format Check

Unit Tests

Build
```

---

## Backend Pipeline

Run:

```text id="d30"
Pytest

Security Scan

Docker Build
```

---

# 15. Release Process

## Versioning

Format:

```text id="d31"
MAJOR.MINOR.PATCH
```

Examples:

```text id="d32"
1.0.0

1.1.0

1.1.1
```

---

## Release Flow

```text id="d33"
Feature Branch
      ↓
Pull Request
      ↓
Code Review
      ↓
Merge
      ↓
Deploy Staging
      ↓
QA Approval
      ↓
Production Release
```

---

# 16. Rollback Strategy

If release fails:

```text id="d34"
Rollback Previous Container
```

Cloud Run:

```bash
gcloud run services update-traffic
```

---

Rollback Conditions:

```text id="d35"
Critical Bugs

Data Corruption

Authentication Failure
```

---

# 17. Backup Strategy

## User Data

Protected by:

```text id="d36"
Google Drive Backup
```

---

## Backend Config

Backup:

```text id="d37"
Environment Config

Secrets

Deployment Files
```

---

# 18. Disaster Recovery

## Scenario 1

Cloud Run Failure

Action:

```text id="d38"
Redeploy Container
```

---

## Scenario 2

Gemini API Failure

Action:

```text id="d39"
Fallback to Rule Engine
```

---

## Scenario 3

User Device Lost

Action:

```text id="d40"
Restore From Drive Backup
```

---

# 19. Security Checklist

Before Production:

```text id="d41"
HTTPS Enabled

Secrets Configured

SQLCipher Enabled

JWT Rotation Enabled

Rate Limiting Enabled

Sentry Enabled
```

All required.

---

# 20. Performance Targets

API Response:

```text id="d42"
< 500ms
```

---

Expense Parsing:

```text id="d43"
< 2 Seconds
```

---

AI Chat:

```text id="d44"
< 3 Seconds
```

---

Backup:

```text id="d45"
< 10 Seconds
```

---

# 21. Launch Checklist

## Functional

```text id="d46"
Login Works

Expense Tracking Works

Budgets Work

AI Works

Backup Works
```

---

## Security

```text id="d47"
Encryption Verified

Audit Logs Verified

Token Security Verified
```

---

## Testing

```text id="d48"
Unit Tests Pass

Integration Tests Pass

Manual QA Pass
```

---

## Production

```text id="d49"
Cloud Run Deployed

Play Store Uploaded

Monitoring Active
```

---

# 22. Post-Launch Operations

Monitor:

```text id="d50"
Crash Rate

AI Cost

Backup Success

API Usage

User Feedback
```

---

Review Weekly:

```text id="d51"
Errors

Performance

Feature Requests
```

---

# Approval

Document:
12_DEPLOYMENT_GUIDE.md

Version:
1.0

Status:
Approved

Project:
Expenso AI

Documentation Package:
COMPLETE

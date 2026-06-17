# Expenso AI

## Google Drive Sync & Backup Design

**Version:** 1.0

---

# 1. Purpose

This document defines the backup, synchronization, recovery, and conflict resolution architecture for Expenso AI.

Goals:

* User owns their data
* No mandatory central database
* Encrypted backups
* Multi-device support
* Offline-first operation
* Disaster recovery

---

# 2. Design Principles

## User-Owned Storage

All backups stored in:

```text id="1f3u7k"
Google Drive App Data Folder
```

Not accessible to other apps.

---

## Offline First

Application works without internet.

---

## Encryption First

All backups encrypted before upload.

---

## Conflict Safe

Never silently overwrite financial data.

---

# 3. Architecture Overview

```text id="0dj6gs"
Flutter App
     │
     ▼
SQLite Database
     │
     ▼
Sync Queue
     │
     ▼
Encryption Layer
     │
     ▼
Google Drive API
     │
     ▼
Google Drive App Folder
```

---

# 4. Backup Types

## Manual Backup (MVP)

User presses:

```text id="2m1rji"
Backup Now
```

System:

```text id="5kl2tt"
Export Database
Encrypt
Upload
Verify
```

---

## Automatic Backup (Future)

Triggers:

```text id="8zgn2w"
Daily

Weekly

Monthly
```

User configurable.

---

# 5. Backup Content

## Included

```text id="ikc48o"
SQLite Database

AI Memory

Settings

Categories

Budgets

Goals

Chat History

Sync Metadata
```

---

## Excluded

```text id="z2tl3j"
JWT Tokens

Google Tokens

Encryption Keys
```

---

# 6. Backup File Structure

File Name:

```text id="h7k4vq"
expenso_backup_v1.enc
```

Encrypted File Format:

```text id="k4uj7y"
AES-256
```

Contents:

```json id="v3w4y8"
{
  "database": "...",
  "metadata": "...",
  "version": "1.0"
}
```

---

# 7. Google Drive Integration

## Storage Location

```text id="8k14k6"
Drive AppDataFolder
```

Benefits:

* Hidden from user
* App-specific
* Secure
* No clutter

---

## Authentication

Uses:

```text id="44cti6"
Google Sign-In
```

Required Scope:

```text id="1bd5wy"
drive.appdata
```

---

# 8. Backup Flow

```text id="zqqxg6"
User
 │
 ▼
Backup Request
 │
 ▼
Export Database
 │
 ▼
Compress
 │
 ▼
Encrypt
 │
 ▼
Upload
 │
 ▼
Verify Upload
 │
 ▼
Success
```

---

# 9. Restore Flow

```text id="8ew5ut"
User
 │
 ▼
Restore Request
 │
 ▼
Download Backup
 │
 ▼
Verify Integrity
 │
 ▼
Decrypt
 │
 ▼
Replace Database
 │
 ▼
Restart Application
```

---

# 10. Sync Architecture

## Goal

Keep multiple devices synchronized.

Example:

```text id="j07g8w"
Android Phone

Web Browser

Tablet
```

---

## Sync Strategy

```text id="qzv8fv"
Delta Sync
```

Only changes are transferred.

---

# 11. Sync Queue

Every change enters queue.

Example:

```json id="prnqmo"
{
  "table": "transactions",
  "record_id": "uuid",
  "operation": "update"
}
```

---

Queue States:

```text id="vxxmce"
pending

uploading

synced

conflict

failed
```

---

# 12. Sync Operations

Supported:

```text id="mjlwmf"
Create

Update

Delete
```

---

Example:

```text id="eiy6v7"
Transaction Added
```

↓

```text id="y8vsyv"
Queue Created
```

↓

```text id="s0l8jc"
Upload
```

↓

```text id="6lsrrr"
Synced
```

---

# 13. Conflict Resolution

## Problem

Same transaction edited on two devices.

---

Example

Phone A:

```text id="j27eji"
Food Expense = ₹500
```

Phone B:

```text id="5brlrx"
Food Expense = ₹700
```

---

## Solution

Create conflict record.

User sees:

```text id="9bbvdk"
Conflict Detected

Version A
Version B
```

Options:

```text id="hm1pfz"
Use A

Use B

Merge
```

---

# 14. Conflict Types

### Type 1

Concurrent Update

---

### Type 2

Duplicate Transaction

---

### Type 3

Delete vs Update

---

### Type 4

Category Changes

---

# 15. Sync Metadata

Stored in:

```text id="u40s7c"
sync_metadata
```

Tracks:

```text id="d6xf9v"
Record ID

Table

Operation

Timestamp

Device ID

Sync Status
```

---

# 16. Device Management

Each device gets:

```text id="r2sh26"
device_id
```

Example:

```text id="1udmb8"
android-phone

web-browser

tablet
```

---

# 17. Encryption Architecture

## Before Upload

Database:

```text id="2f77wl"
SQLite
```

↓

```text id="nqajw6"
Compressed
```

↓

```text id="7a2cwv"
AES-256 Encryption
```

↓

```text id="8i1z8n"
Google Drive
```

---

# 18. Integrity Verification

Generate:

```text id="sqcm91"
SHA-256 Hash
```

Store:

```text id="vcdx4x"
Backup Metadata
```

---

Verify during restore.

---

# 19. Backup Retention

## MVP

Keep:

```text id="wvf95o"
Latest Backup Only
```

---

## Future

Keep:

```text id="pfd9h2"
Last 7 Backups
```

---

# 20. Recovery Scenarios

## Phone Lost

Flow:

```text id="y0k4t9"
Install App

Login

Restore Backup
```

---

## App Reinstall

Flow:

```text id="db5wpn"
Install

Login

Restore
```

---

## New Device

Flow:

```text id="lmbwrw"
Install

Login

Download Backup

Sync
```

---

# 21. Failure Handling

## Upload Failure

Retry:

```text id="v4qot3"
3 Times
```

---

## Network Failure

Move to:

```text id="z4g0ql"
Pending Queue
```

---

## Corrupted Backup

Reject restore.

Show:

```text id="x8u4yh"
Backup Integrity Failed
```

---

# 22. Backup Status Screen

Display:

```text id="9qk5zn"
Last Backup Date

Backup Size

Sync Status

Pending Changes
```

---

# 23. User Controls

Allow:

```text id="3ujv1y"
Backup Now

Restore

Delete Backup

Export Backup

Disable Backup
```

---

# 24. Privacy Considerations

Never Upload:

```text id="ej2kw8"
Google Access Tokens

Encryption Keys

Device Secrets
```

---

Only Upload:

```text id="3qkh9j"
Encrypted Data
```

---

# 25. Performance Targets

Backup Creation:

```text id="r6shv4"
< 10 seconds
```

---

Restore:

```text id="86bnp7"
< 30 seconds
```

---

Sync Operation:

```text id="ggh7jp"
< 5 seconds
```

---

# 26. Future Enhancements

Version 2:

```text id="2p40ot"
Automatic Backup
```

---

Version 3:

```text id="l0g9zk"
Real-Time Sync
```

---

Version 4:

```text id="s8kquu"
End-to-End Multi-Device Sync
```

---

# Approval

Document:
08_GOOGLE_DRIVE_SYNC_DESIGN.md

Version:
1.0

Status:
Approved

Next Document:
09_SECURITY_AND_ENCRYPTION_DESIGN.md

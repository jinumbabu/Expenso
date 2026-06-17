# Expenso AI

## Flutter Project Structure

**Version:** 1.0

---

# 1. Purpose

This document defines the Flutter application architecture, folder structure, coding standards, state management approach, dependency injection strategy, and development guidelines.

The goal is to ensure:

* Scalability
* Maintainability
* Testability
* Clean Architecture compliance
* Easy onboarding of future developers

---

# 2. Technology Stack

## Framework

```text
Flutter 3.x
```

## Language

```text
Dart 3.x
```

## State Management

```text
Riverpod
```

## Routing

```text
Go Router
```

## Local Database

```text
Drift ORM
SQLite
SQLCipher
```

## Networking

```text
Dio
```

## Dependency Injection

```text
Riverpod Providers
```

---

# 3. Project Structure

```text
app/

├── lib/
│
├── core/
│
├── shared/
│
├── features/
│
├── config/
│
├── routes/
│
├── bootstrap/
│
├── main.dart
│
└── app.dart
```

---

# 4. Core Layer

Contains reusable infrastructure.

```text
core/

├── database/
├── network/
├── security/
├── storage/
├── ai/
├── sync/
├── constants/
├── exceptions/
├── utils/
└── widgets/
```

---

## database/

```text
database/

├── app_database.dart
├── migrations/
├── tables/
└── dao/
```

Responsibilities:

* Drift configuration
* SQLCipher integration
* Database migrations

---

## network/

```text
network/

├── dio_client.dart
├── api_interceptor.dart
├── auth_interceptor.dart
└── network_info.dart
```

Responsibilities:

* API communication
* Token handling
* Retry logic

---

## security/

```text
security/

├── encryption_service.dart
├── keystore_service.dart
└── jwt_service.dart
```

Responsibilities:

* AES encryption
* Key management
* JWT handling

---

## ai/

```text
ai/

├── ai_service.dart
├── prompt_templates.dart
├── parser_service.dart
└── insight_service.dart
```

Responsibilities:

* AI requests
* NLP parsing
* Prompt generation

---

## sync/

```text
sync/

├── sync_service.dart
├── backup_service.dart
├── conflict_resolver.dart
└── queue_manager.dart
```

Responsibilities:

* Google Drive sync
* Offline queue
* Conflict handling

---

# 5. Shared Layer

Reusable UI and models.

```text
shared/

├── models/
├── widgets/
├── themes/
├── extensions/
└── enums/
```

---

# 6. Feature Modules

Each feature follows Clean Architecture.

```text
features/

├── auth/
├── dashboard/
├── expenses/
├── budgets/
├── goals/
├── chat/
├── ai_memory/
├── backup/
├── settings/
└── reports/
```

---

# 7. Feature Structure

Example:

```text
features/expenses/

├── data/
├── domain/
├── presentation/
└── providers/
```

---

## data/

Contains:

```text
data/

├── datasources/
├── repositories/
├── models/
└── mappers/
```

---

## domain/

Contains:

```text
domain/

├── entities/
├── repositories/
└── usecases/
```

---

## presentation/

Contains:

```text
presentation/

├── screens/
├── widgets/
├── dialogs/
└── state/
```

---

## providers/

Contains:

```text
providers/

expense_provider.dart
expense_notifier.dart
```

---

# 8. Feature Example

Expense Module

```text
expenses/

├── data/
│   ├── repositories/
│   └── datasources/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
├── presentation/
│   ├── screens/
│   └── widgets/
│
└── providers/
```

---

# 9. Routing Structure

```text
routes/

├── app_router.dart
├── auth_routes.dart
└── protected_routes.dart
```

---

## Main Routes

```text
/
 /login
 /dashboard
 /chat
 /expenses
 /budgets
 /goals
 /settings
 /backup
```

---

# 10. State Management

Use Riverpod only.

---

## Provider Types

### FutureProvider

```dart
FutureProvider<User>
```

Use for:

* API loading
* Database loading

---

### StateNotifierProvider

```dart
StateNotifierProvider
```

Use for:

* Expenses
* Budgets
* Goals

---

### StreamProvider

```dart
StreamProvider
```

Use for:

* Live sync status
* Real-time updates

---

# 11. Repository Pattern

UI never accesses:

```text
Database
API
AI Services
```

directly.

Flow:

```text
UI
 │
 ▼
Use Case
 │
 ▼
Repository
 │
 ▼
Datasource
```

---

# 12. Dependency Injection

All dependencies managed by Riverpod.

Example:

```dart
final expenseRepositoryProvider =
Provider<ExpenseRepository>(
  (ref) => ExpenseRepositoryImpl()
);
```

---

# 13. Error Handling

Create centralized exceptions.

```text
exceptions/

├── api_exception.dart
├── auth_exception.dart
├── database_exception.dart
├── ai_exception.dart
└── sync_exception.dart
```

---

# 14. Theme Structure

```text
themes/

├── app_theme.dart
├── light_theme.dart
└── dark_theme.dart
```

Support:

```text
Light Mode
Dark Mode
System Mode
```

---

# 15. Localization

Prepare structure.

```text
l10n/

├── app_en.arb
├── app_hi.arb
└── app_ta.arb
```

Future support:

* English
* Hindi
* Tamil

---

# 16. Assets Structure

```text
assets/

├── icons/
├── images/
├── animations/
└── fonts/
```

---

# 17. Testing Structure

```text
test/

├── unit/
├── widget/
├── integration/
└── mocks/
```

---

# 18. Naming Conventions

## Files

```text
snake_case.dart
```

Example:

```text
expense_repository.dart
```

---

## Classes

```dart
ExpenseRepository
```

PascalCase

---

## Variables

```dart
expenseAmount
```

camelCase

---

# 19. Code Standards

Maximum responsibilities:

* One feature = one module
* One use case = one business action
* One repository = one domain

Avoid:

```text
God Classes
Large Widgets
Business Logic in UI
```

---

# 20. MVP Feature Order

### Sprint 1

```text
Auth
Database
Routing
Theme
```

### Sprint 2

```text
Expenses
Categories
Dashboard
```

### Sprint 3

```text
Budgets
Goals
Reports
```

### Sprint 4

```text
NLP Parsing
AI Chat
```

### Sprint 5

```text
Backup
Sync
```

### Sprint 6

```text
Financial Advisor
Insights
```

---

# Approval

Document:
05_FLUTTER_PROJECT_STRUCTURE.md

Version:
1.0

Status:
Approved

Next Document:
06_SQL_SCHEMA_AND_MIGRATIONS.md

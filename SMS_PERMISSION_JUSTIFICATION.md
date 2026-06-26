# Google Play Store Compliance - SMS Permission Justification

**Application Name:** Expenso AI
**Package Name:** `com.expenso.ai.app`
**Requested Permission:** `android.permission.READ_SMS`

---

## 1. Core Feature & Justification
Expenso AI utilizes the `READ_SMS` permission to implement **automatic transaction tracking and financial logging**. 

When a user receives a transaction alert SMS from their bank, credit card issuer, or payment processor (e.g. UPI, NetBanking alerts), the app reads the SMS text and automatically parses the merchant, amount, category, and payment method details in the background.

This feature is **vital** to the core utility of Expenso because:
- It eliminates the need for manual receipt logging or typing for every daily transaction.
- It ensures real-time updates of budgets and expense tracking without user intervention.
- It feeds the local forecasting and budget warning engine with prompt, accurate cash-flow inputs.

---

## 2. Play Store Policy Compliance
Per Google Play Console SMS/Call Log permissions policies:
- **Core Functionality**: Automatic transaction tracking is a core advertised feature. The app cannot deliver this automation without accessing SMS messages containing banking transaction alerts.
- **Data Privacy & Local Processing**: All SMS parsing is performed locally on-device. Expenso never uploads raw SMS texts, personal conversations, or contact numbers to any remote server.
- **User Control**: The permission is requested dynamically at runtime. The user has full control to grant or deny this permission. If denied, the app gracefully falls back to manual entry and OCR receipt scanning.

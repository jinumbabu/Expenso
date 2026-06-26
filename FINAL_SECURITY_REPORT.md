# FINAL SECURITY REPORT

## 1. Data Encryption at Rest (SQLCipher)
- **Status**: VERIFIED
- **Mechanism**: The local SQLite database is encrypted using SQLCipher with a 256-bit key.
- **Key Storage**: The database key is randomly generated at first startup and saved securely using `flutter_secure_storage` (backed by Android Keystore / iOS Keychain).

## 2. Authentication & JWT Management
- **Status**: VERIFIED
- **Mechanism**: OAuth2 Google Sign-In is used for authentication. Tokens returned from Google are sent to the FastAPI backend which returns JWT tokens.
- **JWT Storage**: JWT access and refresh tokens are stored in secure storage.
- **HTTP Transport**: Tokens are injected automatically using `AuthInterceptor` only for requests directed at the safe Expenso API domain.

## 3. Firestore Rules Compliance
- **Status**: VERIFIED
- **File**: [firestore.rules](file:///c:/Users/jinum/Expenso/firestore.rules)
- **Logic**: Matches `/users/{userId}/{document=**}` and allows read/write only if `request.auth.uid == userId`. This ensures complete data separation between users.

## 4. API Key Safety
- **Status**: VERIFIED
- **Mechanism**: No Google Cloud, Firebase, or Gemini API keys are hardcoded in the Flutter source code. All backend secrets are fetched from environment variables.

## 5. AI Prompt Injection Defenses
- **Status**: VERIFIED
- **Mechanism**: The FastAPI backend checks all incoming text prompts against known injection regex patterns (`ignore previous instructions`, `system prompt`, `you are now a`, etc.) inside `/ai/chat` and `/ai/parse-expense` routes. Matches are instantly rejected with HTTP 400.

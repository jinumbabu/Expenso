# Expenso AI

## AI Engine Specification

**Version:** 1.0

---

# 1. Purpose

This document defines the complete AI architecture for Expenso AI.

The AI engine is responsible for:

* Natural Language Expense Parsing
* Transaction Categorization
* AI Memory
* Conversational Financial Assistant
* Budget Recommendations
* Spending Analysis
* Financial Health Scoring
* Forecasting
* Personalized Insights

The AI system must remain:

* Privacy-first
* Cost-efficient
* Explainable
* Reliable
* Extensible

---

# 2. AI Architecture Overview

```text
User Input
    │
    ▼
AI Orchestrator
    │
 ┌──┴───────────────┐
 │                  │
 ▼                  ▼
Rule Engine     Gemini AI
 │                  │
 └──────┬───────────┘
        ▼
 Transaction Model
        │
        ▼
 AI Memory
        │
        ▼
 Financial Insights
```

---

# 3. AI Components

## Component 1

Expense Parser

Purpose:

Convert natural language into structured transaction data.

---

## Component 2

Categorization Engine

Purpose:

Automatically classify expenses.

---

## Component 3

AI Memory System

Purpose:

Remember user preferences and spending patterns.

---

## Component 4

Financial Advisor

Purpose:

Provide recommendations and financial guidance.

---

## Component 5

Forecasting Engine

Purpose:

Predict future spending.

---

## Component 6

Insight Engine

Purpose:

Generate actionable recommendations.

---

# 4. Expense Parser

## Input

Examples:

```text
Spent ₹250 on tea

Fuel 1500

Paid electricity bill 1200

Received salary 35000

Amazon order 2500
```

---

## Output

```json
{
  "type": "expense",
  "amount": 250,
  "category": "Food",
  "merchant": "Tea",
  "payment_method": null,
  "date": "today",
  "confidence": 0.95
}
```

---

# 5. Parsing Pipeline

```text
Raw Text
    │
    ▼
Preprocessing
    │
    ▼
Rule Engine
    │
    ▼
Confidence Check
    │
 ┌──┴────────┐
 │           │
 ▼           ▼
Accept      Gemini
 │           │
 └────┬──────┘
      ▼
Structured Transaction
```

---

## Preprocessing

Tasks:

* Remove extra spaces
* Normalize currency symbols
* Normalize dates
* Convert text to lowercase

Example:

```text
Spent ₹250 On Tea
```

↓

```text
spent 250 on tea
```

---

# 6. Rule-Based Categorization Engine

## Purpose

Provide:

* Fast classification
* Offline support
* AI fallback

---

## Category Rules

Food

Keywords:

```text
tea
coffee
restaurant
food
snacks
lunch
dinner
```

---

Fuel

Keywords:

```text
fuel
petrol
diesel
gas
```

---

Utilities

Keywords:

```text
electricity
water
internet
wifi
bill
```

---

Shopping

Keywords:

```text
amazon
flipkart
shopping
order
```

---

# 7. Confidence Scoring

Rule Engine:

```text
0.70 - 1.00
```

High confidence:

Save automatically.

---

Low confidence:

```text
< 0.70
```

Send to Gemini.

---

# 8. Gemini Integration

## Responsibilities

* Expense parsing
* Complex categorization
* Financial reasoning
* Recommendations

---

## API Request

```json
{
  "task": "expense_parsing",
  "input": "Paid SBI credit card bill 2500"
}
```

---

## Response

```json
{
  "amount": 2500,
  "category": "Credit Card Payment",
  "confidence": 0.96
}
```

---

# 9. AI Memory Architecture

## Goal

Remember useful information.

Not personal secrets.

---

## Memory Types

### Preference Memory

Examples:

```text
Preferred Currency

Budget Preferences

Theme Preference
```

---

### Behavioral Memory

Examples:

```text
Frequent Merchant

Salary Date

Monthly Food Budget
```

---

### Conversational Memory

Examples:

```text
Recent Advice

Recent Financial Questions
```

---

# 10. Memory Storage Format

```json
{
  "memory_type": "behavioral",
  "key": "salary_date",
  "value": "1st",
  "confidence": 0.98
}
```

---

# 11. Memory Retention

Default:

```text
180 Days
```

User configurable.

---

User Controls:

* View Memory
* Delete Memory
* Disable Memory

---

# 12. Financial Advisor Engine

## Responsibilities

Analyze:

* Spending
* Income
* Budgets
* Goals

Provide recommendations.

---

## Example

User:

```text
Can I buy a ₹20,000 phone?
```

System evaluates:

```text
Income

Expenses

Savings

Goals

Upcoming Bills
```

---

Output:

```text
Based on your current spending,
waiting 2 weeks would improve
your savings position.
```

---

# 13. Financial Health Score

## Purpose

Provide a simple financial status indicator.

---

## Formula

Score Range:

```text
0 - 100
```

---

## Factors

Savings Rate

```text
30%
```

Budget Compliance

```text
25%
```

Expense Stability

```text
20%
```

Goal Progress

```text
15%
```

Income Consistency

```text
10%
```

---

## Example

```text
Financial Health Score

82 / 100

Status: Healthy
```

---

# 14. Spending Analysis Engine

Detect:

## Overspending

Example:

```text
Food spending increased
35% this month.
```

---

## Category Spikes

Example:

```text
Shopping spending doubled
compared to last month.
```

---

## Recurring Cost Growth

Example:

```text
Subscription costs increased
₹300 this month.
```

---

# 15. Budget Recommendation Engine

Input:

```text
Income
Expenses
Goals
```

---

Output:

```text
Monthly Income: ₹30,000

Needs: ₹15,000

Wants: ₹9,000

Savings: ₹6,000
```

---

# 16. Forecasting Engine

## Goal

Predict future expenses.

---

## Version 1

Simple trend analysis.

---

Example:

```text
Expected Month-End Spend

₹18,500
```

---

## Version 2

Prophet Model

---

## Version 3

ML Forecasting

---

# 17. Insight Engine

Generate recommendations.

---

Examples

```text
Reduce restaurant visits
to save ₹1,500 monthly.
```

---

```text
Fuel spending increased
18% this month.
```

---

```text
Emergency fund target
can be reached in 7 months.
```

---

# 18. AI Chat Assistant

## Supported Queries

Expense Queries

Example:

```text
How much did I spend on food?
```

---

Budget Queries

Example:

```text
What is my budget status?
```

---

Affordability Queries

Example:

```text
Can I buy a bike?
```

---

Goal Queries

Example:

```text
How close am I to my savings goal?
```

---

# 19. Prompt Templates

## Expense Parsing Prompt

```text
Extract:

Amount
Category
Merchant
Payment Method
Date

Return JSON only.
```

---

## Financial Advisor Prompt

```text
Analyze spending patterns.

Provide concise advice.

Focus on actionable recommendations.

Avoid generic responses.
```

---

## Insight Prompt

```text
Generate one useful insight.

Keep under 50 words.

Prioritize savings opportunities.
```

---

# 20. AI Cost Control

## Daily Quotas

Per User:

```text
100 AI requests/day
```

---

## Fallback

If quota exceeded:

```text
Rule Engine
```

---

## Cache Responses

Store:

```text
Recent Queries

Recent Insights
```

Reduce API costs.

---

# 21. Privacy Rules

Never send:

```text
Full Database

Entire Transaction History

Google Tokens

Encryption Keys
```

---

Send only:

```text
Aggregated Data

Required Context

Relevant Memory
```

---

# 22. Future Local AI

Version 2:

```text
Ollama
```

Supported Models:

```text
Llama 3

Mistral

Gemma
```

---

## Local AI Responsibilities

Expense Parsing

Categorization

Insights

Chat Assistant

---

# 23. AI Performance Targets

Expense Parsing:

```text
< 2 seconds
```

---

Chat Response:

```text
< 3 seconds
```

---

Insight Generation:

```text
< 5 seconds
```

---

Forecast Generation:

```text
< 10 seconds
```

---

# Approval

Document:
07_AI_ENGINE_SPECIFICATION.md

Version:
1.0

Status:
Approved

Next Document:
08_GOOGLE_DRIVE_SYNC_DESIGN.md

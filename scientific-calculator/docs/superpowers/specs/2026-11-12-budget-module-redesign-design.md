# Budget Module Redesign Design (2026-11-12)

This document outlines the design specifications for the budget module redesign.

## Companion Mockups

The paper mockup for this redesign can be found at:

`docs/superpowers/mockups/budget-module-paper-mockups.html`

<!-- End of document -->
# Budget Module Redesign – Specification (2026‑11‑12)

## 1. Locked Available Formula
**Available** is now defined as *real free money* and is **locked** (no longer an A/B choice).

```
Available = Income − Already spent − Upcoming
```

- **Income** – This month’s income (sum of month‑income `BudgetEntrys`; if none, use `MonthlyPlan.takeHomeMonthly`).
- **Already spent** – Actual expense `BudgetEntrys` recorded for this month.
- **Upcoming** – Remaining scheduled / recurring commitments for this month (fixed/recurring plan lines not yet covered by actuals, including remaining weekly series).

**Display rules**
- Show the signed value; negative values indicate overspend.
- Clamp progress‑bar / percentage calculations to 0 % – 100 % to avoid UI breakage, but keep the signed number visible.

## 2. Architecture C – Cons
- Updated line: “Must define how Available mixes…” → **Available formula is now locked** (see section 1).

## 3. Screen A – Overview
### Hero
- Prominently display **Available** (large font) with three sub‑metrics:
  - **Income**
  - **Already spent** (label “Spent” or “Already spent”)
  - **Upcoming**
- Thin progress bar = `(Already spent + Upcoming) ÷ Income`.
- Show a caption such as “**61 % of income committed**” (example numbers below).

### Data Mapping Table
| Metric      | Definition |
|------------|------------|
| **Income** | Sum of month‑income `BudgetEntrys` or `MonthlyPlan.takeHomeMonthly` if none. |
| **Already spent** | Actual expense `BudgetEntrys` for the current month. |
| **Upcoming** | Remaining scheduled / recurring commitments not yet realized (includes weekly series). |
| **Available** | `Income − Already spent − Upcoming` (locked formula). |

- Removed “See Open question 1” reference.
- Updated “Spent” wording to **Already spent** for clarity.

## 4. Open Questions
1. **Planning widgets** – still open (renumbered as the sole open question).
- All other questions about the Available formula have been removed.

## 5. Self‑Review
- **Available** is locked; only the planning‑widget question remains.
- Flutter implementation can proceed once the planning‑widget question is resolved; no further changes to Available are expected.

## 6. Cleanup of Legacy Mentions
- Replaced any “A/B Available options”, “recommended default sketch for Available”, or similar phrasing with the locked formula description above.


# Financial Calculator — Slice 1 Design

Date: 2026-09-18

A new standalone Flutter app in a new repository at `C:\Users\franc\Projects\financial-calculator`. It reuses the scientific calculator’s visual system, widgets, settings, and money math. It does not depend on that project at runtime.

This is slice 1 of the full premium offline financial calculator blueprint. Later slices add investments, NPV/IRR, retirement, business, formula library, scenarios, charts, voice, camera, RPN, and bonds. Those destinations are **not** shown until they work. No placeholder screens. No dead buttons.

## Product

**Name:** Financial Calculator  
**Package:** `financial_calculator`  
**Platforms:** Android, iOS, web (web for development)  
**Model:** Local-first, offline, no account, no ads, no cloud.

The app is a calculator. It is not a bank, advisor, tax filer, or brokerage. Every result includes the line: **This is a calculation, not financial advice.**

## Navigation

Bottom destinations, all real:

| Dest | Job |
|------|-----|
| Tools | Chooser: Loan payment, Compound interest, Savings |
| Calculator | Professional TVM (N, I/Y, PV, PMT, FV) |
| History | Past `FinanceResult`s; tap restores the tool and inputs |
| Settings | Layout, type, language, haptics/sound, vision, payment-timing default, privacy |

No Formula Library or Scenarios tab in slice 1.

## Tools

### Loan payment

Inputs: loan amount, yearly percent, number of months.  
Main result: monthly payment.  
Supporting: total repaid, total interest.  
Schedule: amortization rows (period, payment, interest, principal, balance). Last row absorbs rounding so the final balance is 0.

Assumptions shown: payments at period end, 12 payments per year (unless the user later changes timing in Settings for TVM; loan tool stays monthly end-of-period in slice 1).

### Compound interest

Inputs: starting amount, yearly percent, years, times it grows each year.  
Main result: future value.  
Supporting: interest earned.

### Savings

Inputs: starting amount, amount added each month, yearly percent, months.  
Main result: future value.  
Supporting: total added, growth.

### TVM (Calculator tab)

Registers: N, I/Y, PV, PMT, FV. Enter any four, solve the fifth.

- **I/Y** is the nominal annual rate in percent.
- **P/Y** is payments per year (default 12). Periodic rate = `(I/Y) / P/Y`.
- **N** is the number of payments (not years).
- **BEGIN / END** maps to annuity due (`type = 1`) vs ordinary (`type = 0`).
- Cash-sign convention (visible assumption): money paid out is negative, money received is positive.

The existing `TvmSolver` stays per-period. A wrapper converts I/Y + P/Y into the periodic percent the solver already understands.

## Shared result model

Every successful calculation produces a `FinanceResult`:

```dart
class FinanceResult {
  final String toolId;           // loan.payment | compound.interest | savings.future | tvm.solve.{n,iy,pv,pmt,fv}
  final String title;            // "Loan payment"
  final String headline;         // "Monthly payment 88.85"
  final double primaryValue;
  final String primaryLabel;
  final List<LabeledValue> inputs;
  final List<LabeledValue> outputs;
  final List<String> assumptions;
  final List<String> warnings;
  final Explanation explanation;
  final List<AmortizationRow>? schedule;
  final DateTime computedAt;
}
```

Visual UI, spoken output, and History all render this object. They do not recompute.

Errors: invalid domain (months ≤ 0, compounding frequency ≤ 0, TVM with no solution) shows a plain actionable message on the form. The previous result is kept until a valid run replaces it.

## Architecture

```
Input (fields) → workflow → math engine → FinanceResult
    → result card / spoken / History (JSON in shared_preferences)
```

Voice and camera in later slices must emit the same workflow inputs. They never call the engine directly.

### New repo layout

```
lib/
  main.dart
  app.dart
  core/                 # explanation, numeric_input, formatting
  theme/                # copied tokens (AppMetrics, AppTheme, ColorStory, …)
  widgets/              # ChooserTile, NumericField, StepsPanel, AdaptivePhoneShell
  domain/
    finance_result.dart
    labeled_value.dart
  finance/
    money_math.dart     # port
    tvm_solver.dart     # port
    tvm_registers.dart  # P/Y wrapper + solve-for
    amortization.dart
    finance_explainers.dart
  data/
    history_store.dart
  features/
    tools/              # chooser + loan / compound / savings forms
    tvm/
    history/
    settings/
  l10n/
  services/             # settings, haptics
```

Ported from `scientific-calculator` (adapt package name, drop scientific-only settings): theme, fonts, `ChooserTile`, `NumericField`, `StepsPanel`, `AdaptivePhoneShell`, `Explanation`, `NumericInput`, `TvmSolver`, `MoneyMath`, settings/look pickers, language catalog, haptics.

Do not port graphing, matrix, geometry, CAS, convert, or the TI-style scientific keypad.

## Screens

**Tools home.** Prompt: “What do you want to know?” Chooser tiles (title + subtitle). Same pattern as the current scientific Finance picker.

**Tool form.** Back to all tools, title, `NumericField`s, Calculate. After success: result card (below).

**Result card** (primary object):

1. Main figure (`titleMedium` w600)
2. Assumptions caption (`bodySmall`)
3. Supporting figures
4. Disclaimer
5. **How this was worked out** (`StepsPanel`)
6. Loan: amortization table in an expandable panel (240ms `easeInOutCubic`)

A successful Calculate **auto-saves** to History. No extra Save button in slice 1.

**TVM.** Five register rows with a Solve control on each. P/Y and BEGIN/END with the assumptions. Number fields, not a scientific pad. Tap **PV**, **PMT**, or any other register name to toggle the full words (Present value, Payment, …). Screen readers always hear the full name.

**History.** Newest first. Empty state: “No calculations yet.” Row: title, headline, date. Tap restores. Meaningful semantics, not “list item 3”.

**Settings.** Layout, look (color story + type), type size, language, haptics/sound, vision profile, default payment timing (END/BEGIN), in-app privacy: data stays on this device; no account; microphone/camera only when those features exist (they do not in slice 1).

## Visual system

`product-visual-craft` rules. Tokens from `AppMetrics` / `AppMotion`. Cards: 16 pad, 16 radius, hairline **or** tint, elevation 0. Type from `Theme.textTheme`. Icons 24 in a square, 8px to text. Motion 200–280ms, `easeOutCubic` / `easeInOutCubic`. No Material default `ExpansionTile` chrome.

## Accessibility (structural)

- Every control has a meaningful label (not the glyph alone).
- Tap targets ≥ 48 dp (56 in accessible layout).
- Results use `liveRegion`. Announce headline + spoken explanation.
- Walkthroughs: paragraph, then equation; join beats with “ Then ”. Never “Step N”.
- Color is never the only signal.
- Number fields reject letters (`NumericInput`) so a screen-reader user cannot type a word and get a silent zero.
- Focus does not jump away while typing.
- Dynamic type via settings text scale.
- Reduced motion: respect `MediaQuery.disableAnimations` (skip expand animation, still expand).

## Copy

Adult English. Professional names (PV, PMT) sit beside plain labels (“What you pay each period”). No kid-talk, no CAS jargon, no “Step 1”.

## Testing

- Port `tvm_solver_test` and `money_math_test`.
- New: amortization (known 12-month 12% loan; final balance 0).
- New: TVM P/Y wrapper (12% annual, P/Y 12 → 1% per period).
- New: `FinanceResult` JSON round-trip.
- Widget tests through the real UI: loan, compound, savings, TVM solve-PMT, history restore.
- Keep widget `Key`s: `tool-loan`, `tool-compound`, `tool-savings`, `finance-principal`, `finance-rate`, `finance-result`, `how-we-got-this`, `tvm-solve-pmt`, `history-list`.

## Out of scope (later slices)

NPV/IRR, CAGR/ROI, retirement, business, real estate, taxes, bonds, formula library, scenario comparison, charts, voice/camera input, RPN, cloud, tax jurisdictions, personalized advice, social sharing.

## Success

A person can compute a loan payment with amortization, compound growth, a savings plan, and a TVM unknown, inspect assumptions and walkthroughs, hear the result, and reopen it from History — offline, with no account.

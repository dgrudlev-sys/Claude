# Scientific Calculator — Dual-Audience Experience

Date: 2026-10-05  
Status: Research and design only. No app code in this pass.  
App: `scientific-calculator/`  
Sibling product (out of scope here): Financial Calculator at `C:\Users\franc\Projects\financial-calculator`

This document is jobs-to-be-done and information architecture. It does not copy competitor brands, key layouts, or chrome.

---

## 1. One-page summary

**The product is a calculator that opens ready to add, not a catalogue of eleven equally loud tools.** Beginners get a five-second path: open → numbers → equals. Professionals get the same surface, with scientific keys, 2nd functions, DEG/RAD, history, convert, and solve one gesture away — never a “dummy” mode.

**What people hire a scientific calculator for**

| Audience | Five-second job | Power job |
| --- | --- | --- |
| Beginner / homework | `2 + 2`, percent of a bill, fraction of a recipe | See *how this was worked out* in plain language; convert units without hunting |
| Student / exam practice | Algebraic entry that matches the page | DEG/RAD that is visible, history to reuse last result, graph `y = x²` |
| Engineer / pro | Fast arithmetic with last result | 2nd layer, memory, ENG/SCI display, unit convert, chained history |

**What this app already does well:** Samsung-style portrait numpad with SCI leftover (not a landscape hostage); `scientificKeypad` defaults off; 2nd + DEG/RAD on the function cluster; history with pin/reuse; “How this was worked out” (not “Step 1”); Convert / Percentage / Fractions as everyday tools; speech *reads* the equation; many languages; Look/type/vision; Accessible layout is the same keys, denser targets.

**What is a wall:** First-class chooser of 11 modes (Calculator, Convert, Percentage, Fractions, Graph, 3D, Geometry, Matrix, Statistics, Finance, Solve). Cold start can reopen last mode (`openLastMode` defaults **true**), so a beginner can land in Matrix. Mode copy talks down (“Draw a picture of a formula”). Finance here duplicates the other product’s slice-1 jobs and does **not** even expose the TVM engine already in this repo. No Ans/M+/MR keys, no sig-fig/ENG format, no RPN, no photo, no voice *input*. Convert is a separate island from Calc.

**Recommendation (one app, two depths)**

1. **Calc is the hero.** Cold start = Calculator. Remember last tool only if the user opts in.
2. **SCI is a layer, not a mode.** Keep the existing toggle. Do not invent Beginner/Pro profiles.
3. **Tools chooser is short.** Everyday: Convert, Percentage, Fractions. Then Graph, Solve. Everything else under **More** (Statistics, Matrix, Geometry, 3D).
4. **Demote Finance.** Keep the math if useful; do not compete with the Financial Calculator. Point people there for TVM, loans, savings goals.
5. **Do not become Wolfram or Photomath.** Honest numeric solve + polynomial + derivative. Steps stay adult walkthroughs of *this* arithmetic. Camera/CAS are later, optional, never the home screen.
6. **Visual bar:** Harbor’s *craft* (one field, one signal, 8pt grid, 200–280 ms motion). **Panther stays the scientific default look** so this app still reads as an instrument, not the finance sibling. Offer Harbor as a Look.

**Success:** A new user computes `15% of 80` on the pad in five seconds. An engineer toggles SCI, DEG/RAD, 2nd, and reuses history without leaving Calc. Nobody has to pick a personality.

---

## 2. Research: jobs, not clones

Competitors below are **jobs people hire them for**. Layout, color, and brand are out of bounds.

### 2.1 Beginner five-second path vs professional power

**Beginner (homework, kitchen, bill, “I am not a math person”)**

- Open and type. 7-8-9 numpad. C, backspace, equals. No landscape tax for `√` or `x²` (Samsung users complained about this for years; One UI 8 finally put scientific keys above the pad in portrait — this app already does that).
- Percent as a *question* (“what is 15% of 80?”), not only a `/100` key.
- Fractions that stay fractions until they ask for a decimal.
- Convert: cm↔in, °C↔°F, cups, currency, tip — one job per row.
- Walkthrough they can read: sentence, then the matching symbols. Research on homework apps shows students who *check* after attempting learn; students who only snap-and-copy do not. Our steps should verify *their* calculation, not replace thinking.
- Voice that *reads* the line (we have this). Photo that *solves the textbook* is a different product (Photomath / Microsoft Math).

**Professional (engineering, lab, exam-adjacent practice, teaching)**

- Algebraic entry that matches the written expression (TI/Casio/Desmos scientific). RPN is a real minority superpower (HP/PCalc studies: fewer parentheses, visible intermediates); it is not the default for a school-adjacent app.
- **2nd** for inverse trig, `10^x`, `e^x` — the physical-calculator contract.
- **DEG/RAD on the working surface**, not buried in Settings (Google Calculator eventually put the toggle on the display; PCalc users still rage at apps that hide it).
- **History as working memory:** tap to restore result or expression (we have a History screen + compact last line). Pros also expect **Ans** on the pad and **M+/MR/MC**.
- **Display format:** STD / SCI / ENG; optional significant-figure *display* rounding. Engineering habit: keep guard digits internally, round at the end. Do not silently shorten homework answers.
- Unit convert that includes *engineering* quantities (force, pressure, energy, power) in addition to kitchen/tip. Convert must be reachable from Calc, not only from a menu of 11 apps.
- Graph: “plot this formula.” Table of values. Not Desmos Activity Builder.
- Solve: numeric root with a guess (handheld solver model), polynomials, derivative/simplify. Not a general CAS.
- Memory of *the last thirty honest results*, pin, hide, delete.

**Exam vs homework (product honesty)**

- Physical TI-84 / Casio ClassWiz exist because **phones are banned** on many papers. We cannot be the exam-room device. We can be the **practice** device: same jobs (trig in degrees, graph, stats, matrix) without claiming test-board approval.
- Desmos *is* in Bluebook for digital SAT — people will compare our graph to that. We should not chase SAT chrome. We should make `y =` fast and readable.
- CAS (exact solve, symbolic integrate) is what people *expect from Wolfram* and what exam boards *forbid*. Shipping a half-CAS that looks like Wolfram is worse than saying we don’t.

### 2.2 Competitor jobs (hire / do not become)

| Product | People hire it to… | We should not become… |
| --- | --- | --- |
| **Google Calculator** | Instant arithmetic, big keys, swipe history, RAD/DEG on the display | A convert-less pad. Pixel users still ask where the converter is. |
| **Samsung Calculator** | Everyday pad + **Convert hub** (length, temp, volume, tip, …); scientific in portrait (now) | Landscape-only SCI; convert as a secret. |
| **Desmos** | Graph first: sliders, tables, inequalities; classroom; digital SAT scientific/graphing | Graph-home. Full CAS (Desmos itself is **not** CAS). Activity Builder. |
| **GeoGebra** | Geometry constructions, 3D, spreadsheet, **CAS**, stats in one ecosystem | Eleven equal apps. Constraint geometry. Symbolic CAS suite. |
| **NumWorks** | Modern handheld: Python, apps, shareable; “calculator that doesn’t look like 1998” | Hardware clone. Exam firmware. |
| **TI-84** | Muscle memory the US classroom teaches; graph, table, stat, matrix, finance, solver | Mode soup (`MODE`/`APPS` as the product). Navy/silver trade dress. Key-for-key clone (README already warns against this). |
| **Casio ClassWiz** | Calculate as home; menu for Matrix, Statistics, Equation, Spreadsheet, Complex, Base-N | Spreadsheet + 12-icon menu as the first screen. |
| **Photomath** | Point camera at the worksheet; animated steps | Camera-home. Homework completion as identity. |
| **Microsoft Math** | Free typed/photo/ink steps, multiple methods, practice links | Tutor platform. Multi-method pedagogy as the core loop. |
| **Wolfram** | Trustworthy symbolic engine; “what is the closed form?” | Dense Pro notebook. Paywalled steps. Natural-language omniscience. |
| **PCalc / HP RPN** | Stack, intermediates, fewer keystrokes for chained engineering | RPN as default. HP key lore. |

**Pain research (repeated across reviews and forums)**

1. **Mode soup** — ClassWiz/TI/GeoGebra all front a grid of apps. Power users learn it; first-open users bounce.
2. **Scientific keys that scare beginners** — hiding them behind landscape (old Samsung) or dumping 20 functions on the first screen (TI-style phone ports). Progressive **reveal** (CALCU swipe, Google drawer, our SCI) is the pattern that works.
3. **Convert buried** — Google pad has no converter; people leave the app. Samsung wins this job.
4. **Steps that look like a textbook** — “Step 1 / Step 2”, CAS jargon. Our craft skill already forbids this.
5. **Keypad vs OS keyboard** — Calc muscle memory wants 7-8-9. Form tools (convert, percent, solve) want the OS number pad for labeled fields. Mixing both on one screen is the failure. Soulver-style flipping between keyboards is a known pro complaint.

### 2.3 Job map for *this* product

| Job | Beginner 5s | Pro power | Today |
| --- | --- | --- | --- |
| Arithmetic | Pad visible, SCI off | SCI + 2nd + `^` `ln` `π` | Strong |
| DEG/RAD | Hidden until SCI | Toggle on cluster; persist across launches | Strong when SCI on; **session-only today** (resets to DEG). Persist next; when SCI is off, keep last mode silently |
| History / Ans | Last line + History button | Tap restore; want Ans/M+ | Partial (no Ans/M+) |
| Convert | One tap from home-of-tools | Engineering units; from Calc | Everyday units strong; buried; no force/pressure/energy |
| Percent | Dedicated tool | `%` key on pad | Both exist; two mental models |
| Fractions | Dedicated tool | Want `a b/c` on pad later | Tool strong; not on pad |
| Solve | “Find x in `x^2 = 4`” | Guess, polynomials, d/dx | Real; copy still a bit school-kit |
| Graph | `y = x²` | Function/parametric/polar/sequence + table | Real; mode bar is already a mini-soup |
| Geometry / 3D | Rare | Niche | First-class modes — too loud |
| Matrix / Stats | Rare | Coursework | First-class — OK under More |
| Finance | “What’s my payment?” | Full TVM | **Duplicates sibling app**; TVM engine unused in UI |
| Photo | Homework snap | Not a pro calc job | Absent — keep absent as identity |
| Voice | Hear the equation | Hands-busy readback | TTS only |
| RPN | Confusing | Beloved | Absent — Settings later, not Home |
| Sig figs / ENG | Irrelevant | Daily | Absent |

---

## 3. Our product today (audit)

### 3.1 Architecture (as shipped)

- **First launch:** language picker, then Calculator (unless `openLastMode` + `lastMode`).
- **HomeShell:** one tool at a time. Apps icon → **ModePickerScreen**. Settings in the app bar. Comment in code: screen-reader users are not dropped into an unlabeled tab bar. (README still describes an old `TabBarView`; the chooser replaced it.)
- **Modes (11):** Calculator, Convert, Percentage, Fractions, Graph, 3D, Geometry, Matrix, Statistics, Finance, Solve.
- **Chooser grouping:** Everyday ungrouped (Calc, Convert, Percentage, Fractions). Then Graphs (Graph, 3D, Geometry), School (Matrix, Statistics, Solve), Money (Finance).
- **Calc:** display (expression + result + compact last equation) → History / How-this-was-worked-out → editor bar (◀ ▶ ⌫ speak SCI) → portrait Samsung 5×4 numpad; SCI functions in leftover above; landscape/wide: functions left, numpad right.
- **SCI** persisted (`scientificKeypad`, default **false**). **2nd** is session-local. Angle mode lives on the controller (degrees default).
- **History:** 30 visible, pin / hide / delete, tap to use result.
- **Steps:** `StepsPanel` / sheet; title **How this was worked out**; beats are words + symbols; no “Step N”.
- **Convert:** category chooser (currency, cooking, area, length, temperature, volume, mass, data, speed, time, tip) then from/to + amount. Currency via ECB-style table, about daily. Flour density toggle. OS `NumericField`.
- **Percentage:** of / what percent / change.
- **Fractions:** mixed numbers, ops, compare, extra terms.
- **Solve:** Solve for x (numeric, guess), polynomial roots, derivative & simplify.
- **Graph:** function / parametric / polar / sequence + table.
- **Geometry:** tap or type x,y; lines, circles, measure; no live constraints (documented).
- **3D:** `z = f(x,y)` orbit wireframe.
- **Finance UI:** simple interest, compound, loan payment, savings — **not** TVM. `TvmSolver` exists only in `lib/finance/tvm_solver.dart` and tests.
- **Speech:** `SpeechService` TTS + semantics announce. Language follows app locale. Not dictation.
- **Look:** Panther default; nature stories + eight colour-vision stories; type voices Laboratory / Manuscript / Clearest; layouts Classic / Compact / Accessible.

### 3.2 Already strong

- Dual audience **seed**: SCI off is a real basic pad, not a fake kids’ app. Accessible layout is the same keyboard.
- Portrait scientific without stealing the 7-8-9 size (leftover cluster). This matches the job Samsung just spent years fixing.
- History as a dedicated surface (Samsung pattern), not a permanent strip eating keys (a complaint against Samsung landscape).
- Adult walkthrough pattern on tools; Convert as a hub (the job Google refuses).
- Accessibility: TalkBack labels, 48/56 dp, haptics/sound split, colour-vision looks, RTL languages.
- Engine honesty: degree rewrite, auto-close parens, numeric methods tested against reference values.

### 3.3 The wall

- **Eleven peer tiles.** Calc is one row among Matrix and 3D. That is ClassWiz-on-a-phone.
- **`openLastMode` default true.** Five-second path is not guaranteed after the first session.
- **Kid-talk subtitles** vs craft rule “plain adult English that also sounds smart.”
- **Finance as a mode** while a full Financial Calculator product exists and this UI is the *thin* worksheets only.
- **Power missing on the hero pad:** Ans, memory registers, ENG/SCI, sig-fig display, chained percent semantics, engineering convert.
- **Solve/Graph copy and chrome** still feel like extra apps, not depths of Calc.
- **Two input worlds** with no rule: pad vs OS keyboard.

---

## 4. Dual audience without two apps

### 4.1 Approaches considered

| Approach | Idea | Trade-off |
| --- | --- | --- |
| **A. Progressive disclosure (recommended)** | One Calc. SCI / 2nd / More reveal power. Tools grouped by how often a human wants them. | Requires ruthless ranking. Pros must not hunt. |
| **B. Beginner / Pro profiles** | Toggle that hides keys or swaps IA. | Insults engineers (“you’re in easy mode”). Two test matrices. Beginners never discover SCI. |
| **C. Bottom tabs (Calc / Convert / Tools / More)** | Finance-app IA transplanted. | Eats thumb space the numpad needs. Two products feel identical. Convert deserves speed, not a permanent tab if SCI is already competing for height. |

**Recommendation: A.** The insult to avoid is not “hard keys exist”; it is “we decided you are a child.” SCI is opt-in density. 2nd is a shift key, the professional contract. More is a library, not a second personality.

### 4.2 Rules (non-negotiable)

1. **Same math, same keys, different *visibility*.** Never a reduced operator set that cannot do `sin`. SCI off only *hides* the cluster.
2. **No mascot, no “for kids”, no “per hundred” lessons.** Walkthroughs stay adult.
3. **Last-used is a caption, not a trap.** Cold start = Calculator unless the user enables “Open last tool.”
4. **Power is labeled in the user’s words** (`sin⁻¹`, DEG, History), not in internal mode names (`CalculatorMode.solve`).
5. **If a control is for pros, it is one extra tap from Calc**, not a different app identity.

### 4.3 Progressive layers on Calc

```
Layer 0  Display + 7-8-9 pad + C ⌫ = % ( ) ± .
Layer 1  SCI → 2nd, DEG/RAD, sin/cos/tan, √ log ln π e ^ x² 1/x
Layer 2  History, How this was worked out, Ans (future), M+ (future)
Layer 3  Apps → Convert / Percentage / Fractions / Graph / Solve
Layer 4  More → Statistics, Matrix, Geometry, 3D
```

Beginners live in 0–3. Professionals live in 1–4 without ever switching “profile.”

---

## 5. IA: Home / modes / Calc as the hero

### 5.1 Launch

| Event | Behavior |
| --- | --- |
| First install | Language once, then **Calculator**, SCI off |
| Later cold start | **Calculator**, unless Settings → Open last tool |
| In-session | Apps returns to the chooser; last tool marked |

### 5.2 Chrome (HomeShell)

Keep a single AppBar:

- **Leading:** Apps (chooser) — not a hamburger of 11 icons.
- **Title:** name of the current tool (“Calculator”, “Convert”, …).
- **Trailing:** Settings.

No bottom destination bar on Calc. The pad *is* the destination.

Optional later (not required for this spec): a single **Convert** action in the Calc display chrome, so unit convert is not only behind Apps. If added, it is one extra text button beside History, not a tab.

### 5.3 Chooser information architecture

**Primary (always visible, in this order)**

1. **Calculator** — first row, the way home from any tool. Cold start still skips the chooser and opens this surface.
2. **Convert**
3. **Percentage**
4. **Fractions**

**Secondary**

5. **Graph**
6. **Solve**

**More (collapsed section, default collapsed on first visit; remember expanded state)**

7. Statistics  
8. Matrix  
9. Geometry  
10. 3D  

**Removed from chooser (see §6)**

- Finance — demote off the scientific home.

Last-used caption stays. Do not show 3D beside Convert with equal visual weight.

### 5.4 Calc is the hero (detail)

**Beginner 5-second path**

1. Open app.  
2. See a large result `0` and a 7-8-9 pad.  
3. Type `80 × 15 %` or use Percentage from Apps if they think in questions.  
4. Equals. Optional: How this was worked out.

**Professional path without leaving Calc**

1. SCI on (persists).  
2. DEG/RAD on the cluster, mirrored as a tappable chip on the display whenever SCI is on.  
3. 2nd for inverses.  
4. History to pull Ans. Future: Ans key, M+/MR.  
5. Apps → Convert or Solve when the job is not an expression.

**Graph / Solve** are depths, not peers of arithmetic: they should feel like “this formula, plotted” and “this equation, solved,” with a way to send the current Calc expression in (future). Do not require retyping if we can pass a string. That is progressive disclosure, not a new product.

### 5.5 Input rule (keypad vs OS)

| Surface | Input |
| --- | --- |
| Calculator | On-screen 7-8-9 pad only. Hardware keyboard shortcuts already exist (arrows, enter, backspace) — keep. |
| Convert / Percentage / Fractions / Statistics / Matrix forms | OS numeric keyboard via `NumericField`. One field focused at a time. |
| Solve equation / Graph expression | OS keyboard (symbols, `x`, `^`) **or** a math accessory row — not the full scientific pad stacked under a text field. |
| Geometry canvas | Gestures + optional x,y fields (OS). |

Never show the scientific cluster and the OS keyboard at once.

### 5.6 Copy register

Chooser subtitles become adult and specific:

| Mode | Direction (do not ship kid-talk) |
| --- | --- |
| Calculator | Arithmetic, powers, trig. History keeps recent results. |
| Convert | Units, currency, cooking, tip. |
| Percentage | Part of, reverse percent, percent change. |
| Fractions | Add, subtract, multiply, divide; simplified. |
| Graph | Plot a formula. Table of values. |
| Solve | Find x, polynomial roots, derivative. |
| Statistics | Mean, spread, fit, distributions. |
| Matrix | Add, multiply, det, inverse. |
| Geometry | Points, lines, circles, measure. |
| 3D | Plot `z = f(x, y)`. |

Walkthroughs stay **How this was worked out** / **Plain language, with the arithmetic beside it.**

---

## 6. Keep, cut, or demote

### Keep (hero and everyday)

| Thing | Why |
| --- | --- |
| Calculator pad + SCI leftover | Dual audience already works |
| 2nd, DEG/RAD | Pro contract |
| History + pin/reuse | Working memory |
| How this was worked out | Beginner trust without textbook chrome |
| Convert hub | Job Google cedes; Samsung-level everyday |
| Percentage + Fractions tools | Question-shaped jobs the pad `%` cannot carry |
| Speak (TTS) | Accessibility and hands-busy |
| Languages + RTL | Already a product advantage |
| Look / type / vision / Accessible layout | Craft and inclusion |
| Graph (function + table at minimum) | Homework/engineering plot job |
| Solve (numeric + polynomial + d/dx) | Handheld solver, not CAS |

### Demote (keep code, hide from the front)

| Thing | How |
| --- | --- |
| Statistics, Matrix | **More** |
| Geometry | **More**. Honest: no live constraints. Do not market as GeoGebra. |
| 3D | **More**. Niche. Do not sit next to Convert. |
| Graph parametric/polar/sequence | Secondary segmented control *inside* Graph, not home IA |
| Solve’s three tabs | Stay inside Solve; default **Solve for x** |
| `openLastMode` | Default **off** so cold start is always Calc |
| Finance mode | Off the chooser (see cut/thin) |

### Cut or thin (scientific product)

| Thing | Recommendation |
| --- | --- |
| **Finance chooser row** | **Remove from scientific Home.** The sibling Financial Calculator owns TVM, loans, amortization, savings goals, business, budget. This app’s Finance screen is simple/compound/loan/savings worksheets — the same jobs as finance slice 1, with less craft. Shipping both confuses stores and users. |
| **TvmSolver in this repo** | Do **not** build a TVM keypad here. Leave the engine in place or share later; do not expose it as a mode. If a user needs N/I/Y/PV/PMT/FV, that is the other app. |
| **Photo solve** | Do not add as identity. Optional later: camera to *fill an expression*, user confirms, then *our* engine runs. Never Photomath-home. |
| **Voice input (STT)** | Not now. TTS stays. Dictation is a later Settings accessory. |
| **General CAS / symbolic integrate** | Stay out of scope (already in README). Do not fake Wolfram output. |
| **RPN** | Not on Home. If shipped, Settings → Entry: Algebraic (default) / RPN. |
| **Kid-talk strings** | Rewrite; do not keep a “simple language” track that sounds like a primary workbook. |

### Add later (power on the hero, still one app)

Priority order if/when implementation is approved:

1. Cold-start Calc; chooser ranking; copy rewrite (IA only).  
2. DEG/RAD chip on the display when SCI is on.  
3. **Ans** on the pad (shifted or editor bar).  
4. Convert shortcut from Calc chrome **or** engineering unit categories inside Convert.  
5. Display format STD/SCI/ENG; optional sig-fig *display*.  
6. M+/MR/MC (one memory is enough; four HP registers are lore).  
7. Pass current expression into Graph/Solve.  
8. RPN as a setting.  
9. Photo-to-expression with mandatory confirm.

---

## 7. Visual and motion bar (Harbor vs current — recommend, don’t restyle)

### 7.1 What Harbor is

In the Financial Calculator, **Harbor** is the default color story: night-water field `#0A1020`, supporting `#1A2740`, signal `#2F6BFF`, on-field `#F2F5FB`, equals on the blue accent. Paper is the light sibling. Craft rules live in `product-visual-craft`: 8pt grid, card 16/16, hairline *or* tint, elevation 0 at rest, type roles, icons in 24px squares, motion 200/240/280 ms, `easeOutCubic` / `easeInOutCubic`, adult copy.

This scientific app’s default is **Panther**: `#0C0C0E` field, gold eye `#C9A227` on equals, silver operators. Nature looks (Africa, Parrot, Stone, …) plus colour-vision set. No Harbor/Paper in *this* repo today.

### 7.2 Recommendation

**Raise the scientific app to Harbor’s *craft bar*, not Harbor’s *brand* as the forced default.**

| Layer | Scientific default | Why |
| --- | --- | --- |
| Color story | **Panther** remains default | Gold equals on charcoal reads as a handheld instrument. Harbor’s iOS blue reads as the finance sibling. Two apps, two jobs, one craft system. |
| Offer Harbor | Add Harbor (and optionally Paper) to Look | Users who run both apps can match. Not a rewrite of Africa/Parrot. |
| Spacing / type / motion | Follow `AppMetrics` / `AppMotion` / craft skill on every surface we later touch | Chooser tiles, steps sheet, convert cards — same 16 pad, 16 radius, 240 ms expand. |
| Keypad | Keep tessellated keys (radius 8, gutter 4) | Cards are 16; keys are not pillows. |
| Light theme | Paper only as a Look, never as Calc default | Light fields fight dense pads and outdoor glare less well than a dark instrument. |

**Do not:** restyle every mode in one pass; copy finance bottom tabs; put Material shadows on the pad; bounce keys; use Harbor blue as the only equals color across both products unless the user picks Harbor here.

**Motion on Calc:** SCI cluster appear/disappear = 240 ms `easeInOutCubic` (`AnimatedSize`). Result swap = 240 ms fade, no scale. 2nd latch = selected border, not a color cycle. Forbidden: ≥600 ms, elastic, sparkle per key.

**Chooser visual:** full-bleed `ChooserTile` is already the right language (same as Settings). Primary tools get the list; More is a section header + tiles, not a second grid of icons competing with Calc.

---

## 8. What “amazing” means (quality bar, still no code)

- Inevitable first frame: result and pad. No tutorial overlay.
- SCI is an obvious control on the editor bar (already `SCI`). Persist.
- Errors are words (`Syntax error`, `Math error`) plus a warning glyph — color is not the only cue.
- Convert result is visible without a second “calculate” mystery if the amount is filled (live convert is the Samsung/Google Search job).
- Graph: one expression, a plot, pinch-zoom. Extra graph modes behind a control.
- Solve: one field, one guess, one result list. Calculus is a second row inside the tool.
- Screen readers: every key already has a spoken name; keep that while changing IA.

---

## 9. Open questions

1. **Convert on Calc chrome?** One History-style button vs Apps-only. Speed vs editor-bar clutter (already ◀ ▶ ⌫ speak SCI).
2. **Harbor as *family* default?** This spec keeps Panther. If the two apps must screenshot as one brand, flip default to Harbor and keep Panther as a Look instead.
3. **Finance:** delete the chooser entry only, or also hide `FinanceScreen` behind a debug flag? Store listing: mention the Financial Calculator or stay silent?
4. **Engineering units** (force, pressure, energy, power) in Convert now, or after IA?
5. **Ans / memory** in the first experience slice or after IA/copy?
6. **RPN:** ever in this app, or only if professionals ask after algebraic ships well?
7. **Photo-to-expression:** never, or later with confirm-gate so we don’t become Photomath?
8. **Pass expression Calc → Graph/Solve** in the first IA slice?
9. **`openLastMode`:** default off as recommended, or keep on for returning Graph users?
10. **3D / Geometry:** More vs remove from shipping until constraint geometry / hidden-surface exist?
11. **Exam disclaimer** in Settings/About (“not approved as a testing device; phones are often banned”)?
12. **Percent duality:** keep `%` as `/100` on the pad and the Percentage tool, or change pad `%` toward Casio “percent of last” semantics?

---

## 10. Out of scope

- Any edits under `scientific-calculator/lib/`.
- Financial Calculator IA, TVM UX, Harbor restyle in that repo.
- Implementation plan, tests, commits.
- Cloning Desmos/TI/Casio layouts or names.

When this spec is approved, the next document is an implementation plan (IA first, then power keys, then optional convert/engineering), not a theme rewrite.

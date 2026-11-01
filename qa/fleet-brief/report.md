# Release gate: health-ship b441f5e0b1b8

Verdict: **BLOCK** (2026-11-01T10:56:30+00:00)

Every finding blocks except legacy backlog. `qa-gate fix <repo>` fixes them. Motion candidates need a judgement in the ledger: `qa-gate ledger <repo> accept` for an intended change, or `add` a P1 when it is a real glitch.

## Blocking (20)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P1 | copy | newcomer | checkpoint(_:button:in:) / target | em or en dash in app copy: "31–51" | `copy|checkpoint(_:button:in:)|target|#–#` |
| P1 | copy | newcomer | checkpoint(_:button:in:) / target | em or en dash in app copy: "Typical for your profile: 31–51 mL/kg/min" | `copy|checkpoint(_:button:in:)|target|typical for your profile: #–# ml/kg/min` |
| P1 | copy | newcomer | test2TabsUpgradeSettingsAndReturn / settings | em or en dash in app copy: "31–51" | `copy|test2TabsUpgradeSettingsAndReturn|settings|#–#` |
| P1 | copy | newcomer | test2TabsUpgradeSettingsAndReturn / settings | em or en dash in app copy: "Broad typical range for your current profile: 35–47 mL/kg/min" | `copy|test2TabsUpgradeSettingsAndReturn|settings|broad typical range for your current profile: #–# ml/kg/min` |
| P1 | copy | newcomer | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | em or en dash in app copy: "31–70" | `copy|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|#–#` |
| P1 | copy | newcomer | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | em or en dash in app copy: "Broad typical range for your current profile: 35–47 mL/kg/min" | `copy|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|broad typical range for your current profile: #–# ml/kg/min` |
| P1 | copy | newcomer | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | em or en dash in app copy: "31–70" | `copy|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|#–#` |
| P1 | copy | newcomer | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | em or en dash in app copy: "Broad typical range for your current profile: 35–47 mL/kg/min" | `copy|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|broad typical range for your current profile: #–# ml/kg/min` |
| P1 | truncated | german | checkpoint(_:button:in:) / profile | button drawn as "Nicht festgel..." but reads "Nicht festgelegt" | `truncated|checkpoint(_:button:in:)|profile|nicht festgelegt` |
| P1 | copy | german | checkpoint(_:button:in:) / target | em or en dash in app copy: "An deinem Alter (35) orientiert, liegt die typische Cardiofitness für dein Profil bei 31–51 mL/kg/min. Passe den Bereich nach Wunsch an." | `copy|checkpoint(_:button:in:)|target|an deinem alter (#) orientiert, liegt die typische cardiofit` |
| P1 | copy | german | checkpoint(_:button:in:) / target | em or en dash in app copy: "Typisch für dein Profil: 31–51 mL/kg/min" | `copy|checkpoint(_:button:in:)|target|typisch für dein profil: #–# ml/kg/min` |
| P1 | truncated | german | test1FirstRunToTrial / onboarding-trial | text drawn as "Mehr aus VO2+ heraush..." but reads "Mehr aus VO2+ herausholen" | `truncated|test1FirstRunToTrial|onboarding-trial|mehr aus vo#+ herausholen` |
| P1 | paywall-privacy | german | test1FirstRunToTrial / onboarding-trial | no Privacy Policy link anywhere on the paywall (3.1.2) | `paywall-privacy|test1FirstRunToTrial|onboarding-trial|` |
| P1 | truncated | german | test2TabsUpgradeSettingsAndReturn / trends | button drawn as "& Benutzerdef..." but reads "Benutzerdefiniert" | `truncated|test2TabsUpgradeSettingsAndReturn|trends|benutzerdefiniert` |
| P1 | paywall-privacy | german | test2TabsUpgradeSettingsAndReturn / upgrade | no Privacy Policy link anywhere on the paywall (3.1.2) | `paywall-privacy|test2TabsUpgradeSettingsAndReturn|upgrade|` |
| P1 | copy | german | test2TabsUpgradeSettingsAndReturn / settings | em or en dash in app copy: "Grober typischer Bereich für dein aktuelles Profil: 35–47 mL/kg/min" | `copy|test2TabsUpgradeSettingsAndReturn|settings|grober typischer bereich für dein aktuelles profil: #–# ml/k` |
| P1 | copy | german | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | em or en dash in app copy: "Grober typischer Bereich für dein aktuelles Profil: 35–47 mL/kg/min" | `copy|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|grober typischer bereich für dein aktuelles profil: #–# ml/k` |
| P1 | copy | german | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | em or en dash in app copy: "Grober typischer Bereich für dein aktuelles Profil: 35–47 mL/kg/min" | `copy|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|grober typischer bereich für dein aktuelles profil: #–# ml/k` |
| P0 | journey-broken | accessibility | testCoreLoopTargetRangeDrivesTodayAndPersists /  | XCTAssertTrue failed - target range slider | `journey-broken|testCoreLoopTargetRangeDrivesTodayAndPersists` |
| P0 | journey-broken | duo | test2TabsUpgradeSettingsAndReturn /  | XCTAssertTrue failed - Trends missing | `journey-broken|test2TabsUpgradeSettingsAndReturn` |

## Needs a judgement (0)

None.

## Legacy backlog, warns until fixed (250)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / welcome | Contrast failed (measured 2.0:1): "Continue" | `a11y-contrast|checkpoint(_:button:in:)|welcome|continue` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / welcome | Contrast failed (measured 1.7:1): "Read-only. Stays on your device. No account." | `a11y-contrast|checkpoint(_:button:in:)|welcome|read-only. stays on your device. no account.` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / profile | Contrast failed (measured 2.0:1): "Continue" | `a11y-contrast|checkpoint(_:button:in:)|profile|continue` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / profile | Contrast failed (measured 2.2:1): "35" | `a11y-contrast|checkpoint(_:button:in:)|profile|#` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / target | Contrast failed (measured 2.0:1): "Continue" | `a11y-contrast|checkpoint(_:button:in:)|target|continue` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / target | Contrast failed (measured 2.2:1): "31–51" | `a11y-contrast|checkpoint(_:button:in:)|target|#–#` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / target | Contrast nearly passed (measured 3.5:1): "Typical for your profile: 31–51 mL/kg/min" | `a11y-contrast|checkpoint(_:button:in:)|target|typical for your profile: #–# ml/kg/min` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Get Started" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|get started` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Restore" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|restore` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Terms" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|terms` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Privacy" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|privacy` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Get Started" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|get started` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "$9.99 per month is charged now. It renews automatically unless you cancel at least 24 hours before this period ends. Manage or cancel in Settings > Apple ID > Subscr | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|$# per month is charged now. it renews automatically unless ` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 2.0:1): "Continue with VO2+" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|continue with vo#+` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Restore" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|restore` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Terms" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|terms` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Privacy" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|privacy` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Keep your strongest estimate visible" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|keep your strongest estimate visible` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Billed automatically. Cancel anytime." | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|billed automatically. cancel anytime.` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test1FirstRunToTrial|first-today|today` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test1FirstRunToTrial|first-today|trends` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|test1FirstRunToTrial|first-today|vo#+` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.7:1): "Latest estimate 24 seconds ago. You usually get one every 6 days." | `a11y-contrast|test1FirstRunToTrial|first-today|latest estimate # seconds ago. you usually get one every # d` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test1FirstRunToTrial|first-today|ml/kg/min` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|test1FirstRunToTrial|first-today|in target range` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.7:1): "Target 31–51" | `a11y-contrast|test1FirstRunToTrial|first-today|target #–#` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio fitness trend` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|test1FirstRunToTrial|first-today|+# over # days` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|test1FirstRunToTrial|first-today|fitness age estimate` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|test1FirstRunToTrial|first-today|resting heart rate` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|test1FirstRunToTrial|first-today|bpm` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio recovery` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio load` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|test1FirstRunToTrial|first-today|min/week` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|trends` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.7:1): "Latest estimate now. You usually get one every 6 days." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|latest estimate now. you usually get one every # days.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|ml/kg/min` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|in target range` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.7:1): "Target 31–51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|target #–#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio fitness trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|+# over # days` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|fitness age estimate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Chronological age 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|chronological age #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|resting heart rate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|bpm` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio recovery` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio load` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|min/week` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.1:1): "VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.7:1): "Showing Aug 3 to Nov 1, 2026" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|showing aug # to nov #, #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.5:1): "Target" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|target` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.9:1): "Custom" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|custom` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Readings" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|readings` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Average" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|average` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.5:1): "+1.0" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|+#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Change" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|change` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "bpm at rest" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|bpm at rest` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Restore" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|restore` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Terms" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|terms` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Privacy" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|privacy` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.8:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|trends` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 2.7:1): "Continue with VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|continue with vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.7:1): "$79.99 per year is charged now. It renews automatically unless you cancel at least 24 hours before this period ends. Manage or cancel in Settings > Apple ID > Subscr | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|$# per year is charged now. it renews automatically unless y` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Restore" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|restore` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Terms" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|terms` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Privacy" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|privacy` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Extras that sit on top of your Apple Health estimates." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|extras that sit on top of your apple health estimates.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.9:1): "Save 33%" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|save #%` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 2.9:1): "Instead of $9.99 per month" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|instead of $# per month` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.7:1): "$6.67 per month" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|$# per month` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast failed (measured 2.2:1): "31–51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|#–#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|ml/kg/min` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast failed (measured 2.5:1): "Connected" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|connected` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|refresh apple health` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|open apple health` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|trends` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.7:1): "Latest estimate now. You usually get one every 6 days." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|latest estimate now. you usually get one every # days.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|ml/kg/min` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|in target range` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.7:1): "Target 31–51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|target #–#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio fitness trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|+# over # days` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|fitness age estimate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Chronological age 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|chronological age #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|resting heart rate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|bpm` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio recovery` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio load` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|min/week` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|trends` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.7:1): "Latest estimate now. You usually get one every 6 days." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|latest estimate now. you usually get one every # days.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|ml/kg/min` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|in target range` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.7:1): "Target 31–51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|target #–#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio fitness trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|+# over # days` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|fitness age estimate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Chronological age 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|chronological age #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|resting heart rate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|bpm` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio recovery` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio load` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|min/week` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast failed (measured 2.2:1): "31–70" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|#–#` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|ml/kg/min` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast failed (measured 2.5:1): "Connected" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|connected` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|refresh apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|open apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|today` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|trends` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|vo#+` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.7:1): "Latest estimate 17 seconds ago. You usually get one every 6 days." | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|latest estimate # seconds ago. you usually get one every # d` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|ml/kg/min` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|in target range` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.7:1): "Target 31–70" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|target #–#` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio fitness trend` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|+# over # days` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|fitness age estimate` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Chronological age 42" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|chronological age #` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|resting heart rate` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|bpm` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio recovery` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio load` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|min/week` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast failed (measured 2.2:1): "31–70" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|#–#` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|ml/kg/min` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast failed (measured 2.5:1): "Connected" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|connected` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|refresh apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|open apple health` |
| P2 | truncated |  | test1FirstRunToTrial / onboarding-trial | button drawn as "Continue with V..." but reads "Continue with VO2+" (AX3 text only) | `truncated|test1FirstRunToTrial|onboarding-trial|continue with vo#+` |
| P2 | clipped |  | test2TabsUpgradeSettingsAndReturn / trends | text "Readings" is broken across 2 lines: Read- / ings (AX3 text only) | `clipped|test2TabsUpgradeSettingsAndReturn|trends|readings` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.5:1): "$99.99" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|$#` |
| P3 | a11y-element-detection |  | test2TabsUpgradeSettingsAndReturn / trends | Potentially inaccessible text | `a11y-element-detection|test2TabsUpgradeSettingsAndReturn|trends|` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / welcome | Contrast failed (measured 2.0:1): "Weiter" | `a11y-contrast|checkpoint(_:button:in:)|welcome|weiter` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / welcome | Contrast failed (measured 1.7:1): "Nur lesend. Bleibt auf deinem Gerät. Kein Konto." | `a11y-contrast|checkpoint(_:button:in:)|welcome|nur lesend. bleibt auf deinem gerät. kein konto.` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / profile | Contrast failed (measured 2.0:1): "Weiter" | `a11y-contrast|checkpoint(_:button:in:)|profile|weiter` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / target | Contrast failed (measured 2.0:1): "Weiter" | `a11y-contrast|checkpoint(_:button:in:)|target|weiter` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / target | Contrast nearly passed (measured 3.5:1): "Typisch für dein Profil: 31–51 mL/kg/min" | `a11y-contrast|checkpoint(_:button:in:)|target|typisch für dein profil: #–# ml/kg/min` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Los geht's" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|los geht's` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Wiederherstellen" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|wiederherstellen` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Bedingungen" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|bedingungen` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Privatsphäre" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|privatsphäre` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Los geht's" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|los geht's` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "9,99 $/Monat wird jetzt berechnet. Das Abo verlängert sich automatisch, wenn du nicht mindestens 24 Stunden vor Ablauf dieses Zeitraums kündigst. Verwalten oder künd | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|# $/monat wird jetzt berechnet. das abo verlängert sich auto` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 2.0:1): "Weiter mit VO2+" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|weiter mit vo#+` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Wiederherstellen" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|wiederherstellen` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Bedingungen" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|bedingungen` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Privatsphäre" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|privatsphäre` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Grober Referenzbereich für dein Profil" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|grober referenzbereich für dein profil` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Halte deine stärkste Schätzung sichtbar" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|halte deine stärkste schätzung sichtbar` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Wird automatisch abgerechnet. Jederzeit kündbar." | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|wird automatisch abgerechnet. jederzeit kündbar.` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test1FirstRunToTrial|first-today|heute` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.7:1): "Neueste Schätzung: vor 23 Sekunden. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|test1FirstRunToTrial|first-today|neueste schätzung: vor # sekunden. normalerweise bekommst du` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|test1FirstRunToTrial|first-today|im zielbereich` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.7:1): "Ziel 31–51" | `a11y-contrast|test1FirstRunToTrial|first-today|ziel #–#` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|test1FirstRunToTrial|first-today|cardiofitness-trend` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|test1FirstRunToTrial|first-today|+# über # tage` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|test1FirstRunToTrial|first-today|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|test1FirstRunToTrial|first-today|ruheherzfrequenz` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio-erholung` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.2:1): " " | `a11y-contrast|test1FirstRunToTrial|first-today|` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio-belastung` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 3.7:1): "Min./Woche" | `a11y-contrast|test1FirstRunToTrial|first-today|min./woche` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.7:1): "Neueste Schätzung: jetzt. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|neueste schätzung: jetzt. normalerweise bekommst du alle # t` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|im zielbereich` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.7:1): "Ziel 31–51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|ziel #–#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardiofitness-trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|+# über # tage` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Chronologisches Alter 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|chronologisches alter #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|ruheherzfrequenz` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio-erholung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio-belastung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 3.7:1): "Min./Woche" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|min./woche` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.7:1): "3. Aug. bis 1. Nov. 2026 wird angezeigt" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|#. aug. bis #. nov. # wird angezeigt` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.5:1): "Ziel" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|ziel` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.9:1): "Benutzerdefiniert" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|benutzerdefiniert` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Messwerte" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|messwerte` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Durchschnitt" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|durchschnitt` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Veränderung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|veränderung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "bpm in Ruhe" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|bpm in ruhe` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Wiederherstellen" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|wiederherstellen` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Bedingungen" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|bedingungen` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Privatsphäre" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|privatsphäre` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.8:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 2.7:1): "Weiter mit VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|weiter mit vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.7:1): "79,99 $ pro Jahr wird jetzt berechnet. Das Abo verlängert sich automatisch, wenn du nicht mindestens 24 Stunden vor Ablauf dieses Zeitraums kündigst. Verwalten oder  | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|# $ pro jahr wird jetzt berechnet. das abo verlängert sich a` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Wiederherstellen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|wiederherstellen` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Bedingungen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|bedingungen` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Privatsphäre" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|privatsphäre` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.9:1): "33 % sparen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|# % sparen` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 2.9:1): "Anstelle von 9,99 $/Monat" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|anstelle von # $/monat` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.7:1): "6,67 $/Monat" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|# $/monat` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 3.8:1): " " | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast failed (measured 2.5:1): "Verbunden" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|verbunden` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|apple health aktualisieren` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|apple health öffnen` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.7:1): "Neueste Schätzung: jetzt. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|neueste schätzung: jetzt. normalerweise bekommst du alle # t` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|im zielbereich` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.7:1): "Ziel 31–51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|ziel #–#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardiofitness-trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|+# über # tage` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Chronologisches Alter 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|chronologisches alter #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|ruheherzfrequenz` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio-erholung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio-belastung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 3.7:1): "Min./Woche" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|min./woche` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.7:1): "Neueste Schätzung: jetzt. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|neueste schätzung: jetzt. normalerweise bekommst du alle # t` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|im zielbereich` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.7:1): "Ziel 31–51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|ziel #–#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardiofitness-trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|+# über # tage` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Chronologisches Alter 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|chronologisches alter #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|ruheherzfrequenz` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio-erholung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio-belastung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 3.7:1): "Min./Woche" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|min./woche` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast failed (measured 2.5:1): "Verbunden" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|verbunden` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|apple health aktualisieren` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|apple health öffnen` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|heute` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.7:1): "Neueste Schätzung: vor 17 Sekunden. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|neueste schätzung: vor # sekunden. normalerweise bekommst du` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|im zielbereich` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.7:1): "Ziel 31–70" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|ziel #–#` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardiofitness-trend` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|+# über # tage` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Chronologisches Alter 42" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|chronologisches alter #` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|ruheherzfrequenz` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio-erholung` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio-belastung` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 3.7:1): "Min./Woche" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|min./woche` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast failed (measured 2.5:1): "Verbunden" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|verbunden` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|apple health aktualisieren` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|apple health öffnen` |
| P2 | reduce-motion-ignored |  | all / all | with Reduce Motion on the journeys still moved for 28.4s against 28.6s without it (100%); check which animations ignore it | `reduce-motion-ignored|all|all|` |

## Journeys

| Persona | Journey | Result | Seconds |
|---|---|---|---|
| newcomer | test1FirstRunToTrial | Passed | 53.182072043418884 |
| newcomer | test2TabsUpgradeSettingsAndReturn | Passed | 73.85913395881653 |
| newcomer | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 53.670522928237915 |
| accessibility | test1FirstRunToTrial | Passed | 50.334121108055115 |
| accessibility | test2TabsUpgradeSettingsAndReturn | Passed | 59.39058601856232 |
| accessibility | testCoreLoopTargetRangeDrivesTodayAndPersists | Failed | 24.0593900680542 |
| reduce-motion | test1FirstRunToTrial | Passed | 52.00314998626709 |
| reduce-motion | test2TabsUpgradeSettingsAndReturn | Passed | 74.49890494346619 |
| reduce-motion | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 54.60923099517822 |
| german | test1FirstRunToTrial | Passed | 52.874319076538086 |
| german | test2TabsUpgradeSettingsAndReturn | Passed | 74.4834680557251 |
| german | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 53.869585037231445 |
| duo | test1FirstRunToTrial | Passed | 53.083925008773804 |
| duo | test2TabsUpgradeSettingsAndReturn | Failed | 31.673051953315735 |
| duo | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 45.53863501548767 |

## Motion

| Persona | Motion s | Windows | Candidates | Gaps > 25 ms | 60 fps |
|---|---|---|---|---|---|
| newcomer | 28.588 | 39 | 9 | 69 | True |
| accessibility | 22.253 | 30 | 6 | 46 | True |
| reduce-motion | 28.447 | 39 | 5 | 71 | True |
| german | 28.742 | 38 | 8 | 69 | True |

## Launch entrances to look at

Each launch's frames after the springboard zoom, left to right then down, 4 frames per
row at the recorded rate. A blank stretch, text that reflows, or content that arrives and
pushes the layout is a finding: `qa-gate ledger <repo> add`.

- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/newcomer/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/newcomer/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/newcomer/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/accessibility/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/accessibility/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/accessibility/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-16-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/accessibility/entrance-16-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/reduce-motion/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/reduce-motion/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-11-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/reduce-motion/entrance-11-test2tabsupgradesettingsandreturn.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/german/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/german/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/german/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-16-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/german/entrance-16-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-19-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/b441f5e0b1b8/german/entrance-19-testcorelooptargetrangedrivestodayandpersists.png)

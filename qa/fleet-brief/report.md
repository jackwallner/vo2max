# Release gate: health-ship 212776541e6b

Verdict: **BLOCK** (2026-11-01T16:51:51+00:00)

Every finding blocks except legacy backlog. `qa-gate fix <repo>` fixes them. Motion candidates need a judgement in the ledger: `qa-gate ledger <repo> accept` for an intended change, or `add` a P1 when it is a real glitch.

## Blocking (41)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P1 | overlap | newcomer | test2TabsUpgradeSettingsAndReturn / trends | button "Cardio Recovery, The one-minute fall after a recorded workout ends, VO2+, Locked. Included with VO2+, Locked. Included with VO2+, bpm drop in 1 min, How far your heart rate falls in the minute after a workout, trended across the range you pick." overlaps "Today" by 79% | `overlap|test2TabsUpgradeSettingsAndReturn|trends|cardio recovery, the one-minute fall after a recorded workou` |
| P1 | overlap | german | test2TabsUpgradeSettingsAndReturn / trends | button "Ruheherzfrequenz, Wird im Hintergrund erfasst, während du die Apple Watch trägst, VO2+, Gesperrt. In VO2+ enthalten, Gesperrt. In VO2+ enthalten, bpm in Ruhe, Neuester, durchschnittlicher, niedrigster und höchster Wert sowie die Veränderung gegenüber dem vorherigen Zeitraum, über 30 Tage, 90 Tage, 6 Monate oder 1 Jahr." overlaps "Heute" by 30% | `overlap|test2TabsUpgradeSettingsAndReturn|trends|heute / ruheherzfrequenz, wird im hintergrund erfasst, währe` |
| P1 | overlap | german | test2TabsUpgradeSettingsAndReturn / trends | button "Ruheherzfrequenz, Wird im Hintergrund erfasst, während du die Apple Watch trägst, VO2+, Gesperrt. In VO2+ enthalten, Gesperrt. In VO2+ enthalten, bpm in Ruhe, Neuester, durchschnittlicher, niedrigster und höchster Wert sowie die Veränderung gegenüber dem vorherigen Zeitraum, über 30 Tage, 90 Tage, 6 Monate oder 1 Jahr." overlaps "Trends" by 30% | `overlap|test2TabsUpgradeSettingsAndReturn|trends|ruheherzfrequenz, wird im hintergrund erfasst, während du di` |
| P2 | a11y-contrast | german,newcomer,reduce-motion | checkpoint(_:button:in:) / target | Contrast failed (measured 2.2:1): "31-51" | `a11y-contrast|checkpoint(_:button:in:)|target|#-#` |
| P2 | a11y-contrast | newcomer,reduce-motion | checkpoint(_:button:in:) / target | Contrast nearly passed (measured 3.5:1): "Typical for your profile: 31-51 mL/kg/min" | `a11y-contrast|checkpoint(_:button:in:)|target|typical for your profile: #-# ml/kg/min` |
| P2 | a11y-contrast | newcomer,reduce-motion | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Direction and broad timeframe toward your target" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|direction and broad timeframe toward your target` |
| P2 | a11y-contrast | newcomer,reduce-motion | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Broad typical-range context for your profile" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|broad typical-range context for your profile` |
| P2 | a11y-contrast | newcomer,reduce-motion | test1FirstRunToTrial / first-today | Contrast failed (measured 1.7:1): "Target 31-51" | `a11y-contrast|test1FirstRunToTrial|first-today|target #-#` |
| P2 | a11y-contrast | newcomer,reduce-motion | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Used to calculate this broad estimate" | `a11y-contrast|test1FirstRunToTrial|first-today|used to calculate this broad estimate` |
| P2 | a11y-contrast | newcomer,reduce-motion | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.7:1): "Target 31-51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|target #-#` |
| P2 | a11y-contrast | newcomer,reduce-motion | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Apple Health estimates · Aug 3 to Nov 1, 2026" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|apple health estimates · aug # to nov #, #` |
| P2 | a11y-contrast | newcomer,reduce-motion | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.0:1): "Continue with VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|continue with vo#+` |
| P2 | a11y-contrast | german,newcomer,reduce-motion | test2TabsUpgradeSettingsAndReturn / settings | Contrast failed (measured 2.2:1): "31-51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|#-#` |
| P2 | a11y-contrast | newcomer,reduce-motion | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.4:1): "Broad typical range for your current profile: 35-47 mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|broad typical range for your current profile: #-# ml/kg/min` |
| P2 | a11y-contrast | newcomer,reduce-motion | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.7:1): "Target 31-51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|target #-#` |
| P2 | a11y-contrast | newcomer,reduce-motion | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.7:1): "Target 31-51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|target #-#` |
| P2 | a11y-contrast | german,newcomer,reduce-motion | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast failed (measured 2.2:1): "31-70" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|#-#` |
| P2 | a11y-contrast | newcomer,reduce-motion | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.4:1): "Broad typical range for your current profile: 35-47 mL/kg/min" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|broad typical range for your current profile: #-# ml/kg/min` |
| P2 | a11y-contrast | newcomer,reduce-motion | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.7:1): "Target 31-70" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|target #-#` |
| P2 | a11y-contrast | german,newcomer,reduce-motion | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast failed (measured 2.2:1): "31-70" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|#-#` |
| P2 | a11y-contrast | newcomer,reduce-motion | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.4:1): "Broad typical range for your current profile: 35-47 mL/kg/min" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|broad typical range for your current profile: #-# ml/kg/min` |
| P2 | overlap | accessibility | checkpoint(_:button:in:) / welcome | text "We'll ask permission to read your VO2 max estimates. We never write to Apple Health." overlaps "Read-only. Stays on your device. No account." by 97% (AX3 text only) | `overlap|checkpoint(_:button:in:)|welcome|read-only. stays on your device. no account. / we'll ask per` |
| P2 | clipped | accessibility | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | text drawn as "31-7" but reads "31-70", cut off with no ellipsis (AX3 text only) | `clipped|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|#-#` |
| P2 | clipped | accessibility | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | text "mL/kg/min" is broken across 2 lines: mL/kg/ / min (AX3 text only) | `clipped|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|ml/kg/min` |
| P2 | clipped | accessibility | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | text drawn as "31-7" but reads "31-70", cut off with no ellipsis (AX3 text only) | `clipped|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|#-#` |
| P2 | clipped | accessibility | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | text "mL/kg/min" is broken across 2 lines: mL/kg/ / min (AX3 text only) | `clipped|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|ml/kg/min` |
| P2 | a11y-contrast | german | checkpoint(_:button:in:) / target | Contrast nearly passed (measured 3.5:1): "Typisch für dein Profil: 31-51 mL/kg/min" | `a11y-contrast|checkpoint(_:button:in:)|target|typisch für dein profil: #-# ml/kg/min` |
| P2 | a11y-hit-region | german | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Datenschutz" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|datenschutz` |
| P2 | a11y-contrast | german | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Datenschutz" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|datenschutz` |
| P2 | a11y-contrast | german | test1FirstRunToTrial / first-today | Contrast failed (measured 1.7:1): "Ziel 31-51" | `a11y-contrast|test1FirstRunToTrial|first-today|ziel #-#` |
| P2 | a11y-contrast | german | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Geht in diese grobe Schätzung ein" | `a11y-contrast|test1FirstRunToTrial|first-today|geht in diese grobe schätzung ein` |
| P2 | a11y-contrast | german | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.7:1): "Ziel 31-51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|ziel #-#` |
| P2 | a11y-contrast | german | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Apple Health-Schätzungen · 3. Aug. bis 1. Nov. 2026" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|apple health-schätzungen · #. aug. bis #. nov. #` |
| P2 | a11y-contrast | german | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.9:1): "Eigene" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|eigene` |
| P2 | a11y-contrast | german | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.0:1): "Weiter mit VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|weiter mit vo#+` |
| P2 | a11y-hit-region | german | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Datenschutz" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|datenschutz` |
| P2 | a11y-contrast | german | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Datenschutz" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|datenschutz` |
| P2 | a11y-contrast | german | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Zusätzliche Einordnungen zu deinen Apple Health-Schätzungen." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|zusätzliche einordnungen zu deinen apple health-schätzungen.` |
| P2 | a11y-contrast | german | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.7:1): "Ziel 31-51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|ziel #-#` |
| P2 | a11y-contrast | german | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.7:1): "Ziel 31-51" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|ziel #-#` |
| P2 | a11y-contrast | german | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.7:1): "Ziel 31-70" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|ziel #-#` |

## Needs a judgement (0)

None.

## Legacy backlog, warns until fixed (224)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / profile | Contrast failed (measured 2.2:1): "35" | `a11y-contrast|checkpoint(_:button:in:)|profile|#` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / profile | Contrast failed (measured 2.0:1): "Continue" | `a11y-contrast|checkpoint(_:button:in:)|profile|continue` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / profile | Contrast failed (measured 2.0:1): "Weiter" | `a11y-contrast|checkpoint(_:button:in:)|profile|weiter` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / target | Contrast failed (measured 2.0:1): "Continue" | `a11y-contrast|checkpoint(_:button:in:)|target|continue` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / target | Contrast failed (measured 2.0:1): "Weiter" | `a11y-contrast|checkpoint(_:button:in:)|target|weiter` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / welcome | Contrast failed (measured 2.0:1): "Continue" | `a11y-contrast|checkpoint(_:button:in:)|welcome|continue` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / welcome | Contrast failed (measured 1.7:1): "Nur lesend. Bleibt auf deinem Gerät. Kein Konto." | `a11y-contrast|checkpoint(_:button:in:)|welcome|nur lesend. bleibt auf deinem gerät. kein konto.` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / welcome | Contrast failed (measured 1.7:1): "Read-only. Stays on your device. No account." | `a11y-contrast|checkpoint(_:button:in:)|welcome|read-only. stays on your device. no account.` |
| P2 | a11y-contrast |  | checkpoint(_:button:in:) / welcome | Contrast failed (measured 2.0:1): "Weiter" | `a11y-contrast|checkpoint(_:button:in:)|welcome|weiter` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|test1FirstRunToTrial|first-today|+# over # days` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|test1FirstRunToTrial|first-today|+# über # tage` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|test1FirstRunToTrial|first-today|bpm` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio fitness trend` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio load` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio recovery` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio-belastung` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|test1FirstRunToTrial|first-today|cardio-erholung` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|test1FirstRunToTrial|first-today|cardiofitness-trend` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|test1FirstRunToTrial|first-today|fitness age estimate` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|test1FirstRunToTrial|first-today|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test1FirstRunToTrial|first-today|heute` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|test1FirstRunToTrial|first-today|im zielbereich` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|test1FirstRunToTrial|first-today|in target range` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.7:1): "Latest estimate 24 seconds ago. You usually get one every 6 days." | `a11y-contrast|test1FirstRunToTrial|first-today|latest estimate # seconds ago. you usually get one every # d` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.7:1): "Min./Woche" | `a11y-contrast|test1FirstRunToTrial|first-today|min./woche` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|test1FirstRunToTrial|first-today|min/week` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test1FirstRunToTrial|first-today|ml/kg/min` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.7:1): "Neueste Schätzung: vor 23 Sekunden. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|test1FirstRunToTrial|first-today|neueste schätzung: vor # sekunden. normalerweise bekommst du` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|test1FirstRunToTrial|first-today|resting heart rate` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|test1FirstRunToTrial|first-today|ruheherzfrequenz` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test1FirstRunToTrial|first-today|today` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test1FirstRunToTrial|first-today|trends` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / first-today | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|test1FirstRunToTrial|first-today|vo#+` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "9,99 $/Monat wird jetzt berechnet. Das Abo verlängert sich automatisch, wenn du nicht mindestens 24 Stunden vor Ablauf dieses Zeitraums kündigst. Verwalten oder künd | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|# $/monat wird jetzt berechnet. das abo verlängert sich auto` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "$9.99 per month is charged now. It renews automatically unless you cancel at least 24 hours before this period ends. Manage or cancel in Settings > Apple ID > Subscr | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|$# per month is charged now. it renews automatically unless ` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Bedingungen" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|bedingungen` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Billed automatically. Cancel anytime." | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|billed automatically. cancel anytime.` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 2.0:1): "Continue with VO2+" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|continue with vo#+` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Get Started" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|get started` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Grober Referenzbereich für dein Profil" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|grober referenzbereich für dein profil` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Halte deine stärkste Schätzung sichtbar" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|halte deine stärkste schätzung sichtbar` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Keep your strongest estimate visible" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|keep your strongest estimate visible` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Los geht's" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|los geht's` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Privacy" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|privacy` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Restore" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|restore` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Terms" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|terms` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 2.0:1): "Weiter mit VO2+" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|weiter mit vo#+` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast failed (measured 1.7:1): "Wiederherstellen" | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|wiederherstellen` |
| P2 | a11y-contrast |  | test1FirstRunToTrial / onboarding-trial | Contrast nearly passed (measured 3.4:1): "Wird automatisch abgerechnet. Jederzeit kündbar." | `a11y-contrast|test1FirstRunToTrial|onboarding-trial|wird automatisch abgerechnet. jederzeit kündbar.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|apple health aktualisieren` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|apple health öffnen` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast failed (measured 2.5:1): "Connected" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|connected` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|ml/kg/min` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|open apple health` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|refresh apple health` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast failed (measured 2.5:1): "Verbunden" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|verbunden` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|+# over # days` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|+# über # tage` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|bpm` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio fitness trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio load` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio recovery` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio-belastung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardio-erholung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|cardiofitness-trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Chronological age 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|chronological age #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Chronologisches Alter 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|chronologisches alter #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|fitness age estimate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|im zielbereich` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|in target range` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.7:1): "Latest estimate now. You usually get one every 6 days." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|latest estimate now. you usually get one every # days.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.7:1): "Min./Woche" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|min./woche` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|min/week` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|ml/kg/min` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.7:1): "Neueste Schätzung: jetzt. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|neueste schätzung: jetzt. normalerweise bekommst du alle # t` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|resting heart rate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|ruheherzfrequenz` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|trends` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-background | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-background|vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|+# over # days` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|+# über # tage` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|bpm` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio fitness trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio load` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio recovery` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio-belastung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardio-erholung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|cardiofitness-trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Chronological age 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|chronological age #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Chronologisches Alter 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|chronologisches alter #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|fitness age estimate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|im zielbereich` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|in target range` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.7:1): "Latest estimate now. You usually get one every 6 days." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|latest estimate now. you usually get one every # days.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.7:1): "Min./Woche" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|min./woche` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|min/week` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|ml/kg/min` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.7:1): "Neueste Schätzung: jetzt. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|neueste schätzung: jetzt. normalerweise bekommst du alle # t` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|resting heart rate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|ruheherzfrequenz` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|trends` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today-after-relaunch | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today-after-relaunch|vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|+# over # days` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|+# über # tage` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|bpm` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio fitness trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio load` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio recovery` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio-belastung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardio-erholung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|cardiofitness-trend` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Chronological age 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|chronological age #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Chronologisches Alter 42" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|chronologisches alter #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|fitness age estimate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|im zielbereich` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|in target range` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.7:1): "Latest estimate now. You usually get one every 6 days." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|latest estimate now. you usually get one every # days.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.7:1): "Min./Woche" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|min./woche` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|min/week` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|ml/kg/min` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.7:1): "Neueste Schätzung: jetzt. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|neueste schätzung: jetzt. normalerweise bekommst du alle # t` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|resting heart rate` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|ruheherzfrequenz` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|trends` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / today | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|today|vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.7:1): "3. Aug. bis 1. Nov. 2026 wird angezeigt" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|#. aug. bis #. nov. # wird angezeigt` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.5:1): "+1.0" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|+#` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Average" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|average` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "bpm at rest" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|bpm at rest` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "bpm in Ruhe" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|bpm in ruhe` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Change" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|change` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.9:1): "Custom" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|custom` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Durchschnitt" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|durchschnitt` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.7:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Messwerte" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|messwerte` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Readings" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|readings` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.7:1): "Showing Aug 3 to Nov 1, 2026" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|showing aug # to nov #, #` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.5:1): "Target" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|target` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.8:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast nearly passed (measured 3.7:1): "Veränderung" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|veränderung` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 1.7:1): "VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / trends | Contrast failed (measured 2.5:1): "Ziel" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|trends|ziel` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.7:1): "79,99 $ pro Jahr wird jetzt berechnet. Das Abo verlängert sich automatisch, wenn du nicht mindestens 24 Stunden vor Ablauf dieses Zeitraums kündigst. Verwalten oder  | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|# $ pro jahr wird jetzt berechnet. das abo verlängert sich a` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.7:1): "6,67 $/Monat" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|# $/monat` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.9:1): "33 % sparen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|# % sparen` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.7:1): "$6.67 per month" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|$# per month` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.7:1): "$79.99 per year is charged now. It renews automatically unless you cancel at least 24 hours before this period ends. Manage or cancel in Settings > Apple ID > Subscr | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|$# per year is charged now. it renews automatically unless y` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 2.9:1): "Anstelle von 9,99 $/Monat" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|anstelle von # $/monat` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Bedingungen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|bedingungen` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 2.7:1): "Continue with VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|continue with vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Extras that sit on top of your Apple Health estimates." | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|extras that sit on top of your apple health estimates.` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.8:1): "Heute" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|heute` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 2.9:1): "Instead of $9.99 per month" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|instead of $# per month` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Privacy" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|privacy` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Restore" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|restore` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.9:1): "Save 33%" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|save #%` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Terms" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|terms` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.8:1): "Today" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|today` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|trends` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast failed (measured 2.7:1): "Weiter mit VO2+" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|weiter mit vo#+` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / upgrade | Contrast nearly passed (measured 3.4:1): "Wiederherstellen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|upgrade|wiederherstellen` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|apple health aktualisieren` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|apple health öffnen` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast failed (measured 2.5:1): "Connected" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|connected` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|ml/kg/min` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|open apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|refresh apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast failed (measured 2.5:1): "Verbunden" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|verbunden` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|apple health aktualisieren` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|apple health öffnen` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast failed (measured 2.5:1): "Connected" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|connected` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|ml/kg/min` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|open apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|refresh apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast failed (measured 2.5:1): "Verbunden" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|verbunden` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "+1.0 over 90 days" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|+# over # days` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "+1,0 über 90 Tage" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|+# über # tage` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 3.7:1): "bpm" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|bpm` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Cardio fitness trend" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio fitness trend` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Cardio Load" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio load` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Cardio Recovery" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio recovery` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Cardio-Belastung" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio-belastung` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Cardio-Erholung" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardio-erholung` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Cardiofitness-Trend" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|cardiofitness-trend` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Chronological age 42" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|chronological age #` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Chronologisches Alter 42" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|chronologisches alter #` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Fitness age estimate" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|fitness age estimate` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Fitnessalter-Schätzung" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|fitnessalter-schätzung` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.1:1): "Heute" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|heute` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.5:1): "Im Zielbereich" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|im zielbereich` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.5:1): "In target range" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|in target range` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.7:1): "Latest estimate 19 seconds ago. You usually get one every 6 days." | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|latest estimate # seconds ago. you usually get one every # d` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.7:1): "Min./Woche" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|min./woche` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 3.7:1): "min/week" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|min/week` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast nearly passed (measured 3.4:1): "mL/kg/min" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|ml/kg/min` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.7:1): "Neueste Schätzung: vor 23 Sekunden. Normalerweise bekommst du alle 6 Tage eine neue." | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|neueste schätzung: vor # sekunden. normalerweise bekommst du` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Resting Heart Rate" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|resting heart rate` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.2:1): "Ruheherzfrequenz" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|ruheherzfrequenz` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 2.1:1): "Today" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|today` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.8:1): "Trends" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|trends` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / today-new-target | Contrast failed (measured 1.8:1): "VO2+" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|today-new-target|vo#+` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Bedingungen" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|bedingungen` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Get Started" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|get started` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Los geht's" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|los geht's` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Privacy" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|privacy` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Restore" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|restore` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Terms" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|terms` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Wiederherstellen" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|wiederherstellen` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Bedingungen" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|bedingungen` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Privacy" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|privacy` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Restore" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|restore` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Terms" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|terms` |
| P2 | a11y-hit-region |  | test2TabsUpgradeSettingsAndReturn / upgrade | Hit area is too small: "Wiederherstellen" | `a11y-hit-region|test2TabsUpgradeSettingsAndReturn|upgrade|wiederherstellen` |
| P2 | reduce-motion-ignored |  | all / all | with Reduce Motion on the journeys still moved for 27.8s against 29.2s without it (95%); check which animations ignore it | `reduce-motion-ignored|all|all|` |
| P3 | a11y-element-detection |  | test2TabsUpgradeSettingsAndReturn / trends | Potentially inaccessible text | `a11y-element-detection|test2TabsUpgradeSettingsAndReturn|trends|` |

## Journeys

| Persona | Journey | Result | Seconds |
|---|---|---|---|
| newcomer | test1FirstRunToTrial | Passed | 54.48567199707031 |
| newcomer | test2TabsUpgradeSettingsAndReturn | Passed | 95.88447606563568 |
| newcomer | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 60.23511600494385 |
| accessibility | test1FirstRunToTrial | Passed | 54.01747107505798 |
| accessibility | test2TabsUpgradeSettingsAndReturn | Passed | 65.9909360408783 |
| accessibility | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 52.03971493244171 |
| reduce-motion | test1FirstRunToTrial | Passed | 52.857598066329956 |
| reduce-motion | test2TabsUpgradeSettingsAndReturn | Passed | 80.63077306747437 |
| reduce-motion | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 61.7838180065155 |
| german | test1FirstRunToTrial | Passed | 53.15426409244537 |
| german | test2TabsUpgradeSettingsAndReturn | Passed | 79.3765219449997 |
| german | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 66.0096869468689 |
| duo | test1FirstRunToTrial | Passed | 55.68505108356476 |
| duo | test2TabsUpgradeSettingsAndReturn | Passed | 100.89927589893341 |
| duo | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 47.47563302516937 |

## Motion

| Persona | Motion s | Windows | Candidates | Gaps > 25 ms | 60 fps |
|---|---|---|---|---|---|
| newcomer | 29.246 | 39 | 9 | 80 | True |
| accessibility | 33.377 | 40 | 7 | 94 | True |
| reduce-motion | 27.848 | 38 | 5 | 65 | True |
| german | 27.96 | 37 | 8 | 65 | True |

## Launch entrances to look at

Each launch's frames after the springboard zoom, left to right then down, 4 frames per
row at the recorded rate. A blank stretch, text that reflows, or content that arrives and
pushes the layout is a finding: `qa-gate ledger <repo> add`.

- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/newcomer/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/newcomer/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-11-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/newcomer/entrance-11-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/newcomer/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/accessibility/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/accessibility/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/accessibility/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-16-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/accessibility/entrance-16-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-19-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/accessibility/entrance-19-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/reduce-motion/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/reduce-motion/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/reduce-motion/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-16-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/reduce-motion/entrance-16-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-19-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/reduce-motion/entrance-19-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/german/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/german/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/german/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-16-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/german/entrance-16-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-19-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/212776541e6b/german/entrance-19-testcorelooptargetrangedrivestodayandpersists.png)

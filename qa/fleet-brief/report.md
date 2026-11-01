# Release gate: health-ship 771fccf0c7bb

Verdict: **BLOCK** (2026-11-01T18:42:24+00:00)

Every finding blocks except legacy backlog. `qa-gate fix <repo>` fixes them. Motion candidates need a judgement in the ledger: `qa-gate ledger <repo> accept` for an intended change, or `add` a P1 when it is a real glitch.

## Blocking (2)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P1 | overlap | german | test2TabsUpgradeSettingsAndReturn / trends | button "Cardio-Erholung, Herzfrequenzabfall in der ersten Minute nach Trainingsende, VO2+, Gesperrt. In VO2+ enthalten, Gesperrt. In VO2+ enthalten, Herzfrequenzabfall in 1 Min., Wie stark deine Herzfrequenz in der ersten Minute nach einem Training sinkt, im Verlauf des ausgewählten Zeitraums." overlaps "VO2+" by 42% | `overlap|test2TabsUpgradeSettingsAndReturn|trends|cardio-erholung, herzfrequenzabfall in der ersten minute nac` |
| P1 | overlap | duo | test2TabsUpgradeSettingsAndReturn / upgrade | button "Yearly, Save 33%,  , $79.99 per year, Instead of $9.99 per month, $6.67 per month" overlaps "Continue with VO2+" by 91% | `overlap|test2TabsUpgradeSettingsAndReturn|upgrade|continue with vo#+ / yearly, save #%, , $# per year, instead` |

## Needs a judgement (1)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P1 | motion-jump | newcomer | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | jump candidate at 238.22s of journeys.mp4 (score 0.39) ([sheet](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/newcomer/journeys.event-08.png)) | `motion-jump|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|` |

## Legacy backlog, warns until fixed (16)

| Sev | Oracle | Persona | Journey / checkpoint | Detail | Fingerprint |
|---|---|---|---|---|---|
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|apple health aktualisieren` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|apple health öffnen` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|open apple health` |
| P2 | a11y-contrast |  | test2TabsUpgradeSettingsAndReturn / settings | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|test2TabsUpgradeSettingsAndReturn|settings|refresh apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|apple health aktualisieren` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|apple health öffnen` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|open apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-after-relaunch | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-after-relaunch|refresh apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Apple Health aktualisieren" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|apple health aktualisieren` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Apple Health öffnen" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|apple health öffnen` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Open Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|open apple health` |
| P2 | a11y-contrast |  | testCoreLoopTargetRangeDrivesTodayAndPersists / target-widened | Contrast nearly passed (measured 3.5:1): "Refresh Apple Health" | `a11y-contrast|testCoreLoopTargetRangeDrivesTodayAndPersists|target-widened|refresh apple health` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Get Started" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|get started` |
| P2 | a11y-hit-region |  | test1FirstRunToTrial / onboarding-trial | Hit area is too small: "Los geht's" | `a11y-hit-region|test1FirstRunToTrial|onboarding-trial|los geht's` |
| P2 | reduce-motion-ignored |  | all / all | with Reduce Motion on the journeys still moved for 27.6s against 29.5s without it (94%); check which animations ignore it | `reduce-motion-ignored|all|all|` |
| P3 | a11y-element-detection |  | test2TabsUpgradeSettingsAndReturn / trends | Potentially inaccessible text | `a11y-element-detection|test2TabsUpgradeSettingsAndReturn|trends|` |

## Journeys

| Persona | Journey | Result | Seconds |
|---|---|---|---|
| newcomer | test1FirstRunToTrial | Passed | 55.89678597450256 |
| newcomer | test2TabsUpgradeSettingsAndReturn | Passed | 70.36028301715851 |
| newcomer | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 53.444743037223816 |
| accessibility | test1FirstRunToTrial | Passed | 50.65683603286743 |
| accessibility | test2TabsUpgradeSettingsAndReturn | Passed | 62.36490297317505 |
| accessibility | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 51.87494993209839 |
| reduce-motion | test1FirstRunToTrial | Passed | 53.82072699069977 |
| reduce-motion | test2TabsUpgradeSettingsAndReturn | Passed | 68.90823698043823 |
| reduce-motion | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 54.82720100879669 |
| german | test1FirstRunToTrial | Passed | 55.815346002578735 |
| german | test2TabsUpgradeSettingsAndReturn | Passed | 66.13574993610382 |
| german | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 52.01818406581879 |
| duo | test1FirstRunToTrial | Passed | 52.0419499874115 |
| duo | test2TabsUpgradeSettingsAndReturn | Passed | 81.42450201511383 |
| duo | testCoreLoopTargetRangeDrivesTodayAndPersists | Passed | 43.804598927497864 |

## Motion

| Persona | Motion s | Windows | Candidates | Gaps > 25 ms | 60 fps |
|---|---|---|---|---|---|
| newcomer | 29.54 | 40 | 8 | 81 | True |
| accessibility | 33.597 | 40 | 7 | 94 | True |
| reduce-motion | 27.624 | 39 | 5 | 64 | True |
| german | 28.512 | 35 | 8 | 68 | True |

## Launch entrances to look at

Each launch's frames after the springboard zoom, left to right then down, 4 frames per
row at the recorded rate. A blank stretch, text that reflows, or content that arrives and
pushes the layout is a finding: `qa-gate ledger <repo> add`.

- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/newcomer/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/newcomer/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/newcomer/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-16-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/newcomer/entrance-16-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-19-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/newcomer/entrance-19-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/accessibility/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/accessibility/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/accessibility/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-16-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/accessibility/entrance-16-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-19-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/accessibility/entrance-19-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/reduce-motion/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/reduce-motion/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/reduce-motion/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-01-test1firstruntotrial.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/german/entrance-01-test1firstruntotrial.png)
- [entrance-07-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/german/entrance-07-test2tabsupgradesettingsandreturn.png)
- [entrance-14-test2tabsupgradesettingsandreturn.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/german/entrance-14-test2tabsupgradesettingsandreturn.png)
- [entrance-16-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/german/entrance-16-testcorelooptargetrangedrivestodayandpersists.png)
- [entrance-19-testcorelooptargetrangedrivestodayandpersists.png](/Users/jackwallner/health-ship/build/qa/771fccf0c7bb/german/entrance-19-testcorelooptargetrangedrivestodayandpersists.png)

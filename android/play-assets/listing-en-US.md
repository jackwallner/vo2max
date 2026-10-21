# VO2 Max: Google Play listing

Title, short and full description per locale live in `metadata/android/<locale>/`
(fastlane supply layout). en-US is the live listing, unchanged. 50 locales:
en-US, en-GB/AU/CA/IN, de-DE, fr-FR/CA, es-ES/419/US, pt-BR/PT, it-IT, nl-NL,
sv-SE, no-NO, da-DK, fi-FI, pl-PL, cs-CZ, sk, sl, hr, hu-HU, ro, el-GR, tr-TR,
ru-RU, uk, ar, iw-IL, hi-IN, bn-BD, mr-IN, ta-IN, te-IN, kn-IN, ml-IN, id, ms,
ms-MY, th, vi, ja-JP, ko-KR, zh-CN/TW/HK, ca.

Search terms per locale come from the iOS `fastlane/metadata` names and keywords.
Every non-English description says the app is in English (the Android app is not
localized). No prices, no em dashes, no medical claims. Check with
`scripts/validate-play-listing.py`. Not uploaded to Play yet.

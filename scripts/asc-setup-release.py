#!/usr/bin/env python3
"""Idempotently prepare VO2 Max 1.0 metadata, rating, IAP, and review info."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import asc_lib

BUNDLE = "com.jackwallner.vo2max"
PRODUCT_ID = "com.jackwallner.vo2max.pro.lifetime"
PRODUCT_NAME = "VO2 Max Pro Lifetime"
PRODUCT_DESCRIPTION = "Unlock VO2 Max Pro forever. One payment."
PRICE = "29.99"

REVIEW_NOTES = """VO2 Max Daily Tracker is a read-only Apple Health cardio fitness viewer.

No account or login is required. On first launch, connect Apple Health. The app requests read access to Cardio Fitness (VO2 max) and never writes Health data. If the review device has no sample, the app intentionally shows instructions for recording a qualifying outdoor Apple Watch workout.

The app displays the latest Apple Health estimate, a personal target range, trend history, widgets, Watch complications, and a clearly labeled broad fitness-age estimate. It makes no diagnostic or treatment claims.

VO2 Max Pro offers monthly and yearly auto-renewable subscriptions with a 7-day free trial for eligible new subscribers, plus an optional one-time lifetime non-consumable. Terms, renewal disclosure, privacy, and restore controls appear at the purchase point. The app does not use non-exempt encryption."""


def main() -> None:
    client = asc_lib.ASCClient(asc_lib.bearer_token(*asc_lib.load_credentials()))
    app = asc_lib.find_app(client, BUNDLE)
    app_id = app["id"]
    print(f"app {app_id}")

    info = asc_lib.find_editable_app_info(client, app_id)
    if not info:
        raise SystemExit("error: editable appInfo not found")

    client.patch(
        f"/appInfos/{info['id']}",
        {
            "data": {
                "type": "appInfos",
                "id": info["id"],
                "relationships": {
                    "primaryCategory": {"data": {"type": "appCategories", "id": "HEALTH_AND_FITNESS"}},
                    "secondaryCategory": {"data": {"type": "appCategories", "id": "LIFESTYLE"}},
                },
            }
        },
    )
    print("categories set")

    declaration = client.get(f"/appInfos/{info['id']}/ageRatingDeclaration").get("data")
    if declaration:
        attrs = {
            "advertising": False,
            "alcoholTobaccoOrDrugUseOrReferences": "NONE",
            "contests": "NONE",
            "gambling": False,
            "gamblingSimulated": "NONE",
            "gunsOrOtherWeapons": "NONE",
            "healthOrWellnessTopics": True,
            "lootBox": False,
            "medicalOrTreatmentInformation": "NONE",
            "messagingAndChat": False,
            "parentalControls": False,
            "profanityOrCrudeHumor": "NONE",
            "ageAssurance": False,
            "sexualContentGraphicAndNudity": "NONE",
            "sexualContentOrNudity": "NONE",
            "horrorOrFearThemes": "NONE",
            "matureOrSuggestiveThemes": "NONE",
            "unrestrictedWebAccess": False,
            "userGeneratedContent": False,
            "violenceCartoonOrFantasy": "NONE",
            "violenceRealisticProlongedGraphicOrSadistic": "NONE",
            "violenceRealistic": "NONE",
        }
        client.patch(
            f"/ageRatingDeclarations/{declaration['id']}",
            {"data": {"type": "ageRatingDeclarations", "id": declaration["id"], "attributes": attrs}},
        )
        print("age rating set")

    territories = [item["id"] for item in asc_lib.list_all(client, "/territories?limit=200")]
    iaps = asc_lib.list_all(client, f"/apps/{app_id}/inAppPurchasesV2")
    iap = next((item for item in iaps if item["attributes"].get("productId") == PRODUCT_ID), None)
    if not iap:
        asc_lib.API = "https://api.appstoreconnect.apple.com/v2"
        iap = client.post(
            "/inAppPurchases",
            {
                "data": {
                    "type": "inAppPurchases",
                    "attributes": {
                        "name": PRODUCT_NAME,
                        "productId": PRODUCT_ID,
                        "inAppPurchaseType": "NON_CONSUMABLE",
                        "reviewNote": "One-time purchase that unlocks VO2 Max Pro forever.",
                    },
                    "relationships": {"app": {"data": {"type": "apps", "id": app_id}}},
                }
            },
        )["data"]
        asc_lib.API = "https://api.appstoreconnect.apple.com/v1"
        print("lifetime IAP created")
    iap_id = iap["id"]

    asc_lib.API = "https://api.appstoreconnect.apple.com/v2"
    existing_locs = asc_lib.list_all(client, f"/inAppPurchases/{iap_id}/inAppPurchaseLocalizations")
    asc_lib.API = "https://api.appstoreconnect.apple.com/v1"
    existing_locales = {item["attributes"].get("locale") for item in existing_locs}
    locales = json.loads((Path(__file__).parent / "asc-supported-locales.json").read_text())["locales"]
    for locale in locales:
        if locale in existing_locales:
            continue
        client.post(
            "/inAppPurchaseLocalizations",
            {
                "data": {
                    "type": "inAppPurchaseLocalizations",
                    "attributes": {
                        "locale": locale,
                        "name": PRODUCT_NAME,
                        "description": PRODUCT_DESCRIPTION,
                    },
                    "relationships": {"inAppPurchaseV2": {"data": {"type": "inAppPurchases", "id": iap_id}}},
                }
            },
        )
    print(f"IAP localizations set for {len(locales)} locales")

    try:
        asc_lib.API = "https://api.appstoreconnect.apple.com/v2"
        client.get(f"/inAppPurchases/{iap_id}/iapPriceSchedule")
        schedule_exists = True
    except RuntimeError:
        schedule_exists = False
    try:
        points = asc_lib.list_all(client, f"/inAppPurchases/{iap_id}/pricePoints?filter[territory]=USA&limit=200")
        point = next((item for item in points if item["attributes"].get("customerPrice") == PRICE), None)
        if not point:
            raise SystemExit(f"error: USA price point {PRICE} unavailable")
        asc_lib.API = "https://api.appstoreconnect.apple.com/v1"
        client.post(
            "/inAppPurchasePriceSchedules",
            {
                "data": {
                    "type": "inAppPurchasePriceSchedules",
                    "relationships": {
                        "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                        "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                        "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${price0}"}]},
                    },
                },
                "included": [
                    {
                        "type": "inAppPurchasePrices",
                        "id": "${price0}",
                        "attributes": {"startDate": None},
                        "relationships": {
                            "inAppPurchasePricePoint": {"data": {"type": "inAppPurchasePricePoints", "id": point["id"]}}
                        },
                    }
                ],
            },
        )
        print(f"IAP price {'updated' if schedule_exists else 'set'} ${PRICE}")
    finally:
        asc_lib.API = "https://api.appstoreconnect.apple.com/v1"

    try:
        asc_lib.API = "https://api.appstoreconnect.apple.com/v2"
        client.get(f"/inAppPurchases/{iap_id}/inAppPurchaseAvailability")
        print("IAP availability exists")
    except RuntimeError:
        asc_lib.API = "https://api.appstoreconnect.apple.com/v1"
        client.post(
            "/inAppPurchaseAvailabilities",
            {
                "data": {
                    "type": "inAppPurchaseAvailabilities",
                    "attributes": {"availableInNewTerritories": True},
                    "relationships": {
                        "inAppPurchase": {"data": {"type": "inAppPurchases", "id": iap_id}},
                        "availableTerritories": {"data": [{"type": "territories", "id": item} for item in territories]},
                    },
                }
            },
        )
        print(f"IAP available in {len(territories)} territories")
    finally:
        asc_lib.API = "https://api.appstoreconnect.apple.com/v1"

    version = asc_lib.find_version_by_string(client, app_id, "1.0")
    if not version:
        raise SystemExit("error: draft version 1.0 not found")
    client.patch(
        f"/appStoreVersions/{version['id']}",
        {
            "data": {
                "type": "appStoreVersions",
                "id": version["id"],
                "attributes": {"copyright": "2026 Jack Wallner"},
            }
        },
    )
    detail = client.get(f"/appStoreVersions/{version['id']}/appStoreReviewDetail").get("data")
    attrs = {
        "contactFirstName": "Jack",
        "contactLastName": "Wallner",
        "contactPhone": "14257533411",
        "contactEmail": "jackwallner@gmail.com",
        "demoAccountRequired": False,
        "notes": REVIEW_NOTES,
    }
    if detail:
        client.patch(
            f"/appStoreReviewDetails/{detail['id']}",
            {"data": {"type": "appStoreReviewDetails", "id": detail["id"], "attributes": attrs}},
        )
    else:
        client.post(
            "/appStoreReviewDetails",
            {
                "data": {
                    "type": "appStoreReviewDetails",
                    "attributes": attrs,
                    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version["id"]}}},
                }
            },
        )
    print("review information set")


if __name__ == "__main__":
    main()

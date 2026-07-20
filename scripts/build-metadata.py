#!/usr/bin/env python3
"""Generate complete App Store metadata for every supported ASC locale."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "fastlane" / "metadata"
LOCALES = json.loads((ROOT / "scripts" / "asc-supported-locales.json").read_text())["locales"]

# Native ASO fields for every App Store Connect locale. The longer description
# stays deliberately simple and conservative because this is a health app.
COPY: dict[str, tuple[str, str, str]] = {
    "ar-SA": ("متتبع VO2 Max اليومي", "عمر اللياقة، أدوات وWatch", "لياقة,صحة,هوائي,تحمل,تعافي,تدريب,ساعة,متعقب"),
    "bn-BD": ("VO2 Max দৈনিক ট্র্যাকার", "ফিটনেস বয়স, উইজেট ও Watch", "ফিটনেস,স্বাস্থ্য,কার্ডিও,সহনশীলতা,রিকভারি,প্রশিক্ষণ,ওয়াচ"),
    "ca": ("Seguiment diari VO2 Max", "Edat física, ginys i Watch", "cardio,aeròbic,salut,forma,rellotge,seguiment,entrenament,resistència,recuperació"),
    "cs": ("Denní přehled VO2 Max", "Fitness věk, widgety a Watch", "kardio,aerobní,zdraví,kondice,hodinky,sledování,trénink,vytrvalost,regenerace"),
    "da": ("VO2 Max Daglig Tracker", "Fitnessalder, widgets og Watch", "kondition,aerob,sundhed,fitness,ur,tracker,træning,udholdenhed,restitution"),
    "de-DE": ("VO2 Max Tages-Tracker", "Fitnessalter, Widgets & Watch", "cardio,aerob,gesundheit,fitness,watch,tracker,training,ausdauer,erholung"),
    "el": ("Ημερήσιο VO2 Max", "Ηλικία fitness, widget & Watch", "καρδιο,αερόβιο,υγεία,φυσική κατάσταση,ρολόι,προπόνηση,αντοχή,αποκατάσταση"),
    "en-AU": ("VO2 Max Daily Tracker", "Fitness Age, Widgets & Watch", "cardio,aerobic,health,fitness,applewatch,tracker,training,endurance,recovery,notifications"),
    "en-CA": ("VO2 Max Daily Tracker", "Fitness Age, Widgets & Watch", "cardio,aerobic,health,fitness,applewatch,tracker,training,endurance,recovery,notifications"),
    "en-GB": ("VO2 Max Daily Tracker", "Fitness Age, Widgets & Watch", "cardio,aerobic,health,fitness,applewatch,tracker,training,endurance,recovery,notifications"),
    "en-US": ("VO2 Max Daily Tracker", "Fitness Age, Widgets & Watch", "cardio,aerobic,health,fitness,applewatch,tracker,training,endurance,recovery,notifications"),
    "es-ES": ("VO2 Max Seguimiento Diario", "Edad fitness, widgets y Watch", "cardio,aeróbico,salud,fitness,reloj,seguimiento,entreno,resistencia,recuperación"),
    "es-MX": ("VO2 Max Seguimiento Diario", "Edad fitness, widgets y Watch", "cardio,aeróbico,salud,fitness,reloj,seguimiento,entreno,resistencia,recuperación"),
    "fi": ("VO2 Max Päiväseuranta", "Kuntoikä, widgetit ja Watch", "kardio,aerobinen,terveys,kunto,kello,seuranta,harjoittelu,kestävyys,palautuminen"),
    "fr-CA": ("Suivi quotidien VO2 Max", "Âge fitness, widgets et Watch", "cardio,aérobie,santé,forme,montre,suivi,entraînement,endurance,récupération"),
    "fr-FR": ("Suivi quotidien VO2 Max", "Âge fitness, widgets et Watch", "cardio,aérobie,santé,forme,montre,suivi,entraînement,endurance,récupération"),
    "gu-IN": ("VO2 Max દૈનિક ટ્રેકર", "ફિટનેસ ઉંમર, વિજેટ અને Watch", "ફિટનેસ,આરોગ્ય,કાર્ડિયો,સહનશક્તિ,રિકવરી,તાલીમ,વોચ,ટ્રેકર"),
    "he": ("מעקב VO2 Max יומי", "גיל כושר, וידג׳טים ו-Watch", "כושר,בריאות,אירובי,סיבולת,התאוששות,אימון,שעון,מעקב"),
    "hi": ("VO2 Max दैनिक ट्रैकर", "फिटनेस उम्र, विजेट और Watch", "फिटनेस,स्वास्थ्य,कार्डियो,सहनशक्ति,रिकवरी,ट्रेनिंग,वॉच,ट्रैकर"),
    "hr": ("Dnevni VO2 Max", "Fitness dob, widgeti i Watch", "kardio,aerobno,zdravlje,fitness,sat,praćenje,trening,izdržljivost,oporavak"),
    "hu": ("VO2 Max Napi Követő", "Fitneszkor, widgetek és Watch", "kardió,aerob,egészség,fitnesz,óra,követő,edzés,állóképesség,regeneráció"),
    "id": ("Pelacak Harian VO2 Max", "Usia kebugaran, widget & Watch", "kardio,aerobik,kesehatan,kebugaran,jam,pelacak,latihan,daya tahan,pemulihan"),
    "it": ("VO2 Max Tracker Giornaliero", "Età fitness, widget e Watch", "cardio,aerobica,salute,fitness,orologio,tracker,allenamento,resistenza,recupero"),
    "ja": ("VO2 Max デイリートラッカー", "フィットネス年齢・ウィジェット・Watch", "有酸素,健康,フィットネス,ウォッチ,トラッカー,トレーニング,持久力,回復"),
    "kn-IN": ("VO2 Max ದೈನಂದಿನ ಟ್ರ್ಯಾಕರ್", "ಫಿಟ್ನೆಸ್ ವಯಸ್ಸು, ವಿಜೆಟ್, Watch", "ಫಿಟ್ನೆಸ್,ಆರೋಗ್ಯ,ಕಾರ್ಡಿಯೋ,ಸಹಿಷ್ಣುತೆ,ಚೇತರಿಕೆ,ತರಬೇತಿ,ವಾಚ್"),
    "ko": ("VO2 Max 데일리 트래커", "피트니스 나이, 위젯 및 Watch", "유산소,건강,피트니스,워치,트래커,훈련,지구력,회복"),
    "ml-IN": ("VO2 Max ഡെയ്‌ലി ട്രാക്കർ", "ഫിറ്റ്നസ് പ്രായം, വിജറ്റ്, Watch", "ഫിറ്റ്നസ്,ആരോഗ്യം,കാർഡിയോ,സഹിഷ്ണുത,വീണ്ടെടുക്കൽ,പരിശീലനം,വാച്ച്"),
    "mr-IN": ("VO2 Max दैनिक ट्रॅकर", "फिटनेस वय, विजेट आणि Watch", "फिटनेस,आरोग्य,कार्डिओ,सहनशक्ती,रिकव्हरी,प्रशिक्षण,वॉच,ट्रॅकर"),
    "ms": ("Penjejak Harian VO2 Max", "Umur kecergasan, widget & Watch", "kardio,aerobik,kesihatan,kecergasan,jam,penjejak,latihan,daya tahan,pemulihan"),
    "nl-NL": ("VO2 Max Dagelijkse Tracker", "Fitnessleeftijd, widgets & Watch", "cardio,aeroob,gezondheid,fitness,horloge,tracker,training,uithouding,herstel"),
    "no": ("VO2 Max Daglig Måling", "Fitnessalder, widgeter og Watch", "kondisjon,aerob,helse,fitness,klokke,måling,trening,utholdenhet,restitusjon"),
    "or-IN": ("VO2 Max ଦୈନିକ ଟ୍ରାକର", "ଫିଟନେସ ବୟସ, ୱିଜେଟ, Watch", "ଫିଟନେସ,ସ୍ୱାସ୍ଥ୍ୟ,କାର୍ଡିଓ,ସହନଶକ୍ତି,ପୁନରୁଦ୍ଧାର,ପ୍ରଶିକ୍ଷଣ,ୱାଚ"),
    "pa-IN": ("VO2 Max ਰੋਜ਼ਾਨਾ ਟਰੈਕਰ", "ਫਿਟਨੈਸ ਉਮਰ, ਵਿਜੇਟ ਅਤੇ Watch", "ਫਿਟਨੈਸ,ਸਿਹਤ,ਕਾਰਡੀਓ,ਸਹਿਣਸ਼ੀਲਤਾ,ਰਿਕਵਰੀ,ਸਿਖਲਾਈ,ਵਾਚ,ਟਰੈਕਰ"),
    "pl": ("VO2 Max Dzienny Monitor", "Wiek fitness, widżety i Watch", "kardio,aerobowy,zdrowie,fitness,zegarek,monitor,trening,wytrzymałość,regeneracja"),
    "pt-BR": ("VO2 Max Monitor Diário", "Idade fitness, widgets e Watch", "cardio,aeróbico,saúde,fitness,relógio,monitor,treino,resistência,recuperação"),
    "pt-PT": ("VO2 Max Monitor Diário", "Idade fitness, widgets e Watch", "cardio,aeróbico,saúde,fitness,relógio,monitor,treino,resistência,recuperação"),
    "ro": ("Monitor Zilnic VO2 Max", "Vârstă fitness, widgeturi, Watch", "cardio,aerobic,sănătate,fitness,ceas,monitor,antrenament,rezistență,recuperare"),
    "ru": ("VO2 Max: Дневной трекер", "Фитнес-возраст, виджеты, Watch", "кардио,аэробика,здоровье,фитнес,часы,трекер,тренировка,выносливость,восстановление"),
    "sk": ("Denný prehľad VO2 Max", "Fitness vek, widgety a Watch", "kardio,aeróbne,zdravie,fitness,hodinky,sledovanie,tréning,vytrvalosť,regenerácia"),
    "sl-SI": ("Dnevni VO2 Max", "Fitnes starost, gradniki, Watch", "kardio,aerobno,zdravje,fitnes,ura,sledenje,vadba,vzdržljivost,okrevanje"),
    "sv": ("VO2 Max Daglig Mätare", "Fitnessålder, widgetar & Watch", "kondition,aerob,hälsa,fitness,klocka,mätare,träning,uthållighet,återhämtning"),
    "ta-IN": ("VO2 Max தினசரி டிராக்கர்", "உடற்தகுதி வயது, விட்ஜெட், Watch", "உடற்பயிற்சி,ஆரோக்கியம்,கார்டியோ,சகிப்புத்தன்மை,மீட்பு,பயிற்சி,வாட்ச்"),
    "te-IN": ("VO2 Max రోజువారీ ట్రాకర్", "ఫిట్‌నెస్ వయస్సు, విడ్జెట్, Watch", "ఫిట్‌నెస్,ఆరోగ్యం,కార్డియో,ఓర్పు,రికవరీ,శిక్షణ,వాచ్,ట్రాకర్"),
    "th": ("ติดตาม VO2 Max รายวัน", "อายุฟิตเนส วิดเจ็ต และ Watch", "คาร์ดิโอ,แอโรบิก,สุขภาพ,ฟิตเนส,นาฬิกา,ติดตาม,ฝึกซ้อม,ความอึด,ฟื้นตัว"),
    "tr": ("VO2 Max Günlük Takip", "Fitness yaşı, araçlar ve Watch", "kardiyo,aerobik,sağlık,fitness,saat,takip,antrenman,dayanıklılık,toparlanma"),
    "uk": ("VO2 Max: Щоденний трекер", "Фітнес-вік, віджети та Watch", "кардіо,аеробіка,здоровʼя,фітнес,годинник,трекер,тренування,витривалість,відновлення"),
    "ur-PK": ("VO2 Max روزانہ ٹریکر", "فٹنس عمر، ویجٹس اور Watch", "فٹنس,صحت,کارڈیو,برداشت,ریکوری,ٹریننگ,واچ,ٹریکر"),
    "vi": ("Theo dõi VO2 Max hằng ngày", "Tuổi thể lực, tiện ích & Watch", "tim mạch,hiếu khí,sức khỏe,thể lực,đồng hồ,theo dõi,luyện tập,sức bền,phục hồi"),
    "zh-Hans": ("VO2 Max 每日追踪", "体能年龄、小组件与 Watch", "有氧,健康,体能,手表,追踪,训练,耐力,恢复,通知"),
    "zh-Hant": ("VO2 Max 每日追蹤", "體能年齡、小工具與 Watch", "有氧,健康,體能,手錶,追蹤,訓練,耐力,恢復,通知"),
}

DESCRIPTION = """See your Apple Health VO2 max estimate and cardio fitness trend in a calm, focused dashboard.

VO2 Max Daily Tracker shows:

• Your latest Apple Health estimate
• Improving, stable, or declining trend
• A personal target range
• One-year history
• A broad fitness-age estimate with clear methodology
• Home Screen and Lock Screen widgets
• Apple Watch app and complications
• Guidance when no estimate is available

Your fitness data stays on your devices. The app reads Cardio Fitness estimates from Apple Health and never writes Health data.

VO2 max and fitness age are broad estimates for fitness awareness. This app does not diagnose, treat, cure, or prevent any health condition. It is not a substitute for professional medical advice.

VO2 Max Pro is optional. Choose $1.99 monthly, $14.99 yearly, or a $29.99 lifetime purchase. Monthly and yearly plans include a 7-day free trial for eligible new subscribers. Prices shown are U.S. prices and may vary by region. Payment is charged to your Apple Account at confirmation. Subscriptions renew automatically unless canceled at least 24 hours before the current period ends. Your account is charged for renewal within 24 hours before the current period ends. Manage or cancel subscriptions in Apple Account settings.

Terms of Use (Apple Standard EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://jackwallner.github.io/vo2max/privacy-policy.html"""

PROMO = "See your Apple Health VO2 max estimate, cardio fitness trend, fitness age, widgets, and Watch complications. Private and local-first."
RELEASE = "Welcome to VO2 Max Daily Tracker. See your Apple Health estimate, cardio fitness trend, target range, fitness age, widgets, and Watch complications."
URL = "https://jackwallner.github.io/vo2max/"
KEYWORD_FILL = "performance,insights,recovery,athlete,aerobic,endurance,widget,complication,history,goals"


def maximize(value: str, minimum: int, maximum: int, fill: str) -> str:
    result = value.strip()
    for token in fill.split(","):
        separator = "," if "," in result else " "
        candidate = result + separator + token
        if len(candidate) <= maximum:
            result = candidate
        if len(result) >= minimum:
            break
    if len(result) < minimum:
        result = (result + " " + fill.replace(",", " "))[:maximum]
    return result[:maximum]


def maximize_text(value: str, minimum: int, maximum: int, fill: str) -> str:
    result = value.strip()
    if len(result) > maximum and result.endswith("Watch"):
        result = result[:-5].rstrip(" ,&-")
    for token in fill.split(","):
        candidate = f"{result} {token}"
        if len(candidate) <= maximum:
            result = candidate
        if len(result) >= minimum:
            return result
    return result


def write(path: Path, value: str) -> None:
    path.write_text(value.strip() + "\n", encoding="utf-8")


def main() -> None:
    for locale in LOCALES:
        name, subtitle, keywords = COPY[locale]
        folder = OUT / locale
        folder.mkdir(parents=True, exist_ok=True)
        write(folder / "name.txt", maximize_text(name, 24, 30, "Cardio,Fitness,Tracker"))
        write(folder / "subtitle.txt", maximize_text(subtitle, 24, 30, "Trends,Insights,Tracker"))
        write(folder / "keywords.txt", maximize(keywords, 94, 100, KEYWORD_FILL))
        if not (folder / "description.txt").exists():
            write(folder / "description.txt", DESCRIPTION)
        if not (folder / "promotional_text.txt").exists():
            write(folder / "promotional_text.txt", PROMO[:170])
        if not (folder / "release_notes.txt").exists():
            write(folder / "release_notes.txt", RELEASE)
        write(folder / "support_url.txt", URL + "support.html")
        write(folder / "marketing_url.txt", URL)
        write(folder / "privacy_url.txt", URL + "privacy-policy.html")
        write(folder / "apple_tv_privacy_policy.txt", URL + "privacy-policy.html")

    write(OUT / "copyright.txt", "2026 Jack Wallner")
    write(OUT / "primary_category.txt", "HEALTH_AND_FITNESS")
    write(OUT / "secondary_category.txt", "LIFESTYLE")

    review = OUT / "review_information"
    review.mkdir(exist_ok=True)
    write(review / "first_name.txt", "Jack")
    write(review / "last_name.txt", "Wallner")
    write(review / "email_address.txt", "jackwallner@gmail.com")
    write(review / "phone_number.txt", "14257533411")
    write(review / "demo_user.txt", "")
    write(review / "demo_password.txt", "")
    write(review / "notes.txt", "The app is read-only and requests Apple Health Cardio Fitness (VO2 max) access. No account is required. If the review device has no cardio fitness samples, the app shows guidance for obtaining an Apple Watch estimate. VO2 Max Pro offers monthly and yearly auto-renewable subscriptions with a 7-day introductory trial, plus a one-time lifetime unlock. Terms and privacy links appear at the purchase point.")
    print(f"wrote complete metadata for {len(LOCALES)} locales")


if __name__ == "__main__":
    main()

import Foundation
import Testing
@testable import VO2Max

private final class LocalizationBundleMarker: NSObject {}

@Suite("Localization")
struct LocalizationTests {
    static let languages = [
        "de", "fr", "nl", "zh-Hant", "ru", "ar", "es", "ja", "th", "cs",
        "it", "he", "hu", "ro", "el", "pl", "sk", "sv"
    ]

    private func bundle(_ language: String) -> Bundle? {
        for host in [Bundle(for: LocalizationBundleMarker.self), Bundle.main] + Bundle.allBundles {
            if let path = host.path(forResource: language, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return nil
    }

    @Test func everyLanguageShips() {
        for language in Self.languages {
            #expect(bundle(language) != nil, "\(language).lproj is missing")
        }
    }

    @Test func targetStatusMeansWithinTargetRange() throws {
        let expected = [
            ("de", "Im Zielbereich"),
            ("zh-Hant", "目標範圍內"),
            ("ru", "В целевом диапазоне"),
            ("ar", "ضمن الهدف"),
            ("ja", "目標範囲内"),
            ("th", "อยู่ในช่วงเป้าหมาย"),
            ("cs", "V cílovém rozmezí"),
            ("it", "Nell’intervallo obiettivo"),
            ("el", "Εντός στόχου"),
        ]

        for (language, value) in expected {
            let localizedBundle = try #require(bundle(language))
            let locale = Locale(identifier: language)
            #expect(String(localized: "In target", bundle: localizedBundle, locale: locale) == value)
        }
    }

    @Test func germanCopyIsTranslated() throws {
        let german = try #require(bundle("de"))
        let locale = Locale(identifier: "de")
        #expect(String(localized: "Latest Apple Health estimate", bundle: german, locale: locale) == "Neuester Schätzwert aus Apple Health")
        #expect(String(localized: "Age: \(1) years", bundle: german, locale: locale) == "Alter: 1 Jahr")
        #expect(String(localized: "Age: \(5) years", bundle: german, locale: locale) == "Alter: 5 Jahre")

        let date = "today"
        let oneDay = String(localized: "Latest estimate \(date). You usually get one every \(1) days.", bundle: german, locale: locale)
        let sixDays = String(localized: "Latest estimate \(date). You usually get one every \(6) days.", bundle: german, locale: locale)
        #expect(oneDay.contains("jeden Tag"))
        #expect(sixDays.contains("alle 6 Tage"))
        #expect(String(localized: "\(1) estimates from Apple Health", bundle: german, locale: locale) == "1 Schätzwert aus Apple Health")
        #expect(String(localized: "\(2) estimates from Apple Health", bundle: german, locale: locale) == "2 Schätzwerte aus Apple Health")
    }

    @Test func russianPluralCategoriesResolve() throws {
        let russian = try #require(bundle("ru"))
        let locale = Locale(identifier: "ru")
        let one = String(localized: "\(1) readings", bundle: russian, locale: locale)
        let few = String(localized: "\(3) readings", bundle: russian, locale: locale)
        let many = String(localized: "\(5) readings", bundle: russian, locale: locale)
        #expect(one == "1 оценка")
        #expect(few == "3 оценки")
        #expect(many == "5 оценок")

        let date = "today"
        let oneDay = String(localized: "Latest estimate \(date). You usually get one every \(1) days.", bundle: russian, locale: locale)
        let twoDays = String(localized: "Latest estimate \(date). You usually get one every \(2) days.", bundle: russian, locale: locale)
        let fiveDays = String(localized: "Latest estimate \(date). You usually get one every \(5) days.", bundle: russian, locale: locale)
        #expect(oneDay.contains("каждый день"))
        #expect(twoDays.contains("раз в 2 дня"))
        #expect(fiveDays.contains("раз в 5 дней"))
    }

    @Test func polishPluralCategoriesResolve() throws {
        let polish = try #require(bundle("pl"))
        let locale = Locale(identifier: "pl")
        let one = String(localized: "\(1) readings", bundle: polish, locale: locale)
        let few = String(localized: "\(3) readings", bundle: polish, locale: locale)
        let many = String(localized: "\(5) readings", bundle: polish, locale: locale)
        #expect(one == "1 pomiar")
        #expect(few == "3 pomiary")
        #expect(many == "5 pomiarów")
    }

    @Test func hebrewPluralCategoriesResolve() throws {
        let hebrew = try #require(bundle("he"))
        let locale = Locale(identifier: "he")
        let one = String(localized: "\(1) readings", bundle: hebrew, locale: locale)
        let two = String(localized: "\(2) readings", bundle: hebrew, locale: locale)
        let other = String(localized: "\(3) readings", bundle: hebrew, locale: locale)
        #expect(one == "מדידה אחת")
        #expect(two == "שתי מדידות")
        #expect(other == "3 מדידות")
    }

    @Test func arabicPluralCategoriesResolve() throws {
        let arabic = try #require(bundle("ar"))
        let locale = Locale(identifier: "ar")
        let forms = [0, 1, 2, 5, 11, 100].map {
            String(localized: "\($0) readings", bundle: arabic, locale: locale)
        }
        #expect(Set(forms).count == forms.count)
    }
}

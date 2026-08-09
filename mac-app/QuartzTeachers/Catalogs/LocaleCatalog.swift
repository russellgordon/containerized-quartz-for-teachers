import Foundation

/// The Quartz locales the toolchain supports, mirroring the list in
/// `scripts/setup_course.py` (LOCALE_CODES / LOCALE_LABELS).
enum LocaleCatalog {

    // MARK: - Stored properties

    /// Locale codes in the same order the wizard presents them.
    static let codes: [String] = [
        "nb-NO", "ar-SA", "ca-ES", "cs-CZ", "de-DE", "en-GB", "en-US",
        "es-ES", "fa-IR", "fi-FI", "fr-FR", "hu-HU", "it-IT", "ja-JP",
        "ko-KR", "lt-LT", "nl-NL", "pl-PL", "pt-BR", "ro-RO", "ru-RU",
        "th-TH", "tr-TR", "uk-UA", "vi-VN", "zh-CN", "zh-TW",
    ]

    static let labels: [String: String] = [
        "nb-NO": "Norwegian Bokmål (Norway)",
        "ar-SA": "Arabic (Saudi Arabia)",
        "ca-ES": "Catalan (Spain)",
        "cs-CZ": "Czech (Czechia)",
        "de-DE": "German (Germany)",
        "en-GB": "English (United Kingdom)",
        "en-US": "English (United States)",
        "es-ES": "Spanish (Spain)",
        "fa-IR": "Persian (Iran)",
        "fi-FI": "Finnish (Finland)",
        "fr-FR": "French (France)",
        "hu-HU": "Hungarian (Hungary)",
        "it-IT": "Italian (Italy)",
        "ja-JP": "Japanese (Japan)",
        "ko-KR": "Korean (South Korea)",
        "lt-LT": "Lithuanian (Lithuania)",
        "nl-NL": "Dutch (Netherlands)",
        "pl-PL": "Polish (Poland)",
        "pt-BR": "Portuguese (Brazil)",
        "ro-RO": "Romanian (Romania)",
        "ru-RU": "Russian (Russia)",
        "th-TH": "Thai (Thailand)",
        "tr-TR": "Turkish (Türkiye)",
        "uk-UA": "Ukrainian (Ukraine)",
        "vi-VN": "Vietnamese (Vietnam)",
        "zh-CN": "Chinese, Simplified (China)",
        "zh-TW": "Chinese, Traditional (Taiwan)",
    ]

    // MARK: - Functions

    /// A display string like "en-US — English (United States)".
    static func displayName(forCode code: String) -> String {
        if let label = labels[code] {
            return "\(code) — \(label)"
        }
        return code
    }
}

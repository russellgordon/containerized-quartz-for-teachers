import Foundation

/// The header/body/code font families for one section (or the course default),
/// matching the `fonts` entries the setup wizard writes.
struct FontChoice: Equatable {

    // MARK: - Stored properties

    var header: String
    var body: String
    var code: String

    // MARK: - Computed properties

    /// The shape stored inside `course_config.json`.
    var dictionaryRepresentation: [String: Any] {
        return [
            "header": header,
            "body": body,
            "code": code,
        ]
    }

    static var systemDefault: FontChoice {
        return FontChoice(header: "Helvetica, Arial", body: "Helvetica, Arial", code: "IBM Plex Mono")
    }

    // MARK: - Initializer

    init(header: String, body: String, code: String) {
        self.header = header
        self.body = body
        self.code = code
    }

    init(dictionary: [String: Any]) {
        var headerValue: String = "Helvetica, Arial"
        var bodyValue: String = "Helvetica, Arial"
        var codeValue: String = "IBM Plex Mono"
        if let stored = dictionary["header"] as? String {
            headerValue = stored
        }
        if let stored = dictionary["body"] as? String {
            bodyValue = stored
        }
        if let stored = dictionary["code"] as? String {
            codeValue = stored
        }
        self.header = headerValue
        self.body = bodyValue
        self.code = codeValue
    }
}

import Foundation

/// The first publish of a section stops on one line: "Paste Netlify token:".
///
/// That line is the whole question a teacher used to be asked. It names
/// something they have never heard of, does not say where to get it, and
/// arrives in a dialog with a text field and a Send button — so the honest
/// answer to it is "I have no idea". This turns those three requests into
/// something that can be acted on without leaving the app: what the
/// credential is for, the numbered steps that produce one, and the page to
/// get it from as a LINK the teacher clicks.
///
/// **The link is a link, never an automatic browser tab.** The launchers used
/// to `open` the page themselves the moment they asked. A browser jumping in
/// front of the app, unasked, reads as something going wrong rather than as
/// help — so the address is offered and the teacher decides when to follow it.
struct CredentialRequest: Equatable {

    // MARK: - Stored properties

    /// Which credential this is, so the interface can tell them apart
    /// without matching on wording.
    var name: String

    /// The dialog's title.
    var title: String

    /// Why this is being asked at all, in one short paragraph.
    var explanation: String

    /// What to do, in order.
    var steps: [String]

    /// What the link says.
    var linkTitle: String

    /// Where the link goes.
    var linkAddress: URL

    /// The label beside the field the answer is typed into.
    var fieldLabel: String

    /// True when the answer is a secret and must not be shown as it is
    /// typed. A token is; an account's ID is not.
    var isSecret: Bool

    // MARK: - Computed properties

    /// Netlify's personal access token, asked for the first time a section
    /// is published there.
    static var netlifyToken: CredentialRequest {
        return CredentialRequest(
            name: "netlifyToken",
            title: "Connect to Netlify",
            explanation: "Netlify hosts this section's website for free, and it needs to know that "
                       + "the publishing is coming from you. It does that with an access token — a "
                       + "long code that acts like a password made just for this app. Creating one "
                       + "takes about a minute, and you will not be asked again: it is saved "
                       + "securely on this computer.",
            steps: [
                "Open the Netlify page linked below, and sign in if you are asked to.",
                "Choose “New access token”.",
                "Describe it as something you will recognise later, such as “Class websites”.",
                "Set it to never expire, so your publishing does not stop working partway through the year.",
                "Choose “Generate token”, then copy the long code Netlify shows you — it is only shown once.",
                "Paste it below.",
            ],
            linkTitle: "Open Netlify’s access tokens page",
            linkAddress: URL(string: "https://app.netlify.com/user/applications#personal-access-tokens")!,
            fieldLabel: "Netlify token",
            isSecret: true
        )
    }

    /// Cloudflare's API token, asked for the first time a section is
    /// published to Cloudflare Pages.
    static var cloudflareToken: CredentialRequest {
        return CredentialRequest(
            name: "cloudflareToken",
            title: "Connect to Cloudflare",
            explanation: "Cloudflare hosts this section's website for free, and it needs to know that "
                       + "the publishing is coming from you. It does that with an API token — a long "
                       + "code that acts like a password made just for this app. Creating one takes "
                       + "about two minutes, and you will not be asked again: it is saved securely on "
                       + "this computer.",
            steps: [
                "Open the Cloudflare page linked below, and sign in if you are asked to.",
                "Choose “Create Token”, then “Create Custom Token”.",
                "Name it something you will recognise later, such as “Class websites”.",
                "Give it one permission, chosen from the three dropdowns: Account, then Cloudflare Pages, then Edit.",
                "Leave everything else as it is, then choose “Continue to summary” and “Create Token”.",
                "Copy the long code Cloudflare shows you — it is only shown once — and paste it below.",
            ],
            linkTitle: "Open Cloudflare’s API tokens page",
            linkAddress: URL(string: "https://dash.cloudflare.com/profile/api-tokens")!,
            fieldLabel: "Cloudflare token",
            isSecret: true
        )
    }

    /// Cloudflare's account ID, asked only when the token cannot say which
    /// account it belongs to.
    static var cloudflareAccountID: CredentialRequest {
        return CredentialRequest(
            name: "cloudflareAccountID",
            title: "One more thing from Cloudflare",
            explanation: "The token you just made is allowed to publish, but not to look up which "
                       + "Cloudflare account it belongs to — so the account's ID is needed as well. "
                       + "This is the only time you will be asked for it.",
            steps: [
                "Open the Cloudflare dashboard linked below.",
                "Choose “Workers & Pages” from the list on the left.",
                "Find “Account ID” on the right-hand side, and copy it.",
                "Paste it below. (It is also the long code in your browser's address bar, "
                    + "just after dash.cloudflare.com/.)",
            ],
            linkTitle: "Open the Cloudflare dashboard",
            linkAddress: URL(string: "https://dash.cloudflare.com")!,
            fieldLabel: "Account ID",
            isSecret: false
        )
    }

    /// Every request there is, so a test can walk them.
    static var all: [CredentialRequest] {
        return [CredentialRequest.netlifyToken, CredentialRequest.cloudflareToken, CredentialRequest.cloudflareAccountID]
    }

    // MARK: - Functions

    /// The request a launcher's one-line prompt is asking for, or nil when
    /// it is asking something ordinary that the plain dialog handles.
    ///
    /// Matched on the words that name the credential rather than on the
    /// whole line, because the same prompt is worded slightly differently
    /// by the two launchers and neither wording is worth pinning.
    static func matching(_ question: String) -> CredentialRequest? {
        let wording: String = question.lowercased()
        if wording.contains("netlify token") {
            return CredentialRequest.netlifyToken
        }
        if wording.contains("cloudflare account id") {
            return CredentialRequest.cloudflareAccountID
        }
        if wording.contains("cloudflare token") {
            return CredentialRequest.cloudflareToken
        }
        return nil
    }
}

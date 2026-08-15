import SwiftUI

/// Which side of the conversation something belongs to.
nonisolated enum AssistChatSide: Equatable {

    case teacher
    case assistant

    /// Not part of the back and forth at all — a restore, which is a thing
    /// that HAPPENED rather than a thing anybody said. It sits in the flow
    /// without a bubble, and it neither wears a tail nor interrupts anyone's
    /// turn.
    case neither
}

/// Where a batch of messages ends, and therefore where the tail goes.
///
/// A tail on every bubble makes a run of three messages look like three
/// separate interruptions. One tail, on the LAST message a participant sends
/// before the other one answers, is what reads as a turn — the same rule
/// Messages uses, which is why it is the rule a teacher will already expect
/// without being able to say so.
@MainActor
enum AssistChatLayout {

    // MARK: - Functions

    /// Everything the assistant produces is the assistant talking.
    ///
    /// Results and problems used to sit outside the conversation as plain
    /// lines with an icon, which made the window read as a chat with a log
    /// spliced through it. "The preview is rebuilding now" is the assistant
    /// answering; that it happens to have come from a tool is machinery, and
    /// the teacher is not the audience for machinery.
    static func side(of speaker: AssistAgent.Entry.Speaker) -> AssistChatSide {
        switch speaker {
        case .teacher:
            return .teacher
        case .assistant, .toolResult, .problem:
            return .assistant
        }
    }

    /// Whether the bubble at `index` is the last of its participant's run.
    ///
    /// Takes the SIDES rather than the speakers, because the transcript holds
    /// things nobody said — a restore — which belong to neither participant
    /// and must not end a turn.
    static func showsTail(at index: Int, in sides: [AssistChatSide]) -> Bool {
        guard sides.indices.contains(index) else {
            return false
        }
        let mine: AssistChatSide = sides[index]
        if mine == .neither {
            return false
        }
        var next: Int = index + 1
        while next < sides.count {
            let theirs: AssistChatSide = sides[next]
            if theirs != .neither {
                return theirs != mine
            }
            next += 1
        }
        // Nothing said after it, so it is the end of the run so far.
        return true
    }
}

/// A chat bubble shaped like the one Messages draws.
///
/// **Measured, not eyeballed.** Every number here was read off a screenshot of
/// a real Messages conversation, pixel by pixel, after three attempts at
/// guessing produced three different wrong shapes. Re-measured 2026-08-15
/// against a side-by-side comparison, which corrected one of the originals:
/// the "corner radius 12" below is Messages' MULTI-LINE radius; a single-line
/// bubble is a capsule (see `capsuleLimit`), and the tail ratios below were
/// confirmed exactly (tip inset 0.42r, drop 0.33r, corner end 0.54r).
///
/// | | |
/// |---|---|
/// | corner radius, multi-line | 12 |
/// | corner radius, single line | half the body height |
/// | text inset, sides | 11 |
/// | tail drop below the body | 4.8, one size for every bubble |
/// | tail tip, INSIDE the body's edge | 6 |
///
/// Two of those corrected assumptions worth stating, because both look right
/// until measured. The tail **hangs below** the bubble — it is not level with
/// the bottom edge. And it stays **within the bubble's width**: its tip is
/// five and a half points INSIDE the right edge, not outside it. A tail drawn
/// past the side reads as a wedge stuck onto the corner, which is what the
/// last version was.
///
/// So the bubble is a rounded rectangle whose bottom corner, on the speaker's
/// side, dips into a small hook. The hook's underside is concave, curving back
/// up into the bottom edge — that curve, rather than the tip, is what makes
/// the shape read as a tail.
///
/// Proportions are held relative to the corner radius so a short bubble and a
/// tall one are the same design, and everything is drawn inside the rect the
/// background is given, since anything outside it is clipped.
struct AssistChatBubbleShape: Shape {

    // MARK: - Stored properties

    let side: AssistChatSide
    let hasTail: Bool

    /// The strip below the bubble that the tail hangs into. Nothing is needed
    /// at the sides: the tail never reaches past the bubble's own edge.
    static let drop: CGFloat = 5

    /// Messages' corner radius for bubbles of more than one line.
    private let corner: CGFloat = 12

    /// What the tail's measurements scale from — and it is NOT the bubble's
    /// corner radius. Measured 2026-08-15 on a three-line bubble and a
    /// single-line one side by side: Messages draws the SAME tail on both
    /// (drop, tip and hook all within a pixel), while the corner radius
    /// differs. Scaling the tail with the corner — what this shape did —
    /// shrank every multi-line bubble's tail to a nub. The value is the
    /// single-line capsule's radius, where the two scales coincide.
    private let tailScale: CGFloat = 14.5

    /// Below this half-height, a bubble is a CAPSULE — its corners are half
    /// its height. Re-measured 2026-08-15 from a side-by-side screenshot at
    /// 6x: Messages' single-line bubble bulges continuously from top to
    /// bottom (a capsule, radius 24px at a 48px height), while its
    /// multi-line bubbles settle to a fixed radius (19px at the same scale
    /// — our 12, at our text size). The FIXED radius on a single-line
    /// bubble was the visible difference: the corner finished tight and the
    /// tail hung off it like a drip, where Messages' tail continues a broad
    /// arc. One line at our text size gives a half-height of about 14.5;
    /// two lines about 22. The limit sits between them.
    private let capsuleLimit: CGFloat = 15

    // MARK: - Functions

    func path(in rect: CGRect) -> Path {
        // Every bubble gives up the same strip beneath it, tail or no tail, so
        // a run of them sits on one rhythm rather than jumping wherever a turn
        // ends.
        var body: CGRect = rect
        body.size.height -= AssistChatBubbleShape.drop

        let halfHeight: CGFloat = body.height / 2
        let radius: CGFloat
        if halfHeight <= capsuleLimit {
            radius = min(halfHeight, body.width / 2)
        } else {
            radius = min(corner, body.width / 2)
        }

        guard hasTail, side != .neither else {
            return Path(roundedRect: body, cornerRadius: radius)
        }

        // Written for a tail on the right, then mirrored. `at` flips x when
        // the tail belongs on the left, so there is one path to read and one
        // to get right.
        let flip: Bool = (side == .assistant)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            return CGPoint(x: flip ? (rect.maxX - (x - rect.minX)) : x, y: y)
        }

        // Measured off Messages, expressed against `tailScale` — one size of
        // tail for every size of bubble, which is what Messages draws. The
        // silhouette is the fussy part, and it was measured a
        // SECOND time after a first pass got the tip in the right place and
        // the shape wrong:
        //
        //   base of the tail   about 5.5pt wide — a sliver, not a wedge
        //   outer edge         drifts OUTWARD as it descends, ending in a
        //                      small flick. Curling inward is what made ours
        //                      read as a fin rather than a tail.
        //   hook rejoins       about 11.5pt inside the bubble's edge
        // Straight off the measurements, at r = 12:
        //
        //   the corner meets the bottom edge   6.5pt inside the right edge
        //   the tip                            5pt inside, 4pt below
        //   the hook rejoins the bottom edge   11.5pt inside
        //
        // The tip being LESS inset than the corner is the whole character of
        // the thing: the outer edge comes in with the corner and then flicks
        // back out and down. An outer edge that keeps curving inward gives a
        // fin, which is what two earlier attempts drew.
        let dropBelow: CGFloat = tailScale * 0.333    // 4.8
        let cornerEnd: CGFloat = tailScale * 0.542    // 7.9
        let tipInset: CGFloat = tailScale * 0.417     // 6
        let hookBase: CGFloat = min(tailScale * 0.958, body.width / 2)

        let tip: CGPoint = at(body.maxX - tipInset, body.maxY + dropBelow)

        var path: Path = Path()

        // Top edge, left to right.
        path.move(to: at(body.minX + radius, body.minY))
        path.addLine(to: at(body.maxX - radius, body.minY))
        path.addQuadCurve(to: at(body.maxX, body.minY + radius),
                          control: at(body.maxX, body.minY))

        // Down the right edge, then the corner into the tail — and the whole
        // character of the joint is the TANGENT it ends on. Traced row by row
        // off Messages (2026-08-15): the outer silhouette reaches its deepest
        // inset (0.542 of the tail scale) exactly at the bottom line while
        // travelling straight DOWN, keeps descending a hair, and only then
        // eases back out to the tip. A corner curve that lands travelling
        // horizontally — a normal rounded corner, which is what was here —
        // meets the descending tail edge in a cusp, and the tail reads as a
        // comma stuck under the bubble rather than the corner pulled down.
        path.addLine(to: at(body.maxX, body.maxY - radius))
        path.addCurve(
            to: at(body.maxX - cornerEnd, body.maxY),
            control1: at(body.maxX, body.maxY - radius * 0.45),
            control2: at(body.maxX - cornerEnd, body.maxY - tailScale * 0.35)
        )

        // Still heading down at the bottom line; eases outward to the tip.
        path.addQuadCurve(
            to: tip,
            control: at(body.maxX - cornerEnd, body.maxY + dropBelow * 0.6)
        )

        // The hook: back up and in, concave, rejoining the bottom edge. This
        // curve — not the tip — is what makes the shape read as a tail. The
        // traced inner edge is a diagonal with a mild sag toward the bubble,
        // not a deep scoop.
        path.addQuadCurve(
            to: at(body.maxX - hookBase, body.maxY),
            control: at(body.maxX - tailScale * 0.85, body.maxY + dropBelow * 0.65)
        )

        // Bottom edge back to the far side, and up.
        path.addLine(to: at(body.minX + radius, body.maxY))
        path.addQuadCurve(to: at(body.minX, body.maxY - radius),
                          control: at(body.minX, body.maxY))
        path.addLine(to: at(body.minX, body.minY + radius))
        path.addQuadCurve(to: at(body.minX + radius, body.minY),
                          control: at(body.minX, body.minY))
        path.closeSubpath()
        return path
    }
}

/// The assistant thinking, as three dots that breathe.
///
/// The conversation used to go silent between the teacher pressing return and
/// the answer arriving — several seconds in which the only honest reading was
/// that nothing had happened. Everyone who has used a messaging app knows what
/// three pulsing dots mean, so nothing has to be explained.
///
/// **It is a THOUGHT bubble, not a speech bubble.** Messages draws this one
/// differently from everything else in the conversation: a capsule, with two
/// plain circles stepping down toward the speaker — the comic-strip sign for
/// thinking — rather than the pointed tail that marks something said. Ours
/// wore the speech tail, and that is part of what made it read as off.
///
/// Sized from a screen recording of Messages itself (frame-extracted and
/// measured, 2026-08-15), as ratios of the bubble's height: the capsule
/// about 1.7 times as wide as tall, dots about 0.24 of the height with a
/// gap about half a dot, the larger thought-circle about 0.40 poking two
/// points past the lower corner, the smaller about 0.14 below and outside
/// it. An earlier pass used a piece of reference artwork instead and got
/// the circle small and the dots big; the recording of the real thing
/// corrected both. The height itself matches a single-line message bubble,
/// so the indicator sits in the conversation as exactly the thing it stands
/// for: a message that is on its way.
struct AssistTypingIndicator: View {

    // MARK: - Stored properties

    /// Drives the animation. Toggled once when the view appears; the phase
    /// difference between the dots comes from each dot's delay, not from three
    /// separate pieces of state.
    @State private var isBreathing: Bool = false

    /// A single-line message bubble's body: one line of callout text plus
    /// the 7-point padding above and below it.
    private let bubbleHeight: CGFloat = 29

    /// About a quarter of the bubble's height, measured off the recording;
    /// an earlier 9 came from artwork and crowded the capsule.
    private let dot: CGFloat = 7

    // MARK: - Computed properties

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: dot, height: dot)
                        .opacity(isBreathing ? 0.95 : 0.35)
                        // Each dot lags the one before it, so the three read
                        // as a wave rather than as a single blink.
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.18),
                            value: isBreathing
                        )
                }
            }
            .padding(.horizontal, 10)
            .frame(height: bubbleHeight)
            // ONE shape holding the capsule and both thought-circles, filled
            // once. The bubble colour is translucent, so drawing the circles
            // as separate views doubled the fill where they overlapped the
            // capsule — a brighter lens along the join that Messages, drawing
            // one flat shape, does not have.
            .background(AssistThoughtBubbleShape().fill(AssistBubbleColour.assistant))
            .padding(.bottom, AssistChatBubbleShape.drop)
            Spacer(minLength: 48)
        }
        .onAppear {
            isBreathing = true
        }
        // Read out as one thing rather than as three dots.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The assistant is working")
        .accessibilityIdentifier("assistTypingIndicator")
    }
}

/// The typing indicator's outline: the capsule and the two thought-circles
/// stepping down toward the speaker, as one shape.
///
/// One shape because the fill is TRANSLUCENT: separate views double the
/// colour where they overlap, and the join between circle and capsule shows
/// as a brighter lens. Subpaths filled together union cleanly.
///
/// The rect is the capsule; the circles hang below and to the left of it,
/// which a `Shape` is free to draw (`.background` does not clip). Sizes and
/// positions are ratios of the capsule's height, measured from a screen
/// recording of Messages: the larger circle 0.41 of it, poking about two
/// points past the corner; the smaller 0.14, below and outside with a
/// sliver of gap.
struct AssistThoughtBubbleShape: Shape {

    // MARK: - Functions

    func path(in rect: CGRect) -> Path {
        var path: Path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: rect.height / 2, height: rect.height / 2))

        let large: CGFloat = rect.height * 0.41
        path.addEllipse(in: CGRect(
            x: rect.minX - 2,
            y: rect.maxY + 2 - large,
            width: large,
            height: large
        ))

        let small: CGFloat = rect.height * 0.14
        path.addEllipse(in: CGRect(
            x: rect.minX - 3.5,
            y: rect.maxY + 6 - small,
            width: small,
            height: small
        ))
        return path
    }
}

/// Text the assistant said, with its **bold** rendered.
///
/// `Text(someString)` does NOT parse markdown — only a string LITERAL is
/// treated as a localised key and styled. The plans are built at runtime, so
/// their emphasis would otherwise reach the teacher as literal asterisks.
///
/// `.inlineOnlyPreservingWhitespace` is the interpretation that matters:
/// the default one treats the text as a markdown DOCUMENT and throws the line
/// breaks away, which would run a plan's headings and its list into one
/// paragraph. This keeps the layout and styles only what is inline.
///
/// Anything that fails to parse is shown exactly as it arrived. A stray
/// asterisk in a page title should look odd, never swallow the message.
@MainActor
enum AssistSaid {

    // MARK: - Functions

    static func styled(_ text: String) -> AttributedString {
        if let parsed = try? AttributedString(
            markdown: text,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            return parsed
        }
        return AttributedString(text)
    }
}

/// The two bubble colours.
///
/// **Not `Color.accentColor`.** That is whatever accent the teacher has chosen
/// in System Settings, and it is not always blue: set to graphite it would
/// make the teacher's bubbles grey — the same grey as the assistant's — and
/// the whole left/right, blue/grey distinction the window relies on would
/// quietly disappear. Messages does not follow the accent either; its blue is
/// its own.
///
/// The blue is SAMPLED from a Messages bubble rather than guessed: 20, 147,
/// 255. The obvious candidates are all near it and none is it — the system
/// blue is (0, 122, 255) and its dark variant (10, 132, 255) — and being a
/// few points out is exactly the sort of thing that reads as "nearly right",
/// which is worse than clearly different.
///
/// Taken from a dark-appearance screenshot. Messages appears to use the same
/// blue in both appearances, and this is used in both; if it turns out to
/// differ in light mode, this is the one place to say so.
enum AssistBubbleColour {

    // MARK: - Stored properties

    static let teacher: Color = Color(red: 20 / 255, green: 147 / 255, blue: 255 / 255)

    /// The assistant's side stays a system grey, so it follows the
    /// appearance the way the surrounding window does.
    static let assistant: Color = Color.secondary.opacity(0.16)
}

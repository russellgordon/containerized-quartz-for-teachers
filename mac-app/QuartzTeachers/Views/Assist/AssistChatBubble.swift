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

/// A chat bubble shaped like the one macOS Messages draws.
///
/// **The tail does not hang below the bubble.** That was the structural
/// mistake in the first two attempts: a tail drawn beneath the body reads as a
/// spike hanging off a box, whichever way it is curved. In Messages the tail's
/// lowest point is LEVEL with the bubble's bottom edge — it bulges sideways
/// out of the bottom corner and curls back underneath itself, so the bubble
/// keeps one flat baseline and the tail looks like part of the same blob.
///
/// The curve below is the well-known reconstruction of Apple's own path, and
/// the odd-looking constants (17, 4, 11.04, 7.61…) are kept as they are rather
/// than rounded off, because they are what makes it read as the real thing
/// rather than as an imitation. The body's edge on the tail side sits four
/// points inside the rect, and the tail fills that strip — which is also why
/// bubbles with and without tails line up down the column: every bubble gives
/// up the same four points, and only the tailed one uses them.
struct AssistChatBubbleShape: Shape {

    // MARK: - Stored properties

    let side: AssistChatSide
    let hasTail: Bool

    /// The strip on the tail's side that the body gives up, so the tail has
    /// somewhere to go without being clipped or knocking bubbles out of line.
    static let reach: CGFloat = 4

    /// Messages' own corner radius. Bubbles here are at least 34 points tall
    /// (nine points of padding above and below a line of text), so it never
    /// has to be clamped in practice — but it is, for the day something short
    /// is put in one.
    private let corner: CGFloat = 17

    // MARK: - Functions

    func path(in rect: CGRect) -> Path {
        // Both sides give up the same strip, tail or no tail, so a run of
        // bubbles has one straight edge down the column.
        var body: CGRect = rect
        body.size.width -= AssistChatBubbleShape.reach
        if side == .assistant {
            body.origin.x += AssistChatBubbleShape.reach
        }

        // Messages' geometry is written for a bubble at least twice its
        // corner radius tall. Below that the top and bottom curves would
        // overlap and the tail would take a third of the bubble's height —
        // which is exactly what a too-short bubble looked like. So the whole
        // figure is SCALED rather than clipped, and stays in proportion at
        // any size.
        let radius: CGFloat = min(corner, rect.height / 2)
        let unit: CGFloat = radius / corner

        guard hasTail, side != .neither else {
            return Path(roundedRect: body, cornerRadius: radius)
        }

        // Worked out left-to-right for the teacher's side, then mirrored.
        // `at` flips the x of every point when the tail belongs on the left,
        // so there is one path to read and one to get right.
        let flip: Bool = (side == .assistant)
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            let across: CGFloat = flip ? (rect.maxX - x) : (rect.minX + x)
            return CGPoint(x: across, y: rect.minY + y)
        }

        let width: CGFloat = rect.width
        let height: CGFloat = rect.height

        // Apple's own numbers, in seventeenths of the corner radius. They are
        // kept as measured rather than rounded off: the proportions are what
        // make it read as the real thing rather than as an impression of it.
        let cornerPull: CGFloat = 7.61 * unit     // how far a corner's curve reaches
        let tailStart: CGFloat = 22 * unit        // where the bottom edge gives way to the tail
        let topRight: CGFloat = 21 * unit
        let edge: CGFloat = AssistChatBubbleShape.reach * unit   // body edge inside the rect
        let tailRise: CGFloat = 11 * unit         // how far up the edge the tail begins
        let hookIn: CGFloat = 11.04 * unit        // where the hook returns into the bubble
        let hookUp: CGFloat = 4.04 * unit

        var path: Path = Path()
        path.move(to: at(width - tailStart, height))
        path.addLine(to: at(radius, height))
        path.addCurve(to: at(0, height - radius),
                      control1: at(cornerPull, height), control2: at(0, height - cornerPull))
        path.addLine(to: at(0, radius))
        path.addCurve(to: at(radius, 0), control1: at(0, cornerPull), control2: at(cornerPull, 0))
        path.addLine(to: at(width - topRight, 0))
        path.addCurve(to: at(width - edge, radius),
                      control1: at(width - topRight + cornerPull * 1.3, 0),
                      control2: at(width - edge, cornerPull))

        // Down the body's edge, then the tail: out past the edge, round the
        // tip, and back underneath into the bubble's own bottom — which is
        // why the bubble keeps ONE flat baseline and the tail reads as part
        // of the same blob rather than a spike hung off it.
        path.addLine(to: at(width - edge, height - tailRise))
        path.addCurve(to: at(width, height),
                      control1: at(width - edge, height - 1 * unit), control2: at(width, height))
        path.addLine(to: at(width + 0.05, height - 0.01))
        path.addCurve(to: at(width - hookIn, height - hookUp),
                      control1: at(width - 4.07 * unit, height + 0.43 * unit),
                      control2: at(width - 8.16 * unit, height - 1.06 * unit))
        path.addCurve(to: at(width - tailStart, height),
                      control1: at(width - 16 * unit, height), control2: at(width - 19 * unit, height))
        path.closeSubpath()
        return path
    }
}

/// The assistant thinking, as three dots that breathe.
///
/// The conversation used to go silent between the teacher pressing return and
/// the answer arriving — several seconds in which the only honest reading was
/// that nothing had happened. Everyone who has used a messaging app knows
/// what three pulsing dots mean, so nothing has to be explained.
struct AssistTypingIndicator: View {

    // MARK: - Stored properties

    /// Drives the animation. Toggled once when the view appears; the phase
    /// difference between the dots comes from each dot's delay, not from
    /// three separate pieces of state.
    @State private var isBreathing: Bool = false

    // MARK: - Computed properties

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 7, height: 7)
                    .opacity(isBreathing ? 0.9 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.18),
                        value: isBreathing
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            AssistChatBubbleShape(side: .assistant, hasTail: false)
                .fill(Color.secondary.opacity(0.16))
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            isBreathing = true
        }
        // Read out as one thing rather than three dots.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The assistant is working")
        .accessibilityIdentifier("assistTypingIndicator")
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

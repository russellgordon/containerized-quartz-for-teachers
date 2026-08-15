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
/// **The tail hangs BELOW the bubble.** This was got wrong twice in opposite
/// directions, so it is worth stating plainly: the tip sits below the bubble's
/// bottom edge and outside its side, and the underside of the tail curves back
/// up INTO the bubble's bottom edge. A tail that only bulges sideways looks
/// like a wedge stuck on the corner; a tail made of straight lines looks like
/// a spike. It is the concave underside — the hook — that makes it read as a
/// tail rather than as a shape that happens to be pointy.
///
/// Everything is drawn INSIDE the rect the background is given: the body gives
/// up a strip below and to its own side, and the tail lives in that strip.
/// Anything drawn outside is clipped, and a clipped tail is severed rather than
/// pointed.
///
/// Proportions scale with the corner radius rather than being fixed, so a
/// short bubble and a tall one look like the same design. Both sides give up
/// the same strip whether or not they have a tail, so a run of bubbles keeps
/// one straight edge down the column.
struct AssistChatBubbleShape: Shape {

    // MARK: - Stored properties

    let side: AssistChatSide
    let hasTail: Bool

    /// The strip the tail needs: below the bubble, and beyond its side.
    static let drop: CGFloat = 6
    static let reach: CGFloat = 7

    /// Messages' corner radius, clamped for bubbles too short to take it.
    private let corner: CGFloat = 17

    // MARK: - Functions

    func path(in rect: CGRect) -> Path {
        // Every bubble gives up the same strip, tail or no tail, so a run of
        // them lines up down the column.
        var body: CGRect = rect
        body.size.width -= AssistChatBubbleShape.reach
        body.size.height -= AssistChatBubbleShape.drop
        if side == .assistant {
            body.origin.x += AssistChatBubbleShape.reach
        }

        let radius: CGFloat = min(corner, body.height / 2)

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

        let drop: CGFloat = AssistChatBubbleShape.drop
        let reach: CGFloat = AssistChatBubbleShape.reach

        var path: Path = Path()

        // Top edge, left to right.
        path.move(to: at(body.minX + radius, body.minY))
        path.addLine(to: at(body.maxX - radius, body.minY))
        path.addQuadCurve(to: at(body.maxX, body.minY + radius),
                          control: at(body.maxX, body.minY))

        // Down the right edge, stopping where the tail begins.
        path.addLine(to: at(body.maxX, body.maxY - radius * 0.55))

        // Out and DOWN to the tip, below the bubble's bottom and beyond its
        // side. The first control keeps it flush with the edge as it leaves,
        // so the tail grows out of the bubble instead of being attached to it.
        path.addCurve(
            to: at(body.maxX + reach, body.maxY + drop),
            control1: at(body.maxX, body.maxY - radius * 0.1),
            control2: at(body.maxX + reach * 0.45, body.maxY + drop * 0.45)
        )

        // The hook: back up and in, concave, rejoining the bottom edge. This
        // curve is the whole difference between a tail and a spike.
        path.addCurve(
            to: at(body.maxX - radius * 0.6, body.maxY),
            control1: at(body.maxX + reach * 0.1, body.maxY + drop * 0.1),
            control2: at(body.maxX - radius * 0.1, body.maxY)
        )

        // Bottom edge back to the left, and up the far side.
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

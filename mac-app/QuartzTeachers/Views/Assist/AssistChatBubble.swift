import SwiftUI

/// Which side of the conversation something belongs to.
nonisolated enum AssistChatSide: Equatable {

    case teacher
    case assistant

    /// Nothing anyone said — a restore, a tool's result line. These sit in
    /// the middle of the flow rather than in a bubble, because a bubble is a
    /// claim that somebody SAID it, and a note about what happened is not
    /// something anybody said.
    case neither
}

/// Where a batch of messages ends, and therefore where the tail goes.
///
/// A tail on every bubble makes a run of three messages look like three
/// separate interruptions. One tail, on the LAST message a participant sends
/// before the other one answers, is what reads as a turn — the same rule
/// iMessage uses, which is why it is the rule a teacher will already expect
/// without being able to say so.
@MainActor
enum AssistChatLayout {

    // MARK: - Functions

    static func side(of speaker: AssistAgent.Entry.Speaker) -> AssistChatSide {
        switch speaker {
        case .teacher:
            return .teacher
        case .assistant:
            return .assistant
        case .toolResult, .problem:
            return .neither
        }
    }

    /// Whether the bubble at `index` is the last of its participant's run.
    ///
    /// Looks PAST anything that is not a bubble. A tool result between two
    /// things the assistant said does not end the assistant's turn — nobody
    /// spoke, something merely happened — so a tail there would break one
    /// answer into two.
    static func showsTail(at index: Int, in speakers: [AssistAgent.Entry.Speaker]) -> Bool {
        guard speakers.indices.contains(index) else {
            return false
        }
        let mine: AssistChatSide = side(of: speakers[index])
        if mine == .neither {
            return false
        }
        var next: Int = index + 1
        while next < speakers.count {
            let theirs: AssistChatSide = side(of: speakers[next])
            if theirs != .neither {
                return theirs != mine
            }
            next += 1
        }
        // Nothing said after it, so it is the end of the run so far.
        return true
    }
}

/// A chat bubble, with a curved tail when it ends a turn.
///
/// **One continuous outline, not a rectangle with a triangle stuck on it.**
/// The first version added the tail as a second subpath hanging off the
/// corner, and it showed: a hard spike with a visible notch where the two
/// shapes met. Overlapping subpaths only merge cleanly under a non-zero fill
/// AND matching winding directions, which is a lot to hold true by accident —
/// so the outline is walked once, and the tail is simply part of the walk.
///
/// **The tail is drawn INSIDE the rect.** The first version drew below
/// `rect.maxY`, outside the bounds the background was given, so the tip was
/// clipped — which is most of why it looked severe. The body is now inset by
/// the tail's drop and the tail lives in the strip beneath it, so nothing is
/// ever cut off.
///
/// The curve itself is two arcs rather than two straight lines: it leaves the
/// bubble tangentially, swells outward, and hooks back in — the way a
/// speech tail does. A triangle points; a tail flows out of what said it.
struct AssistChatBubbleShape: Shape {

    // MARK: - Stored properties

    let side: AssistChatSide
    let hasTail: Bool

    /// How far the tail hangs below the bubble body, and how far it reaches
    /// sideways. Modest on purpose: a big tail on "Undo that" is more tail
    /// than message.
    static let drop: CGFloat = 7
    static let reach: CGFloat = 7
    private let corner: CGFloat = 15

    // MARK: - Functions

    func path(in rect: CGRect) -> Path {
        guard hasTail, side != .neither else {
            return Path(roundedRect: rect, cornerRadius: corner)
        }

        // The bubble body gives up the strip the tail needs — below it, and
        // to its own side — so the whole outline stays inside the rect the
        // background was handed. Anything drawn outside that rect is clipped,
        // and a clipped tail is exactly what made the first attempt look like
        // a severed spike.
        var body: CGRect = rect
        body.size.height -= AssistChatBubbleShape.drop
        body.size.width -= AssistChatBubbleShape.reach
        if side == .assistant {
            body.origin.x += AssistChatBubbleShape.reach
        }

        var path: Path = Path()
        let radius: CGFloat = min(corner, body.height / 2)
        let tipY: CGFloat = body.maxY + AssistChatBubbleShape.drop

        if side == .teacher {
            // Clockwise from the top-left, with the tail replacing the
            // bottom-RIGHT corner.
            path.move(to: CGPoint(x: body.minX + radius, y: body.minY))
            path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
            path.addQuadCurve(to: CGPoint(x: body.maxX, y: body.minY + radius),
                              control: CGPoint(x: body.maxX, y: body.minY))
            // Down the right edge, then out into the tail: a shallow swell
            // outward…
            path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
            path.addQuadCurve(to: CGPoint(x: body.maxX + AssistChatBubbleShape.reach, y: tipY),
                              control: CGPoint(x: body.maxX + AssistChatBubbleShape.reach * 0.5, y: body.maxY))
            // …then the hook back in, which is what stops it reading as a
            // spike. The control point sits INSIDE the bubble's edge, so the
            // return curve is concave.
            path.addQuadCurve(to: CGPoint(x: body.maxX - radius * 1.2, y: body.maxY),
                              control: CGPoint(x: body.maxX - radius * 0.35, y: body.maxY))
            path.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
            path.addQuadCurve(to: CGPoint(x: body.minX, y: body.maxY - radius),
                              control: CGPoint(x: body.minX, y: body.maxY))
            path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
            path.addQuadCurve(to: CGPoint(x: body.minX + radius, y: body.minY),
                              control: CGPoint(x: body.minX, y: body.minY))
        } else {
            // The mirror image, tail at the bottom-LEFT.
            path.move(to: CGPoint(x: body.maxX - radius, y: body.minY))
            path.addLine(to: CGPoint(x: body.minX + radius, y: body.minY))
            path.addQuadCurve(to: CGPoint(x: body.minX, y: body.minY + radius),
                              control: CGPoint(x: body.minX, y: body.minY))
            path.addLine(to: CGPoint(x: body.minX, y: body.maxY - radius))
            path.addQuadCurve(to: CGPoint(x: body.minX - AssistChatBubbleShape.reach, y: tipY),
                              control: CGPoint(x: body.minX - AssistChatBubbleShape.reach * 0.5, y: body.maxY))
            path.addQuadCurve(to: CGPoint(x: body.minX + radius * 1.2, y: body.maxY),
                              control: CGPoint(x: body.minX + radius * 0.35, y: body.maxY))
            path.addLine(to: CGPoint(x: body.maxX - radius, y: body.maxY))
            path.addQuadCurve(to: CGPoint(x: body.maxX, y: body.maxY - radius),
                              control: CGPoint(x: body.maxX, y: body.maxY))
            path.addLine(to: CGPoint(x: body.maxX, y: body.minY + radius))
            path.addQuadCurve(to: CGPoint(x: body.maxX - radius, y: body.minY),
                              control: CGPoint(x: body.maxX, y: body.minY))
        }
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

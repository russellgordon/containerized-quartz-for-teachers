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

/// A chat bubble: a rounded rectangle, with a tail when it ends a turn.
///
/// Drawn rather than assembled from a rectangle and a triangle, so the tail
/// joins the body as one filled outline. Two shapes overlapping look right
/// until the bubble is translucent or has a border, and then the seam shows.
struct AssistChatBubbleShape: Shape {

    // MARK: - Stored properties

    let side: AssistChatSide
    let hasTail: Bool

    /// Kept modest on purpose: a large tail on a short message ("Undo that")
    /// takes up more of the bubble than the words do.
    private let tailWidth: CGFloat = 9
    private let tailHeight: CGFloat = 9
    private let corner: CGFloat = 14

    // MARK: - Functions

    func path(in rect: CGRect) -> Path {
        var path: Path = Path(roundedRect: rect, cornerRadius: corner)
        guard hasTail, side != .neither else {
            return path
        }

        // Sits just above the bottom corner and sweeps down and outward, the
        // way a spoken tail points back at whoever said it.
        var tail: Path = Path()
        if side == .assistant {
            tail.move(to: CGPoint(x: rect.minX + corner, y: rect.maxY))
            tail.addLine(to: CGPoint(x: rect.minX - tailWidth, y: rect.maxY + tailHeight))
            tail.addLine(to: CGPoint(x: rect.minX + corner, y: rect.maxY - corner))
        } else {
            tail.move(to: CGPoint(x: rect.maxX - corner, y: rect.maxY))
            tail.addLine(to: CGPoint(x: rect.maxX + tailWidth, y: rect.maxY + tailHeight))
            tail.addLine(to: CGPoint(x: rect.maxX - corner, y: rect.maxY - corner))
        }
        tail.closeSubpath()
        path.addPath(tail)
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

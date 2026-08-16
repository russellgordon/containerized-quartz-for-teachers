import AppKit
import SwiftUI

/// Bubble text whose selection highlight is the system's, not SwiftUI's.
///
/// SwiftUI's `.textSelection(.enabled)` on macOS draws its own selection in a
/// flat grey, with nothing to style it by — put beside Messages, where
/// selecting a word paints the accent's light blue, the difference is
/// immediately visible. An `NSTextField` label selects through AppKit's field
/// editor, which uses `selectedTextBackgroundColor` — the same light blue
/// Messages shows — so the text is wrapped rather than fought.
///
/// Sizing is the part worth explaining: a wrapping label has no natural width,
/// so `sizeThatFits` answers SwiftUI's proposal by measuring the text within
/// the proposed width. Without it the label claims one endless line.
/// The label whose selection is painted Messages' way: a fixed light blue
/// behind the selected run, with the glyphs in the bubble's own colour —
/// measured off a highlighted word in both apps side by side, where the
/// system's DARK-mode `selectedTextBackgroundColor` (63, 99, 139) read as
/// grey next to Messages' pinned (174, 218, 255). Messages pins the
/// light-appearance selection because its bubbles keep their colours in
/// either appearance; so does this.
///
/// The colours are applied to the window's field editor when the label takes
/// first-responder status, which is when AppKit attaches the editor that
/// draws selection.
final class BubbleSelectionTextField: NSTextField {

    // MARK: - Stored properties

    /// Messages' selection blue, from the side-by-side measurement.
    static let selectionBackground: NSColor = NSColor(
        srgbRed: 174 / 255, green: 218 / 255, blue: 255 / 255, alpha: 1
    )

    /// The bubble's own fill, which is what the selected glyphs wear.
    var selectionGlyph: NSColor = NSColor.black

    // MARK: - Functions

    /// The label's cell is where the colours are applied, because the cell is
    /// what AppKit asks when it attaches the field editor. Applying them in
    /// `becomeFirstResponder` was tried and silently did nothing: for a
    /// SELECTABLE label — unlike an editable field — the editor does not
    /// exist yet when that returns, so `currentEditor()` is nil and the
    /// selection keeps the system's colours. Proved in a harness that made
    /// the field first responder and printed "no field editor".
    override class var cellClass: AnyClass? {
        get { BubbleSelectionCell.self }
        set { }
    }
}

/// Hands the field editor Messages' selection colours at the moment AppKit
/// attaches it — the one hook that runs on every path into selection.
final class BubbleSelectionCell: NSTextFieldCell {

    // MARK: - Functions

    override func setUpFieldEditorAttributes(_ textObj: NSText) -> NSText {
        let editor: NSText = super.setUpFieldEditorAttributes(textObj)
        if let textView = editor as? NSTextView {
            let glyph: NSColor = (controlView as? BubbleSelectionTextField)?.selectionGlyph
                ?? NSColor.labelColor
            textView.selectedTextAttributes = [
                .backgroundColor: BubbleSelectionTextField.selectionBackground,
                .foregroundColor: glyph,
            ]
        }
        return editor
    }
}

struct SelectableBubbleText: NSViewRepresentable {

    // MARK: - Stored properties

    let text: String

    /// White on the teacher's blue; the label colour on the assistant's grey.
    let colour: NSColor

    /// The bubble's fill — what the selected glyphs are painted in, the way
    /// Messages does it.
    let bubbleFill: NSColor

    // MARK: - Functions

    func makeNSView(context: Context) -> NSTextField {
        let field: BubbleSelectionTextField = BubbleSelectionTextField(labelWithString: "")
        field.lineBreakMode = .byWordWrapping
        field.maximumNumberOfLines = 0
        field.isSelectable = true
        field.allowsEditingTextAttributes = false
        field.drawsBackground = false
        field.focusRingType = .none
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        field.attributedStringValue = SelectableBubbleText.styled(text, colour: colour)
        if let field = field as? BubbleSelectionTextField {
            field.selectionGlyph = bubbleFill
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize, nsView: NSTextField, context: Context
    ) -> CGSize? {
        guard let cell = nsView.cell else {
            return nil
        }
        let width: CGFloat = proposal.width ?? CGFloat.greatestFiniteMagnitude
        let bounds: NSRect = NSRect(
            x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude
        )
        let measured: NSSize = cell.cellSize(forBounds: bounds)
        return CGSize(width: min(width, ceil(measured.width)), height: ceil(measured.height))
    }

    /// The same **bold** rendering `AssistSaid.styled` gives SwiftUI, carried
    /// into AppKit by hand.
    ///
    /// The hand-carrying is not optional: converting an `AttributedString`
    /// straight to `NSAttributedString` keeps the markdown INTENT ("this run
    /// is strongly emphasised") but no AppKit font, so the emphasis silently
    /// disappears when AppKit draws it. Each run gets the real font here.
    static func styled(_ text: String, colour: NSColor) -> NSAttributedString {
        let parsed: AttributedString = AssistSaid.styled(text)
        let base: NSFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let bold: NSFont = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)

        let result: NSMutableAttributedString = NSMutableAttributedString()
        for run in parsed.runs {
            let piece: String = String(parsed[run.range].characters)
            let isBold: Bool = run.inlinePresentationIntent?.contains(.stronglyEmphasized) ?? false
            result.append(NSAttributedString(
                string: piece,
                attributes: [
                    .font: isBold ? bold : base,
                    .foregroundColor: colour,
                ]
            ))
        }
        return result
    }
}

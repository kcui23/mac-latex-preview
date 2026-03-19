import Foundation

struct LatexDetector {
    /// Check if text likely contains LaTeX formulas
    static func containsLatex(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Dollar sign delimiters
        if trimmed.contains("$") { return true }

        // Bracket/paren delimiters: \[ \] \( \)
        if trimmed.contains("\\[") || trimmed.contains("\\]") { return true }
        if trimmed.contains("\\(") || trimmed.contains("\\)") { return true }

        // LaTeX commands: backslash followed by letters
        if trimmed.range(of: "\\\\[a-zA-Z]+", options: .regularExpression) != nil { return true }

        // Superscript/subscript with braces
        if trimmed.contains("^{") || trimmed.contains("_{") { return true }

        return false
    }

    /// Extract LaTeX formula and determine display mode
    static func extractLatex(_ text: String) -> (latex: String, displayMode: Bool) {
        var latex = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var displayMode = true

        if latex.hasPrefix("$$") && latex.hasSuffix("$$") && latex.count > 4 {
            latex = String(latex.dropFirst(2).dropLast(2))
            displayMode = true
        } else if latex.hasPrefix("$") && latex.hasSuffix("$") && latex.count > 2 {
            latex = String(latex.dropFirst(1).dropLast(1))
            displayMode = false
        } else if latex.hasPrefix("\\[") && latex.hasSuffix("\\]") {
            latex = String(latex.dropFirst(2).dropLast(2))
            displayMode = true
        } else if latex.hasPrefix("\\(") && latex.hasSuffix("\\)") {
            latex = String(latex.dropFirst(2).dropLast(2))
            displayMode = false
        }

        return (latex.trimmingCharacters(in: .whitespacesAndNewlines), displayMode)
    }
}

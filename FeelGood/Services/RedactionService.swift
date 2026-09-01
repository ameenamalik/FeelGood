//
//  RedactionService.swift
//  FeelGood
//
//  On-device redaction and sanitization pipeline for conversational check-in
//  (PRD §7.5.8, Decision 15).
//
//  Ensures that personal identifiers (email, phone, URLs) and sensitive/reproductive
//  health terms are scrubbed on-device before any text leaves the phone for the
//  Worker parsing endpoint.
//

import Foundation

nonisolated struct RedactionService: Sendable {
    static let shared = RedactionService()

    /// Reproductive and sensitive health terms that must never leave the device unredacted (PRD Decision 15).
    private static let sensitiveKeywords: [String] = [
        "period", "periods", "menstrual", "menstruation", "menstruating",
        "ovulation", "ovulating", "pregnant", "pregnancy", "postpartum",
        "pelvic floor", "bleeding", "spotting", "cramping", "cramps",
        "luteal", "follicular", "miscarriage", "trimester", "breastfeeding"
    ]

    /// Regular expressions for PII.
    private static let emailRegex = try? NSRegularExpression(
        pattern: #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#,
        options: .caseInsensitive
    )

    private static let phoneRegex = try? NSRegularExpression(
        pattern: #"(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"#,
        options: []
    )

    private static let urlRegex = try? NSRegularExpression(
        pattern: #"https?://[^\s]+"#,
        options: .caseInsensitive
    )

    /// Sanitizes the user input by redacting emails, phone numbers, URLs, and sensitive health terms.
    func sanitize(_ input: String) -> String {
        var text = input

        // 1. Redact URLs
        if let urlRegex = Self.urlRegex {
            let range = NSRange(text.startIndex..., in: text)
            text = urlRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "[link]")
        }

        // 2. Redact Emails
        if let emailRegex = Self.emailRegex {
            let range = NSRange(text.startIndex..., in: text)
            text = emailRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "[email]")
        }

        // 3. Redact Phone numbers
        if let phoneRegex = Self.phoneRegex {
            let range = NSRange(text.startIndex..., in: text)
            text = phoneRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "[phone]")
        }

        // 4. Redact Sensitive Health / Reproductive Keywords (whole words)
        for keyword in Self.sensitiveKeywords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                text = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "[body-state]")
            }
        }

        return text
    }

    /// Checks if the input contained any sensitive terms or PII.
    func containsSensitiveData(_ input: String) -> Bool {
        sanitize(input) != input
    }
}

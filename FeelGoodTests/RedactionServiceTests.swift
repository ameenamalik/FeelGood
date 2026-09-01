//
//  RedactionServiceTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Redaction Service")
struct RedactionServiceTests {
    let redactor = RedactionService.shared

    @Test("Clean text passes through unchanged")
    func cleanTextUnchanged() {
        let input = "I have 15 minutes, feeling low energy and stiff back"
        #expect(redactor.sanitize(input) == input)
        #expect(!redactor.containsSensitiveData(input))
    }

    @Test("Emails and phone numbers are redacted")
    func piiIsRedacted() {
        let textWithEmail = "Contact me at user@example.com before my 20 min session"
        let sanitizedEmail = redactor.sanitize(textWithEmail)
        #expect(sanitizedEmail.contains("[email]"))
        #expect(!sanitizedEmail.contains("user@example.com"))

        let textWithPhone = "Call 555-123-4567 or 555 123 4567 for info"
        let sanitizedPhone = redactor.sanitize(textWithPhone)
        #expect(sanitizedPhone.contains("[phone]"))
        #expect(!sanitizedPhone.contains("555-123-4567"))
    }

    @Test("Sensitive reproductive and health terms are redacted on-device")
    func reproductiveTermsRedacted() {
        let input = "I am on my period with heavy cramping and feeling exhausted"
        let sanitized = redactor.sanitize(input)
        #expect(!sanitized.lowercased().contains("period"))
        #expect(!sanitized.lowercased().contains("cramping"))
        #expect(sanitized.contains("[body-state]"))
        #expect(redactor.containsSensitiveData(input))
    }

    @Test("Postpartum and pelvic floor keywords are scrubbed")
    func postpartumScrubbed() {
        let input = "6 months postpartum, need gentle pelvic floor movement"
        let sanitized = redactor.sanitize(input)
        #expect(!sanitized.lowercased().contains("postpartum"))
        #expect(!sanitized.lowercased().contains("pelvic floor"))
        #expect(redactor.containsSensitiveData(input))
    }

    @Test("URLs and links are scrubbed")
    func urlsScrubbed() {
        let input = "Check https://example.com/routine for my workout"
        let sanitized = redactor.sanitize(input)
        #expect(!sanitized.contains("https://example.com"))
        #expect(sanitized.contains("[link]"))
    }
}

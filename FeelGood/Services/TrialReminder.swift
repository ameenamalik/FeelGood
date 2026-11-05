//
//  TrialReminder.swift
//  FeelGood
//
//  A free trial that ends in a charge should never be a surprise. One local
//  notification goes out the day before the trial ends, and only when the
//  person has already allowed notifications. Nothing here prompts; the ask
//  lives on the post-purchase reminder screen.
//

import Foundation
import RevenueCat
import UserNotifications

/// The decisions, kept apart from UserNotifications so they can be tested
/// with plain dates.
nonisolated enum TrialReminderPlan {
    static let identifier = "feelgood.trial-reminder"

    /// A trial is worth reminding about only while it is running and will
    /// turn into a charge. A cancelled trial ends quietly.
    static func shouldRemind(_ status: ProSubscriptionStatus) -> Bool {
        status.phase == .trial && status.willRenew && status.expirationDate != nil
    }

    /// One day before the trial ends, moved into waking hours (9:00 to
    /// 20:00) so a purchase at 2 a.m. does not become a 2 a.m. buzz. `nil`
    /// when that moment has already passed.
    static func fireDate(trialEnd: Date, now: Date = .now, calendar: Calendar = .current) -> Date? {
        let target = trialEnd.addingTimeInterval(-24 * 60 * 60)
        var parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: target)
        let hour = parts.hour ?? 10
        if hour < 9 {
            parts.hour = 9
            parts.minute = 0
        } else if hour > 20 || (hour == 20 && (parts.minute ?? 0) > 0) {
            parts.hour = 20
            parts.minute = 0
        }
        guard let date = calendar.date(from: parts),
              date > now.addingTimeInterval(60),
              date < trialEnd
        else { return nil }
        return date
    }

    /// `price` is the localized amount with its period ("$34.99 a year"),
    /// read from StoreKit by the caller. Without it the line stays true but
    /// does not name a figure.
    static func content(price: String?) -> (title: String, body: String) {
        let body: String
        if let price {
            body = "Your free trial ends tomorrow, then it's \(price). Cancel any time in Settings."
        } else {
            body = "Your free trial ends tomorrow, then FeelGood Pro renews. Cancel any time in Settings."
        }
        return ("Your free trial ends tomorrow", body)
    }
}

@MainActor
final class TrialReminderScheduler {
    static let shared = TrialReminderScheduler()

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// True when iOS would let a reminder through, or has never been asked.
    func authorizationIsUndecided() async -> Bool {
        await authorization().isUndecided
    }

    /// Makes the pending reminder match the subscription. Safe to call as
    /// often as the subscription changes: it replaces by identifier, cancels
    /// when the trial is cancelled, converted or gone, and does nothing
    /// (and asks for nothing) when notifications are not allowed.
    func sync(status: ProSubscriptionStatus?, price: String?, now: Date = .now) async {
        guard let status,
              TrialReminderPlan.shouldRemind(status),
              let trialEnd = status.expirationDate,
              let fireDate = TrialReminderPlan.fireDate(trialEnd: trialEnd, now: now)
        else {
            cancel()
            return
        }

        let permission = await authorization()
        guard permission.allowsReminder else {
            return
        }

        let copy = TrialReminderPlan.content(price: price)
        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.userInfo = ["destination": "today"]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let request = UNNotificationRequest(
            identifier: TrialReminderPlan.identifier,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        center.removePendingNotificationRequests(withIdentifiers: [TrialReminderPlan.identifier])
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            center.add(request) { _ in continuation.resume() }
        }
    }

    /// Only sendable flags leave the callback; older iOS SDKs do not mark
    /// UNNotificationSettings as safe to transfer across concurrency contexts.
    private func authorization() async -> (isUndecided: Bool, allowsReminder: Bool) {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                let status = settings.authorizationStatus
                continuation.resume(returning: (
                    isUndecided: status == .notDetermined,
                    allowsReminder: status == .authorized || status == .provisional
                ))
            }
        }
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [TrialReminderPlan.identifier])
    }
}

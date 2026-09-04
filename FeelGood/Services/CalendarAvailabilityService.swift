//
//  CalendarAvailabilityService.swift
//  FeelGood
//
//  Calendar stays a source of anonymous availability, never content. Event
//  titles, notes, people, locations, and links do not cross this file.
//

@preconcurrency import EventKit
import Foundation

nonisolated enum CalendarConnectionState: Sendable, Equatable {
    case notRequested
    case connected
    case denied
}

/// The only calendar-derived value the rest of the app can see.
nonisolated struct CalendarBusyInterval: Hashable, Sendable {
    let start: Date
    let end: Date
}

/// A proposed opening. It remains a suggestion until the person explicitly
/// chooses it in the check-in; FeelGood never writes it back to Calendar.
nonisolated enum CalendarOpeningContext: Hashable, Sendable {
    case beforeNextEvent
    case openForRestOfDay
    case openToday
    case uncertain
}

nonisolated struct CalendarOpening: Hashable, Sendable {
    let start: Date
    let end: Date
    let budget: TimeBudget
    let context: CalendarOpeningContext

    init(
        start: Date,
        end: Date,
        budget: TimeBudget,
        context: CalendarOpeningContext = .uncertain
    ) {
        self.start = start
        self.end = end
        self.budget = budget
        self.context = context
    }
}

/// A calendar event whose title matched a small, on-device movement
/// vocabulary. The title itself is deliberately discarded at this boundary.
nonisolated struct CalendarMovementPlan: Hashable, Sendable, Identifiable {
    let id: String
    let start: Date
    let end: Date
    let activity: Activity

    var durationMinutes: Int {
        max(1, Int(end.timeIntervalSince(start) / 60))
    }
}

/// Pure, conservative title matching. A miss only means the event remains an
/// ordinary busy interval; a false positive would ask an intrusive question.
nonisolated enum CalendarMovementTitleClassifier {
    static func activity(for title: String) -> Activity? {
        let normalized = title
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()
        let words = Set(normalized.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))

        func hasWord(_ candidates: String...) -> Bool {
            candidates.contains(where: words.contains)
        }

        func hasPhrase(_ candidates: String...) -> Bool {
            candidates.contains(where: normalized.contains)
        }

        if hasWord("pilates", "reformer") { return .pilates }
        if hasWord("yoga") { return .yoga }
        if hasWord("qigong") || hasPhrase("qi gong", "tai chi") { return .qigong }
        if hasWord("swim", "swimming") { return .swimming }
        if hasWord("bike", "biking", "cycling", "spin") { return .biking }
        if hasWord("skate", "skating") { return .skating }
        if hasWord("dance", "dancing", "zumba") { return .dance }
        if hasPhrase("jump rope") { return .jumpRope }
        if hasWord("tennis", "pickleball", "badminton", "squash") { return .racquet }
        if hasWord("climb", "climbing", "bouldering") { return .climbing }
        if hasWord("boxing", "kickboxing", "judo", "karate") || hasPhrase("martial arts") {
            return .martialArts
        }
        if hasWord("breathwork") || hasPhrase("breath work") { return .breathwork }
        if hasWord("stretch", "stretching", "mobility") { return .stretching }
        if hasWord("walk", "walking", "hike", "hiking") { return .walking }
        if hasWord("lifting", "weightlifting", "crossfit", "workout")
            || hasPhrase("strength training", "gym session", "personal training") {
            return .strength
        }
        return nil
    }
}

/// Local-only decisions prevent the same calendar event being asked about on
/// every check-in. Only opaque event identifiers are stored, never titles.
@MainActor
enum CalendarMovementPreferences {
    static let recognitionEnabledKey = "calendarMovementRecognitionEnabled"
    private static let handledEventIDsKey = "calendarMovementHandledEventIDs"

    static func isHandled(_ eventID: String, defaults: UserDefaults = .standard) -> Bool {
        Set(defaults.stringArray(forKey: handledEventIDsKey) ?? []).contains(eventID)
    }

    static func markHandled(_ eventID: String, defaults: UserDefaults = .standard) {
        var ids = defaults.stringArray(forKey: handledEventIDsKey) ?? []
        ids.removeAll(where: { $0 == eventID })
        ids.append(eventID)
        defaults.set(Array(ids.suffix(100)), forKey: handledEventIDsKey)
    }
}

@MainActor
protocol CalendarAvailabilityProviding: AnyObject {
    var connectionState: CalendarConnectionState { get }

    func requestAccess() async -> CalendarConnectionState
    func suggestedOpening(
        on date: Date,
        preferredTime: TimeOfDay,
        realisticMinutes: Int,
        calendar: Calendar
    ) async throws -> CalendarOpening?

    /// Call only after the person explicitly enables title recognition.
    func movementPlans(on date: Date, calendar: Calendar) async throws -> [CalendarMovementPlan]
}

/// Deterministic stand-in for previews and view-level tests. Keeping it beside
/// the protocol makes the EventKit boundary replaceable everywhere it is used.
@MainActor
final class InMemoryCalendarAvailabilityService: CalendarAvailabilityProviding {
    var connectionState: CalendarConnectionState
    var opening: CalendarOpening?
    var plans: [CalendarMovementPlan]

    init(
        connectionState: CalendarConnectionState = .connected,
        opening: CalendarOpening? = nil,
        plans: [CalendarMovementPlan] = []
    ) {
        self.connectionState = connectionState
        self.opening = opening
        self.plans = plans
    }

    func requestAccess() async -> CalendarConnectionState {
        connectionState
    }

    func suggestedOpening(
        on date: Date,
        preferredTime: TimeOfDay,
        realisticMinutes: Int,
        calendar: Calendar
    ) async throws -> CalendarOpening? {
        opening
    }

    func movementPlans(on date: Date, calendar: Calendar) async throws -> [CalendarMovementPlan] {
        plans
    }
}

@MainActor
final class EventKitCalendarAvailabilityService: CalendarAvailabilityProviding {
    static let shared = EventKitCalendarAvailabilityService()

    private let store: EKEventStore

    init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    var connectionState: CalendarConnectionState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            .connected
        case .notDetermined:
            .notRequested
        case .denied, .restricted, .writeOnly:
            .denied
        @unknown default:
            .denied
        }
    }

    func requestAccess() async -> CalendarConnectionState {
        do {
            return try await store.requestFullAccessToEvents() ? .connected : .denied
        } catch {
            return .denied
        }
    }

    func suggestedOpening(
        on date: Date,
        preferredTime: TimeOfDay,
        realisticMinutes: Int,
        calendar: Calendar
    ) async throws -> CalendarOpening? {
        guard connectionState == .connected else { return nil }

        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
        let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil)

        // Deliberately copy only temporal facts. No other EKEvent property is
        // allowed beyond this adapter.
        let busy = store.events(matching: predicate).compactMap { event -> CalendarBusyInterval? in
            guard event.status != .canceled, event.availability != .free else { return nil }
            return CalendarBusyInterval(start: event.startDate, end: event.endDate)
        }

        return CalendarOpeningFinder.bestOpening(
            on: date,
            busy: busy,
            preferredTime: preferredTime,
            realisticMinutes: realisticMinutes,
            calendar: calendar
        )
    }

    func movementPlans(on date: Date, calendar: Calendar) async throws -> [CalendarMovementPlan] {
        guard connectionState == .connected else { return [] }

        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil)

        return store.events(matching: predicate).compactMap { event in
            guard
                event.status != .canceled,
                let activity = CalendarMovementTitleClassifier.activity(for: event.title ?? "")
            else { return nil }

            let fallbackID = [
                "calendar",
                String(event.startDate.timeIntervalSinceReferenceDate),
                String(event.endDate.timeIntervalSinceReferenceDate),
                activity.rawValue,
            ].joined(separator: "-")
            return CalendarMovementPlan(
                id: event.eventIdentifier ?? fallbackID,
                start: event.startDate,
                end: event.endDate,
                activity: activity
            )
        }
        .sorted { $0.start < $1.start }
    }
}

/// Pure availability arithmetic, separate from EventKit so boundaries and
/// unhappy paths can be tested without a permission prompt or a device.
nonisolated enum CalendarOpeningFinder {
    static func bestOpening(
        on now: Date,
        busy: [CalendarBusyInterval],
        preferredTime: TimeOfDay,
        realisticMinutes: Int,
        calendar: Calendar,
        bufferMinutes: Int = 10
    ) -> CalendarOpening? {
        let dayStart = calendar.startOfDay(for: now)
        guard
            let sevenAM = calendar.date(byAdding: .hour, value: 7, to: dayStart),
            let ninePM = calendar.date(byAdding: .hour, value: 21, to: dayStart)
        else { return nil }

        let searchStart = max(roundUpToFiveMinutes(now, calendar: calendar), sevenAM)
        guard searchStart < ninePM else { return nil }

        let buffered = busy.compactMap { interval -> CalendarBusyInterval? in
            let start = calendar.date(byAdding: .minute, value: -bufferMinutes, to: interval.start) ?? interval.start
            let end = calendar.date(byAdding: .minute, value: bufferMinutes, to: interval.end) ?? interval.end
            let clippedStart = max(start, searchStart)
            let clippedEnd = min(end, ninePM)
            guard clippedStart < clippedEnd else { return nil }
            return CalendarBusyInterval(start: clippedStart, end: clippedEnd)
        }
        .sorted { $0.start < $1.start }

        let merged = merge(buffered)
        var openings: [(start: Date, end: Date)] = []
        var cursor = searchStart

        for interval in merged {
            if cursor < interval.start {
                openings.append((cursor, interval.start))
            }
            cursor = max(cursor, interval.end)
        }
        if cursor < ninePM {
            openings.append((cursor, ninePM))
        }

        let candidates = openings.compactMap { opening -> CalendarOpening? in
            let available = max(0, Int(opening.end.timeIntervalSince(opening.start) / 60))
            let capped = min(available, max(realisticMinutes, 5))
            guard let budget = fittingBudget(minutes: capped) else { return nil }
            return CalendarOpening(
                start: opening.start,
                end: opening.end,
                budget: budget,
                context: openingContext(for: opening, busy: busy)
            )
        }

        return candidates.sorted {
            let lhsMatches = matchesPreference($0, preferredTime: preferredTime, calendar: calendar)
            let rhsMatches = matchesPreference($1, preferredTime: preferredTime, calendar: calendar)
            if lhsMatches != rhsMatches { return lhsMatches }
            if $0.budget.maxMinutes != $1.budget.maxMinutes {
                return $0.budget.maxMinutes > $1.budget.maxMinutes
            }
            return $0.start < $1.start
        }.first
    }

    private static func merge(_ intervals: [CalendarBusyInterval]) -> [CalendarBusyInterval] {
        intervals.reduce(into: []) { merged, interval in
            guard let last = merged.last else {
                merged.append(interval)
                return
            }
            guard interval.start <= last.end else {
                merged.append(interval)
                return
            }
            merged[merged.count - 1] = CalendarBusyInterval(
                start: last.start,
                end: max(last.end, interval.end)
            )
        }
    }

    private static func fittingBudget(minutes: Int) -> TimeBudget? {
        TimeBudget.allCases
            .filter { $0.maxMinutes <= minutes }
            .max { $0.maxMinutes < $1.maxMinutes }
    }

    /// Calendar data is context, not proof that the person is available. This
    /// classification deliberately exposes no event content to the UI.
    private static func openingContext(
        for opening: (start: Date, end: Date),
        busy: [CalendarBusyInterval]
    ) -> CalendarOpeningContext {
        if busy.contains(where: { $0.start > opening.start }) {
            return .beforeNextEvent
        }
        return busy.isEmpty ? .openToday : .openForRestOfDay
    }

    private static func matchesPreference(
        _ opening: CalendarOpening,
        preferredTime: TimeOfDay,
        calendar: Calendar
    ) -> Bool {
        guard preferredTime != .varies else { return true }
        let midpoint = opening.start.addingTimeInterval(opening.end.timeIntervalSince(opening.start) / 2)
        return TimeOfDay(hour: calendar.component(.hour, from: midpoint)) == preferredTime
    }

    private static func roundUpToFiveMinutes(_ date: Date, calendar: Calendar) -> Date {
        guard let minuteInterval = calendar.dateInterval(of: .minute, for: date) else { return date }
        let minute = calendar.component(.minute, from: minuteInterval.start)
        let minutesToAdd = (5 - minute % 5) % 5
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: minuteInterval.start) ?? date
    }
}

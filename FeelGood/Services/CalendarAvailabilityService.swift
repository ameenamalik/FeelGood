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
}

/// Deterministic stand-in for previews and view-level tests. Keeping it beside
/// the protocol makes the EventKit boundary replaceable everywhere it is used.
@MainActor
final class InMemoryCalendarAvailabilityService: CalendarAvailabilityProviding {
    var connectionState: CalendarConnectionState
    var opening: CalendarOpening?

    init(
        connectionState: CalendarConnectionState = .connected,
        opening: CalendarOpening? = nil
    ) {
        self.connectionState = connectionState
        self.opening = opening
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

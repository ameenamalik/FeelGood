//
//  CalendarAvailabilityService.swift
//  FeelGood
//
//  Calendar stays a source of anonymous availability, never content. Event
//  titles, notes, people, locations, and links do not cross this file.
//

@preconcurrency import EventKit
import Foundation
@preconcurrency import UserNotifications

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

    /// The part of the opening FeelGood is actually proposing, rather than
    /// the whole free block that may extend for hours.
    var suggestedEnd: Date {
        min(end, start.addingTimeInterval(TimeInterval(budget.maxMinutes * 60)))
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

/// The one small session FeelGood can place around movement that is already
/// on somebody's calendar. It is deliberately a before/after suggestion, not
/// another appointment or a second "main" to complete.
nonisolated enum CalendarMovementCompanionPhase: Hashable, Sendable {
    case warmUp
    case recovery
}

/// Pure, deterministic selection keeps Calendar personalization testable and
/// on-device. Event titles never enter this selector; it only receives the
/// coarse activity that the title classifier already produced.
nonisolated enum CalendarMovementCompanionSelector {
    static func session(
        for plan: CalendarMovementPlan,
        phase: CalendarMovementCompanionPhase,
        from sessions: [Session],
        profile: PlanProfile
    ) -> Session? {
        let targetFocus = bodyFocus(for: plan.activity)
        let preferredActivities: Set<Activity> = switch phase {
        case .warmUp: [.stretching, .qigong, .agility]
        case .recovery: [.stretching, .breathwork, .qigong]
        }

        return sessions
            .filter { candidate in
                candidate.durationMin > 0
                    && candidate.durationMin <= 5
                    && candidate.intensity <= 2
                    && candidate.needsNoEquipment
                    && candidate.worksAtHome
                    && !candidate.source.isVideo
                    && !profile.hiddenSessionIDs.contains(candidate.id)
                    && Set(candidate.contraindications).isDisjoint(with: profile.workArounds)
                    && (candidate.activity.isAlwaysAvailable
                        || profile.availableActivities.contains(candidate.activity))
                    && preferredActivities.contains(candidate.activity)
                    && candidate.activity != plan.activity
            }
            .sorted { lhs, rhs in
                let lhsScore = score(lhs, phase: phase, targetFocus: targetFocus)
                let rhsScore = score(rhs, phase: phase, targetFocus: targetFocus)
                if lhsScore != rhsScore { return lhsScore > rhsScore }
                if lhs.durationMin != rhs.durationMin { return lhs.durationMin < rhs.durationMin }
                return lhs.id < rhs.id
            }
            .first
    }

    private static func score(
        _ session: Session,
        phase: CalendarMovementCompanionPhase,
        targetFocus: Set<BodyFocus>
    ) -> Int {
        let focus = Set(session.bodyFocus)
        var result = focus.isDisjoint(with: targetFocus) ? 0 : 12
        if focus.contains(.full) { result += 3 }
        if session.qualities.contains(.mobility) { result += 8 }

        switch phase {
        case .warmUp:
            if session.activity == .stretching { result += 5 }
            if session.qualities.contains(.balance) || session.qualities.contains(.coordination) {
                result += 2
            }
        case .recovery:
            if session.qualities.contains(.downRegulation) { result += 10 }
            if session.activity == .breathwork { result += 4 }
            result += max(0, 3 - session.intensity)
        }

        return result
    }

    private static func bodyFocus(for activity: Activity) -> Set<BodyFocus> {
        switch activity {
        case .pilates:
            [.core, .hips, .back]
        case .yoga:
            [.full, .hips, .back]
        case .strength:
            [.full, .upperBody, .lowerBody, .core]
        case .walking, .running, .biking, .skating, .jumpRope, .agility:
            [.lowerBody, .hips]
        case .swimming, .racquet, .climbing, .carries:
            [.upperBody, .back, .full]
        case .martialArts:
            [.full, .hips, .lowerBody]
        case .generalWellness:
            []
        case .qigong, .stretching, .dance, .breathwork:
            [.full]
        }
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

        if hasWord("pilates", "reformer", "barre") { return .pilates }
        if hasWord("yoga") { return .yoga }
        if hasWord("qigong") || hasPhrase("qi gong", "tai chi") { return .qigong }
        if hasWord("swim", "swimming", "aquafit", "aquacise")
            || hasPhrase("water aerobics") { return .swimming }
        if hasWord("bike", "biking", "cycle", "cycling", "spin", "spinning", "peloton") {
            return .biking
        }
        if hasWord("skate", "skating", "rollerblade", "rollerblading") { return .skating }
        if hasWord("dance", "dancing", "zumba", "ballet", "salsa", "tap") { return .dance }
        if hasWord("jumprope", "skipping") || hasPhrase("jump rope") { return .jumpRope }
        if hasWord(
            "tennis", "pickleball", "badminton", "squash",
            "basketball", "soccer", "football", "volleyball",
            "baseball", "softball", "rugby", "cricket", "hockey",
            "lacrosse", "handball", "netball", "golf", "futsal"
        ) { return .racquet }
        if hasWord("climb", "climbing", "bouldering") { return .climbing }
        if hasWord(
            "boxing", "kickboxing", "judo", "karate", "taekwondo",
            "jiujitsu", "wrestling", "muaythai"
        ) || hasPhrase("martial arts", "muay thai", "jiu jitsu", "jui jitsu") {
            return .martialArts
        }
        if hasWord("breathwork", "meditation") || hasPhrase("breath work") { return .breathwork }
        if hasWord("stretch", "stretching", "mobility", "foamrolling")
            || hasPhrase("foam rolling") { return .stretching }
        if hasWord("walk", "walking", "hike", "hiking", "trek", "trekking") { return .walking }
        if hasWord(
            "gym", "lifting", "weightlifting", "weights", "crossfit", "workout",
            "strength", "powerlifting", "bodybuilding", "calisthenics", "resistance",
            "rowing", "row"
        ) || hasPhrase("strength training", "gym session", "personal training", "weight training") {
            return .strength
        }
        if hasWord("run", "running", "jog", "jogging") { return .running }
        if hasWord(
            "sprint", "sprinting",
            "cardio", "hiit", "bootcamp", "aerobics", "gymnastics",
            "ski", "skiing", "snowboard", "snowboarding", "surf", "surfing",
            "kayak", "kayaking", "paddleboard", "paddleboarding"
        ) || hasPhrase("circuit training", "track practice") {
            return .agility
        }
        return nil
    }
}

/// Local-only decisions prevent the same calendar event being asked about on
/// every check-in. Only opaque event identifiers are stored, never titles.
@MainActor
enum CalendarMovementPreferences {
    static let personalizationEnabledKey = "calendarPersonalizationEnabled"
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
    func suggestedOpenings(
        on date: Date,
        preferredTime: TimeOfDay,
        realisticMinutes: Int,
        calendar: Calendar
    ) async throws -> [CalendarOpening]
    func isOpeningStillAvailable(_ opening: CalendarOpening, calendar: Calendar) async throws -> Bool

    /// Call only after the person explicitly enables title recognition.
    func movementPlans(on date: Date, calendar: Calendar) async throws -> [CalendarMovementPlan]
}

extension CalendarAvailabilityProviding {
    func suggestedOpenings(
        on date: Date,
        preferredTime: TimeOfDay,
        realisticMinutes: Int,
        calendar: Calendar
    ) async throws -> [CalendarOpening] {
        if let opening = try await suggestedOpening(
            on: date,
            preferredTime: preferredTime,
            realisticMinutes: realisticMinutes,
            calendar: calendar
        ) {
            return [opening]
        }
        return []
    }
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

    func isOpeningStillAvailable(_ opening: CalendarOpening, calendar: Calendar) async throws -> Bool {
        self.opening == opening
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
        try await suggestedOpenings(
            on: date,
            preferredTime: preferredTime,
            realisticMinutes: realisticMinutes,
            calendar: calendar
        ).first
    }

    func suggestedOpenings(
        on date: Date,
        preferredTime: TimeOfDay,
        realisticMinutes: Int,
        calendar: Calendar
    ) async throws -> [CalendarOpening] {
        guard connectionState == .connected else { return [] }

        let dayStart = calendar.startOfDay(for: date)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }
        let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: nil)

        // Deliberately copy only temporal facts. No other EKEvent property is
        // allowed beyond this adapter.
        let busy = store.events(matching: predicate).compactMap { event -> CalendarBusyInterval? in
            guard event.status != .canceled, event.availability != .free else { return nil }
            return CalendarBusyInterval(start: event.startDate, end: event.endDate)
        }

        return CalendarOpeningFinder.rankedOpenings(
            on: date,
            busy: busy,
            preferredTime: preferredTime,
            realisticMinutes: realisticMinutes,
            calendar: calendar
        )
    }

    func isOpeningStillAvailable(_ opening: CalendarOpening, calendar: Calendar) async throws -> Bool {
        guard connectionState == .connected else { return false }

        let buffer: TimeInterval = 10 * 60
        let predicate = store.predicateForEvents(
            withStart: opening.start.addingTimeInterval(-buffer),
            end: opening.suggestedEnd.addingTimeInterval(buffer),
            calendars: nil
        )
        return !store.events(matching: predicate).contains { event in
            guard event.status != .canceled, event.availability != .free else { return false }
            let busyStart = event.startDate.addingTimeInterval(-buffer)
            let busyEnd = event.endDate.addingTimeInterval(buffer)
            return busyStart < opening.suggestedEnd && busyEnd > opening.start
        }
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

            // An EventKit identifier can survive edits. Include the anonymous
            // temporal/activity fingerprint so changing Yoga into Gym (or
            // moving it to a new time) becomes a new plan instead of inheriting
            // the old plan's handled decision.
            let planID = [
                event.eventIdentifier ?? "calendar",
                String(event.startDate.timeIntervalSinceReferenceDate),
                String(event.endDate.timeIntervalSinceReferenceDate),
                activity.rawValue,
            ].joined(separator: "-")
            return CalendarMovementPlan(
                id: planID,
                start: event.startDate,
                end: event.endDate,
                activity: activity
            )
        }
        .sorted { $0.start < $1.start }
    }
}

/// A reminder is only created after a person explicitly asks for one. It is a
/// local notification: Calendar remains read-only and no event data leaves the
/// device.
@MainActor
final class CalendarOpeningReminderService {
    static let shared = CalendarOpeningReminderService()
    static let notificationID = "feelgood.calendar-opening-reminder"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func schedule(for opening: CalendarOpening) async -> Bool {
        guard OneSignalManager.shared.isPushEnabled, opening.start.timeIntervalSinceNow > 30 else { return false }

        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            do {
                guard try await center.requestAuthorization(options: [.alert, .sound]) else { return false }
            } catch {
                return false
            }
        } else if settings.authorizationStatus != .authorized && settings.authorizationStatus != .provisional {
            return false
        }

        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        let content = UNMutableNotificationContent()
        content.title = "Your FeelGood opening is here"
        content.body = "You set aside \(opening.budget.maxMinutes) minutes for a reset."
        content.sound = .default
        content.userInfo = ["destination": "today"]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: opening.start
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        do {
            try await center.add(UNNotificationRequest(
                identifier: Self.notificationID,
                content: content,
                trigger: trigger
            ))
            return true
        } catch {
            return false
        }
    }

    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
    }

    func isScheduled() async -> Bool {
        await center.pendingNotificationRequests().contains { $0.identifier == Self.notificationID }
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
        rankedOpenings(
            on: now,
            busy: busy,
            preferredTime: preferredTime,
            realisticMinutes: realisticMinutes,
            calendar: calendar,
            bufferMinutes: bufferMinutes,
            limit: 1
        ).first
    }

    /// Returns one recommended opening plus genuinely different alternatives.
    /// The first item is always the best fit. When available, the second is a
    /// sooner option and the third is the nearest later option.
    static func rankedOpenings(
        on now: Date,
        busy: [CalendarBusyInterval],
        preferredTime: TimeOfDay,
        realisticMinutes: Int,
        calendar: Calendar,
        bufferMinutes: Int = 10,
        limit: Int = 3
    ) -> [CalendarOpening] {
        guard limit > 0 else { return [] }
        let dayStart = calendar.startOfDay(for: now)
        guard
            let sevenAM = calendar.date(byAdding: .hour, value: 7, to: dayStart),
            let ninePM = calendar.date(byAdding: .hour, value: 21, to: dayStart)
        else { return [] }

        let searchStart = max(roundUpToFiveMinutes(now, calendar: calendar), sevenAM)
        guard searchStart < ninePM else { return [] }

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

        let anchorHours = [9, 12, 18]
        let candidates = openings.flatMap { opening -> [CalendarOpening] in
            let anchors = anchorHours.compactMap { hour in
                calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dayStart)
            }
            let possibleStarts = [opening.start] + anchors.filter {
                $0 > opening.start && $0 < opening.end
            }

            return possibleStarts.compactMap { start in
                let available = max(0, Int(opening.end.timeIntervalSince(start) / 60))
                let capped = min(available, max(realisticMinutes, 5))
                guard let budget = fittingBudget(minutes: capped) else { return nil }
                return CalendarOpening(
                    start: start,
                    end: opening.end,
                    budget: budget,
                    context: openingContext(for: (start, opening.end), busy: busy)
                )
            }
        }

        let ranked = candidates.sorted {
            let lhsMatches = matchesPreference($0, preferredTime: preferredTime, calendar: calendar)
            let rhsMatches = matchesPreference($1, preferredTime: preferredTime, calendar: calendar)
            if lhsMatches != rhsMatches { return lhsMatches }
            if $0.budget.maxMinutes != $1.budget.maxMinutes {
                return $0.budget.maxMinutes > $1.budget.maxMinutes
            }
            return $0.start < $1.start
        }

        guard let best = ranked.first else { return [] }
        var result = [best]

        if let sooner = candidates
            .filter({ $0.start < best.start && isDistinct($0, from: result) })
            .min(by: { $0.start < $1.start }) {
            result.append(sooner)
        }
        if result.count < limit, let later = candidates
            .filter({ $0.start > best.start && isDistinct($0, from: result) })
            .min(by: { $0.start < $1.start }) {
            result.append(later)
        }

        for candidate in ranked where result.count < limit && isDistinct(candidate, from: result) {
            result.append(candidate)
        }
        return Array(result.prefix(limit))
    }

    private static func isDistinct(_ candidate: CalendarOpening, from selected: [CalendarOpening]) -> Bool {
        let minimumSeparation: TimeInterval = 30 * 60
        return selected.allSatisfy { abs($0.start.timeIntervalSince(candidate.start)) >= minimumSeparation }
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
            .filter { $0.maxMinutes > 0 && $0.maxMinutes <= minutes }
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
        let midpoint = opening.start.addingTimeInterval(opening.suggestedEnd.timeIntervalSince(opening.start) / 2)
        return TimeOfDay(hour: calendar.component(.hour, from: midpoint)) == preferredTime
    }

    private static func roundUpToFiveMinutes(_ date: Date, calendar: Calendar) -> Date {
        guard let minuteInterval = calendar.dateInterval(of: .minute, for: date) else { return date }
        let minute = calendar.component(.minute, from: minuteInterval.start)
        let minutesToAdd = (5 - minute % 5) % 5
        return calendar.date(byAdding: .minute, value: minutesToAdd, to: minuteInterval.start) ?? date
    }
}

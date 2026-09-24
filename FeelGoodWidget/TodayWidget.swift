//
//  TodayWidget.swift
//  FeelGoodWidget
//
//  One line on the home screen: the thing worth doing today. It shows what the
//  app has already decided — the widget never plans, never scores, and never
//  counts. No streak, no ring, no "you haven't opened this in 4 days".
//
//  An empty or stale snapshot is not an error state. It renders an invitation,
//  because the app has no visual language for absence and neither does this.
//

import AppIntents
import SwiftUI
import WidgetKit

/// Long-press → Edit Widget.
nonisolated enum WidgetLook: String, AppEnum {
    /// Your fruit on a soft colour.
    case fruit
    /// The plain card with the tinted course pill.
    case plain

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Style"
    static let caseDisplayRepresentations: [WidgetLook: DisplayRepresentation] = [
        .fruit: "Fruit",
        .plain: "Plain",
    ]
}

nonisolated enum WidgetTint: String, AppEnum {
    /// Whatever colour the fruit has in the app.
    case match, blush, apricot, butter, sage, lilac

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Colour"
    static let caseDisplayRepresentations: [WidgetTint: DisplayRepresentation] = [
        .match: "Match my fruit",
        .blush: "Blush",
        .apricot: "Apricot",
        .butter: "Butter",
        .sage: "Sage",
        .lilac: "Lilac",
    ]
}

nonisolated struct TodayWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Today"
    static let description = IntentDescription("Pick a look for your Today widget.")

    @Parameter(title: "Style", default: .fruit)
    var look: WidgetLook

    @Parameter(title: "Colour", default: .match)
    var tint: WidgetTint
}

struct TodayEntry: TimelineEntry {
    let date: Date
    /// The one thing this hour's entry says. `nil` renders the invitation.
    let item: TodayItem?
    var appearance: WidgetAppearance = .fallback
    var look: WidgetLook = .fruit
    var tint: WidgetTint = .match

    /// The colour behind the fruit: the person's override, else the fruit's own.
    var aura: WidgetAura {
        WidgetAura(rawValue: tint == .match ? appearance.auraRaw : tint.rawValue) ?? .apricot
    }
}

struct TodayProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, item: .preview)
    }

    func snapshot(for configuration: TodayWidgetIntent, in context: Context) async -> TodayEntry {
        entry(for: configuration, now: .now, snapshot: context.isPreview ? .preview : current(now: .now))
    }

    func timeline(for configuration: TodayWidgetIntent, in context: Context) async -> Timeline<TodayEntry> {
        let calendar = Calendar.current
        let now = Date()
        let snapshot = current(now: now)
        let midnight = calendar.startOfDay(for: now.addingTimeInterval(86_400))

        // One entry now, then one at the top of every hour until the day turns
        // over, each with a different item from the menu. WidgetKit does not let
        // a widget refresh on unlock, so a pre-built hourly rotation is the
        // reliable way to make the home screen feel alive. The app also nudges
        // the timeline whenever the menu changes.
        var dates = [now]
        var next = calendar.nextDate(after: now, matching: DateComponents(minute: 0, second: 0),
                                     matchingPolicy: .nextTime) ?? midnight
        while next < midnight {
            dates.append(next)
            next = calendar.date(byAdding: .hour, value: 1, to: next) ?? midnight
        }
        let entries = dates.map { entry(for: configuration, now: $0, snapshot: snapshot) }
        return Timeline(entries: entries, policy: .after(midnight))
    }

    private func entry(for configuration: TodayWidgetIntent, now: Date, snapshot: TodaySnapshot?) -> TodayEntry {
        TodayEntry(
            date: now,
            item: snapshot?.item(atHour: Calendar.current.component(.hour, from: now)),
            appearance: SharedContainer.readAppearance() ?? .fallback,
            look: configuration.look,
            tint: configuration.tint
        )
    }

    /// A snapshot from an earlier day is discarded rather than shown. Yesterday's
    /// suggestion presented as today's would be a small lie.
    private func current(now: Date) -> TodaySnapshot? {
        guard let snapshot = SharedContainer.readSnapshot(),
              snapshot.isCurrent(on: now, calendar: .current)
        else { return nil }
        return snapshot
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "TodayWidget", intent: TodayWidgetIntent.self,
                               provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { background(for: entry) }
        }
        .configurationDisplayName("Today")
        .description("The one thing worth doing today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    @ViewBuilder
    private func background(for entry: TodayEntry) -> some View {
        switch entry.look {
        case .fruit:
            LinearGradient(colors: [entry.aura.core, entry.aura.mid],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        case .plain:
            WidgetPalette.surface
        }
    }
}

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    private var item: TodayItem? { entry.item }
    private var isFruit: Bool { entry.look == .fruit }
    /// The aura never flips with the appearance (neither does the app's), so on
    /// it the ink doesn't either.
    private var ink: Color { isFruit ? WidgetPalette.inkOnAccent : WidgetPalette.ink }
    private var inkMuted: Color {
        isFruit ? WidgetPalette.inkOnAccent.opacity(0.72) : WidgetPalette.inkMuted
    }

    var body: some View {
        content
            // Opens the session it is showing, not just the app.
            .widgetURL(item.flatMap { DeepLink.session($0.sessionID) })
    }

    @ViewBuilder
    private var content: some View {
        if isFruit, family == .systemMedium {
            HStack(alignment: .center, spacing: 12) {
                text
                mascot(size: 88)
            }
        } else if isFruit {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 4) {
                    if let item { courseTag(item) }
                    Spacer(minLength: 4)
                    mascot(size: 40)
                }
                text(showingTag: false)
            }
        } else {
            text
        }
    }

    private var text: some View { text(showingTag: !isFruit || family == .systemMedium) }

    private func text(showingTag: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let item {
                if showingTag { courseTag(item) }
                Text(item.title)
                    .font(.system(family == .systemSmall ? .subheadline : .headline,
                                  design: .rounded).weight(.semibold))
                    .foregroundStyle(ink)
                    .lineLimit(family == .systemSmall ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                if family != .systemSmall, !item.reason.isEmpty {
                    Text(item.reason)
                        .font(.subheadline)
                        .foregroundStyle(inkMuted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(item.isDone ? "Done" : item.durationLabel)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(inkMuted)
            } else {
                Text("Today")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(inkMuted)
                    .textCase(.uppercase)
                Text("Open when you're ready.")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mascot(size: CGFloat) -> some View {
        Image(WidgetMascot.imageName(for: entry.appearance.avatarRaw))
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private func courseTag(_ item: TodayItem) -> some View {
        Text(item.courseLabel)
            .font(.system(size: family == .systemSmall ? 9 : 11,
                          weight: .semibold,
                          design: .rounded))
            .textCase(.uppercase)
            .tracking(family == .systemSmall ? 0.6 : 1.1)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
            .allowsTightening(true)
            // Ink on the accent, always. The accents are far too light to carry
            // white text, and this one does not flip with the appearance.
            .foregroundStyle(WidgetPalette.inkOnAccent)
            .padding(.horizontal, family == .systemSmall ? 6 : 8)
            .padding(.vertical, 3)
            // On a fruit colour the course accent would vanish into it, so the
            // pill goes translucent white there.
            .background(Capsule().fill(isFruit ? Color.white.opacity(0.55) : Color(hex: item.accentHex)))
    }
}

/// The widget's own list of mascot artwork, keyed by `ProfileAvatar.rawValue`.
/// Downsized copies live in the widget's asset catalog: a home-screen widget
/// has a small memory budget and the app's originals are 1254px.
enum WidgetMascot {
    static let known: Set<String> = ["apple", "plum", "banana", "pear", "blueberry", "peach", "clementine", "lime"]

    static func imageName(for raw: String) -> String {
        "mascot-\(known.contains(raw) ? raw : "apple")"
    }
}

/// Restated from `FGAura` for the same reason as `WidgetPalette`: importing the
/// design system would cost the extension the whole app. Keep the hexes in step.
enum WidgetAura: String {
    case apricot, lilac, blush, sage, butter, sky

    var core: Color {
        switch self {
        case .apricot: Color(hex: 0xFCE3D2)
        case .lilac: Color(hex: 0xF1E4EB)
        case .blush: Color(hex: 0xFCE2E8)
        case .sage: Color(hex: 0xEAF0DE)
        case .butter: Color(hex: 0xFFF8D8)
        case .sky: Color(hex: 0xE2F1F7)
        }
    }

    var mid: Color {
        switch self {
        case .apricot: Color(hex: 0xF7C8A8)
        case .lilac: Color(hex: 0xE2CAD6)
        case .blush: Color(hex: 0xF2C4D3)
        case .sage: Color(hex: 0xC6D8BE)
        case .butter: Color(hex: 0xF4DF91)
        case .sky: Color(hex: 0xBEDCE8)
        }
    }
}

/// The four tokens the widget needs, restated.
///
/// The design system lives in the app target and pulls in `Course` and the rest
/// of the content model with it; importing that here to get three colours would
/// cost the extension the whole app. These values must stay in step with
/// `FGColor` — they are the same hexes, for the same reasons.
enum WidgetPalette {
    static let surface = Color(light: 0xFFFFFF, dark: 0x181C20)
    static let ink = Color(light: 0x14171A, dark: 0xF7F8FA)
    static let inkMuted = Color(light: 0x565E6B, dark: 0xA8B0BC)
    /// Does not flip: the accent underneath it doesn't either.
    static let inkOnAccent = Color(light: 0x14171A, dark: 0x14171A)
}

nonisolated extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// Resolves per appearance. `nonisolated` is load-bearing — SwiftUI
    /// resolves colours on a background rendering thread, and a MainActor
    /// provider closure traps the process the first time one is drawn.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

extension TodayItem {
    static let preview = TodayItem(
        sessionID: "main-pilates-gentle-10",
        courseLabel: "Appetizer",
        accentHex: 0xC7EA4E,
        title: "Ten gentle minutes on the mat",
        reason: "An easy way back in.",
        durationLabel: "10 min",
        isDone: false
    )
}

extension TodaySnapshot {
    static let preview = TodaySnapshot(day: .now, items: [.preview])
}

#Preview("Small · fruit", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, item: .preview, appearance: .init(avatarRaw: "peach", auraRaw: "blush"))
    TodayEntry(date: .now, item: nil, appearance: .init(avatarRaw: "peach", auraRaw: "blush"))
}

#Preview("Small · plain", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, item: .preview, look: .plain)
    TodayEntry(date: .now, item: nil, look: .plain)
}

#Preview("Medium · fruit", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, item: .preview, appearance: .init(avatarRaw: "pear", auraRaw: "sage"))
}

#Preview("Medium · plain", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, item: .preview, look: .plain)
}

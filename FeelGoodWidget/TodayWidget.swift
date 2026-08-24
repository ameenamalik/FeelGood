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

import SwiftUI
import WidgetKit

struct TodayEntry: TimelineEntry {
    let date: Date
    let snapshot: TodaySnapshot?
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: .now, snapshot: context.isPreview ? .preview : current()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date()
        let entry = TodayEntry(date: now, snapshot: current(now: now))
        // Refresh at the next local midnight: the menu is a day at a time, so
        // there is nothing to say until the day turns over. The app also nudges
        // the timeline whenever it regenerates.
        let midnight = Calendar.current.startOfDay(for: now.addingTimeInterval(86_400))
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    /// A snapshot from an earlier day is discarded rather than shown. Yesterday's
    /// suggestion presented as today's would be a small lie.
    private func current(now: Date = .now) -> TodaySnapshot? {
        guard let snapshot = SharedContainer.readSnapshot(),
              snapshot.isCurrent(on: now, calendar: .current)
        else { return nil }
        return snapshot
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { entry in
            TodayWidgetView(snapshot: entry.snapshot)
                .containerBackground(WidgetPalette.surface, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("The one thing worth doing today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayWidgetView: View {
    let snapshot: TodaySnapshot?
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let snapshot {
                courseTag(snapshot)
                Text(snapshot.title)
                    .font(.system(family == .systemSmall ? .subheadline : .headline,
                                  design: .rounded).weight(.semibold))
                    .foregroundStyle(WidgetPalette.ink)
                    .lineLimit(family == .systemSmall ? 3 : 2)
                    .fixedSize(horizontal: false, vertical: true)

                if family != .systemSmall, !snapshot.reason.isEmpty {
                    Text(snapshot.reason)
                        .font(.subheadline)
                        .foregroundStyle(WidgetPalette.inkMuted)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Text(snapshot.isDone ? "Done" : snapshot.durationLabel)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(WidgetPalette.inkMuted)
            } else {
                Text("Today")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(WidgetPalette.inkMuted)
                    .textCase(.uppercase)
                Text("Open when you're ready.")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(WidgetPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Opens the session it is showing, not just the app.
        .widgetURL(snapshot.flatMap { DeepLink.session($0.sessionID) })
    }

    private func courseTag(_ snapshot: TodaySnapshot) -> some View {
        Text(snapshot.courseLabel)
            .font(.system(.caption2, design: .rounded).weight(.medium))
            .textCase(.uppercase)
            .tracking(1.1)
            // Ink on the accent, always. The accents are far too light to carry
            // white text, and this one does not flip with the appearance.
            .foregroundStyle(WidgetPalette.inkOnAccent)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color(hex: snapshot.accentHex)))
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

extension TodaySnapshot {
    static let preview = TodaySnapshot(
        day: .now,
        sessionID: "main-pilates-gentle-10",
        courseLabel: "Main",
        accentHex: 0xC7EA4E,
        title: "Ten gentle minutes on the mat",
        reason: "An easy way back in.",
        durationLabel: "10 min",
        isDone: false
    )
}

#Preview("Small", as: .systemSmall) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview)
    TodayEntry(date: .now, snapshot: nil)
}

#Preview("Medium", as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayEntry(date: .now, snapshot: .preview)
}

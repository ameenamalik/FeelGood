//
//  ActivityHistorySection.swift
//  FeelGood
//
//  A dedicated, chronological log of completed movement sessions.
//  Honors FeelGood's no-guilt philosophy: days with no sessions are never
//  rendered, no streaks or counts are demanded, and every session is valued.
//

import SwiftUI

struct ActivityHistorySection: View {
    let model: TodayModel
    private let previewLimit = 5

    private var completedEntries: [HistoryEntry] {
        model.history
            .filter { $0.wasCompleted }
            .sorted { $0.date > $1.date }
    }

    private var previewEntries: [HistoryEntry] {
        Array(completedEntries.prefix(previewLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            header

            if completedEntries.isEmpty {
                emptyCard
            } else {
                ActivityHistoryList(entries: previewEntries, model: model)

                if completedEntries.count > previewLimit {
                    NavigationLink {
                        ActivityHistoryView(entries: completedEntries, model: model)
                    } label: {
                        HStack(spacing: FGSpace.s) {
                            Text("View all sessions")
                                .font(FGFont.label.weight(.semibold))

                            Spacer()

                            Text("\(completedEntries.count)")
                                .font(FGFont.label.weight(.semibold))
                                .foregroundStyle(FGColor.inkMuted)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(FGColor.ink)
                        .padding(.horizontal, FGSpace.m)
                        .frame(minHeight: FGSize.minTouchTarget)
                        .background(FGColor.surface, in: Capsule())
                        .overlay(Capsule().strokeBorder(FGColor.lineStrong, lineWidth: 1))
                    }
                    .buttonStyle(.feelGoodPress)
                    .accessibilityLabel("View all \(completedEntries.count) completed sessions")
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Your past sessions")
                .font(FGFont.title)
                .foregroundStyle(FGColor.ink)

            Spacer()

            if !completedEntries.isEmpty {
                Text("\(completedEntries.count) completed")
                    .font(FGFont.label)
                    .foregroundStyle(FGColor.inkMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(FGColor.surface)
                    .clipShape(.capsule)
                    .overlay(Capsule().strokeBorder(FGColor.line, lineWidth: 1))
            }
        }
    }

    private var emptyCard: some View {
        HStack(spacing: FGSpace.m) {
            Image("MascotShowingUpBanana")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .padding(6)
                .background(FGAura.butter.core, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(FGAura.butter.mid.opacity(0.7), lineWidth: 1)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: FGSpace.xs) {
                Text("Nothing here yet")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)

                Text("Completed routines will appear here.")
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
            }

            Spacer()
        }
        .padding(FGSpace.s)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .strokeBorder(FGColor.line, lineWidth: 1)
        )
    }
}

private struct ActivityHistoryView: View {
    let entries: [HistoryEntry]
    let model: TodayModel

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.34).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.m) {
                    Text("Every session you chose to count, newest first.")
                        .font(FGFont.reason)
                        .foregroundStyle(FGColor.inkMuted)

                    ActivityHistoryList(entries: entries, model: model)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FGSpace.page)
                .padding(.vertical, FGSpace.m)
            }
        }
        .fgTabBarInset()
        .navigationTitle("Session history")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ActivityHistoryList: View {
    let entries: [HistoryEntry]
    let model: TodayModel

    private var groups: [ActivityHistoryDayGroup] {
        ActivityHistoryDayGroup.make(from: entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: FGSpace.s) {
                    Text(group.title)
                        .font(FGFont.label.weight(.semibold))
                        .foregroundStyle(FGColor.inkMuted)

                    VStack(spacing: FGSpace.xs) {
                        ForEach(group.entries, id: \.self) { entry in
                            ActivityHistoryRow(entry: entry, title: model.title(for: entry))
                        }
                    }
                }
            }
        }
    }
}

private struct ActivityHistoryDayGroup: Identifiable {
    let id: Date
    let title: String
    let entries: [HistoryEntry]

    static func make(
        from entries: [HistoryEntry],
        calendar: Calendar = .current
    ) -> [ActivityHistoryDayGroup] {
        Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .map { day, entries in
                ActivityHistoryDayGroup(
                    id: day,
                    title: title(for: day, calendar: calendar),
                    entries: entries.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.id > $1.id }
    }

    private static func title(for day: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

private struct ActivityHistoryRow: View {
    let entry: HistoryEntry
    let title: String

    private var aura: FGAura {
        entry.activity.completionAura ?? .sage
    }

    var body: some View {
        HStack(spacing: FGSpace.m) {
            Image(systemName: entry.activity.onboardingSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(aura.mid)
                .frame(width: 36, height: 36)
                .background(aura.core.opacity(0.35))
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(entry.activity.label)
                    Text("•").foregroundStyle(FGColor.lineStrong)
                    Text("\(max(1, entry.durationMin)) min")

                    if case .completed(feel: let feel?) = entry.outcome {
                        Text("•").foregroundStyle(FGColor.lineStrong)
                        Text(feelLabel(feel))
                            .fontWeight(.medium)
                            .foregroundStyle(feelColor(feel))
                    }
                }
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(FGColor.sageDeep)
        }
        .padding(.horizontal, FGSpace.m)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .fill(FGColor.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FGRadius.tile, style: .continuous)
                .strokeBorder(FGColor.line, lineWidth: 1)
        )
    }

    private func feelLabel(_ feel: Feel) -> String {
        switch feel {
        case .lovedIt: "Loved it"
        case .fine: "Felt good"
        case .tooMuch: "Challenging"
        }
    }

    private func feelColor(_ feel: Feel) -> Color {
        switch feel {
        case .lovedIt: FGAura.apricot.mid
        case .fine: FGAura.sage.mid
        case .tooMuch: FGColor.inkMuted
        }
    }
}

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

    private var completedEntries: [HistoryEntry] {
        model.history
            .filter { $0.wasCompleted }
            .sorted { $0.date > $1.date }
    }

    private var groupedEntries: [(dateString: String, entries: [HistoryEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: completedEntries) { entry -> String in
            if calendar.isDateInToday(entry.date) {
                return "Today"
            } else if calendar.isDateInYesterday(entry.date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, MMM d"
                return formatter.string(from: entry.date)
            }
        }

        var seenDays: [String] = []
        var result: [(dateString: String, entries: [HistoryEntry])] = []

        for entry in completedEntries {
            let dayKey: String
            if calendar.isDateInToday(entry.date) {
                dayKey = "Today"
            } else if calendar.isDateInYesterday(entry.date) {
                dayKey = "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE, MMM d"
                dayKey = formatter.string(from: entry.date)
            }

            if !seenDays.contains(dayKey) {
                seenDays.append(dayKey)
                if let entries = grouped[dayKey] {
                    result.append((dateString: dayKey, entries: entries))
                }
            }
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            header

            if completedEntries.isEmpty {
                emptyCard
            } else {
                VStack(alignment: .leading, spacing: FGSpace.m) {
                    ForEach(groupedEntries, id: \.dateString) { group in
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text(group.dateString)
                                .font(FGFont.label.weight(.semibold))
                                .foregroundStyle(FGColor.inkMuted)

                            VStack(spacing: FGSpace.xs) {
                                ForEach(group.entries, id: \.self) { entry in
                                    historyRow(for: entry)
                                }
                            }
                        }
                    }
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
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(FGColor.line, lineWidth: 1))
            }
        }
    }

    private func historyRow(for entry: HistoryEntry) -> some View {
        let aura = entry.activity.completionAura ?? .sage
        return HStack(spacing: FGSpace.m) {
            Image(systemName: entry.activity.onboardingSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(aura.mid)
                .frame(width: 36, height: 36)
                .background(aura.core.opacity(0.35))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(model.title(for: entry))
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(entry.activity.label)
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)

                    Text("•")
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.lineStrong)

                    Text("\(max(1, entry.durationMin)) min")
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.inkMuted)

                    if case .completed(feel: let feel?) = entry.outcome {
                        Text("•")
                            .font(FGFont.label)
                            .foregroundStyle(FGColor.lineStrong)

                        Text(feelLabel(feel))
                            .font(FGFont.label.weight(.medium))
                            .foregroundStyle(feelColor(feel))
                    }
                }
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

    private var emptyCard: some View {
        HStack(alignment: .center, spacing: FGSpace.m) {
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                Text("Your movement log")
                    .font(FGFont.itemTitle)
                    .foregroundStyle(FGColor.ink)

                Text("Completed sessions will appear here as you log them. Every session is worth noticing — no streaks required.")
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
                    .lineSpacing(2)
            }

            Spacer()

            Image("MascotShowingUpBanana")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
        }
        .padding(FGSpace.m)
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

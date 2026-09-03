//
//  LibraryView.swift
//  FeelGood
//
//  Everything there is, free forever. Deliberately not the home screen: the
//  app's job is to remove options, and this is the one place that hands them
//  all back for the times somebody wants to go looking. See PRD §8.
//

import SwiftUI

struct LibraryView: View {
    let model: TodayModel

    @State private var selected: Session?

    private var courses: [(course: Course, sessions: [Session])] {
        Course.allCases.compactMap { course in
            let sessions = model.everything.filter { $0.course == course }
            return sessions.isEmpty ? nil : (course, sessions)
        }
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.xl) {
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        Text("Everything")
                            .font(FGFont.title)
                            .foregroundStyle(FGColor.ink)
                        Text("Nothing here is chosen for you. That's the point of it.")
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(courses, id: \.course) { group in
                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text(group.course.label)
                                .font(FGFont.label)
                                .foregroundStyle(FGColor.inkMuted)
                                .textCase(.uppercase)
                                .tracking(1.1)

                            ForEach(group.sessions) { session in
                                row(session)
                            }
                        }
                    }
                }
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .sheet(item: $selected) { session in
            SessionDetailView(session: session, model: model)
        }
        .presentationDragIndicator(.visible)
    }

    private func row(_ session: Session) -> some View {
        FGCard {
            VStack(alignment: .leading, spacing: FGSpace.xs) {
                Text(session.title)
                    .font(FGFont.body.weight(.medium))
                    .foregroundStyle(FGColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                WrapRow(spacing: FGSpace.xs, lineSpacing: FGSpace.xs) {
                    ForEach(session.chips, id: \.self) { FGChip(text: $0) }
                    if session.isOwn {
                        FGChip(text: "Yours")
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { selected = session }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(session.title). \(session.chips.joined(separator: ", "))")
        .accessibilityAddTraits(.isButton)
    }
}

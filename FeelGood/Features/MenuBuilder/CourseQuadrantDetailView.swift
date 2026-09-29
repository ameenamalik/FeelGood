//
//  CourseQuadrantDetailView.swift
//  FeelGood
//
//  Detail list for an individual course quadrant in My Menu (Appetizer, Main, Side, Dessert).
//

import SwiftUI
import PostHog

struct CourseQuadrantDetailView: View {
    let model: TodayModel
    let course: Course

    @State private var isAddingRoutine = false
    @State private var selectedSession: Session?
    @State private var sessionToEdit: Session?
    @State private var sessionToDelete: Session?
    @State private var isShowingDeleteConfirm = false

    private var routines: [Session] {
        model.customRoutines(for: course)
    }

    private var courseSubtitle: String {
        switch course {
        case .appetizer: "2–5 min quick resets. Easy starting points."
        case .main: "15–30 min core movement. Today's centerpiece."
        case .side: "5–10 min add-ons. Pairs with your daily habits."
        case .dessert: "5–15 min pure joy. Movement purely for fun."
        case .special: "Longer sessions planned ahead."
        }
    }

    var body: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    courseHero

                    // Routines list
                    VStack(alignment: .leading, spacing: FGSpace.s) {
                        if !routines.isEmpty {
                            Text("Saved routines")
                                .font(FGFont.label.weight(.semibold))
                                .foregroundStyle(FGColor.inkMuted)
                                .textCase(.uppercase)
                                .tracking(0.7)
                                .padding(.horizontal, FGSpace.xs)
                        }

                        if routines.isEmpty {
                            VStack(spacing: FGSpace.s) {
                                Text("Nothing here yet")
                                    .font(FGFont.itemTitle)
                                    .foregroundStyle(FGColor.ink)
                                Text("Add a routine you would happily choose again.")
                                    .font(FGFont.caption)
                                    .foregroundStyle(FGColor.inkMuted)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpace.l)
                        } else {
                            ForEach(routines) { session in
                                routineRow(session)
                            }
                        }

                        // Add button
                        Button {
                            isAddingRoutine = true
                        } label: {
                            HStack(spacing: FGSpace.s) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Add \(course.label.lowercased()) routine")
                                    .font(FGFont.body.weight(.semibold))
                            }
                            .foregroundStyle(FGColor.ink)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 54)
                            .background(course.accentGradient)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(course.tagText.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.feelGoodPress)
                        .padding(.top, FGSpace.xs)
                    }
                }
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingRoutine = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(FGColor.ink)
                }
                .accessibilityLabel("Add \(course.label) routine")
            }
        }
        .sheet(isPresented: $isAddingRoutine) {
            AddRoutineSheet(model: model, initialCourse: course)
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session, model: model)
        }
        .sheet(item: $sessionToEdit) { session in
            AddRoutineSheet(model: model, editingSession: session)
        }
        .alert("Remove Routine?", isPresented: $isShowingDeleteConfirm) {
            Button("Remove", role: .destructive) {
                if let s = sessionToDelete {
                    model.forget(s)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove this routine from your personal menu.")
        }
    }

    private var courseHero: some View {
        HStack(spacing: FGSpace.m) {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                Text(course.label)
                    .font(FGFont.title)
                    .foregroundStyle(FGColor.ink)

                Text(courseSubtitle)
                    .font(FGFont.reason)
                    .foregroundStyle(FGColor.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(routines.count) saved")
                    .font(FGFont.label.weight(.semibold))
                    .foregroundStyle(course.tagText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(FGColor.surface.opacity(0.68), in: Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(course.menuMascotAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .accessibilityHidden(true)
        }
        .padding(FGSpace.l)
        .background(course.accentGradient)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(course.tagText.opacity(0.10), lineWidth: 1)
        )
    }

    /// One tap opens it; everything else — rename, delete, put it on Today —
    /// lives in the long-press menu instead of a row of always-visible
    /// buttons.
    private func routineRow(_ session: Session) -> some View {
        let isTodayOverride = model.todayCustomOverrides[course]?.id == session.id

        return Button {
            selectedSession = session
        } label: {
            HStack(spacing: FGSpace.m) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(course.accentGradient)
                    .frame(width: 5, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.ink)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: FGSpace.s) {
                        Text("\(session.durationMin) min")
                            .font(FGFont.label.weight(.semibold))
                            .foregroundStyle(course.tagText)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(course.tagFill, in: Capsule())

                        if isTodayOverride {
                            Text("On Today’s menu")
                                .font(FGFont.caption)
                                .foregroundStyle(course.tagText)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(course.tagText)
                    .frame(width: 32, height: 32)
                    .background(course.tagFill, in: Circle())
            }
            .padding(FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(FGColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(course.tagText.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.feelGoodPress)
        .contextMenu {
            if isTodayOverride {
                Button("Remove from Today's menu", systemImage: "minus.circle") {
                    withAnimation(FGMotion.settle) {
                        model.removeTodayCourseOverride(for: course)
                    }
                }
            } else {
                Button("Put on Today's menu", systemImage: "arrow.up.circle") {
                    withAnimation(FGMotion.settle) {
                        model.setTodayCourseOverride(session: session, for: course)
                    }
                }
            }

            Button("Edit", systemImage: "pencil") {
                sessionToEdit = session
            }

            Divider()

            Button("Delete", systemImage: "trash", role: .destructive) {
                sessionToDelete = session
                isShowingDeleteConfirm = true
            }
        }
    }
}

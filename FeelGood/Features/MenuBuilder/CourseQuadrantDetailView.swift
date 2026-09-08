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
    @State private var sessionToRename: Session?
    @State private var renameText = ""
    @State private var isShowingRenameAlert = false
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
                    // Header
                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                        HStack(spacing: FGSpace.s) {
                            Text(course.label)
                                .font(FGFont.title)
                                .foregroundStyle(FGColor.ink)
                            CourseTag(course: course)
                        }

                        Text(courseSubtitle)
                            .font(FGFont.reason)
                            .foregroundStyle(FGColor.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Routines list
                    VStack(spacing: FGSpace.s) {
                        if routines.isEmpty {
                            VStack(spacing: FGSpace.s) {
                                Text("No custom routines in \(course.label.lowercased())s yet")
                                    .font(FGFont.itemTitle)
                                    .foregroundStyle(FGColor.ink)
                                Text("Tap the button below to add your first routine.")
                                    .font(FGFont.caption)
                                    .foregroundStyle(FGColor.inkMuted)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FGSpace.xl)
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
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Add another \(course.label.lowercased()) routine")
                                    .font(FGFont.body.weight(.medium))
                            }
                            .foregroundStyle(course.tagText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                                    .strokeBorder(course.tagText.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, FGSpace.xs)
                    }
                }
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .navigationTitle(course.label)
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
        .alert("Rename Routine", isPresented: $isShowingRenameAlert) {
            TextField("Routine name", text: $renameText)
            Button("Save") {
                if let s = sessionToRename {
                    model.rename(s, to: renameText)
                }
            }
            Button("Cancel", role: .cancel) {}
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

    /// One tap opens it; everything else — rename, delete, put it on Today —
    /// lives in the long-press menu instead of a row of always-visible
    /// buttons.
    private func routineRow(_ session: Session) -> some View {
        let isTodayOverride = model.todayCustomOverrides[course]?.id == session.id

        return Button {
            selectedSession = session
        } label: {
            HStack(spacing: FGSpace.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.ink)
                        .multilineTextAlignment(.leading)

                    Text(isTodayOverride ? "On Today's menu · \(session.durationMin) min" : "\(session.durationMin) min")
                        .font(FGFont.caption)
                        .foregroundStyle(isTodayOverride ? course.tagText : FGColor.inkMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FGColor.inkMuted)
            }
            .padding(FGSpace.m)
            .background(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .fill(FGColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(FGColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

            Button("Rename", systemImage: "pencil") {
                sessionToRename = session
                renameText = session.title
                isShowingRenameAlert = true
            }

            Divider()

            Button("Delete", systemImage: "trash", role: .destructive) {
                sessionToDelete = session
                isShowingDeleteConfirm = true
            }
        }
    }
}

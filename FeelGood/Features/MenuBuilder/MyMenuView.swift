//
//  MyMenuView.swift
//  FeelGood
//
//  A stacked Dopamine Menu: one ticket for each course. The whole ticket opens
//  its routine list; nothing inside it is a separate tap target.
//

import SwiftUI
import PostHog

struct MyMenuView: View {
    let model: TodayModel

    @Environment(\.dismiss) private var dismiss
    @State private var activeAddingCourse: Course?
    @State private var newlySavedSession: Session?
    @State private var savedSessionToShow: Session?
    @State private var selectedDetailCourse: Course?

    private let quadrants: [Course] = [
        .appetizer, .main,
        .side, .dessert
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.l) {
                        header
                        dashboardGrid
                    }
                    .padding(.horizontal, FGSpace.page)
                    .padding(.vertical, FGSpace.m)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .navigationTitle("My Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(FGFont.body.weight(.medium))
                        .foregroundStyle(FGColor.ink)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        activeAddingCourse = .main
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Routine")
                        }
                        .font(FGFont.label.weight(.semibold))
                        .foregroundStyle(FGColor.ink)
                    }
                }
            }
            .sheet(item: $activeAddingCourse, onDismiss: {
                savedSessionToShow = newlySavedSession
                newlySavedSession = nil
            }) { course in
                AddRoutineSheet(model: model, initialCourse: course) { saved in
                    newlySavedSession = saved
                }
            }
            .sheet(item: $savedSessionToShow) { session in
                SessionDetailView(session: session, model: model)
            }
            .navigationDestination(item: $selectedDetailCourse) { course in
                CourseQuadrantDetailView(model: model, course: course)
            }
            .onAppear {
                model.syncFromFirestore()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("Your Menu")
            .font(FGFont.display)
            .tracking(-0.5)
            .foregroundStyle(FGColor.ink)
    }

    // MARK: - Stacked Menu

    private var dashboardGrid: some View {
        VStack(spacing: FGSpace.s) {
            ForEach(quadrants, id: \.self) { course in
                quadrantCard(for: course)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func quadrantCard(for course: Course) -> some View {
        let routines = model.customRoutines(for: course)
        let previewItems = Array(routines.prefix(3))

        return Button {
            selectedDetailCourse = course
        } label: {
            ZStack(alignment: .trailing) {
                HStack(spacing: FGSpace.m) {
                    VStack(alignment: .leading, spacing: FGSpace.xs) {
                        Text(course.label)
                            .font(FGFont.sectionTitle)
                            .foregroundStyle(FGColor.ink)
                            .lineLimit(1)

                        Text("\(routines.count) \(routines.count == 1 ? "routine" : "routines")")
                            .font(FGFont.label)
                            .foregroundStyle(FGColor.inkMuted)

                        if previewItems.isEmpty {
                            Text("Nothing yet")
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.inkMuted)
                        } else {
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(previewItems) { session in
                                    Text(session.title)
                                        .font(FGFont.caption)
                                        .foregroundStyle(FGColor.inkMuted)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if routines.count > previewItems.count {
                                    Text("+\(routines.count - previewItems.count) more")
                                        .font(FGFont.caption.weight(.semibold))
                                        .foregroundStyle(course.accentText)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(course.menuMascotAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .accessibilityHidden(true)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(course.tagText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(course.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(course.edge, lineWidth: 1.5)
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(course.label), \(routines.count) routines")
        .accessibilityValue(previewItems.map(\.title).joined(separator: ", "))
        .accessibilityHint("Opens all saved routines in this course")
        .accessibilityAddTraits(.isButton)
    }

}

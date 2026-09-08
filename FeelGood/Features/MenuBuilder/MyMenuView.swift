//
//  MyMenuView.swift
//  FeelGood
//
//  The 2x2 Dopamine Menu Dashboard.
//  Designated sections for Appetizer, Main, Side, and Dessert. Each card is a
//  title, a count, and a few plain preview lines — the whole card opens the
//  full list; nothing on it is a separate tap target.
//

import SwiftUI
import PostHog

struct MyMenuView: View {
    let model: TodayModel

    @Environment(\.dismiss) private var dismiss
    @State private var activeAddingCourse: Course?
    @State private var selectedDetailCourse: Course?

    private let quadrants: [Course] = [
        .appetizer, .main,
        .side, .dessert
    ]

    private let gridColumns = [
        GridItem(.flexible(), spacing: FGSpace.s),
        GridItem(.flexible(), spacing: FGSpace.s)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.l) {
                        // Header
                        header

                        // 2x2 Dashboard Grid
                        dashboardGrid
                    }
                    .padding(FGSpace.page)
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
            .sheet(item: $activeAddingCourse) { course in
                AddRoutineSheet(model: model, initialCourse: course)
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

    // MARK: - 2x2 Dashboard Grid

    private var dashboardGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: FGSpace.s) {
            ForEach(quadrants, id: \.self) { course in
                quadrantCard(for: course)
            }
        }
    }

    private func quadrantCard(for course: Course) -> some View {
        let routines = model.customRoutines(for: course)
        let previewItems = Array(routines.prefix(3))

        return Button {
            selectedDetailCourse = course
        } label: {
            VStack(alignment: .leading, spacing: FGSpace.s) {
                // Quadrant header: title, count, chevron — no colour block.
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(course.label)
                        .font(FGFont.itemTitle)
                        .foregroundStyle(FGColor.ink)

                    Spacer()

                    Text("\(routines.count)")
                        .font(FGFont.body)
                        .foregroundStyle(course.tagText)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(course.tagText)
                }

                Divider()
                    .overlay(FGColor.line)

                // Plain preview lines — no boxes, no icons, no per-row taps.
                VStack(alignment: .leading, spacing: 6) {
                    if previewItems.isEmpty {
                        Text("Nothing yet")
                            .font(FGFont.caption)
                            .foregroundStyle(FGColor.inkMuted)
                    } else {
                        ForEach(previewItems) { session in
                            Text("•  \(session.title)")
                                .font(FGFont.caption)
                                .foregroundStyle(FGColor.inkMuted)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(FGSpace.m)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(course.label), \(routines.count) routines")
        .accessibilityAddTraits(.isButton)
    }
}

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
    @State private var selectedDetailCourse: Course?

    private let quadrants: [Course] = [
        .appetizer, .main,
        .side, .dessert
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                GeometryReader { proxy in
                    let fixedHeight = CGFloat(122)
                    let cardHeight = max(104, (proxy.size.height - fixedHeight) / 4)

                    VStack(alignment: .leading, spacing: FGSpace.l) {
                        header
                        dashboardGrid(cardHeight: cardHeight)
                    }
                    .padding(.horizontal, FGSpace.page)
                    .padding(.vertical, FGSpace.m)
                }
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

    // MARK: - Stacked Menu

    private func dashboardGrid(cardHeight: CGFloat) -> some View {
        VStack(spacing: FGSpace.s) {
            ForEach(quadrants, id: \.self) { course in
                quadrantCard(for: course, height: cardHeight)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func quadrantCard(for course: Course, height: CGFloat) -> some View {
        let routines = model.customRoutines(for: course)
        let previewItems = Array(routines.prefix(1))

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
                                        .lineLimit(1)
                                }
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(course.menuMascotAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .accessibilityHidden(true)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(course.tagText)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .leading)
            .background(course.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(course.tagText.opacity(0.05), lineWidth: 0.75)
            )
        }
        .buttonStyle(.feelGoodPress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(course.label), \(routines.count) routines")
        .accessibilityAddTraits(.isButton)
    }

}

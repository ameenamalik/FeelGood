//
//  CatalogPickerSheet.swift
//  FeelGood
//
//  Allows selecting a pre-made session from the FeelGood catalog
//  to save into a custom routine slot in My Menu.
//

import SwiftUI

struct CatalogPickerSheet: View {
    let model: TodayModel
    let preferredCourse: Course
    let onSelect: (Session) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCourse: Course

    init(model: TodayModel, preferredCourse: Course, onSelect: @escaping (Session) -> Void) {
        self.model = model
        self.preferredCourse = preferredCourse
        self.onSelect = onSelect
        _selectedCourse = State(initialValue: preferredCourse)
    }

    private var filteredSessions: [Session] {
        model.store.sessions.filter { session in
            let matchesCourse = session.course == selectedCourse
            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return matchesCourse
            }
            let query = searchText.lowercased()
            return matchesCourse && (
                session.title.lowercased().contains(query) ||
                session.activity.label.lowercased().contains(query) ||
                session.chips.contains(where: { $0.lowercased().contains(query) })
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                VStack(spacing: FGSpace.m) {
                    // Course tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: FGSpace.s) {
                            ForEach([Course.appetizer, Course.main, Course.side, Course.dessert], id: \.self) { course in
                                Button {
                                    withAnimation(FGMotion.gentle) {
                                        selectedCourse = course
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(course.label)
                                            .font(FGFont.label.weight(.semibold))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(selectedCourse == course ? course.tagText : FGColor.inkMuted)
                                    .background(selectedCourse == course ? course.tagFill : FGColor.surface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(selectedCourse == course ? course.tagText.opacity(0.3) : FGColor.line, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, FGSpace.page)
                    }

                    // Search Field
                    HStack(spacing: FGSpace.s) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(FGColor.inkMuted)

                        TextField("Search sessions...", text: $searchText)
                            .font(FGFont.body)
                            .foregroundStyle(FGColor.ink)
                            .textFieldStyle(.plain)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(FGColor.inkMuted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, FGSpace.m)
                    .padding(.vertical, 10)
                    .background(FGColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                            .strokeBorder(FGColor.line, lineWidth: 1)
                    )
                    .padding(.horizontal, FGSpace.page)

                    // Results List
                    ScrollView {
                        LazyVStack(spacing: FGSpace.s) {
                            if filteredSessions.isEmpty {
                                VStack(spacing: FGSpace.s) {
                                    Text("No sessions found")
                                        .font(FGFont.itemTitle)
                                        .foregroundStyle(FGColor.ink)
                                    Text("Try searching for a different keyword or course.")
                                        .font(FGFont.caption)
                                        .foregroundStyle(FGColor.inkMuted)
                                }
                                .padding(.top, FGSpace.xl)
                            } else {
                                ForEach(filteredSessions) { session in
                                    Button {
                                        onSelect(session)
                                        dismiss()
                                    } label: {
                                        FGCard {
                                            VStack(alignment: .leading, spacing: FGSpace.xs) {
                                                HStack(alignment: .top) {
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text(session.title)
                                                            .font(FGFont.body.weight(.medium))
                                                            .foregroundStyle(FGColor.ink)
                                                            .multilineTextAlignment(.leading)
                                                        Text(session.subtitle)
                                                            .font(FGFont.caption)
                                                            .foregroundStyle(FGColor.inkMuted)
                                                            .lineLimit(2)
                                                    }
                                                    Spacer()
                                                    Text("\(session.durationMin)m")
                                                        .font(FGFont.label.weight(.semibold))
                                                        .foregroundStyle(FGColor.clayDeep)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Capsule().fill(FGColor.bg))
                                                }

                                                WrapRow(spacing: FGSpace.xs, lineSpacing: FGSpace.xs) {
                                                    ForEach(session.chips, id: \.self) { chip in
                                                        FGChip(text: chip)
                                                    }
                                                }
                                                .padding(.top, 4)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, FGSpace.page)
                        .padding(.bottom, FGSpace.xl)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
                .padding(.top, FGSpace.m)
            }
            .navigationTitle("Pick from Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(FGColor.ink)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

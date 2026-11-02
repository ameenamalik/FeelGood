//
//  AccessChoices.swift
//  FeelGood
//
//  "What do you have access to?" — asked once in onboarding and answerable
//  again forever after from the profile screen. One component, so the two can
//  never drift apart.
//

import SwiftUI

struct AccessChoices: View {
    @Binding var activities: Set<Activity>
    @Binding var sports: Set<SportPreference>
    @Binding var equipment: Set<Equipment>
    @Binding var places: Set<Place>
    /// Where the person types what "Other" means. Optional so a caller that
    /// has nowhere to keep the text still gets a working chip list.
    var otherNote: Binding<String>? = nil
    var showsSymbols = false
    var accent: FGAccent = .ink
    /// Draws the tiles as washes instead of white cards. Onboarding opts in;
    /// the profile screen does not, because a settings list of sixteen colour
    /// fields is a different thing from a first-run question.
    var usesAura = false
    /// Onboarding presents these as quick text choices rather than a wall of
    /// illustrated tiles. Profile editing keeps its existing compact controls.
    var usesPills = false
    /// Whether to show the Where section (omitted from onboarding, shown in profile editing).
    var showsWhere = true

    @Environment(\.dynamicTypeSize) private var typeSize

    /// A gym is asked about as a *place*, and the kit inside it follows from
    /// that — see `Place.impliedEquipment`. Asking again under Equipment would
    /// be the same question twice with two ways to answer it wrong.
    /// A pool is covered under Swimming / Places rather than handheld equipment.
    private static let equipmentChoices = Equipment.allCases.filter {
        $0 != .gym && $0 != .outdoor && $0 != .pool
    }

    /// Only movement that genuinely depends on owning something or going
    /// somewhere is worth a chip. Breathwork, qi gong, carries and footwork
    /// need nothing, so they are recommended when they fit rather than
    /// recognised from a list. See `Activity.isAlwaysAvailable`.
    private static let movementChoices = Activity.allCases.filter { !$0.isAlwaysAvailable || $0 == .other }

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.l) {
            group("Movement") {
                ForEach(Self.movementChoices, id: \.self) { activity in
                    choice(
                        title: activity.label,
                        symbol: activity.onboardingSymbol,
                        aura: .sage,
                        isSelected: activities.contains(activity)
                    ) {
                        toggleActivity(activity)
                    }
                }
                // Pickleball is what a lot of people mean by "movement", so it
                // sits beside the other choices instead of inside Sports.
                choice(
                    title: SportPreference.pickleball.label,
                    symbol: SportPreference.pickleball.onboardingSymbol,
                    aura: .sage,
                    isSelected: sports.contains(.pickleball)
                ) {
                    togglePickleball()
                }
            }
            if activities.contains(.racquet) {
                group("Which sports? (optional)") {
                    ForEach(Self.sportChoices, id: \.self) { sport in
                        choice(
                            title: sport.label,
                            symbol: sport.onboardingSymbol,
                            aura: .apricot,
                            isSelected: sports.contains(sport)
                        ) {
                            toggle(sport, in: $sports)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            if let otherNote, showsOtherNote {
                VStack(alignment: .leading, spacing: FGSpace.xs) {
                    Text("What do you do?")
                        .font(FGFont.label)
                        .foregroundStyle(FGColor.ink)
                    TextField("e.g. Kayaking, roller derby, rock climbing...", text: otherNote)
                        .font(FGFont.body)
                        .padding(.horizontal, FGSpace.m)
                        .padding(.vertical, 12)
                        .background(FGColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(FGColor.line, lineWidth: 1)
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            group("Equipment") {
                ForEach(Self.equipmentChoices, id: \.self) { item in
                    choice(
                        title: item.label ?? "No equipment",
                        symbol: item.onboardingSymbol,
                        aura: .lilac,
                        isSelected: equipment.contains(item)
                    ) {
                        toggleEquipment(item)
                    }
                }
            }
            if showsWhere {
                group("Where") {
                    ForEach(Place.allCases, id: \.self) { place in
                        choice(
                            title: place.label,
                            symbol: place.onboardingSymbol,
                            aura: .blush,
                            isSelected: places.contains(place)
                        ) {
                            toggle(place, in: $places)
                        }
                    }
                }
            }
        }
        // Text typed for an "Other" that is no longer ticked should not linger.
        .onChange(of: showsOtherNote) { _, shows in
            if !shows { otherNote?.wrappedValue = "" }
        }
    }

    /// One aura per *group*, so a picked tile also says which group it is in.
    ///
    /// Only picked tiles are washed at all — see `FGAuraTile`. That is what
    /// makes a single hue per group work here: the page is mostly neutral, and
    /// the colour is a record of what you chose rather than wallpaper.
    @ViewBuilder
    private func choice(
        title: String,
        symbol: String,
        aura: FGAura,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        if usesPills {
            FGPill(title: title, selectedAura: aura, isSelected: isSelected, action: action)
        } else if usesAura {
            FGAuraTile(
                title: title,
                systemImage: showsSymbols ? symbol : nil,
                aura: aura,
                isSelected: isSelected,
                action: action
            )
        } else {
            FGChoice(
                title: title,
                systemImage: showsSymbols ? symbol : nil,
                accent: accent,
                isSelected: isSelected,
                action: action
            )
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(FGColor.ink)
            // Symbol groups are the tile grid; the rest are plain chips that
            // wrap on their own width rather than on a tile's.
            if usesPills {
                WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                    content()
                }
            } else if showsSymbols {
                FlowRow.choices(isAccessibilitySize: typeSize.isAccessibilitySize) {
                    content()
                }
            } else {
                FlowRow(
                    spacing: FGSpace.s,
                    maxPerRow: typeSize.isAccessibilitySize ? 1 : 3,
                    minimumItemWidth: 1
                ) { content() }
            }
        }
    }

    private func toggle<T: Hashable>(_ value: T, in binding: Binding<Set<T>>) {
        withAnimation(FGMotion.gentle) {
            if binding.wrappedValue.contains(value) {
                binding.wrappedValue.remove(value)
            } else {
                binding.wrappedValue.insert(value)
            }
        }
    }

    private func toggleActivity(_ activity: Activity) {
        withAnimation(FGMotion.gentle) {
            if activities.contains(activity) {
                activities.remove(activity)
                if activity == .racquet { sports.removeAll() }
            } else {
                activities.insert(activity)
            }
        }
    }

    /// Pickleball is stored the way it always was, as a sport under the racquet
    /// activity, so the engine and saved profiles need no migration.
    private func togglePickleball() {
        withAnimation(FGMotion.gentle) {
            if sports.contains(.pickleball) {
                sports.remove(.pickleball)
                if sports.isEmpty { activities.remove(.racquet) }
            } else {
                sports.insert(.pickleball)
                activities.insert(.racquet)
            }
        }
    }

    /// Pickleball has its own chip, so it is not repeated under Which sports.
    private static let sportChoices = SportPreference.allCases.filter { $0 != .pickleball }

    private var showsOtherNote: Bool {
        activities.contains(.other) || sports.contains(.other)
    }


    /// "No equipment" is an answer, not equipment that can coexist with a
    /// mat or weights. Choosing either side clears the contradictory side.
    private func toggleEquipment(_ item: Equipment) {
        withAnimation(FGMotion.gentle) {
            if item == .none {
                equipment = equipment == [.none] ? [] : [.none]
            } else {
                equipment.remove(.none)
                if equipment.contains(item) {
                    equipment.remove(item)
                } else {
                    equipment.insert(item)
                }
            }
        }
    }
}

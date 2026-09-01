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
    @Binding var equipment: Set<Equipment>
    @Binding var places: Set<Place>
    var showsSymbols = false
    var accent: FGAccent = .ink
    /// Draws the tiles as washes instead of white cards. Onboarding opts in;
    /// the profile screen does not, because a settings list of sixteen colour
    /// fields is a different thing from a first-run question.
    var usesAura = false
    /// Onboarding presents these as quick text choices rather than a wall of
    /// illustrated tiles. Profile editing keeps its existing compact controls.
    var usesPills = false

    @Environment(\.dynamicTypeSize) private var typeSize

    /// A gym is asked about as a *place*, and the kit inside it follows from
    /// that — see `Place.impliedEquipment`. Asking again under Equipment would
    /// be the same question twice with two ways to answer it wrong.
    private static let equipmentChoices = Equipment.allCases.filter {
        $0 != .gym && $0 != .outdoor
    }

    /// Only movement that genuinely depends on owning something or going
    /// somewhere is worth a chip. Breathwork, qi gong, carries and footwork
    /// need nothing, so they are recommended when they fit rather than
    /// recognised from a list. See `Activity.isAlwaysAvailable`.
    private static let movementChoices = Activity.allCases.filter { !$0.isAlwaysAvailable }

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
                        toggle(activity, in: $activities)
                    }
                }
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

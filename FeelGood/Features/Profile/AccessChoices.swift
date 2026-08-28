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

    @Environment(\.dynamicTypeSize) private var typeSize

    /// A gym is asked about as a *place*, and the kit inside it follows from
    /// that — see `Place.impliedEquipment`. Asking again under Equipment would
    /// be the same question twice with two ways to answer it wrong.
    private static let equipmentChoices = Equipment.allCases.filter { $0 != .none && $0 != .gym }

    /// Only movement that genuinely depends on owning something or going
    /// somewhere is worth a chip. Breathwork, qi gong, carries and footwork
    /// need nothing, so they are recommended when they fit rather than
    /// recognised from a list. See `Activity.isAlwaysAvailable`.
    private static let movementChoices = Activity.allCases.filter { !$0.isAlwaysAvailable }

    var body: some View {
        VStack(alignment: .leading, spacing: FGSpace.l) {
            group("Movement") {
                ForEach(Self.movementChoices, id: \.self) { activity in
                    FGChoice(title: activity.label, isSelected: activities.contains(activity)) {
                        toggle(activity, in: $activities)
                    }
                }
            }
            group("Equipment") {
                ForEach(Self.equipmentChoices, id: \.self) { item in
                    FGChoice(title: item.label ?? "", isSelected: equipment.contains(item)) {
                        toggle(item, in: $equipment)
                    }
                }
            }
            group("Where") {
                ForEach(Place.allCases, id: \.self) { place in
                    FGChoice(title: place.label, isSelected: places.contains(place)) {
                        toggle(place, in: $places)
                    }
                }
            }
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.s) {
            Text(title)
                .font(FGFont.label)
                .foregroundStyle(FGColor.inkMuted)
            FlowRow(spacing: FGSpace.s, maxPerRow: typeSize.isAccessibilitySize ? 1 : 3) { content() }
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
}

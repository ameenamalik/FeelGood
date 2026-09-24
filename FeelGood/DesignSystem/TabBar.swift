//
//  TabBar.swift
//  FeelGood
//
//  The app's tab bar. The system one is a glass pill that ignores
//  `toolbarBackground`, so card text showed through it. This is a solid pill
//  with an outline, from docs/PRD-themes.md §6.
//
//  The system bar is hidden (`toolbarVisibility`) and this is placed in the
//  bottom safe area, so scroll views still inset for it. `TabView(selection:)`
//  stays the source of truth, which keeps deep links and state restoration as
//  they were.
//

import SwiftUI

struct FGTabBarItem<Tag: Hashable>: Identifiable {
    let tag: Tag
    let title: String
    let systemImage: String
    var id: Tag { tag }
}

struct FGTabBar<Tag: Hashable>: View {
    let items: [FGTabBarItem<Tag>]
    @Binding var selection: Tag

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let isSelected = item.tag == selection
                Button {
                    selection = item.tag
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 19, weight: .regular))
                            .frame(height: 22)
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(isSelected ? FGColor.onActionFill : FGColor.ink)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        Capsule().fill(isSelected ? FGColor.actionFill : Color.clear)
                    )
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(8)
        .background(Capsule().fill(FGColor.surface))
        .overlay(Capsule().strokeBorder(FGColor.tabBarEdge, lineWidth: 1.5))
        // A pill that spans a 13" iPad is a slab, so cap it and centre it. On a
        // phone the screen is narrower than this and nothing changes.
        .frame(maxWidth: FGTabBar.maxWidth)
        .padding(.horizontal, 36)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
    }
}

extension FGTabBar {
    /// The widest the bar gets. About a phone plus generous room, so it reads as
    /// the same control on iPad instead of stretching edge to edge.
    static var maxWidth: CGFloat { 480 }

    /// The bar's height: two 8pt paddings around a 52pt row, plus the 8pt gap
    /// to the bottom safe area.
    static var height: CGFloat { 76 }
}

private struct KeyboardVisibleKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True while the software keyboard is up. The tab bar lives in the
    /// TabView's bottom inset, so the keyboard lifts it and it jumps above the
    /// keyboard; the root hides the bar instead, and tabs stop reserving room
    /// for it, so a composer sits straight on the keyboard.
    var isKeyboardVisible: Bool {
        get { self[KeyboardVisibleKey.self] }
        set { self[KeyboardVisibleKey.self] = newValue }
    }
}

private struct TabBarInsetModifier: ViewModifier {
    @Environment(\.isKeyboardVisible) private var isKeyboardVisible

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: isKeyboardVisible ? 0 : FGTabBar<Int>.height)
        }
    }
}

extension View {
    /// Reserves the tab bar's space at the bottom of a tab's content.
    ///
    /// Needed because the bar lives outside the `TabView`: a safe-area inset
    /// applied out there does not reach each tab's scroll view, so the last
    /// card sat under the bar with nothing to scroll it clear. Collapses while
    /// the keyboard is up, because the bar is hidden then.
    func fgTabBarInset() -> some View {
        modifier(TabBarInsetModifier())
    }
}

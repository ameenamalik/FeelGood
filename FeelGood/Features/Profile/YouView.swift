//
//  YouView.swift
//  FeelGood
//
//  The second tab. The reflection is the screen; everything else about you —
//  what you have access to, and everything there is to do — waits behind one
//  quiet control rather than adding tabs to a two-tab app.
//

import SwiftUI

struct YouView: View {
    let model: TodayModel
    let answers: ProfileAnswers
    let onProfileSaved: (ProfileAnswers) -> Void

    @State private var isEditingProfile = false
    @State private var isBrowsing = false

    var body: some View {
        NavigationStack {
            LookBackView(reflection: model.lookBack(now: .now))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        // `SwiftUI.Menu` spelled out: `Menu` is this app's own
                        // word for the day's plan, and that type wins here.
                        SwiftUI.Menu {
                            Button("Everything", systemImage: "square.stack") { isBrowsing = true }
                            Button("What's true now", systemImage: "slider.horizontal.3") { isEditingProfile = true }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundStyle(FGColor.inkMuted)
                        }
                        .accessibilityLabel("More")
                        .accessibilityHint("Browse everything, or change what you have access to")
                    }
                }
        }
        .sheet(isPresented: $isBrowsing) {
            LibraryView(model: model)
        }
        .sheet(isPresented: $isEditingProfile) {
            ProfileEditView(answers: answers) { updated in
                onProfileSaved(updated)
                model.update(profile: updated.planProfile)
            }
        }
    }
}

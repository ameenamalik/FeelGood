//
//  YouView.swift
//  FeelGood
//
//  The second tab. A quiet identity mark sits above the Look Back: recent
//  patterns rendered as observations, never scores or streaks. Account details
//  and the broader library wait behind secondary controls.
//

import SwiftUI

struct YouView: View {
    let model: TodayModel
    @Bindable var profile: UserProfile
    let onProfileSaved: (ProfileAnswers) -> Void

    @State private var isEditingProfile = false
    @State private var isBrowsing = false
    @State private var isShowingSubscription = false
    @State private var isShowingAccount = false

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()
                FGBrandWash(reach: 0.38).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.xl) {
                        profileHero

                        VStack(alignment: .leading, spacing: FGSpace.s) {
                            Text("You, lately.")
                                .font(FGFont.display)
                                .foregroundStyle(FGColor.ink)
                                .accessibilityAddTraits(.isHeader)

                            Text("A quiet look at your last two weeks.")
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.inkMuted)
                        }

                        LookBackView(reflection: model.lookBack(now: .now))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(FGSpace.page)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .toolbarBackground(FGColor.bg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // `SwiftUI.Menu` spelled out: `Menu` is this app's own
                    // word for the day's plan, and that type wins here.
                    SwiftUI.Menu {
                        Button("Everything", systemImage: "square.stack") { isBrowsing = true }
                        Button("What's true now", systemImage: "slider.horizontal.3") { isEditingProfile = true }
                        Button("Account & privacy", systemImage: "person.crop.circle") { isShowingAccount = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(FGColor.inkMuted)
                            .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                    }
                    .accessibilityLabel("More")
                    .accessibilityHint("Browse everything, edit your profile, or manage your account")
                }
            }
        }
        .sheet(isPresented: $isBrowsing) {
            LibraryView(model: model)
        }
        .sheet(isPresented: $isEditingProfile) {
            ProfileEditView(answers: profile.answers) { updated in
                onProfileSaved(updated)
                model.update(profile: updated.planProfile)
            }
        }
        .sheet(isPresented: $isShowingSubscription) {
            NavigationStack {
                SubscriptionSettingsView()
            }
        }
        .sheet(isPresented: $isShowingAccount) {
            NavigationStack {
                ScrollView {
                    ProfileHeaderView(profile: profile) {
                        isShowingAccount = false
                        isShowingSubscription = true
                    }
                }
                .background(FGColor.bg)
                .navigationTitle("Your account")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isShowingAccount = false }
                    }
                }
            }
            .presentationDragIndicator(.visible)
        }
    }

    /// A quiet mark, not a control — editing identity lives behind "..." only.
    /// Pairing this with its own pencil button used to open the identical
    /// "Account & privacy" sheet as the overflow menu's own entry; two ways
    /// to the same place is the confusing kind of affordance, not the
    /// helpful kind.
    private var profileHero: some View {
        HStack(spacing: FGSpace.s) {
            Circle()
                .fill(FGColor.sage)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(FGColor.inkOnAccent.opacity(0.72))
                        .accessibilityHidden(true)
                }

            Text(welcomeLine)
                .font(FGFont.body.weight(.semibold))
                .foregroundStyle(FGColor.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private var welcomeLine: String {
        let name = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Welcome back" : "Welcome back, \(name)"
    }

}

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

    private var profileHero: some View {
        VStack(spacing: FGSpace.m) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(FGColor.lavender)
                    .frame(width: 144, height: 144)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 46, weight: .medium))
                            .foregroundStyle(FGColor.inkOnAccent.opacity(0.72))
                            .accessibilityHidden(true)
                    }

                Button { isShowingAccount = true } label: {
                    Image(systemName: "pencil")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(FGColor.bg)
                        .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                        .background(Circle().fill(FGColor.ink))
                        .overlay(Circle().stroke(FGColor.bg, lineWidth: 3))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit your account")
                .offset(x: FGSpace.s, y: FGSpace.s)
            }

            Text(welcomeLine)
                .font(FGFont.body.weight(.medium))
                .foregroundStyle(FGColor.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, FGSpace.s)
        .accessibilityElement(children: .contain)
    }

    private var welcomeLine: String {
        let name = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Welcome back" : "Welcome back, \(name)"
    }

}

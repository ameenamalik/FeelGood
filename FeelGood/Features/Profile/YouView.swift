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
    @State private var isShowingHiddenExercises = false
    #if DEBUG
    @State private var isDebugging = false
    #endif

    var body: some View {
        NavigationStack {
            // Match the navigation bar to the page's warm background.
            page.toolbarBackground(FGColor.bg, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        SwiftUI.Menu {
                            #if DEBUG
                            Button("User journeys (Time travel)", systemImage: "clock.arrow.circlepath") {
                                isDebugging = true
                            }
                            Divider()
                            #endif
                            Button("Everything", systemImage: "square.stack") { isBrowsing = true }
                            Button("My Preferences", systemImage: "slider.horizontal.3") { isEditingProfile = true }
                            Button("Hidden exercises", systemImage: "eye.slash") { isShowingHiddenExercises = true }
                            Button("Account & privacy", systemImage: "person.crop.circle") { isShowingAccount = true }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(FGColor.inkMuted)
                                .frame(width: FGSize.minTouchTarget, height: FGSize.minTouchTarget)
                        }
                        .accessibilityLabel("More")
                        .accessibilityHint("Browse everything, edit your preferences, or manage your account")
                    }
                }
        }
        .sheet(isPresented: $isBrowsing) {
            LibraryView(model: model)
        }
        .sheet(isPresented: $isEditingProfile) {
            ProfileEditView(
                answers: profile.answers,
                onShowHiddenExercises: { isShowingHiddenExercises = true }
            ) { updated in
                onProfileSaved(updated)
                model.update(profile: updated.planProfile)
            }
            .sheet(isPresented: $isShowingHiddenExercises) {
                HiddenExercisesView(model: model)
            }
        }
        .sheet(isPresented: $isShowingAccount) {
            NavigationStack {
                ScrollView {
                    ProfileHeaderView(profile: profile) {
                        isShowingSubscription = true
                    }
                }
                .background(FGColor.bg)
                .navigationTitle("Account & privacy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { isShowingAccount = false }
                    }
                }
            }
            .sheet(isPresented: $isShowingSubscription) {
                NavigationStack {
                    SubscriptionSettingsView()
                }
            }
            .presentationDragIndicator(.visible)
        }
        #if DEBUG
        .sheet(isPresented: $isDebugging) {
            DebugMenu(content: model.store) { model.reload() }
        }
        #endif
    }

    private var page: some View {
        ZStack {
            FGColor.bg.ignoresSafeArea()
            FGBrandWash(reach: 0.38).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FGSpace.l) {
                    profileHeader

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

                    LittleWinsSection(progress: model.littleWins)

                    Text("FeelGood provides general wellness recommendations and is not a substitute for medical advice or physical therapy.")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, FGSpace.m)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(FGSpace.page)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            profileHero

            HStack(spacing: 6) {
                preferencePill(
                    "My Preferences",
                    fill: FGColor.rose.opacity(0.34)
                ) {
                    isEditingProfile = true
                }
                preferencePill(
                    "Library",
                    fill: FGColor.gold.opacity(0.36)
                ) {
                    isBrowsing = true
                }
                preferencePill(
                    "Plan & account",
                    fill: FGColor.sage.opacity(0.38)
                ) {
                    isShowingAccount = true
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Filled factual-chip styling, matching the pills used on menu cards.
    private func preferencePill(
        _ title: String,
        fill: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(FGColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Capsule().fill(fill))
        }
        .buttonStyle(.plain)
        .frame(minHeight: FGSize.minTouchTarget)
        .contentShape(Rectangle())
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private var profileHero: some View {
        #if DEBUG
        profileHeroContent
            .contextMenu {
                Button("Time travel", systemImage: "clock.arrow.circlepath") {
                    isDebugging = true
                }
            }
        #else
        profileHeroContent
        #endif
    }

    private var profileHeroContent: some View {
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

//
//  AddVideoSheet.swift
//  FeelGood
//
//  Paste a YouTube link, check it plays, and keep it beside your own routines.
//  The app ships with no videos of its own.
//

import PostHog
import SwiftUI

struct AddVideoSheet: View {
    let model: TodayModel
    let initialCourse: Course
    let lookup: any YouTubeLookup
    let onSaved: (Session) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var link = ""
    @State private var phase: Phase = .idle
    @State private var title = ""
    @State private var durationMin = 20
    @State private var activity: Activity = .generalWellness
    @State private var course: Course
    @State private var addToToday = false
    @FocusState private var isLinkFocused: Bool

    private static let durations = [5, 10, 15, 20, 30, 45, 60]

    private enum Phase: Equatable {
        case idle
        case checking
        case found(YouTubeVideoInfo)
        case failed(String)
    }

    init(
        model: TodayModel,
        initialCourse: Course = .main,
        lookup: any YouTubeLookup = OEmbedYouTubeLookup(),
        onSaved: @escaping (Session) -> Void
    ) {
        self.model = model
        self.initialCourse = initialCourse
        self.lookup = lookup
        self.onSaved = onSaved
        _course = State(initialValue: initialCourse)
    }

    private var foundVideo: YouTubeVideoInfo? {
        if case .found(let info) = phase { return info }
        return nil
    }

    private var canSave: Bool {
        foundVideo != nil && !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: FGSpace.xl) {
                        HStack(alignment: .firstTextBaseline, spacing: FGSpace.m) {
                            Text("Add a YouTube video")
                                .font(FGFont.title)
                                .foregroundStyle(FGColor.ink)
                                .accessibilityAddTraits(.isHeader)
                            Spacer(minLength: 0)
                            Button("Cancel") { dismiss() }
                                .fixedSize()
                                .font(FGFont.body)
                                .foregroundStyle(FGColor.ink)
                                .frame(minHeight: FGSize.minTouchTarget)
                                .buttonStyle(.plain)
                        }

                        linkSection

                        if let info = foundVideo {
                            detailsSection(info)
                        }
                    }
                    .padding(FGSpace.page)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { isLinkFocused = true }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Link

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text("Paste the link")
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)
                .accessibilityAddTraits(.isHeader)

            TextField("youtube.com/watch?v=…", text: $link)
                .font(FGFont.body)
                .foregroundStyle(FGColor.ink)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .submitLabel(.go)
                .focused($isLinkFocused)
                .onSubmit { Task { await check() } }
                .onChange(of: link) { _, _ in
                    if phase != .idle && phase != .checking { phase = .idle }
                }
                .padding(.horizontal, FGSpace.m)
                .padding(.vertical, 12)
                .background(FGColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                        .strokeBorder(isLinkFocused ? FGColor.clayDeep : FGColor.line, lineWidth: isLinkFocused ? 1.5 : 1)
                )
                .postHogMask()

            Text("It plays here, in the app. Videos the owner has turned off sharing for can't be added.")
                .font(FGFont.caption)
                .foregroundStyle(FGColor.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            if case .failed(let message) = phase {
                Text(message)
                    .font(FGFont.caption.weight(.medium))
                    .foregroundStyle(FGColor.clayDeep)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Problem: \(message)")
            }

            if foundVideo == nil {
                FGPrimaryButton(
                    title: phase == .checking ? "Checking…" : "Find video",
                    isEnabled: !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && phase != .checking
                ) {
                    Task { await check() }
                }
            }
        }
    }

    // MARK: - Details once the video is found

    @ViewBuilder
    private func detailsSection(_ info: YouTubeVideoInfo) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.xl) {
            YouTubeThumbnail(videoID: info.videoID)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
                .accessibilityHidden(true)

            question("What should we call it?") {
                TextField("Title", text: $title, axis: .vertical)
                    .font(FGFont.body)
                    .foregroundStyle(FGColor.ink)
                    .textFieldStyle(.plain)
                    .lineLimit(1...3)
                    .padding(.horizontal, FGSpace.m)
                    .padding(.vertical, 12)
                    .background(FGColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                            .strokeBorder(FGColor.line, lineWidth: 1)
                    )
                    .postHogMask()
                Text("From \(info.channel)")
                    .font(FGFont.caption)
                    .foregroundStyle(FGColor.inkMuted)
            }

            question("How long is it?") {
                menuPicker("Length", selection: $durationMin) {
                    ForEach(Self.durations, id: \.self) { Text("\($0) min").tag($0) }
                }
            }

            question("What kind of movement?") {
                menuPicker("Movement", selection: $activity) {
                    ForEach(Activity.allCases, id: \.self) { Text($0.label).tag($0) }
                }
            }

            question("Where does it belong?") {
                WrapRow(spacing: FGSpace.s, lineSpacing: FGSpace.s) {
                    ForEach([Course.appetizer, Course.main, Course.side, Course.dessert], id: \.self) { option in
                        FGPill(title: option.label, selectedAura: aura(for: option), isSelected: course == option) {
                            withAnimation(FGMotion.gentle) { course = option }
                        }
                    }
                }
            }

            Toggle(isOn: $addToToday) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add to today’s menu")
                        .font(FGFont.body.weight(.semibold))
                        .foregroundStyle(FGColor.ink)
                    Text("Replaces today’s suggested \(course.label.lowercased()).")
                        .font(FGFont.caption)
                        .foregroundStyle(FGColor.inkMuted)
                }
            }
            .tint(FGColor.controlAccent)
            .padding(FGSpace.m)
            .background(FGColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.card, style: .continuous)
                    .strokeBorder(FGColor.lineStrong.opacity(0.45), lineWidth: 1)
            )

            FGPrimaryButton(title: "Save video", isEnabled: canSave) { save(info) }
        }
    }

    // MARK: - Actions

    private func check() async {
        guard phase != .checking else { return }
        guard let videoID = YouTubeLink.videoID(from: link) else {
            phase = .failed("That doesn't look like a YouTube video link. Copy it from the Share button on the video.")
            return
        }

        phase = .checking
        isLinkFocused = false
        do {
            let info = try await lookup.info(for: videoID)
            title = info.title
            phase = .found(info)
        } catch YouTubeLookupError.embeddingDisabled {
            phase = .failed("The owner doesn't let this video play outside YouTube, so it can't play here. Try another one.")
        } catch YouTubeLookupError.notFound {
            phase = .failed("YouTube can't find that video. It may be private or removed.")
        } catch {
            phase = .failed("Couldn't reach YouTube. Check your connection and try again.")
        }
    }

    private func save(_ info: YouTubeVideoInfo) {
        let saved = model.addVideo(
            info,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            activity: activity,
            durationMin: durationMin,
            course: course,
            addToToday: addToToday
        )
        Analytics.capture("youtube_video_added", properties: [
            "course": course.rawValue,
            "added_to_today": addToToday,
        ])
        onSaved(saved)
        dismiss()
    }

    // MARK: - Pieces

    private func question<Content: View>(_ prompt: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FGSpace.m) {
            Text(prompt)
                .font(FGFont.itemTitle)
                .foregroundStyle(FGColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    private func menuPicker<Value: Hashable, Options: View>(
        _ label: String,
        selection: Binding<Value>,
        @ViewBuilder options: () -> Options
    ) -> some View {
        Picker(label, selection: selection, content: options)
            .pickerStyle(.menu)
            .tint(FGColor.ink)
            .font(FGFont.body.weight(.medium))
            .frame(maxWidth: .infinity, minHeight: FGSize.minTouchTarget, alignment: .leading)
            .padding(.horizontal, FGSpace.m)
            .background(FGColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FGRadius.chip, style: .continuous)
                    .strokeBorder(FGColor.line, lineWidth: 1)
            )
    }

    private func aura(for course: Course) -> FGAura {
        switch course {
        case .appetizer: .butter
        case .main: .apricot
        case .side: .sage
        case .dessert: .blush
        case .special: .lilac
        }
    }
}

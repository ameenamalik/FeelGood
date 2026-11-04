//
//  UserVideoTests.swift
//  FeelGoodTests
//

import Testing
import Foundation
import SwiftData
@testable import FeelGood

@Suite("Videos people add themselves")
struct UserVideoTests {
    private let id = "dQw4w9WgXcQ"

    @Test("Every common link shape gives the same video id", arguments: [
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "https://youtube.com/watch?v=dQw4w9WgXcQ&t=42s",
        "https://m.youtube.com/watch?feature=share&v=dQw4w9WgXcQ",
        "https://youtu.be/dQw4w9WgXcQ?si=abc",
        "https://www.youtube.com/shorts/dQw4w9WgXcQ",
        "https://www.youtube.com/embed/dQw4w9WgXcQ",
        "https://www.youtube.com/live/dQw4w9WgXcQ",
        "youtube.com/watch?v=dQw4w9WgXcQ",
        "  https://youtu.be/dQw4w9WgXcQ \n",
        "dQw4w9WgXcQ",
    ])
    func parsesLinks(link: String) {
        #expect(YouTubeLink.videoID(from: link) == "dQw4w9WgXcQ")
    }

    @Test("Anything that isn't a single video gives nothing", arguments: [
        "",
        "hello",
        "https://www.youtube.com/playlist?list=PL1234567890A",
        "https://www.youtube.com/@somechannel",
        "https://www.youtube.com/watch?v=short",
        "https://vimeo.com/dQw4w9WgXcQ",
        "https://evil.example/youtu.be/dQw4w9WgXcQ",
    ])
    func rejectsOthers(link: String) {
        #expect(YouTubeLink.videoID(from: link) == nil)
    }

    @Test("A saved video is the person's own, and plays from YouTube")
    func ownVideoShape() {
        let session = Session.ownVideo(
            id: "own-1", title: "Gentle flow", channel: "Some Channel", videoID: id,
            activity: .yoga, durationMin: 20, course: .main
        )

        #expect(session.isOwn)
        #expect(session.source == .youtube(videoID: id, channel: "Some Channel"))
        #expect(session.source.isVideo)
        #expect(session.source.steps.isEmpty)
    }

    @Test("A video in the shipped catalog is never the person's own")
    func catalogVideoIsNotOwn() {
        let session = Session.ownVideo(
            id: "main-class", title: "Class", channel: "Creator", videoID: id,
            activity: .yoga, durationMin: 30, course: .main
        )
        #expect(!session.isOwn)
    }

    @Test("A saved video survives a trip through storage")
    @MainActor
    func storageRoundTrip() throws {
        let container = try ModelContainer(
            for: Schema(FeelGoodSchema.models),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        let log = SessionLog(context: ModelContext(container), calendar: Fixture.utc)

        let saved = log.keepVideo(
            title: "Gentle flow", channel: "Some Channel", videoID: id,
            activity: .yoga, durationMin: 20, course: .main, now: Fixture.now
        )
        let kept = try #require(log.kept().first)

        #expect(kept.id == saved.id)
        #expect(kept.title == "Gentle flow")
        #expect(kept.source == .youtube(videoID: id, channel: "Some Channel"))
        #expect(kept.isOwn)

        log.rename(kept.id, to: "Evening flow")
        let renamed = try #require(log.kept().first)
        #expect(renamed.title == "Evening flow")
        #expect(renamed.source == .youtube(videoID: id, channel: "Some Channel"))
    }

    @Test("A video is added to Today on request, and the menu never picks one by itself")
    @MainActor
    func addedVideoStaysOffTheEngine() {
        let store = ContentStore(catalog: ContentCatalog(version: 1, sessions: Fixture.catalog, glossary: []))
        let model = TodayModel(
            store: store, profile: Fixture.profile(), log: InMemorySessionLog(),
            now: Fixture.now, calendar: Fixture.utc
        )
        let info = YouTubeVideoInfo(videoID: id, title: "Gentle flow", channel: "Some Channel")

        let saved = model.addVideo(
            info, title: "Gentle flow", activity: .yoga, durationMin: 20,
            course: .main, addToToday: false, now: Fixture.now
        )
        #expect(model.customRoutines(for: .main).contains { $0.id == saved.id })
        #expect(!model.isCourseOverridden(.main))
        #expect(model.menu.items.allSatisfy { $0.session.id != saved.id })

        model.addVideo(
            info, title: "Gentle flow", activity: .yoga, durationMin: 20,
            course: .main, addToToday: true, now: Fixture.now
        )
        #expect(model.menu.main?.session.source.isVideo == true)
    }
}

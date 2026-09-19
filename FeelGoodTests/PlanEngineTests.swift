//
//  PlanEngineTests.swift
//  FeelGoodTests
//
//  The engine is the product. These tests cover the promises it makes —
//  and the unhappy paths in PRD §11, which are where a demo actually breaks.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("PlanEngine")
struct PlanEngineTests {

    // MARK: - The floor of the product

    @Test("There is always something to offer, even with nothing available")
    func alwaysOffersAnAppetizer() {
        // Worst case: no activities selected, no equipment, no time, no energy.
        let input = PlanInput(
            profile: Fixture.profile(activities: [], equipment: []),
            checkIn: PlanCheckIn(energy: .low, time: .aLittle),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(menu.appetizer?.session.id == "a-breath")
        #expect(menu.main == nil)
        #expect(!menu.items.isEmpty)
    }

    @Test("A 35-minute budget doesn't balloon into 48 minutes")
    func totalMenuDurationStaysNearBudget() {
        // Reported live, 2026-09-15: a 35-minute check-in produced a menu
        // totaling 48 minutes, and — after a first round of fixes — still
        // 36 against a 30-minute target. `.strong` energy and a 30-minute
        // main (m-pilates-30 / m-strength-30, both energy-fit for `.strong`)
        // reproduces the shape of the original report: a main big enough to
        // fill most of the budget on its own.
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .strong, time: .thirtyFiveMinutes),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)
        let budget = TimeBudget.thirtyFiveMinutes.maxMinutes

        let total = menu.items
            .filter { $0.course != .special }
            .reduce(0) { $0 + $1.session.durationMin }

        // `makeMenu` now reserves room for the appetizer/dessert floor
        // guarantee *before* picking the main (see `reservedFloor` in
        // `PlanEngine.swift`), so the common case should land at or under
        // budget rather than needing headroom for an overshoot. This is
        // still not a hard invariant — a tight enough budget, or a
        // reservation estimate that gets invalidated once an activity is
        // actually taken, could still land a few minutes over — so this
        // stays a bounded check, just a much tighter one than the +15 this
        // test started with before that reservation existed.
        #expect(total <= budget, "menu totaled \(total) minutes against a \(budget)-minute budget")
    }

    @Test("Total menu duration never exceeds check-in budget across all times and moments")
    func totalMenuDurationNeverExceedsBudget() {
        for time in TimeBudget.allCases where !time.isZero {
            for energy in Energy.allCases {
                for moments in MovementMoments.allCases {
                    let input = PlanInput(
                        profile: Fixture.profile(moments: moments),
                        checkIn: PlanCheckIn(energy: energy, time: time),
                        context: Fixture.context()
                    )
                    let menu = Fixture.engine.makeMenu(input)
                    let total = menu.items
                        .filter { $0.course != .special }
                        .reduce(0) { $0 + $1.session.durationMin }
                    #expect(total <= time.maxMinutes, "menu totaled \(total) min against a \(time.maxMinutes)-minute budget for \(energy)/\(moments)")
                }
            }
        }
    }

    @Test("Swapping an item preserves total menu budget")
    func swappingItemPreservesBudget() {
        for time in TimeBudget.allCases where !time.isZero {
            let input = PlanInput(
                profile: Fixture.profile(moments: .aCouple),
                checkIn: PlanCheckIn(energy: .steady, time: time),
                context: Fixture.context()
            )
            let menu = Fixture.engine.makeMenu(input)
            for item in menu.items where item.course != .special {
                var current = item
                var seen: Set<String> = [item.session.id]
                for _ in 0..<3 {
                    if let alt = Fixture.engine.alternative(for: current, onMenu: menu, input: input, alreadySeen: seen) {
                        let other = menu.items.filter { $0.id != item.id && $0.course != .special }.reduce(0) { $0 + $1.session.durationMin }
                        let newTotal = other + alt.session.durationMin
                        #expect(newTotal <= time.maxMinutes, "swap to \(alt.session.title) totaled \(newTotal) against \(time.maxMinutes) min")
                        seen.insert(alt.session.id)
                        current = alt
                    }
                }
            }
        }
    }

    @Test("A skipped check-in still produces a menu")
    func skippedCheckInStillProducesAMenu() {
        let input = PlanInput(profile: Fixture.profile(), checkIn: nil, context: Fixture.context())
        let menu = Fixture.engine.makeMenu(input)

        #expect(menu.appetizer != nil)
        #expect(menu.main != nil)
        #expect(!menu.headline.isEmpty)
    }

    @Test("Menu cards follow their course order")
    func menuCardsFollowCourseOrder() {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        let courses = Fixture.engine.makeMenu(input).items.map(\.course)
        let position: [Course: Int] = [
            .appetizer: 0,
            .main: 1,
            .side: 2,
            .dessert: 3,
            .special: 4,
        ]

        #expect(courses.first == .appetizer)
        #expect(zip(courses, courses.dropFirst()).allSatisfy { pair in
            (position[pair.0] ?? 0) <= (position[pair.1] ?? 0)
        })
    }

    @Test("Every item carries a plain-language reason")
    func everyItemSaysWhy() {
        let input = PlanInput(profile: Fixture.profile(), context: Fixture.context())
        let menu = Fixture.engine.makeMenu(input)

        #expect(!menu.items.isEmpty)
        for item in menu.items {
            #expect(!item.reasonText.isEmpty)
        }
    }

    @Test("No two items give the same reason")
    func reasonsDoNotRepeat() {
        // Three cards reading "toward the strength you're building" is not
        // saying why — it's wallpaper.
        for intent in Intent.allCases {
            let input = PlanInput(
                profile: Fixture.profile(intent: intent),
                checkIn: PlanCheckIn(energy: .steady, time: .plenty),
                context: Fixture.context()
            )
            let texts = Fixture.engine.makeMenu(input).items.map(\.reasonText)
            #expect(Set(texts).count == texts.count, "repeated reason for \(intent): \(texts)")
        }
    }

    @Test("A session can match any selected direction")
    func anySelectedIntentCanMatch() {
        let calm = Fixture.session(
            id: "a-calm",
            activity: .breathwork,
            qualities: [.downRegulation],
            durationMin: 10,
            intensity: 1,
            course: .main,
            intents: [.calm]
        )
        let joy = Fixture.session(
            id: "b-joy",
            activity: .breathwork,
            qualities: [.downRegulation],
            durationMin: 10,
            intensity: 1,
            course: .main,
            intents: [.joy]
        )
        let input = PlanInput(
            profile: Fixture.profile(intents: [.strengthen, .calm]),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )

        let menu = PlanEngine(catalog: [joy, calm]).makeMenu(input)
        #expect(menu.main?.session.id == calm.id)
        #expect(menu.main?.reasons.contains(.matchesIntent) == true)
    }

    @Test("Play is a distinct direction that boosts playful sessions")
    func playCanDriveRanking() {
        let neutral = Fixture.session(
            id: "a-neutral",
            activity: .walking,
            qualities: [.endurance],
            durationMin: 10,
            intensity: 2,
            course: .main,
            intents: [.energize]
        )
        let playful = Fixture.session(
            id: "b-play",
            activity: .dance,
            qualities: [.coordination],
            durationMin: 10,
            intensity: 2,
            course: .main,
            intents: [.play]
        )
        let input = PlanInput(
            profile: Fixture.profile(intents: [.play]),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )

        let menu = PlanEngine(catalog: [neutral, playful]).makeMenu(input)
        #expect(menu.main?.session.id == playful.id)
        #expect(menu.main?.reasonText == "Because it sounds fun.")
    }

    // MARK: - Hard filters

    @Test("Never recommends more time than the check-in said was available")
    func respectsTimeBudget() {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .aLittle),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        for item in menu.items where item.course != .special {
            #expect(item.session.durationMin <= TimeBudget.aLittle.maxMinutes)
        }
    }

    @Test("Never recommends equipment that isn't available")
    func respectsEquipment() {
        let input = PlanInput(
            profile: Fixture.profile(equipment: [.none, .mat]),
            checkIn: PlanCheckIn(energy: .strong, time: .plenty),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(!menu.items.contains { $0.session.id == "m-strength-30" })
        for item in menu.items {
            #expect(Set(item.session.equipment).subtracting([.none]).isSubset(of: [.mat]))
        }
    }

    @Test("Movement that needs nothing is eligible without ever having been picked")
    func theActivityGateAppliesOnlyToAccess() {
        // A profile that named one thing: Pilates. Breathwork and carries were
        // never on the onboarding card to name, so the engine may still reach
        // for them — but a rope is a real question, and this profile has one.
        let input = PlanInput(
            profile: Fixture.profile(activities: [.pilates], equipment: [.none, .mat, .rope]),
            context: Fixture.context()
        )
        let checkIn = PlanCheckIn(energy: .strong, time: .plenty)
        let byID = Dictionary(uniqueKeysWithValues: Fixture.catalog.map { ($0.id, $0) })

        #expect(Fixture.engine.isEligible(byID["a-breath"]!, input: input, checkIn: checkIn))
        #expect(Fixture.engine.isEligible(byID["s-carry"]!, input: input, checkIn: checkIn))
        #expect(!Fixture.engine.isEligible(byID["a-jump"]!, input: input, checkIn: checkIn))
        #expect(!Fixture.engine.isEligible(byID["m-walk-20"]!, input: input, checkIn: checkIn))
    }

    @Test("Nothing bouncy reaches someone who flagged their pelvic floor")
    func workAroundsHardFilterImpact() {
        let input = PlanInput(
            profile: Fixture.profile(
                activities: [.jumpRope, .breathwork, .pilates],
                equipment: [.none, .mat, .rope],
                workArounds: [.pelvicFloor]
            ),
            checkIn: PlanCheckIn(energy: .strong, time: .plenty),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(!menu.items.contains { $0.session.id == "a-jump" })
        #expect(menu.appetizer != nil)
    }

    @Test("Work-arounds still filter the guaranteed fallback path")
    func fallbackAppetizerRespectsSafety() {
        let engine = PlanEngine(catalog: [
            Fixture.session(id: "a-only", activity: .breathwork, qualities: [.downRegulation],
                            durationMin: 2, intensity: 1, course: .appetizer,
                            contraindications: [.pregnancy])
        ])
        let input = PlanInput(
            profile: Fixture.profile(activities: [], equipment: [], workArounds: [.pregnancy]),
            checkIn: PlanCheckIn(energy: .low, time: .aLittle),
            context: Fixture.context()
        )

        // Nothing safe exists, so nothing is offered — we never fall back to
        // something contraindicated just to fill the menu.
        #expect(engine.makeMenu(input).appetizer == nil)
    }

    @Test("Offline silently drops video sessions", arguments: [
        (true, false), (false, true), (true, true)
    ])
    func offlineFiltersVideo(isOffline: Bool, dataSaver: Bool) {
        let profile = Fixture.profile(activities: [.pilates, .breathwork], equipment: [.none, .mat])
        let checkIn = PlanCheckIn(energy: .steady, time: .plenty)

        let offline = PlanInput(
            profile: profile, checkIn: checkIn,
            context: Fixture.context(isOffline: isOffline, dataSaver: dataSaver)
        )
        #expect(Fixture.engine.makeMenu(offline).items.allSatisfy { !$0.session.source.isVideo })

        // ...and it is only the connectivity that ruled it out.
        let online = PlanInput(profile: profile, checkIn: checkIn, context: Fixture.context())
        let video = Fixture.catalog.first { $0.id == "m-video-20" }!
        #expect(Fixture.engine.isEligible(video, input: online, checkIn: checkIn))
    }

    // MARK: - Place

    @Test("Deciding not to leave the house never produces a menu that requires leaving")
    func stayingInFiltersEverythingOutdoors() {
        // The brief this product exists to answer: twenty minutes, nothing left,
        // not going anywhere.
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .low, time: .some, place: .stayingIn),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(!menu.items.isEmpty)
        for item in menu.items {
            #expect(item.session.places.contains(.home), "\(item.session.id) needs leaving the house")
        }
        #expect(!menu.items.contains { $0.session.id == "m-walk-20" })
    }

    @Test("Somebody with no gym is never sent to one")
    func placesAreFilteredByTheProfile() {
        let input = PlanInput(
            profile: Fixture.profile(places: [.home]),
            checkIn: PlanCheckIn(energy: .strong, time: .plenty),
            context: Fixture.context()
        )
        for item in Fixture.engine.makeMenu(input).items {
            #expect(item.session.places.contains(.home))
        }
    }

    @Test("There is still something to do when staying in with nothing at all")
    func theFloorSurvivesStayingIn() throws {
        let input = PlanInput(
            profile: Fixture.profile(activities: [], equipment: [], places: [.home]),
            checkIn: PlanCheckIn(energy: .low, time: .aLittle, place: .stayingIn),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        let appetizer = try #require(menu.appetizer)
        #expect(appetizer.session.places.contains(.home))
    }

    @Test("Going out doesn't rule out staying in")
    func goingOutStillAllowsHomeSessions() {
        // "Happy to go out" widens the menu; it never narrows it to only
        // outdoor things.
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty, place: .happyToGoOut),
            context: Fixture.context()
        )
        let places = Set(Fixture.engine.makeMenu(input).items.flatMap(\.session.places))
        #expect(places.contains(.home) || places.contains(.outdoors))
    }

    // MARK: - Shape of the day

    @Test("Wanting one proper session gets a Main and no Sides")
    func onceADayIsShapedAroundTheMain() {
        let input = PlanInput(
            profile: Fixture.profile(moments: .once),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(menu.main != nil)
        #expect(menu.sides.isEmpty)
    }

    @Test("Wanting movement sprinkled through the day gets more small things")
    func sprinkledIsShapedAroundSides() {
        let sprinkled = PlanInput(
            profile: Fixture.profile(moments: .sprinkled),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        let once = PlanInput(
            profile: Fixture.profile(moments: .once),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        let sprinkledMenu = Fixture.engine.makeMenu(sprinkled)

        #expect(sprinkledMenu.sides.count > Fixture.engine.makeMenu(once).sides.count)
        // Same day, rearranged — not a longer one.
        #expect(sprinkledMenu.items.count <= PlanEngine.maxMenuItems)
    }

    // MARK: - Scoring behaviour

    @Test("A low-energy day gets something gentle")
    func lowEnergyPrefersRestfulWork() throws {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .low, time: .plenty),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        let main = try #require(menu.main)
        #expect(main.session.intensity <= 2)
        #expect(menu.reasonCodes.contains(.lowEnergy))
    }

    @Test("Two hard days running do not become three")
    func recoveryBalanceAfterTwoHardDays() throws {
        let history = [
            Fixture.completed("m-strength-30", activity: .strength, intensity: 5, daysAgo: 1),
            Fixture.completed("m-strength-30", activity: .strength, intensity: 5, daysAgo: 2),
        ]
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .strong, time: .plenty),
            history: history,
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        let main = try #require(menu.main)
        #expect(main.session.intensity <= 2)
        #expect(menu.reasonCodes.contains(.recoveryBalance))
        #expect(menu.headline == "You've shown up a few days running — today's a lighter one on purpose.")
    }

    @Test("The same activity three days running gets a break")
    func varietyBreaksMonotony() {
        let history = [
            Fixture.completed("m-pilates-30", activity: .pilates, intensity: 3, daysAgo: 1),
            Fixture.completed("m-pilates-30", activity: .pilates, intensity: 3, daysAgo: 2),
        ]
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            history: history,
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(menu.main?.session.activity != .pilates)
        #expect(menu.reasonCodes.contains(.varietyBreak))
    }

    @Test("Coming back after a gap gets a short, easy menu and a warm line")
    func returningAfterAGap() {
        let history = [Fixture.completed("m-pilates-30", activity: .pilates, intensity: 3, daysAgo: 9)]
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            history: history,
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(menu.headline == "Good to see you. Let's start small.")
        #expect(menu.reasonCodes.contains(.returningAfterGap))
        #expect(menu.main.map { $0.session.durationMin <= 15 } ?? true)
        // Nothing anywhere mentions the gap itself.
        #expect(!menu.headline.lowercased().contains("days"))
        for item in menu.items {
            #expect(!item.reasonText.lowercased().contains("haven't been"))
        }
    }

    @Test("A brand-new user is not behind on any movement quality")
    func qualityCoverageNeedsRealHistory() {
        let thin = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            history: [Fixture.completed("m-pilates-30", activity: .pilates, intensity: 3, daysAgo: 2)],
            context: Fixture.context()
        )
        #expect(!Fixture.engine.makeMenu(thin).reasonCodes.contains(.qualityGap))

        // With two weeks of one-note history, the absence starts to mean something.
        let oneNote = (1...5).map {
            Fixture.completed("m-pilates-30", activity: .pilates,
                              qualities: [.strength], intensity: 3, daysAgo: $0 + 2)
        }
        let rich = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            history: oneNote,
            context: Fixture.context()
        )
        #expect(Fixture.engine.makeMenu(rich).reasonCodes.contains(.qualityGap))
    }

    @Test("Loving a session makes it more likely; finding it too much makes it less")
    func affinityShiftsPicks() {
        let profile = Fixture.profile(intent: .energize)
        let checkIn = PlanCheckIn(energy: .steady, time: .plenty)
        let base = PlanInput(profile: profile, checkIn: checkIn, context: Fixture.context())
        let baseMain = Fixture.engine.makeMenu(base).main?.session.id

        let loved = PlanInput(
            profile: profile, checkIn: checkIn, context: Fixture.context(),
            affinity: ["m-pilates-10": 1.0]
        )
        #expect(Fixture.engine.makeMenu(loved).main?.session.id == "m-pilates-10")

        let disliked = PlanInput(
            profile: profile, checkIn: checkIn, context: Fixture.context(),
            affinity: [baseMain ?? "": -1.0]
        )
        #expect(Fixture.engine.makeMenu(disliked).main?.session.id != baseMain)
    }

    @Test("Skipping a session is not held against you")
    func skippingCarriesNoPenalty() {
        let profile = Fixture.profile()
        let checkIn = PlanCheckIn(energy: .steady, time: .plenty)
        let clean = PlanInput(profile: profile, checkIn: checkIn, context: Fixture.context())
        let skipped = PlanInput(
            profile: profile, checkIn: checkIn,
            history: [HistoryEntry(sessionID: "m-pilates-10", activity: .pilates,
                                   qualities: [.strength], intensity: 2, course: .main,
                                   date: Fixture.daysAgo(1), outcome: .skipped)],
            context: Fixture.context()
        )
        #expect(Fixture.engine.makeMenu(clean).main?.session.id == Fixture.engine.makeMenu(skipped).main?.session.id)
    }

    @Test("A sore body gets mobility and recovery, not intensity")
    func bodyStateShapesThePicks() throws {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .strong, time: .plenty, body: .sore),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)
        let main = try #require(menu.main)
        #expect(main.session.intensity <= 3)
    }

    // MARK: - Shape of the menu

    @Test("The menu never grows past one screen")
    func menuStaysShort() {
        let input = PlanInput(
            profile: Fixture.profile(
                activities: Set(Activity.allCases),
                equipment: Set(Equipment.allCases),
                places: Set(Place.allCases),
                moments: .sprinkled
            ),
            checkIn: PlanCheckIn(energy: .strong, time: .plenty),
            context: Fixture.context(specials: [ScheduledSpecial(sessionID: "sp-swim", date: Fixture.now)])
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(menu.items.count <= PlanEngine.maxMenuItems)
        #expect(menu.items.count >= 3)
        #expect(Set(menu.items.map(\.id)).count == menu.items.count)
    }

    @Test("A special is surfaced ahead of the day it happens, ignoring today's time")
    func specialsAreSurfacedAhead() throws {
        let profile = Fixture.profile(
            activities: [.swimming, .breathwork, .pilates],
            equipment: [.none, .mat, .pool],
            places: [.home, .pool]
        )
        let input = PlanInput(
            profile: profile,
            checkIn: PlanCheckIn(energy: .low, time: .aLittle),
            context: Fixture.context(specials: [
                ScheduledSpecial(sessionID: "sp-swim", date: Fixture.utc.date(byAdding: .day, value: 2, to: Fixture.now)!)
            ])
        )
        let menu = Fixture.engine.makeMenu(input)

        let special = try #require(menu.special)
        #expect(special.session.id == "sp-swim")
        #expect(special.session.durationMin > TimeBudget.aLittle.maxMinutes)
    }

    @Test("A special further out than a few days stays off today's menu")
    func distantSpecialsAreNotSurfaced() {
        let input = PlanInput(
            profile: Fixture.profile(
                activities: [.swimming, .breathwork],
                equipment: [.none, .pool],
                places: [.home, .pool]
            ),
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            context: Fixture.context(specials: [
                ScheduledSpecial(sessionID: "sp-swim", date: Fixture.utc.date(byAdding: .day, value: 9, to: Fixture.now)!)
            ])
        )
        #expect(Fixture.engine.makeMenu(input).special == nil)
    }

    // MARK: - Swapping

    @Test("Not today returns a different session in the same course")
    func swapReturnsTheNextBest() throws {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        let engine = Fixture.engine
        let menu = engine.makeMenu(input)
        let main = try #require(menu.main)

        let swapped = try #require(engine.alternative(for: main, onMenu: menu, input: input))
        #expect(swapped.session.id != main.session.id)
        #expect(swapped.course == .main)
        #expect(!menu.items.map(\.id).contains(swapped.id))
    }

    @Test("Swapping repeatedly runs out gracefully rather than repeating itself")
    func swapExhaustsWithoutRepeating() throws {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        let engine = Fixture.engine
        let menu = engine.makeMenu(input)
        var current = try #require(menu.main)
        var seen: Set<String> = [current.session.id]

        while let next = engine.alternative(for: current, onMenu: menu, input: input, alreadySeen: seen) {
            #expect(!seen.contains(next.session.id))
            seen.insert(next.session.id)
            current = next
            if seen.count > Fixture.catalog.count { Issue.record("swap looped"); break }
        }
        #expect(seen.count >= 2)
    }

    @Test("Cyclic alternative returns an option even when all candidates have been seen")
    func cyclicAlternativeWrapsAround() throws {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        let engine = Fixture.engine
        let menu = engine.makeMenu(input)
        let main = try #require(menu.main)

        let cyclic = try #require(engine.cyclicAlternative(for: main, onMenu: menu, input: input))
        #expect(cyclic.session.id != main.session.id)
        #expect(cyclic.course == .main)
    }

    @Test("A dessert is guaranteed even with no activities selected and minimal access")
    func guaranteedDessertIsAlwaysOfferable() {
        let input = PlanInput(
            profile: Fixture.profile(activities: [], equipment: [.none], places: [.home]),
            checkIn: PlanCheckIn(energy: .low, time: .aLittle),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)
        #expect(menu.dessert != nil)
        #expect(menu.dessert?.course == .dessert)
    }

    // MARK: - Determinism and time

    @Test("The same inputs always produce the same menu")
    func isDeterministic() {
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            history: [Fixture.completed("m-walk-20", activity: .walking, intensity: 2, daysAgo: 1)],
            context: Fixture.context()
        )
        #expect(Fixture.engine.makeMenu(input) == Fixture.engine.makeMenu(input))
    }

    @Test("The day boundary follows the user's calendar, not UTC")
    func dayStartUsesTheUsersCalendar() {
        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = TimeZone(identifier: "America/New_York")!

        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            context: Fixture.context(calendar: newYork)
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(menu.dayStart == newYork.startOfDay(for: Fixture.now))
        #expect(menu.dayStart != Fixture.utc.startOfDay(for: Fixture.now))
    }

    @Test("History from the future or beyond the window is ignored")
    func historyWindowIsBounded() {
        let profile = Fixture.profile()
        let checkIn = PlanCheckIn(energy: .steady, time: .plenty)
        let clean = PlanInput(profile: profile, checkIn: checkIn, context: Fixture.context())
        let noise = PlanInput(
            profile: profile, checkIn: checkIn,
            history: [
                Fixture.completed("m-pilates-30", activity: .pilates, intensity: 5, daysAgo: 40),
                Fixture.completed("m-pilates-30", activity: .pilates, intensity: 5, daysAgo: -3),
            ],
            context: Fixture.context()
        )
        #expect(Fixture.engine.makeMenu(clean) == Fixture.engine.makeMenu(noise))
    }

    @Test("Every combination of energy and time still produces a safe menu")
    func neverFailsAcrossTheCheckInMatrix() {
        for energy in Energy.allCases {
            for time in TimeBudget.allCases {
                for body in BodyState.allCases.map(Optional.some) + [nil] {
                    let input = PlanInput(
                        profile: Fixture.profile(),
                        checkIn: PlanCheckIn(energy: energy, time: time, body: body),
                        context: Fixture.context()
                    )
                    let menu = Fixture.engine.makeMenu(input)
                    #expect(menu.appetizer != nil, "no appetizer for \(energy)/\(time)")
                    #expect(menu.items.count <= PlanEngine.maxMenuItems)
                    for item in menu.items where item.course != .special {
                        #expect(item.session.durationMin <= time.maxMinutes)
                    }
                }
            }
        }
    }

    @Test("De-duplicates activities across courses (Main vs Appetizer/Dessert/Sides)")
    func deDuplicatesActivitiesAcrossCourses() {
        let mainYoga = Fixture.session(id: "main-yoga", activity: .yoga, qualities: [.mobility], durationMin: 20, intensity: 2, course: .main)
        let mainPilates = Fixture.session(id: "main-pilates", activity: .pilates, qualities: [.strength], durationMin: 20, intensity: 3, course: .main)
        
        let appYoga = Fixture.session(id: "app-yoga", activity: .yoga, qualities: [.mobility], durationMin: 5, intensity: 1, course: .appetizer)
        let appPilates = Fixture.session(id: "app-pilates", activity: .pilates, qualities: [.strength], durationMin: 5, intensity: 1, course: .appetizer)
        
        // des-yoga is given the profile's own intent so it outscores des-pilates.
        // The point of the assertion below is that it still doesn't win: the
        // Dessert declines to echo the Main even when the echo scores higher.
        let desYoga = Fixture.session(id: "des-yoga", activity: .yoga, qualities: [.mobility], durationMin: 5, intensity: 1, course: .dessert, intents: [.mobilize])
        let desPilates = Fixture.session(id: "des-pilates", activity: .pilates, qualities: [.strength], durationMin: 5, intensity: 1, course: .dessert)
        
        let input = PlanInput(
            profile: Fixture.profile(activities: [.yoga, .pilates], intent: .mobilize),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        
        let catalog = [mainYoga, mainPilates, appYoga, appPilates, desYoga, desPilates]
        let engine = PlanEngine(catalog: catalog)
        let menu = engine.makeMenu(input)
        
        #expect(menu.main?.session.id == "main-yoga")
        #expect(menu.appetizer?.session.id == "app-pilates")
        // Two activities, three courses — something has to repeat. It repeats
        // the Appetizer, never the Main: the Main is the day's real offer and
        // the contrast that reads is contrast with it.
        #expect(menu.dessert?.session.id == "des-pilates")
    }

    @Test("Falls back to duplicate activity if no distinct activities are available")
    func fallsBackToDuplicateActivityWhenNoChoice() {
        let mainYoga = Fixture.session(id: "main-yoga", activity: .yoga, qualities: [.mobility], durationMin: 20, intensity: 2, course: .main)
        let appYoga = Fixture.session(id: "app-yoga", activity: .yoga, qualities: [.mobility], durationMin: 5, intensity: 1, course: .appetizer)
        
        let input = PlanInput(
            profile: Fixture.profile(activities: [.yoga], intent: .mobilize),
            checkIn: PlanCheckIn(energy: .steady, time: .plenty),
            context: Fixture.context()
        )
        
        let catalog = [mainYoga, appYoga]
        let engine = PlanEngine(catalog: catalog)
        let menu = engine.makeMenu(input)
        
        #expect(menu.main?.session.id == "main-yoga")
        #expect(menu.appetizer?.session.id == "app-yoga")
    }

    @Test("Hidden sessions are strictly excluded from the menu")
    func hiddenSessionsAreNeverRecommended() {
        let profile = Fixture.profile(activities: [.yoga, .pilates])
        let checkIn = PlanCheckIn(energy: .steady, time: .plenty)
        let unhiddenInput = PlanInput(profile: profile, checkIn: checkIn, context: Fixture.context())
        let unhiddenMenu = Fixture.engine.makeMenu(unhiddenInput)

        guard let mainSession = unhiddenMenu.main?.session else {
            Issue.record("Expected a main session")
            return
        }

        // Hide that main session
        var hiddenProfile = profile
        hiddenProfile.hiddenSessionIDs.insert(mainSession.id)
        let hiddenInput = PlanInput(profile: hiddenProfile, checkIn: checkIn, context: Fixture.context())
        let hiddenMenu = Fixture.engine.makeMenu(hiddenInput)

        #expect(hiddenMenu.main?.session.id != mainSession.id)
        #expect(!hiddenMenu.items.contains(where: { $0.session.id == mainSession.id }))
    }

    @Test("Barefoot porch breath is excluded when hidden by user")
    func barefootPorchBreathExcludedWhenHidden() {
        var profile = Fixture.profile(activities: [.breathwork, .yoga, .pilates])
        profile.hiddenSessionIDs.insert("dessert-barefoot-breath")
        let input = PlanInput(
            profile: profile,
            checkIn: PlanCheckIn(energy: .low, time: .plenty),
            context: Fixture.context()
        )
        let menu = Fixture.engine.makeMenu(input)

        #expect(!menu.items.contains(where: { $0.session.id == "dessert-barefoot-breath" }))
    }

    @Test("Checking in with zero minutes produces an untimed rest day menu")
    func zeroMinuteCheckInProducesRestDayMenu() {
        for energy in Energy.allCases {
            let input = PlanInput(
                profile: Fixture.profile(),
                checkIn: PlanCheckIn(energy: energy, time: .zeroMinutes),
                context: Fixture.context()
            )
            let menu = Fixture.engine.makeMenu(input)
            #expect(menu.headline == "Rest is part of it. Take the day.")
            #expect(menu.appetizer != nil)
            #expect(menu.main != nil)
            #expect(menu.sides.isEmpty)
            #expect(menu.dessert == nil)
            #expect(menu.special == nil)
            #expect(menu.items.count == 2)
            #expect(menu.items.allSatisfy { $0.session.durationMin == 0 })
            #expect(menu.items.allSatisfy { $0.session.durationLabel == "Untimed" })
        }
    }
}

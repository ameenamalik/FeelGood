//
//  CatalogTests.swift
//  FeelGoodTests
//
//  The shipped catalog is content, which means it changes far more often than
//  the code that reads it. These run the real bundled JSON through the real
//  engine so a bad content drop fails the build, not somebody's morning.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Bundled catalog")
struct CatalogTests {

    private func store() throws -> ContentStore {
        try ContentStore.bundled()
    }

    @Test("A step authored before reps existed still decodes, as untimed-by-count")
    func stepWithoutRepsDecodes() throws {
        // The shape of every step in the catalog today. Adding `reps` must not
        // require touching any of them.
        let json = Data("""
        {"name": "Dead bug", "seconds": 40, "cue": "Slow and low."}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        #expect(step.reps == nil)
        #expect(step.sets == nil)
        #expect(step.switchSides == nil)
        #expect(step.switchAfterSeconds == nil)
        #expect(step.isCounted == false)
        #expect(step.seconds == 40)
    }

    @Test("A step with explicit switchSides and switchAfterSeconds decodes correctly")
    func stepWithSwitchSidesDecodes() throws {
        let json = Data("""
        {"name": "Side plank", "seconds": 60, "cue": "Lift hips.", "switchSides": true, "switchAfterSeconds": 30}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        #expect(step.switchSides == true)
        #expect(step.switchAfterSeconds == 30)
        #expect(step.requiresSideSwitch == true)
        #expect(step.sideSwitchThresholdSeconds == 30)
    }

    @Test("Cue text inference correctly identifies side-switch exercises and thresholds")
    func cueTextInferenceDetectsSideSwitch() throws {
        // "Switch sides halfway."
        let step1 = Step(name: "Figure 4", seconds: 60, cue: "Lean forward gently. Switch sides halfway.")
        #expect(step1.requiresSideSwitch == true)
        #expect(step1.sideSwitchThresholdSeconds == 30)

        // "after 2 minutes"
        let step2 = Step(name: "Runner lunge", seconds: 240, cue: "Step into a runner lunge. Switch sides after 2 minutes.")
        #expect(step2.requiresSideSwitch == true)
        #expect(step2.sideSwitchThresholdSeconds == 120)

        // "Ninety seconds each side"
        let step3 = Step(name: "Leg stretch", seconds: 180, cue: "Strap, towel or hands. Ninety seconds each side.")
        #expect(step3.requiresSideSwitch == true)
        #expect(step3.sideSwitchThresholdSeconds == 90)

        // Single-side step with "(Right)" should not switch mid-hold
        let step4 = Step(name: "Figure four (Right)", seconds: 60, cue: "Breathe, then switch sides.")
        #expect(step4.requiresSideSwitch == false)

        // Counted step should not switch timed
        let step5 = Step(name: "Lunges", seconds: 60, cue: "Switch sides halfway.", reps: 10)
        #expect(step5.requiresSideSwitch == false)
    }

    @Test("CueBreakdown parses lead action and tips, filtering inline switch notice when alert is handled")
    func cueBreakdownParsesCorrectly() {
        let cue = "Sit on the edge of your chair, cross right ankle over left knee. Gently lean forward with a flat back. Switch sides halfway."
        let breakdown = CueBreakdown(raw: cue, requiresSideSwitch: true)
        #expect(breakdown.leadAction == "Sit on the edge of your chair, cross right ankle over left knee")
        #expect(breakdown.tips == ["Gently lean forward with a flat back"])

        let singleSentenceCue = "Hold onto desk for balance and breathe deep."
        let breakdown2 = CueBreakdown(raw: singleSentenceCue, requiresSideSwitch: false)
        #expect(breakdown2.leadAction == "Hold onto desk for balance and breathe deep")
        #expect(breakdown2.tips.isEmpty)
    }

    @Test("A counted step decodes and reports itself as counted")
    func stepWithRepsDecodes() throws {
        let json = Data("""
        {"name": "Sit to stand", "seconds": 40, "cue": "Drive through the heels.", "reps": 8}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        #expect(step.reps == 8)
        #expect(step.isCounted)
        // Reps with no sets authored is one set of them, not none.
        #expect(step.setCount == 1)
        // A counted step still costs time on the menu — the engine's time fit
        // is built from seconds, and a set nobody timed still takes a while.
        #expect(step.seconds == 40)
    }

    @Test("Reps are per set, so three sets of ten is a ten and never a thirty")
    func repsAreCountedPerSet() throws {
        let json = Data("""
        {"name": "Leg press", "seconds": 240, "cue": "Feet flat.", "reps": 10, "sets": 3}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        #expect(step.reps == 10)
        #expect(step.setCount == 3)
    }

    @Test("Zero reps is authoring noise, not a step nobody can finish")
    func zeroRepsIsNotCounted() throws {
        let json = Data("""
        {"name": "Breathe", "seconds": 30, "cue": "In, out.", "reps": 0}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        // Counted would mean the player waits for a tap that can never come.
        #expect(step.isCounted == false)
    }

    @Test("Zero sets is one set, not a step that ends before it starts")
    func zeroSetsIsOneSet() throws {
        let json = Data("""
        {"name": "Calf raises", "seconds": 120, "cue": "Slowly.", "reps": 10, "sets": 0}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        #expect(step.setCount == 1)
    }

    @Test("Every counted step in the bundled catalog asks for a finishable set")
    func countedStepsAreFinishable() throws {
        let store = try store()
        for session in store.sessions {
            for step in session.source.steps where step.reps != nil {
                #expect(step.reps! > 0, "\(session.id) has a step with a non-positive rep count")
                // Per-set, so the ceiling is what one set can plausibly be —
                // a number past this is a sign somebody authored a total.
                #expect(step.reps! <= 20, "\(session.id) asks for \(step.reps!) reps in one set")
                #expect(step.setCount <= 5, "\(session.id) asks for \(step.setCount) sets in one step")
            }
        }
    }

    @Test("The bundled catalog decodes")
    func catalogDecodes() throws {
        let store = try store()
        #expect(store.version >= 1)
        #expect(store.sessions.count >= 20)
        #expect(!store.glossary.isEmpty)
    }

    @Test("The catalog holds its invariants")
    func catalogIsValid() throws {
        let issues = try store().validate()
        #expect(issues.isEmpty, "\(issues.map(\.description))")
    }

    @Test("Every course is represented")
    func everyCourseIsStocked() throws {
        let sessions = try store().sessions
        for course in Course.allCases {
            #expect(sessions.contains { $0.course == course }, "no \(course) sessions")
        }
    }

    @Test("Every step that offers an explanation resolves to one")
    func glossaryReferencesResolve() throws {
        let store = try store()
        for session in store.sessions {
            for step in session.source.steps where step.glossaryID != nil {
                #expect(store.term(id: step.glossaryID) != nil,
                        "\(session.id) references \(step.glossaryID!)")
            }
        }
    }

    @Test("A step without a visual decodes as a plain card")
    func stepWithoutVisualDecodes() throws {
        let json = Data("""
        {"name": "Warm up", "seconds": 60, "cue": "Easy pace."}
        """.utf8)
        let step = try JSONDecoder().decode(Step.self, from: json)
        #expect(step.visual == nil)
    }

    @Test("A breathing visual decodes its cadence and fills in what it leaves out")
    func breathingVisualDecodes() throws {
        let explicit = try JSONDecoder().decode(Step.self, from: Data("""
        {"name": "Box breathing", "seconds": 60, "cue": "In, hold, out, hold.",
         "visual": {"type": "breathing", "inhale": 4, "holdIn": 4, "exhale": 4, "holdOut": 4}}
        """.utf8))
        #expect(explicit.visual?.breathingCadence == BreathingCadence(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4))

        let bare = try JSONDecoder().decode(Step.self, from: Data("""
        {"name": "Breathe", "seconds": 60, "cue": "Nothing to do.", "visual": {"type": "breathing"}}
        """.utf8))
        #expect(bare.visual?.breathingCadence == .default)
        #expect(BreathingCadence.default.cycleSeconds == 10)

        // Round-trips, so a custom routine that carries one survives being saved.
        let encoded = try JSONEncoder().encode(explicit)
        #expect(try JSONDecoder().decode(Step.self, from: encoded) == explicit)
    }

    @Test("Every paced breathing step has a cadence that fits inside it")
    func breathingStepsHaveUsableCadences() throws {
        var paced = 0
        for session in try store().sessions {
            for step in session.source.steps {
                guard let cadence = step.visual?.breathingCadence else { continue }
                paced += 1
                let label = "\(session.id) / \(step.name)"
                #expect(cadence.inhale > 0 && cadence.exhale > 0, "\(label) has no in or out breath")
                #expect(cadence.holdIn >= 0 && cadence.holdOut >= 0, "\(label) has a negative hold")
                #expect(cadence.cycleSeconds <= step.seconds, "\(label) can't complete one breath")
            }
        }
        #expect(paced > 0, "no breathing step is paced at all")
    }

    @Test("Box breathing is paced four-four-four-four, not the resting default")
    func boxBreathingCarriesItsCadence() throws {
        // The cue says "in for four, hold for four, out for four, hold for
        // four"; the orb used to animate all of these as four in, six out.
        let box = BreathingCadence(inhale: 4, holdIn: 4, exhale: 4, holdOut: 4)
        let sessions = try store().sessions
        let rounds = try #require(sessions.first { $0.id == "app-box-breathing" })
            .source.steps.filter { $0.name.hasPrefix("Round") }
        #expect(rounds.count == 4)
        for round in rounds {
            #expect(round.visual?.breathingCadence == box, "app-box-breathing / \(round.name)")
        }
        let barefoot = try #require(sessions.first { $0.id == "dessert-barefoot-breath" })
            .source.steps.first { $0.name == "Box breathing" }
        #expect(barefoot?.visual?.breathingCadence == box)
    }

    @Test("A recovery gap that mentions breath is a rest, not a breathing exercise")
    func recoveryGapsAreNotPaced() throws {
        // These used to get the orb because their names contain "breath".
        // Content decides now, and a rest between two bursts is a plain card.
        let rests: [(session: String, step: String)] = [
            ("app-jumping-jacks-two", "Breathe & recover"),
            ("app-shake-out-five", "Catch your breath"),
            ("app-power-explosions", "Active recovery breath"),
            ("side-gym-carry-the-floor", "Set down and breathe"),
        ]
        let sessions = try store().sessions
        for rest in rests {
            let steps = try #require(sessions.first { $0.id == rest.session }).source.steps
            let matches = steps.filter { $0.name == rest.step }
            #expect(!matches.isEmpty, "\(rest.session) no longer has \(rest.step)")
            for step in matches {
                #expect(step.visual == nil, "\(rest.session) / \(rest.step) is paced")
            }
        }
    }

    @Test("Gym taxonomy never reaches the glossary text")
    func glossaryAvoidsShameVocabulary() throws {
        // "Expert" next to a move someone is about to try is a shame vector, and
        // gym register is the voice we are deliberately not writing in.
        let banned = ["beginner", "intermediate", "expert", "advanced", "calorie", "burn fat", "toned"]
        for term in try store().glossary {
            let text = ([term.name] + term.instructions + term.muscles).joined(separator: " ").lowercased()
            for word in banned {
                #expect(!text.contains(word), "\(term.id) contains \"\(word)\"")
            }
        }
    }

    @Test("Nothing in the catalog claims a creator endorsed it")
    func nothingIsAttributedYet() throws {
        // Stays true until sign-off is in writing. See PRD §6.
        for session in try store().sessions {
            #expect(session.attribution == nil, "\(session.id) carries attribution")
        }
    }

    @Test("Anything bouncy is gated for pregnancy, postpartum and pelvic floor")
    func impactWorkIsSafetyGated() throws {
        for session in try store().sessions where session.qualities.contains(.impact) {
            let gates = Set(session.contraindications)
            #expect(gates.isSuperset(of: [.pregnancy, .postpartum, .pelvicFloor]),
                    "\(session.id) is impact work without full safety gating")
        }
    }

    @Test("Authored sessions carry the offline path")
    func authoredSessionsHaveSteps() throws {
        for session in try store().sessions where !session.source.isVideo {
            #expect(!session.source.steps.isEmpty, "\(session.id) has no steps")
            for step in session.source.steps {
                #expect(step.seconds > 0)
                #expect(!step.cue.isEmpty)
            }
        }
    }

    @Test("The real catalog produces a real menu for a real profile")
    func realCatalogPlansAWholeMenu() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .steady, time: .some),
            context: Fixture.context()
        )
        let menu = engine.makeMenu(input)

        #expect(menu.main != nil)
        #expect(menu.appetizer != nil)
        #expect((3...PlanEngine.maxMenuItems).contains(menu.items.count))
    }

    @Test("The real catalog never repeats a reason across a menu")
    func realCatalogGivesDistinctReasons() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        for energy in Energy.allCases {
            for time in TimeBudget.allCases {
                let input = PlanInput(
                    profile: Fixture.profile(),
                    checkIn: PlanCheckIn(energy: energy, time: time),
                    context: Fixture.context()
                )
                let texts = engine.makeMenu(input).items.map(\.reasonText)
                #expect(Set(texts).count == texts.count, "\(energy)/\(time): \(texts)")
            }
        }
    }

    @Test("Movement nobody is asked about still needs nothing to do it")
    func alwaysAvailableActivitiesHaveAnUnequippedSession() throws {
        let sessions = try store().sessions
        for activity in Activity.allCases where activity.isAlwaysAvailable {
            #expect(
                sessions.contains { $0.activity == activity && $0.needsNoEquipment },
                "\(activity) is never asked about, so it must be doable with nothing"
            )
        }
    }

    @Test("Qi gong reaches a stressed evening nobody had to ask for")
    func realCatalogRecommendsMovementThatWasNeverPicked() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        let input = PlanInput(
            profile: Fixture.profile(
                activities: [.pilates],
                equipment: [.none, .mat],
                places: [.home],
                intent: .calm
            ),
            checkIn: PlanCheckIn(energy: .low, time: .some, body: .stressed),
            context: Fixture.context()
        )
        let menu = engine.makeMenu(input)

        #expect(menu.items.contains { $0.session.activity.isAlwaysAvailable })
    }

    @Test("A gym membership fills the menu with things you can do at a gym")
    func realCatalogServesAGymMembership() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        let input = PlanInput(
            profile: Fixture.profile(
                activities: [.strength],
                equipment: [.none, .gym, .mat, .weights, .band, .bike],
                places: [.home, .gym],
                intent: .strengthen
            ),
            checkIn: PlanCheckIn(energy: .strong, time: .plenty, place: .atTheGym),
            context: Fixture.context()
        )
        let menu = engine.makeMenu(input)

        #expect(menu.main != nil)
        #expect(menu.items.contains { $0.session.equipment.contains(.gym) })
    }

    @Test("Every appetizer can be done without leaving the house")
    func appetizersAlwaysWorkAtHome() throws {
        for session in try store().sessions where session.course == .appetizer {
            #expect(session.worksAtHome, "\(session.id) needs somewhere other than home")
        }
    }

    @Test("Every session says where it can happen")
    func everySessionIsPlaced() throws {
        for session in try store().sessions {
            #expect(!session.places.isEmpty, "\(session.id) has no place")
        }
    }

    @Test("Twenty minutes, nothing left, not leaving the house")
    func theHardDayStillGetsAMenu() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        let input = PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .low, time: .some, place: .stayingIn),
            context: Fixture.context()
        )
        let menu = engine.makeMenu(input)

        #expect(menu.appetizer != nil)
        #expect(menu.main != nil)
        for item in menu.items {
            #expect(item.session.places.contains(.home))
            #expect(item.session.durationMin <= TimeBudget.some.maxMinutes)
        }
    }

    @Test("Nothing at the gym hangs on a chip the gym doesn't imply")
    func gymSessionsAreReachableFromAMembership() throws {
        for session in try store().sessions where session.equipment.contains(.gym) {
            #expect(
                session.activity.isAlwaysAvailable
                    || Equipment.gym.impliedActivities.contains(session.activity),
                "\(session.id) needs \(session.activity) picked, which a gym membership does not imply"
            )
        }
    }

    @Test("The real catalog holds up for someone with nothing but a floor")
    func realCatalogServesTheHardestCase() throws {
        let engine = PlanEngine(catalog: try store().sessions)
        let input = PlanInput(
            profile: Fixture.profile(
                activities: [.breathwork, .stretching],
                equipment: [.none],
                places: [.home],
                realisticMinutes: 10,
                workArounds: [.pregnancy, .postpartum, .pelvicFloor, .lowBack, .knees, .wrists]
            ),
            checkIn: PlanCheckIn(energy: .low, time: .aLittle),
            context: Fixture.context(isOffline: true)
        )
        let menu = engine.makeMenu(input)

        #expect(menu.appetizer != nil)
        for item in menu.items {
            #expect(!item.session.source.isVideo)
            #expect(Set(item.session.contraindications).isDisjoint(with: input.profile.workArounds))
        }
    }

    @Test("All authored steps have descriptive names and avoid bare placeholders")
    func stepNamesAreDescriptive() throws {
        let store = try store()
        let placeholderNames: Set<String> = ["other side", "rest", "switch", "side"]
        for session in store.sessions {
            for step in session.source.steps {
                let trimmed = step.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                #expect(!placeholderNames.contains(trimmed), "\(session.id) has generic step name: \(step.name)")
                #expect(!step.name.isEmpty, "\(session.id) has an empty step name")
            }
        }
    }

    @Test("Glossary terms are uniquely identified with non-empty metadata")
    func glossaryEntriesAreUniqueAndValid() throws {
        let store = try store()
        var seenIDs = Set<String>()
        var seenNames = Set<String>()
        for term in store.glossary {
            #expect(!seenIDs.contains(term.id), "Duplicate glossary ID: \(term.id)")
            seenIDs.insert(term.id)
            #expect(!seenNames.contains(term.name), "Duplicate glossary name: \(term.name)")
            seenNames.insert(term.name)
            #expect(!term.name.isEmpty, "Glossary term \(term.id) has empty name")
            #expect(!term.instructions.isEmpty, "Glossary term \(term.id) has no instructions")
        }
    }

    @Test("Session computed properties report sets and counted status accurately")
    func sessionComputedPropertiesWork() throws {
        let store = try store()
        for session in store.sessions {
            if session.hasCountedSteps {
                #expect(session.source.steps.contains { $0.isCounted })
            }
            #expect(session.totalSets >= session.source.steps.count)
        }
    }
}


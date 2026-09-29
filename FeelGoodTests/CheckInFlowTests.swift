//
//  CheckInFlowTests.swift
//  FeelGoodTests
//
//  The check-in moves itself on after every tap, so the rules for where a tap
//  lands, and what reaches the engine at the end, are the whole of its
//  behaviour. The view only draws them.
//

import Testing
@testable import FeelGood

@Suite("Check-in flow")
struct CheckInFlowTests {

    private func answer(_ goal: Intent, _ index: Int = 0) -> CheckInAnswer {
        goal.checkInAnswers[index]
    }

    // MARK: - Walking the flow

    @Test("A goal, an answer and a length make a check-in", arguments: Intent.allCases.filter(\.asksForTime))
    func threeTapsCompleteTheFlow(goal: Intent) {
        var flow = CheckInFlow()
        #expect(flow.step == .goal)

        flow.choose(goal: goal)
        #expect(flow.step == .answer)
        #expect(!flow.isComplete)

        flow.choose(answer: answer(goal))
        #expect(flow.step == .time)
        #expect(!flow.isComplete)

        flow.choose(time: .fifteenMinutes)
        #expect(flow.isComplete)
        #expect(flow.checkIn?.time == .fifteenMinutes)
        #expect(flow.checkIn?.todayIntent == goal)
    }

    @Test("Just showing up is done after its answer, which already says how long")
    func showingUpSkipsTheTimeQuestion() {
        for option in Intent.joy.checkInAnswers {
            var flow = CheckInFlow()
            flow.choose(goal: .joy)
            flow.choose(answer: option)

            #expect(flow.isComplete, "\(option.title) should finish the check-in")
            #expect(flow.step == .answer)
            #expect(flow.checkIn?.time == option.time)
        }
    }

    @Test("Resting today is a length like any other")
    func restingCompletesTheFlow() {
        var flow = CheckInFlow()
        flow.choose(goal: .calm)
        flow.choose(answer: answer(.calm))
        flow.choose(time: .zeroMinutes)

        #expect(flow.checkIn?.time == .zeroMinutes)
    }

    // MARK: - Unhappy paths

    @Test("Nothing reaches the engine until every question is answered")
    func partialAnswersProduceNoCheckIn() {
        var flow = CheckInFlow()
        #expect(flow.checkIn == nil)

        flow.choose(goal: .strengthen)
        #expect(flow.checkIn == nil)

        flow.choose(answer: answer(.strengthen))
        #expect(flow.checkIn == nil)
    }

    @Test("A length before an answer is ignored")
    func timeWithoutAnAnswerIsRefused() {
        var flow = CheckInFlow()
        flow.choose(time: .some)
        #expect(flow.time == nil)

        flow.choose(goal: .play)
        flow.choose(time: .some)
        #expect(flow.time == nil)
        #expect(flow.step == .answer)
    }

    @Test("An answer from a different goal's list is refused")
    func foreignAnswerIsRefused() {
        var flow = CheckInFlow()
        flow.choose(goal: .calm)
        flow.choose(answer: answer(.strengthen))

        #expect(flow.answer == nil)
        #expect(flow.step == .answer)
    }

    @Test("Changing the goal clears the answer given under the old one")
    func changingGoalClearsTheAnswer() {
        var flow = CheckInFlow()
        flow.choose(goal: .strengthen)
        flow.choose(answer: answer(.strengthen))
        flow.goBack()
        flow.goBack()
        flow.choose(goal: .mobilize)

        #expect(flow.answer == nil)
        #expect(flow.checkIn == nil)
    }

    @Test("Going back to the same goal keeps its answer")
    func reselectingTheGoalKeepsTheAnswer() {
        var flow = CheckInFlow()
        let legs = answer(.strengthen)
        flow.choose(goal: .strengthen)
        flow.choose(answer: legs)
        flow.goBack()
        flow.goBack()
        flow.choose(goal: .strengthen)

        #expect(flow.answer == legs)
    }

    @Test("Back from the first screen goes nowhere")
    func backFromTheStartStaysPut() {
        var flow = CheckInFlow()
        flow.goBack()
        #expect(flow.step == .goal)
    }

    // MARK: - What the engine gets

    @Test("The answer's energy, body area and leanings are handed over")
    func answerCarriesItsMeaning() throws {
        let legs = try #require(Intent.strengthen.checkInAnswers.first { $0.title == "Legs" })
        var flow = CheckInFlow(place: .atTheGym, bodies: [.stiff])
        flow.choose(goal: .strengthen)
        flow.choose(answer: legs)
        flow.choose(time: .some)

        let checkIn = try #require(flow.checkIn)
        #expect(checkIn.energy == legs.energy)
        #expect(checkIn.focus == .lowerBody)
        #expect(checkIn.favoured == [.strength])
        #expect(checkIn.place == .atTheGym)
        #expect(checkIn.bodies == [.stiff])
    }

    @Test("The fruit fills a third per answer and is full only at the end")
    func fillFollowsTheAnswers() {
        var flow = CheckInFlow()
        #expect(flow.fillFraction == 0)
        flow.choose(goal: .play)
        #expect(flow.fillFraction == 1.0 / 3.0)
        flow.choose(answer: answer(.play))
        #expect(flow.fillFraction == 2.0 / 3.0)
        flow.choose(time: .aLittle)
        #expect(flow.fillFraction == 1)
    }

    // MARK: - The content itself

    @Test("Every goal offers six answers with distinct ids", arguments: Intent.allCases)
    func everyGoalHasSixAnswers(goal: Intent) {
        let answers = goal.checkInAnswers
        #expect(answers.count == 6)
        #expect(Set(answers.map(\.id)).count == 6)
    }

    @Test("Only Just showing up answers carry their own length")
    func onlyShowingUpSetsTime() {
        for goal in Intent.allCases {
            for option in goal.checkInAnswers {
                #expect((option.time != nil) == !goal.asksForTime, "\(option.id)")
            }
        }
    }

    @Test("Time chips are ordered and never include resting")
    func timeChipsAreShortestFirst() {
        let minutes = TimeBudget.checkInChoices.map(\.maxMinutes)
        #expect(minutes == minutes.sorted())
        #expect(!TimeBudget.checkInChoices.contains(.zeroMinutes))
    }

    // MARK: - Onboarding leads

    @Test("Onboarding goals lead, the rest follow, both in onboarding order")
    func standingGoalsComeFirst() {
        let goals = CheckInFlow.orderedGoals(standing: [.play, .calm])
        #expect(goals.picks == [.calm, .play])
        #expect(goals.others == [.energize, .strengthen, .mobilize, .joy])
    }

    @Test("With nothing picked, or everything, no goal is set apart")
    func noPicksOrAllPicksAreEqual() {
        #expect(CheckInFlow.orderedGoals(standing: []).picks.isEmpty)
        let all = CheckInFlow.orderedGoals(standing: Set(Intent.allCases))
        #expect(all.picks.isEmpty)
        #expect(all.others == Intent.allCases)
    }
}

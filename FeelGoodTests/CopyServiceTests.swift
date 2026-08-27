//
//  CopyServiceTests.swift
//  FeelGoodTests
//
//  `CopyService` has exactly one contract that matters: whatever goes wrong
//  underneath it — a thrown error, a slow response, an empty line — the
//  caller sees `nil` and falls back to the deterministic template headline.
//  Never a crash, never a distinguishable error, never a block.
//

import Testing
import Foundation
@testable import FeelGood

@Suite("Copy service")
struct CopyServiceTests {

    @Test("A missing Worker URL disables the upgrade instead of crashing")
    func missingWorkerURLIsDisabled() {
        #expect(CopyServiceConstants.workerURL(from: nil) == nil)
        #expect(CopyServiceConstants.workerURL(from: "") == nil)
        #expect(CopyServiceConstants.workerURL(from: "$(COPY_WORKER_BASE_URL)") == nil)
        #expect(CopyServiceConstants.workerURL(from: "https://copy.example.com/copy") != nil)
    }

    private func input() -> PlanInput {
        PlanInput(
            profile: Fixture.profile(),
            checkIn: PlanCheckIn(energy: .low, time: .aLittle),
            history: [Fixture.completed("s-walk", activity: .walking, daysAgo: 3)],
            context: Fixture.context()
        )
    }

    private func menu() -> Menu {
        Fixture.engine.makeMenu(input())
    }

    private func checkIn() -> PlanCheckIn {
        Fixture.engine.resolvedCheckIn(input())
    }

    private func stats() -> HistoryStats {
        HistoryStats(input: input())
    }

    @Test("A successful response is returned")
    func successReturnsLine() async {
        let transport = FakeCopyTransport(result: .success("Here's a lighter one."))
        let service = CopyService(transport: transport, timeout: 1)

        let line = await service.upgradedHeadline(menu: menu(), checkIn: checkIn(), stats: stats())

        #expect(line == "Here's a lighter one.")
        #expect(await transport.callCount == 1)
    }

    @Test("An identical request a second time hits the cache, not the transport")
    func identicalRequestIsCached() async {
        let transport = FakeCopyTransport(result: .success("Here's a lighter one."))
        let service = CopyService(transport: transport, timeout: 1)

        _ = await service.upgradedHeadline(menu: menu(), checkIn: checkIn(), stats: stats())
        let second = await service.upgradedHeadline(menu: menu(), checkIn: checkIn(), stats: stats())

        #expect(second == "Here's a lighter one.")
        #expect(await transport.callCount == 1, "A second identical request should not re-bill a call.")
    }

    @Test("A thrown transport error falls back to nil, never crashes")
    func transportErrorReturnsNil() async {
        let transport = FakeCopyTransport(result: .failure(FakeCopyTransportError.boom))
        let service = CopyService(transport: transport, timeout: 1)

        let line = await service.upgradedHeadline(menu: menu(), checkIn: checkIn(), stats: stats())

        #expect(line == nil)
    }

    @Test("A response slower than the timeout falls back to nil")
    func timeoutReturnsNil() async {
        let transport = FakeCopyTransport(result: .success("Too slow."), delay: .seconds(2))
        let service = CopyService(transport: transport, timeout: 0.05)

        let line = await service.upgradedHeadline(menu: menu(), checkIn: checkIn(), stats: stats())

        #expect(line == nil)
    }

    @Test("A failure is never cached")
    func failureIsNotCached() async {
        let transport = FakeCopyTransport(result: .failure(FakeCopyTransportError.boom))
        let service = CopyService(transport: transport, timeout: 1)

        _ = await service.upgradedHeadline(menu: menu(), checkIn: checkIn(), stats: stats())
        await transport.setResult(.success("Recovered."))
        let second = await service.upgradedHeadline(menu: menu(), checkIn: checkIn(), stats: stats())

        #expect(second == "Recovered.")
        #expect(await transport.callCount == 2, "A failed attempt must not poison the cache for a later, successful one.")
    }
}

// MARK: - Fake

private enum FakeCopyTransportError: Error {
    case boom
}

/// Settable canned result, an optional artificial delay (to exercise the
/// timeout path), and a call counter — enough to test `CopyService`'s
/// caching and fallback behaviour without a real network call. An actor
/// rather than a locked class: `fetchLine` is already async, so the call
/// counter just needs actor isolation, not manual locking.
private actor FakeCopyTransport: CopyTransport {
    var result: Result<String, Error>
    private let delay: Duration?
    private(set) var callCount = 0

    init(result: Result<String, Error>, delay: Duration? = nil) {
        self.result = result
        self.delay = delay
    }

    func setResult(_ result: Result<String, Error>) {
        self.result = result
    }

    func fetchLine(payload: CopyPayload, timeout: TimeInterval) async throws -> String {
        callCount += 1

        if let delay {
            let outcome = result
            // Races the fake's own delay against the timeout `CopyService`
            // asked for, the same way a real `URLSession` request would.
            return try await withThrowingTaskGroup(of: String.self) { group in
                group.addTask {
                    try await Task.sleep(for: delay)
                    return try outcome.get()
                }
                group.addTask {
                    try await Task.sleep(for: .seconds(timeout))
                    throw FakeCopyTransportError.boom
                }
                defer { group.cancelAll() }
                return try await group.next()!
            }
        } else {
            return try result.get()
        }
    }
}

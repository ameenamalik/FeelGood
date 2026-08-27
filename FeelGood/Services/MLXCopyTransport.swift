//
//  MLXCopyTransport.swift
//  FeelGood
//
//  The on-device replacement for `URLSessionCopyTransport`. Same seam
//  (`CopyTransport`), same contract (throw or return an empty line, and
//  `CopyService` turns that into `nil`) — the difference is entirely
//  underneath: this never opens a socket. `CopyPayload` is built the same
//  way either transport would receive it, then JSON-encoded straight into a
//  prompt for a small model running in-process. Nothing here can leave the
//  device, because there is nowhere for it to go.
//
//  The model is Qwen2.5 0.5B, 4-bit (`mlx-community/Qwen2.5-0.5B-Instruct-4bit`)
//  via MLX Swift. It needs Apple Silicon's GPU through Metal, which the
//  iOS Simulator cannot exercise correctly — this transport is only
//  meaningfully testable on a physical device.
//

import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
// `ChatSession` isn't `Sendable` yet — mlx-swift-lm hasn't finished its own
// Swift 6 concurrency audit. `@preconcurrency` downgrades that gap to a
// warning here rather than failing the build over a type this file doesn't
// own and can't fix; the actual safety argument (this actor never lets two
// calls touch `session` concurrently) is documented at its call site below.
@preconcurrency import MLXLMCommon
import Tokenizers

/// Generates the copy line on-device with a small local language model,
/// rather than over the network. An `actor` for the same reason `CopyService`
/// is one: it owns mutable state (the loaded session) that multiple callers
/// could otherwise race on.
actor MLXCopyTransport: CopyTransport {

    /// Ported verbatim from `worker/src/systemPrompt.ts` — the coaching
    /// voice is a copy decision (CLAUDE.md's "Voice and product rules"),
    /// not a code decision, and running on-device instead of on a Worker
    /// doesn't change what it's allowed to say.
    private static let instructions = """
    You write one short line of framing copy for a daily movement app.
    You are given the sessions a deterministic engine has already chosen \
    ("picks"), why it chose them ("reasonCodes"), and coarse state \
    ("energy", "time", "daysSinceLast"). You never choose what anyone does \
    with their body — the engine already decided; you only write the \
    sentence that sits above the menu.

    Hard rules:
    - One line only. Warm, plain, specific to the state you were given.
    - No medical claims, no diagnosis, no treatment language.
    - No streaks, no guilt, no scores, no rings, no completion percentages, no leaderboards.
    - Never address a gap as a deficit. If reasonCodes includes "returningAfterGap", the register is warm and welcoming, never apologetic or scolding — think "good to see you", never "you've been away" or "let's get back on track".
    - Never imply a real person wrote, taught, endorsed, or reviewed a session.
    - Never assume the reader's gender. Address them as "you".
    - No calorie or weight talk.

    Examples of the register you're writing in:
    - "Good to see you. Let's start small."
    - "You've shown up a few days running — today's a lighter one on purpose."

    Respond with only the line itself — no quotation marks, no preamble, no explanation.
    """

    private static let modelConfiguration = ModelConfiguration(
        id: "mlx-community/Qwen2.5-0.5B-Instruct-4bit",
        extraEOSTokens: ["<|im_end|>"]
    )

    /// Loaded once per process and kept resident. Model load — on first use
    /// per device, a download of the weights, cached by swift-huggingface
    /// after that — is the slow part; generation itself is fast once this
    /// exists. A cold load easily exceeds `timeout` below, which is fine:
    /// that attempt falls back to the deterministic template exactly like a
    /// slow first network request would have, and every attempt after it in
    /// the same app run reuses this session instead of reloading.
    private var session: ChatSession?

    func fetchLine(payload: CopyPayload, timeout: TimeInterval) async throws -> String {
        let response = try await withTimeout(seconds: timeout) {
            try await self.generateLine(for: payload)
        }

        let line = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { throw MLXCopyTransportError.emptyLine }
        return line
    }

    /// Loads the session if needed and generates, all on this actor.
    /// `ChatSession` isn't `Sendable`, so it must never be returned out of
    /// actor isolation into the timeout race below — only the `String`
    /// result crosses that boundary.
    private func generateLine(for payload: CopyPayload) async throws -> String {
        let activeSession: ChatSession
        if let session {
            activeSession = session
        } else {
            let container = try await #huggingFaceLoadModelContainer(configuration: Self.modelConfiguration)
            activeSession = ChatSession(
                container,
                instructions: Self.instructions,
                // Framing copy is one sentence — capped well below the
                // model's context window so a rambling completion can't
                // stall the UI waiting on tokens nobody will read.
                generateParameters: GenerateParameters(maxTokens: 60, temperature: 0.7)
            )
            session = activeSession
        }
        // Bound to a local before the `await`: `respond` suspends, and this
        // actor is reentrant, so reading `session` again afterward could
        // observe a different instance than the one generation actually ran
        // against — the local snapshot is what the compiler needs to prove
        // this call can't race a concurrent reassignment of `self.session`.
        return try await activeSession.respond(to: Self.prompt(for: payload))
    }

    /// The exact allow-listed payload either transport receives, JSON-encoded
    /// straight into the prompt instead of a request body — the boundary
    /// `CopyPayload` already enforces doesn't change just because this walks
    /// to a local model instead of a socket.
    private static func prompt(for payload: CopyPayload) throws -> String {
        let data = try JSONEncoder().encode(payload)
        return String(decoding: data, as: UTF8.self)
    }

    /// A slow cold load or a slow generation must never hang the caller past
    /// `CopyService`'s budget — mirrors the timeout race `URLSession` gives
    /// for free over the network, which a local `await` needs to do by hand.
    private func withTimeout<T: Sendable>(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw MLXCopyTransportError.timedOut
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
}

private enum MLXCopyTransportError: Error {
    case emptyLine
    case timedOut
}

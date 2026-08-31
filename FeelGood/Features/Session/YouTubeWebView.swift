//
//  YouTubeWebView.swift
//  FeelGood
//
//  A WKWebView wrapper that loads the Worker's `/player` page, which frames the
//  YouTube embed. The user keeps the real player's controls — captions,
//  quality, fullscreen, and the link back to the channel.
//

import SwiftUI
import WebKit

/// Renders the Worker-hosted player page.
///
/// The indirection through the Worker is not incidental — it is the whole fix.
/// YouTube refuses an embed whose request carries no credible page origin
/// (Error 152-4), and no client-side trick produces one: `loadHTMLString`,
/// a hand-set `Referer`, and `loadSimulatedRequest` all synthesise an origin
/// without ever fetching a page from it. `worker/src/player.ts` serves a page
/// that genuinely was fetched over HTTPS, so the iframe inside it sends the
/// Referer and Origin the embed checks for.
///
/// `PlayerView` is responsible for never constructing this when the Worker is
/// unconfigured — see `WorkerConstants.playerURL(videoID:)`.
struct YouTubeWebView: UIViewRepresentable {
    let playerURL: URL

    /// Persists across SwiftUI redraws so a re-render doesn't restart playback.
    /// During an async load `uiView.url` is still nil, so tracking what we
    /// asked for is the only race-free way to tell "already loading this".
    final class Coordinator: NSObject {
        var loadedURL: URL?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != playerURL else { return }
        context.coordinator.loadedURL = playerURL
        uiView.load(URLRequest(url: playerURL))
    }
}

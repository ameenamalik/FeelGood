//
//  YouTubeWebView.swift
//  FeelGood
//
//  A WKWebView wrapper that embeds a YouTube video iframe inline, allowing
//  the user to watch the workout while preserving interactive features like
//  viewing the channel, liking, and sharing.
//

import SwiftUI
import WebKit

struct YouTubeWebView: UIViewRepresentable {
    let videoID: String

    // Coordinator to persist state across redraw cycles and prevent reload loops.
    class Coordinator: NSObject {
        var loadedVideoID: String? = nil
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

    private static let embedOrigin = "https://www.youtube.com"

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Prevent redundant reloads on SwiftUI redraws by checking the coordinator.
        // During async loading, uiView.url is nil, so checking coordinator state is the only race-free way.
        guard context.coordinator.loadedVideoID != videoID else {
            return
        }
        context.coordinator.loadedVideoID = videoID

        // Navigate directly to the embed URL as the WKWebView's top-level
        // request, rather than wrapping it in an iframe inside a
        // loadHTMLString page. loadHTMLString never performs a real network
        // fetch for the "page", so a nested iframe has no genuine Referer
        // chain to inherit — the `origin` query param alone doesn't satisfy
        // YouTube's check on the request's actual Referer/Origin headers,
        // which is what produces Error 152-4 ("video unavailable"). Setting
        // Referer on a real top-level load does.
        guard let url = URL(
            string: "\(Self.embedOrigin)/embed/\(videoID)?playsinline=1&rel=0&enablejsapi=1&origin=\(Self.embedOrigin)"
        ) else {
            return
        }

        var request = URLRequest(url: url)
        request.setValue("\(Self.embedOrigin)/", forHTTPHeaderField: "Referer")
        uiView.load(request)
    }
}

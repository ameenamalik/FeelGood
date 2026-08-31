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

        // Error 152-4 is YouTube refusing the embed because the request
        // carries no credible page origin. Two earlier attempts do not
        // produce one: `loadHTMLString(_:baseURL:)` never performs a real
        // fetch, so the nested iframe has no Referer chain to inherit; and a
        // `Referer` header set by hand on a top-level `load(_:)` is dropped
        // by WKWebView before the request leaves the process.
        //
        // `loadSimulatedRequest(_:responseHTML:)` is the one that works: the
        // wrapper page is delivered as the genuine response to a URL on
        // youtube.com, so the iframe inside it is same-origin with the
        // player and sends the Referer and Origin the embed checks for.
        guard let hostURL = URL(string: "\(Self.embedOrigin)/"),
              let embedURL = URL(
                  string: "\(Self.embedOrigin)/embed/\(videoID)?playsinline=1&rel=0&enablejsapi=1&origin=\(Self.embedOrigin)"
              )
        else {
            return
        }

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            body, html { margin: 0; padding: 0; width: 100%; height: 100%; background-color: transparent; overflow: hidden; }
            iframe { width: 100%; height: 100%; border: none; }
        </style>
        </head>
        <body>
            <iframe id="player" type="text/html" src="\(embedURL.absoluteString)" allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>
        </body>
        </html>
        """

        uiView.loadSimulatedRequest(URLRequest(url: hostURL), responseHTML: html)
    }
}

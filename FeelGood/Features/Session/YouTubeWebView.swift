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

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Prevent redundant reloads on SwiftUI redraws by checking the coordinator.
        // During async loading, uiView.url is nil, so checking coordinator state is the only race-free way.
        guard context.coordinator.loadedVideoID != videoID else {
            return
        }
        context.coordinator.loadedVideoID = videoID

        // Construct the official YouTube embed URL.
        // - playsinline=1: Plays inline in SwiftUI.
        // - rel=0: Limit recommendations to the same channel.
        // - enablejsapi=1 & origin=https://www.youtube.com: Passes origin checks to satisfy YouTube Referer checks (Error 152-4).
        let embedURLString = "https://www.youtube.com/embed/\(videoID)?playsinline=1&rel=0&enablejsapi=1&origin=https://www.youtube.com"
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            body, html {
                margin: 0;
                padding: 0;
                width: 100%;
                height: 100%;
                background-color: transparent;
                overflow: hidden;
            }
            iframe {
                width: 100%;
                height: 100%;
                border: none;
            }
        </style>
        </head>
        <body>
            <iframe id="player" type="text/html" 
                src="\(embedURLString)" 
                allowfullscreen>
            </iframe>
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }
}

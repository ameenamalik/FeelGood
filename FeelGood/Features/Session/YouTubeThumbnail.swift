//
//  YouTubeThumbnail.swift
//  FeelGood
//

import SwiftUI

/// The video's poster frame, shown where the player itself can't run — see
/// `PlayerView.watchElsewhere`. A session you can't play yet should still look
/// like the session it is, not like an empty box.
struct YouTubeThumbnail: View {
    let videoID: String

    var body: some View {
        // The crop has to be pinned to the container's real size rather than
        // left to `.aspectRatio(contentMode: .fill)`: inside an AsyncImage
        // phase the image has no intrinsic frame to fill against, so it lays
        // out at its own 4:3 and the letterbox bars survive. GeometryReader
        // gives scaledToFill something concrete to overflow, and `clipped`
        // takes the bars off.
        GeometryReader { geometry in
            AsyncImage(url: Self.posterURL(videoID: videoID)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                case .empty, .failure:
                    // Offline, or a video whose poster has been pulled. The
                    // card still has to read as a video, so keep the shape and
                    // lose only the picture.
                    FGColor.surface
                @unknown default:
                    FGColor.surface
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityHidden(true)
    }

    /// `hqdefault` is the one size YouTube has generated for every video since
    /// forever — `maxresdefault` is truer 16:9 but 404s on plenty of older
    /// uploads, and a poster that sometimes isn't there is worse than one that
    /// always is.
    ///
    /// It is 480×360, which letterboxes a 16:9 video with exactly 45pt of black
    /// top and bottom. Filling a 16:9 frame from a 4:3 image crops precisely
    /// those bars, so the result is the original frame rather than a picture
    /// with borders — which is why the caller must clip to 16:9.
    static func posterURL(videoID: String) -> URL? {
        guard WorkerConstants.isValidVideoID(videoID) else { return nil }
        return URL(string: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")
    }
}

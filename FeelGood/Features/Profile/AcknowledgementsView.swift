//
//  AcknowledgementsView.swift
//  FeelGood
//
//  Surfaces the CC BY-SA 4.0 attribution for the glossary's line-art frames
//  in-app. See Content/ExerciseDemos/ATTRIBUTION.md for the full engineering
//  record (which files are covered and which are house-drawn); this screen
//  is the user-facing notice CC BY-SA §3(a) requires.
//

import SwiftUI

struct AcknowledgementsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("Most exercise illustrations in FeelGood's glossary are line-art frames adapted from Workout Guide by Bryl Lim, itself building on Everkinetic. Used unmodified, and licensed under Creative Commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0). A small number (Wall angels, Qigong: lifting the sky) are original art made in-house in the same style, and carry no third-party license.")
                Link("bryllim.com", destination: URL(string: "https://bryllim.com")!)
                Link("Workout Guide on GitHub", destination: URL(string: "https://github.com/bryllim/workout-guide")!)
                Link("Everkinetic on GitHub", destination: URL(string: "https://github.com/everkinetic/data")!)
                Link("CC BY-SA 4.0 license text", destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/legalcode")!)
            } header: {
                Text("Illustrations")
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationStack { AcknowledgementsView() }
}

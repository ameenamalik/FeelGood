//
//  ChatHistorySheet.swift
//  FeelGood
//
//  A serene sheet displaying previous chat check-in conversations.
//  Allows browsing past recommendations, switching threads, starting a new chat,
//  and deleting past conversations.
//

import SwiftUI

struct ChatHistorySheet: View {
    let threads: [ConversationThread]
    let activeThreadID: UUID?
    let onSelectThread: (ConversationThread) -> Void
    let onNewChat: () -> Void
    let onDeleteThread: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                FGColor.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Bar
                    sheetHeader

                    // Start New Chat Prominent Card
                    newChatButton
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    if threads.isEmpty {
                        emptyState
                    } else {
                        threadsList
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Chat History")
                    .font(.custom("SFProRounded-Semibold", size: 20))
                    .foregroundStyle(FGColor.ink)
                Text("\(threads.count) previous \(threads.count == 1 ? "conversation" : "conversations")")
                    .font(.system(size: 13))
                    .foregroundStyle(FGColor.inkMuted)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FGColor.ink)
                    .frame(width: 32, height: 32)
                    .background(FGColor.surface)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(FGColor.line, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 6)
    }

    // MARK: - New Chat Button

    private var newChatButton: some View {
        Button {
            onNewChat()
            dismiss()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(FGColor.clay.opacity(0.2))
                        .frame(width: 38, height: 38)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(FGColor.ink)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Start New Check-In")
                        .font(.custom("SFProRounded-Semibold", size: 16))
                        .foregroundStyle(FGColor.ink)
                    Text("Begin a fresh conversation thread")
                        .font(.system(size: 13))
                        .foregroundStyle(FGColor.inkMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(FGColor.inkMuted.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(FGColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(FGColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Threads List

    private var threadsList: some View {
        List {
            ForEach(threads) { thread in
                let isActive = thread.id == activeThreadID

                Button {
                    onSelectThread(thread)
                    dismiss()
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(thread.displayTitle)
                                    .font(.custom("SFProRounded-Semibold", size: 15))
                                    .foregroundStyle(FGColor.ink)
                                    .lineLimit(1)

                                Spacer()

                                Text(thread.formattedDate)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(FGColor.inkMuted)
                            }

                            Text(thread.previewSnippet)
                                .font(.system(size: 13))
                                .foregroundStyle(FGColor.inkMuted)
                                .lineLimit(2)
                                .lineSpacing(2)

                            if isActive {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(FGColor.goldDeep)
                                        .frame(width: 6, height: 6)
                                    Text("Active Thread")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(FGColor.goldDeep)
                                }
                                .padding(.top, 2)
                            }
                        }

                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(FGColor.goldDeep)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isActive ? Color(light: 0xFDFBF7, dark: 0x221D17) : FGColor.surface)
                        .padding(.vertical, 2)
                )
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onDeleteThread(thread.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(FGColor.bg)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 42))
                .foregroundStyle(FGColor.inkMuted.opacity(0.5))

            Text("No previous conversations")
                .font(.custom("SFProRounded-Semibold", size: 17))
                .foregroundStyle(FGColor.ink)

            Text("Your check-ins and custom recommendations will be preserved here so you can revisit them anytime.")
                .font(.system(size: 14))
                .foregroundStyle(FGColor.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

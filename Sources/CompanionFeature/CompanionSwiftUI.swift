#if canImport(SwiftUI)
import CompanionCore
import SwiftUI

@MainActor
public final class CompanionViewModel: ObservableObject {
    @Published public private(set) var coordinator: CompanionCoordinator
    @Published public var draftMessage: String = ""
    @Published public var selectedCategory: MessageCategory = .casual
    @Published public var sentimentScore: Double = 0
    @Published public var hasCompletedOnboarding: Bool

    public init(coordinator: CompanionCoordinator = .init(), hasCompletedOnboarding: Bool = false) {
        self.coordinator = coordinator
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    public var profile: AIProfile {
        coordinator.state.profile
    }

    public var timeline: [QuestionEvent] {
        coordinator.history()
    }

    public var snapshot: DashboardSnapshot {
        coordinator.stats(now: Date())
    }

    public var relationshipStage: String {
        coordinator.relationshipStage()
    }

    public func completeOnboarding(name: String, speechStyle: SpeechStyle, themeHex: String, tags: [String]) {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        coordinator.customizeProfile(
            name: finalName.isEmpty ? profile.name : finalName,
            speechStyle: speechStyle,
            appearanceThemeHex: themeHex,
            personalityTags: tags.isEmpty ? profile.personalityTags : tags
        )
        hasCompletedOnboarding = true
    }

    public func sendMessage() {
        let text = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }

        _ = coordinator.ask(
            text,
            category: selectedCategory,
            sentimentScore: sentimentScore,
            isAggressive: text.contains("!?") || text.contains("ふざけるな")
        )
        draftMessage = ""
    }

    public func updateProfile(name: String, speechStyle: SpeechStyle, appearanceThemeHex: String, personalityTags: [String]) {
        _ = coordinator.customizeProfile(
            name: name,
            speechStyle: speechStyle,
            appearanceThemeHex: appearanceThemeHex,
            personalityTags: personalityTags
        )
    }
}

public struct CompanionRootView: View {
    @StateObject private var viewModel: CompanionViewModel

    public init(viewModel: CompanionViewModel = .init()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.hasCompletedOnboarding {
                mainTabs
            } else {
                CompanionOnboardingView(viewModel: viewModel)
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            CompanionChatView(viewModel: viewModel)
                .tabItem { Label("Chat", systemImage: "message") }

            CompanionHistoryView(viewModel: viewModel)
                .tabItem { Label("History", systemImage: "clock") }

            CompanionStatsView(viewModel: viewModel)
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            CompanionCustomizeView(viewModel: viewModel)
                .tabItem { Label("Customize", systemImage: "paintbrush") }
        }
    }
}

public struct CompanionOnboardingView: View {
    @ObservedObject var viewModel: CompanionViewModel
    @State private var name: String = ""
    @State private var style: SpeechStyle = .friendly
    @State private var themeHex: String = "#7C9DFF"
    @State private var tags: String = "聞き上手,励まし"

    public var body: some View {
        NavigationStack {
            Form {
                Section("AIの基本設定") {
                    TextField("AI名", text: $name)
                    Picker("話し方", selection: $style) {
                        ForEach(SpeechStyle.allCases, id: \.rawValue) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    TextField("テーマ色(HEX)", text: $themeHex)
                    TextField("性格タグ(カンマ区切り)", text: $tags)
                }

                Button("はじめる") {
                    let parsedTags = tags
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { $0.isEmpty == false }

                    viewModel.completeOnboarding(
                        name: name,
                        speechStyle: style,
                        themeHex: themeHex,
                        tags: parsedTags
                    )
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("ようこそ")
            .onAppear {
                name = viewModel.profile.name
                style = viewModel.profile.speechStyle
                themeHex = viewModel.profile.appearanceThemeHex
                tags = viewModel.profile.personalityTags.joined(separator: ",")
            }
        }
    }
}

public struct CompanionChatView: View {
    @ObservedObject var viewModel: CompanionViewModel

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(MessageCategory.allCases, id: \.rawValue) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)

                Slider(value: $viewModel.sentimentScore, in: -1...1, step: 0.1) {
                    Text("Sentiment")
                }

                TextField("質問を入力", text: $viewModel.draftMessage)
                    .textFieldStyle(.roundedBorder)

                Button("送信") {
                    viewModel.sendMessage()
                }
                .buttonStyle(.borderedProminent)

                List(viewModel.timeline.prefix(20), id: \.id) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.content)
                        Text("\(event.category.rawValue) / \(event.createdAt.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .navigationTitle("\(viewModel.profile.name) と会話")
        }
    }
}

public struct CompanionHistoryView: View {
    @ObservedObject var viewModel: CompanionViewModel
    @State private var keyword: String = ""

    public var body: some View {
        NavigationStack {
            List(filteredHistory, id: \.id) { event in
                VStack(alignment: .leading) {
                    Text(event.content)
                    Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .searchable(text: $keyword, prompt: "キーワード検索")
            .navigationTitle("履歴")
        }
    }

    private var filteredHistory: [QuestionEvent] {
        if keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.timeline
        }
        return viewModel.coordinator.history(keyword: keyword)
    }
}

public struct CompanionStatsView: View {
    @ObservedObject var viewModel: CompanionViewModel

    public var body: some View {
        let snapshot = viewModel.snapshot

        NavigationStack {
            List {
                statRow("総質問数", value: "\(snapshot.totalQuestions)")
                statRow("一緒に過ごした日数", value: "\(snapshot.daysTogether)")
                statRow("連続日数", value: "\(snapshot.currentStreak)")
                statRow("今日の質問数", value: "\(snapshot.todayQuestions)")
                statRow("親密度", value: "\(snapshot.intimacyScore)")
                statRow("信頼度", value: "\(snapshot.trustScore)")
                statRow("関係性", value: viewModel.relationshipStage)
            }
            .navigationTitle("Stats")
        }
    }

    @ViewBuilder
    private func statRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).bold()
        }
    }
}

public struct CompanionCustomizeView: View {
    @ObservedObject var viewModel: CompanionViewModel
    @State private var name: String = ""
    @State private var themeHex: String = "#7C9DFF"
    @State private var style: SpeechStyle = .friendly
    @State private var tags: String = "聞き上手,励まし"

    public var body: some View {
        NavigationStack {
            Form {
                TextField("AI名", text: $name)
                TextField("テーマ色(HEX)", text: $themeHex)

                Picker("話し方", selection: $style) {
                    ForEach(SpeechStyle.allCases, id: \.rawValue) { item in
                        Text(item.rawValue).tag(item)
                    }
                }

                TextField("性格タグ(カンマ区切り)", text: $tags)

                Button("保存") {
                    let parsedTags = tags
                        .split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { $0.isEmpty == false }

                    viewModel.updateProfile(
                        name: name.isEmpty ? viewModel.profile.name : name,
                        speechStyle: style,
                        appearanceThemeHex: themeHex,
                        personalityTags: parsedTags.isEmpty ? viewModel.profile.personalityTags : parsedTags
                    )
                }
            }
            .onAppear {
                name = viewModel.profile.name
                themeHex = viewModel.profile.appearanceThemeHex
                style = viewModel.profile.speechStyle
                tags = viewModel.profile.personalityTags.joined(separator: ",")
            }
            .navigationTitle("Customize")
        }
    }
}
#endif

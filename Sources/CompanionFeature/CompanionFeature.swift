import CompanionCore
import Foundation

public enum SpeechStyle: String, Codable, CaseIterable {
    case gentle
    case friendly
    case polite
    case cool
}

public enum AvatarStyle: String, Codable, CaseIterable {
    case rabbit
    case cat
    case fox
    case robot

    public var icon: String {
        switch self {
        case .rabbit: return "🐰"
        case .cat: return "🐱"
        case .fox: return "🦊"
        case .robot: return "🤖"
        }
    }
}

public struct AIProfile: Codable, Equatable {
    public var name: String
    public var speechStyle: SpeechStyle
    public var appearanceThemeHex: String
    public var avatarStyle: AvatarStyle
    public var personalityTags: [String]

    public init(
        name: String = "Airi",
        speechStyle: SpeechStyle = .friendly,
        appearanceThemeHex: String = "#7C9DFF",
        avatarStyle: AvatarStyle = .rabbit,
        personalityTags: [String] = ["聞き上手", "励まし"]
    ) {
        self.name = name
        self.speechStyle = speechStyle
        self.appearanceThemeHex = appearanceThemeHex
        self.avatarStyle = avatarStyle
        self.personalityTags = personalityTags
    }
}

public struct ChatTurn: Equatable {
    public let question: QuestionEvent
    public let answer: String

    public init(question: QuestionEvent, answer: String) {
        self.question = question
        self.answer = answer
    }
}

public struct CompanionAppState {
    public var profile: AIProfile
    public var service: CompanionService

    public init(profile: AIProfile = .init(), service: CompanionService = .init()) {
        self.profile = profile
        self.service = service
    }
}

public struct CompanionCoordinator {
    public private(set) var state: CompanionAppState

    public init(state: CompanionAppState = .init()) {
        self.state = state
    }

    @discardableResult
    public mutating func customizeProfile(
        name: String? = nil,
        speechStyle: SpeechStyle? = nil,
        appearanceThemeHex: String? = nil,
        avatarStyle: AvatarStyle? = nil,
        personalityTags: [String]? = nil
    ) -> AIProfile {
        if let name, name.isEmpty == false {
            state.profile.name = name
        }
        if let speechStyle {
            state.profile.speechStyle = speechStyle
        }
        if let appearanceThemeHex, appearanceThemeHex.isEmpty == false {
            state.profile.appearanceThemeHex = appearanceThemeHex
        }
        if let avatarStyle {
            state.profile.avatarStyle = avatarStyle
        }
        if let personalityTags, personalityTags.isEmpty == false {
            state.profile.personalityTags = personalityTags
        }

        return state.profile
    }

    @discardableResult
    public mutating func ask(
        _ text: String,
        category: MessageCategory,
        at date: Date = Date(),
        sentimentScore: Double = 0,
        isAggressive: Bool = false
    ) -> ChatTurn? {
        let beforeCount = state.service.state.events.count
        state.service.ask(text, category: category, at: date, sentimentScore: sentimentScore, isAggressive: isAggressive)
        guard state.service.state.events.count > beforeCount,
              let question = state.service.state.events.last else {
            return nil
        }

        let answer = generateLocalAnswer(for: question)
        return ChatTurn(question: question, answer: answer)
    }

    public func stats(now: Date = Date()) -> DashboardSnapshot {
        state.service.dashboardSnapshot(now: now)
    }

    public func history(keyword: String = "") -> [QuestionEvent] {
        state.service.history(containing: keyword)
    }



    public mutating func loadState(from store: CompanionStateStore) throws {
        let loaded = try store.load()
        state.service = CompanionService(state: loaded)
    }

    public func saveState(to store: CompanionStateStore) throws {
        try store.save(state.service.state)
    }

    public func relationshipStage() -> String {
        let intimacy = state.service.state.metrics.intimacyScore
        switch intimacy {
        case ..<31: return "まだぎこちない"
        case 31..<71: return "仲良し"
        default: return "とても親しい"
        }
    }

    private func generateLocalAnswer(for event: QuestionEvent) -> String {
        let tone: String
        switch state.profile.speechStyle {
        case .gentle: tone = "やさしく"
        case .friendly: tone = "フレンドリーに"
        case .polite: tone = "丁寧に"
        case .cool: tone = "簡潔に"
        }

        return "\(state.profile.name)が\(tone)返答: 『\(event.content)』について一緒に考えよう。"
    }
}

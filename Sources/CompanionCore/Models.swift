import Foundation

public enum MessageCategory: String, Codable, CaseIterable {
    case work
    case learning
    case love
    case casual
    case emotionalConsultation
    case other
}

public struct QuestionEvent: Codable, Equatable {
    public let id: UUID
    public let content: String
    public let category: MessageCategory
    public let createdAt: Date
    public let sentimentScore: Double
    public let isAggressive: Bool

    public init(
        id: UUID = UUID(),
        content: String,
        category: MessageCategory,
        createdAt: Date,
        sentimentScore: Double,
        isAggressive: Bool
    ) {
        self.id = id
        self.content = content
        self.category = category
        self.createdAt = createdAt
        self.sentimentScore = sentimentScore
        self.isAggressive = isAggressive
    }
}

public struct DailyUsage: Codable, Equatable {
    public let date: Date
    public var questionCount: Int

    public init(date: Date, questionCount: Int) {
        self.date = date
        self.questionCount = questionCount
    }
}

public struct RelationshipMetrics: Codable, Equatable {
    public private(set) var intimacyScore: Int
    public private(set) var trustScore: Int
    public private(set) var totalQuestions: Int
    public private(set) var daysTogether: Int
    public private(set) var activeDays: Int
    public private(set) var currentStreak: Int
    public private(set) var firstQuestionDate: Date?
    public private(set) var lastQuestionDate: Date?

    public init(
        intimacyScore: Int = 50,
        trustScore: Int = 50,
        totalQuestions: Int = 0,
        daysTogether: Int = 0,
        activeDays: Int = 0,
        currentStreak: Int = 0,
        firstQuestionDate: Date? = nil,
        lastQuestionDate: Date? = nil
    ) {
        self.intimacyScore = Self.clamp(intimacyScore)
        self.trustScore = Self.clamp(trustScore)
        self.totalQuestions = max(0, totalQuestions)
        self.daysTogether = max(0, daysTogether)
        self.activeDays = max(0, activeDays)
        self.currentStreak = max(0, currentStreak)
        self.firstQuestionDate = firstQuestionDate
        self.lastQuestionDate = lastQuestionDate
    }

    mutating func apply(question event: QuestionEvent, calendar: Calendar) {
        totalQuestions += 1

        if firstQuestionDate == nil {
            firstQuestionDate = event.createdAt
            activeDays = 1
            currentStreak = 1
        }

        updateDayBasedStats(with: event.createdAt, calendar: calendar)
        applyRelationshipDelta(for: event)

        lastQuestionDate = event.createdAt
        updateDaysTogether(now: event.createdAt, calendar: calendar)
    }

    private mutating func updateDayBasedStats(with date: Date, calendar: Calendar) {
        guard let last = lastQuestionDate else { return }

        let lastDay = calendar.startOfDay(for: last)
        let newDay = calendar.startOfDay(for: date)

        guard lastDay != newDay else { return }
        activeDays += 1

        let gap = calendar.dateComponents([.day], from: lastDay, to: newDay).day ?? 0
        if gap == 1 {
            currentStreak += 1
        } else if gap > 1 {
            currentStreak = 1
        }
    }

    private mutating func applyRelationshipDelta(for event: QuestionEvent) {
        var intimacyDelta = 0
        var trustDelta = 0

        switch event.category {
        case .emotionalConsultation:
            intimacyDelta += 1
            trustDelta += 1
        case .learning, .work:
            trustDelta += 1
        case .love:
            intimacyDelta += 1
        case .casual, .other:
            break
        }

        if event.content.count >= 80 {
            intimacyDelta += 1
        }

        if event.isAggressive {
            intimacyDelta -= 2
            trustDelta -= 2
        }

        if event.sentimentScore > 0.45 {
            intimacyDelta += 1
        } else if event.sentimentScore < -0.45 {
            trustDelta -= 1
        }

        intimacyScore = Self.clamp(intimacyScore + intimacyDelta)
        trustScore = Self.clamp(trustScore + trustDelta)
    }

    private mutating func updateDaysTogether(now: Date, calendar: Calendar) {
        guard let first = firstQuestionDate else {
            daysTogether = 0
            return
        }

        let start = calendar.startOfDay(for: first)
        let end = calendar.startOfDay(for: now)
        let diff = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        daysTogether = max(1, diff)
    }

    private static func clamp(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }
}

public struct CompanionState: Codable, Equatable {
    public private(set) var events: [QuestionEvent]
    public private(set) var metrics: RelationshipMetrics

    public init(events: [QuestionEvent] = [], metrics: RelationshipMetrics = .init()) {
        self.events = events.sorted(by: { $0.createdAt < $1.createdAt })
        self.metrics = metrics
    }

    public mutating func ingest(_ event: QuestionEvent, calendar: Calendar = .current) {
        events.append(event)
        events.sort(by: { $0.createdAt < $1.createdAt })
        metrics.apply(question: event, calendar: calendar)
    }

    public func questions(on date: Date, calendar: Calendar = .current) -> [QuestionEvent] {
        let target = calendar.startOfDay(for: date)
        return events.filter { calendar.startOfDay(for: $0.createdAt) == target }
    }
}

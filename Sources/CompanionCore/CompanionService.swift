import Foundation

public struct CompanionService {
    public private(set) var state: CompanionState
    public let calendar: Calendar

    public init(state: CompanionState = .init(), calendar: Calendar = .current) {
        self.state = state
        self.calendar = calendar
    }

    @discardableResult
    public mutating func ask(
        _ question: String,
        category: MessageCategory,
        at date: Date = Date(),
        sentimentScore: Double = 0,
        isAggressive: Bool = false
    ) -> RelationshipMetrics {
        let normalized = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.isEmpty == false else {
            return state.metrics
        }

        let event = QuestionEvent(
            content: normalized,
            category: category,
            createdAt: date,
            sentimentScore: sentimentScore,
            isAggressive: isAggressive
        )

        state.ingest(event, calendar: calendar)
        return state.metrics
    }

    public func timeline() -> [QuestionEvent] {
        state.events.sorted(by: { $0.createdAt > $1.createdAt })
    }

    public func dailyQuestionCount(on date: Date) -> Int {
        state.questions(on: date, calendar: calendar).count
    }
}

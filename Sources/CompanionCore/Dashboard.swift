import Foundation

public struct DashboardSnapshot: Equatable {
    public let totalQuestions: Int
    public let daysTogether: Int
    public let activeDays: Int
    public let currentStreak: Int
    public let intimacyScore: Int
    public let trustScore: Int
    public let todayQuestions: Int

    public init(metrics: RelationshipMetrics, todayQuestions: Int) {
        self.totalQuestions = metrics.totalQuestions
        self.daysTogether = metrics.daysTogether
        self.activeDays = metrics.activeDays
        self.currentStreak = metrics.currentStreak
        self.intimacyScore = metrics.intimacyScore
        self.trustScore = metrics.trustScore
        self.todayQuestions = todayQuestions
    }
}

public extension CompanionService {
    func dashboardSnapshot(now: Date = Date()) -> DashboardSnapshot {
        DashboardSnapshot(metrics: state.metrics, todayQuestions: dailyQuestionCount(on: now))
    }

    func history(containing keyword: String) -> [QuestionEvent] {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return timeline()
        }

        return timeline().filter { $0.content.localizedCaseInsensitiveContains(trimmed) }
    }
}

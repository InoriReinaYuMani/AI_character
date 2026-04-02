import XCTest
@testable import CompanionCore

final class CompanionCoreTests: XCTestCase {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    private func date(_ yyyyMMdd: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: yyyyMMdd)!
    }

    func testMetricsIncreaseWithConsistentQuestions() {
        var service = CompanionService(calendar: calendar)

        service.ask(
            "最近ちょっと落ち込んでいます。",
            category: .emotionalConsultation,
            at: date("2026-03-01"),
            sentimentScore: 0.7
        )

        service.ask(
            "今日も相談していいですか？",
            category: .emotionalConsultation,
            at: date("2026-03-02"),
            sentimentScore: 0.6
        )

        let metrics = service.state.metrics
        XCTAssertEqual(metrics.totalQuestions, 2)
        XCTAssertEqual(metrics.daysTogether, 2)
        XCTAssertEqual(metrics.activeDays, 2)
        XCTAssertEqual(metrics.currentStreak, 2)
        XCTAssertGreaterThan(metrics.intimacyScore, 50)
        XCTAssertGreaterThan(metrics.trustScore, 50)
    }

    func testAggressiveQuestionDecreasesScores() {
        var service = CompanionService(calendar: calendar)

        service.ask(
            "手伝ってくれてありがとう。",
            category: .casual,
            at: date("2026-03-10"),
            sentimentScore: 0.8
        )
        let before = service.state.metrics

        service.ask(
            "なんでこんなこともできないんだ。",
            category: .work,
            at: date("2026-03-11"),
            sentimentScore: -0.8,
            isAggressive: true
        )

        let after = service.state.metrics
        XCTAssertLessThan(after.intimacyScore, before.intimacyScore)
        XCTAssertLessThan(after.trustScore, before.trustScore)
    }

    func testBlankQuestionIsIgnored() {
        var service = CompanionService(calendar: calendar)
        service.ask("   ", category: .other, at: date("2026-03-20"))

        XCTAssertEqual(service.state.metrics.totalQuestions, 0)
        XCTAssertTrue(service.timeline().isEmpty)
    }
}

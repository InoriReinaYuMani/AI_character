import Foundation
import XCTest
@testable import CompanionCore
@testable import CompanionFeature

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

    func testStreakResetsAfterGap() {
        var service = CompanionService(calendar: calendar)
        service.ask("1", category: .casual, at: date("2026-03-01"))
        service.ask("2", category: .casual, at: date("2026-03-02"))
        service.ask("3", category: .casual, at: date("2026-03-05"))

        XCTAssertEqual(service.state.metrics.currentStreak, 1)
        XCTAssertEqual(service.state.metrics.activeDays, 3)
        XCTAssertEqual(service.state.metrics.daysTogether, 5)
    }

    func testHistoryFilterAndDashboardSnapshot() {
        var service = CompanionService(calendar: calendar)
        service.ask("今日は相談です", category: .emotionalConsultation, at: date("2026-03-10"))
        service.ask("買い物メモ", category: .casual, at: date("2026-03-10"))

        let filtered = service.history(containing: "相談")
        XCTAssertEqual(filtered.count, 1)

        let snapshot = service.dashboardSnapshot(now: date("2026-03-10"))
        XCTAssertEqual(snapshot.todayQuestions, 2)
        XCTAssertEqual(snapshot.totalQuestions, 2)
    }

    func testJSONStoreRoundTrip() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = tempDir.appendingPathComponent("state.json")

        let store = JSONCompanionStateStore(fileURL: fileURL)
        var service = CompanionService(calendar: calendar)
        service.ask("保存テスト", category: .learning, at: date("2026-03-15"), sentimentScore: 0.2)

        try store.save(service.state)
        let loaded = try store.load()

        XCTAssertEqual(loaded.metrics.totalQuestions, 1)
        XCTAssertEqual(loaded.events.count, 1)
    }


    func testCustomizeAndAskFlow() {
        var coordinator = CompanionCoordinator()
        let profile = coordinator.customizeProfile(name: "Mina", speechStyle: .gentle)

        XCTAssertEqual(profile.name, "Mina")
        XCTAssertEqual(profile.speechStyle, .gentle)

        let turn = coordinator.ask(
            "今日も相談していい？",
            category: .emotionalConsultation,
            at: date("2026-04-01"),
            sentimentScore: 0.5
        )

        XCTAssertNotNil(turn)
        XCTAssertTrue(turn?.answer.contains("Mina") ?? false)
        XCTAssertEqual(coordinator.stats(now: date("2026-04-01")).totalQuestions, 1)
    }

    func testRelationshipStageLabel() {
        var coordinator = CompanionCoordinator()
        _ = coordinator.ask("短い質問", category: .casual, at: date("2026-04-01"), sentimentScore: -0.2, isAggressive: true)
        _ = coordinator.ask("ふざけるな!?", category: .casual, at: date("2026-04-02"), sentimentScore: -0.7, isAggressive: true)

        let stage = coordinator.relationshipStage()
        XCTAssertEqual(stage, "仲良し")
    }


    func testCoordinatorSaveAndLoadState() throws {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = tempDir.appendingPathComponent("coordinator-state.json")

        let store = JSONCompanionStateStore(fileURL: fileURL)

        var writer = CompanionCoordinator()
        _ = writer.ask("保存対象", category: .learning, at: date("2026-04-03"), sentimentScore: 0.1)
        try writer.saveState(to: store)

        var reader = CompanionCoordinator()
        try reader.loadState(from: store)

        XCTAssertEqual(reader.stats(now: date("2026-04-03")).totalQuestions, 1)
        XCTAssertEqual(reader.history().first?.content, "保存対象")
    }

}

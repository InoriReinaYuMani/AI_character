import CompanionCore
import CompanionFeature
import Foundation

@main
struct CompanionCLIMain {
    static func main() {
        var coordinator = CompanionCoordinator()

        print("CompanionCLI demo started")
        print("Commands: ask <category> <sentiment -1.0...1.0> <message>")
        print("          profile <name> <speechStyle(gentle|friendly|polite|cool)>")
        print("          stats")
        print("          history <keyword(optional)>")
        print("          quit")

        while let line = readLine(strippingNewline: true) {
            if line == "quit" { break }

            if line == "stats" {
                let snapshot = coordinator.stats()
                print("questions=\(snapshot.totalQuestions) daysTogether=\(snapshot.daysTogether) streak=\(snapshot.currentStreak) intimacy=\(snapshot.intimacyScore) trust=\(snapshot.trustScore) today=\(snapshot.todayQuestions)")
                print("relationship=\(coordinator.relationshipStage())")
                continue
            }

            if line.hasPrefix("history") {
                let keyword = line.replacingOccurrences(of: "history", with: "").trimmingCharacters(in: .whitespaces)
                let records = coordinator.history(keyword: keyword)
                for item in records.prefix(10) {
                    print("[\(item.createdAt)] (\(item.category.rawValue)) \(item.content)")
                }
                continue
            }

            if line.hasPrefix("profile ") {
                let payload = String(line.dropFirst(8))
                let comps = payload.split(separator: " ", maxSplits: 1).map(String.init)
                guard comps.count == 2 else {
                    print("Invalid profile format")
                    continue
                }

                guard let style = SpeechStyle(rawValue: comps[1]) else {
                    print("Unknown style")
                    continue
                }

                let profile = coordinator.customizeProfile(name: comps[0], speechStyle: style)
                print("profile updated: name=\(profile.name) style=\(profile.speechStyle.rawValue)")
                continue
            }

            if line.hasPrefix("ask ") {
                let payload = String(line.dropFirst(4))
                let comps = payload.split(separator: " ", maxSplits: 2).map(String.init)
                guard comps.count == 3 else {
                    print("Invalid ask format")
                    continue
                }

                guard let category = MessageCategory(rawValue: comps[0]) else {
                    let available = MessageCategory.allCases.map { $0.rawValue }.joined(separator: ", ")
                    print("Unknown category. Use: \(available)")
                    continue
                }

                guard let sentiment = Double(comps[1]) else {
                    print("sentiment must be number")
                    continue
                }

                let text = comps[2]
                let aggressive = text.contains("!?") || text.contains("ふざけるな")
                let turn = coordinator.ask(text, category: category, sentimentScore: sentiment, isAggressive: aggressive)
                if let turn {
                    print(turn.answer)
                } else {
                    print("ignored")
                }
                continue
            }

            print("Unknown command")
        }

        print("bye")
    }
}

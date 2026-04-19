import Foundation

public protocol CompanionStateStore {
    func load() throws -> CompanionState
    func save(_ state: CompanionState) throws
}

public final class JSONCompanionStateStore: CompanionStateStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() throws -> CompanionState {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return CompanionState()
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(CompanionState.self, from: data)
    }

    public func save(_ state: CompanionState) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: [.atomic])
    }
}

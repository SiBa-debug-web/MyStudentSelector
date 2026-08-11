import CryptoKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// The shape of an exported backup file. Only `people` is required, so a file
/// written by the web build — or an older version of this app — still reads.
struct BackupPayload: Codable {
    var app: String?
    var version: Int?
    var exportedAt: Date?
    var people: [Person]
}

/// Lets SwiftUI's `.fileExporter` write the backup out to Files / iCloud Drive.
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum BackupCoder {
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private static let iso8601WithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let iso8601Plain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        // JavaScript's toISOString() always emits milliseconds, which the
        // stock .iso8601 strategy rejects — so a web backup's timestamps
        // would silently decode as "now" and wreck the follow-up dates.
        // Accept both forms.
        decoder.dateDecodingStrategy = .custom { dateDecoder in
            let container = try dateDecoder.singleValueContainer()
            let raw = try container.decode(String.self)
            if let date = iso8601WithFraction.date(from: raw) { return date }
            if let date = iso8601Plain.date(from: raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unrecognised date: \(raw)"
            )
        }
        return decoder
    }

    /// Accepts a full backup file, or a bare array of people (which is what
    /// the raw storage looks like if someone pulls it out by hand).
    static func decodePeople(from data: Data) throws -> [Person] {
        if let payload = try? decoder.decode(BackupPayload.self, from: data) {
            return payload.people
        }
        return try decoder.decode([Person].self, from: data)
    }

    /// The web build generates short random ids, not UUIDs. Hashing them to a
    /// fixed UUID keeps identity stable across imports, so re-importing the
    /// same web backup is still a no-op instead of duplicating everyone.
    static func stableUUID(from raw: String) -> UUID {
        if let uuid = UUID(uuidString: raw) { return uuid }
        let hex = Insecure.MD5.hash(data: Data(raw.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
        let formatted = "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-"
            + "\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-"
            + "\(hex.dropFirst(20).prefix(12))"
        return UUID(uuidString: formatted) ?? UUID()
    }

    static func filename(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "convo-notes-backup-\(formatter.string(from: date))"
    }
}

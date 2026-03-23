import Foundation
import SwiftData

@Model
final class SocialConnection {
    var id: UUID
    var platformRaw: String
    var accessTokenKeychainKey: String
    var username: String
    var connectedAt: Date

    var platform: SocialPlatform {
        get { SocialPlatform(rawValue: platformRaw) ?? .twitter }
        set { platformRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        platform: SocialPlatform,
        username: String = "",
        connectedAt: Date = Date()
    ) {
        self.id = id
        self.platformRaw = platform.rawValue
        self.accessTokenKeychainKey = "social_token_\(platform.rawValue)_\(id.uuidString)"
        self.username = username
        self.connectedAt = connectedAt
    }
}

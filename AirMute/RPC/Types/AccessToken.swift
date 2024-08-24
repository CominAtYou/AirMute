import Foundation

public class AccessToken: Codable {
    public let refreshToken: String?
    public let accessToken: String
    public let expiresIn: Int
    public let tokenType: String
    public let scopes: [OAuth2Scope]

    private enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
        case accessToken  = "access_token"
        case expiresIn    = "expires_in"
        case tokenType    = "token_type"
        case scope
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        self.tokenType = try container.decode(String.self, forKey: .tokenType)

        let scopesStr = try container.decode(String.self, forKey: .scope)
        var scopes: [OAuth2Scope] = []
        for scope in scopesStr.components(separatedBy: .whitespaces) {
            scopes.append(OAuth2Scope(rawValue: scope)!)
        }
        self.scopes = scopes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if refreshToken != nil { try container.encode(refreshToken, forKey: .refreshToken) }
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(expiresIn, forKey: .expiresIn)
        try container.encode(tokenType, forKey: .tokenType)

        var scopesStr: [String] = []
        for scope in scopes {
            scopesStr.append(scope.rawValue)
        }
        try container.encode(scopesStr.joined(separator: " "), forKey: .scope)
    }

    public class func from(data: Data) throws -> AccessToken {
        return try NewJSONDecoder().decode(AccessToken.self, from: data)
    }
}

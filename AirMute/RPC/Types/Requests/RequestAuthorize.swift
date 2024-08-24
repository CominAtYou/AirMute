import Foundation

class RequestAuthorize: Encodable {
    let cmd: CommandType = .authorize
    let nonce: String
    let args: RequestAuthorizeArgs

    private enum CodingKeys: String, CodingKey {
        case cmd
        case nonce
        case args
    }

    init(nonce: String, clientID: String, scopes: [OAuth2Scope], rpcToken: String?, username: String?) throws {
        self.nonce = nonce
        self.args = try RequestAuthorizeArgs(clientID: clientID, scopes: scopes, rpcToken: rpcToken, username: username)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cmd, forKey: .cmd)
        try container.encode(nonce, forKey: .nonce)
        try container.encode(args, forKey: .args)
    }

    func jsonData() throws -> Data {
        return try NewJSONEncoder().encode(self)
    }

    func jsonString() throws -> String {
        return String(data: try self.jsonData(), encoding: .utf8)!
    }
}

class RequestAuthorizeArgs: Encodable {
    let clientID: String
    let scopes: [OAuth2Scope]
    let rpcToken: String?
    let username: String?

    private enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case scopes
        case rpcToken = "rpc_token"
        case username
    }

    init(clientID: String, scopes: [OAuth2Scope], rpcToken: String?, username: String?) throws {
        self.clientID = clientID
        self.scopes = scopes
        self.rpcToken = rpcToken
        self.username = username
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientID, forKey: .clientID)
        try container.encode(scopes, forKey: .scopes)
        if self.rpcToken != nil { try container.encode(rpcToken, forKey: .rpcToken) }
        if self.username != nil { try container.encode(username, forKey: .username) }
    }
}

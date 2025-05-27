import Foundation

extension RPC {
    func authenticateOverRPC() throws -> ResponseAuthenticate {
        if let tokenExpiry = UserDefaults.standard.object(forKey: "token_expiry") as? Date, tokenExpiry > Date() {
            if let accessTokenData = UserDefaults.standard.data(forKey: "access_token") {
                logger.info("Loaded cached credentials")
                let accessToken = try AccessToken.from(data: accessTokenData)
                return try authenticate(accessToken: accessToken.accessToken)
            }
        }
        
        logger.info("Credentials expired, reauthenticating...")
        
        let authorization = try authorize(oAuth2Scopes: [.rpc, .rpcVoiceRead, .rpcVoiceWrite, .identify])
        let accessToken = try fetchAccessToken(code: authorization.data.code, redirectURI: "http://localhost")
        let authentication = try authenticate(accessToken: accessToken.accessToken)
        
        UserDefaults.standard.setValue(authentication.data.expires, forKey: "token_expiry")
        UserDefaults.standard.setValue(try NewJSONEncoder().encode(accessToken), forKey: "access_token")
        
        return authentication
    }
}

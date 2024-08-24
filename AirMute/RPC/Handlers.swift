import Foundation

extension RPC {
    public func onEvent(handler: @escaping (_ rpc: RPC, _ eventType: EventType, _ event: Data) -> Void) {
        self.eventHandler = handler
    }
    
    public func onDisconnect(handler: @escaping (_ rpc: RPC, _ closeError: EventClose) -> Void) {
        self.disconnectHandler = handler
    }
    
    public func onResponse(handler: @escaping (_ rpc: RPC, _ nonce: String, _ commandType: CommandType, _ response: Data) -> Void) {
        self.responseHandler = handler
    }
    
    public func onConnect(handler: @escaping (_ rpc: RPC, _ eventReady: EventReady) -> Void) {
        self.connectHandler = handler
    }
    
    public func onError(handler: @escaping (_ rpc: RPC, _ nonce: String, _ eventError: EventError) -> Void) {
        self.errorHandler = handler
    }
}

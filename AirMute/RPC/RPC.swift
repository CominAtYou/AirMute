import Foundation
import Socket
import NotificationCenter


class RPC {
    internal var socket: Socket?
    let clientId: String
    let clientSecret: String
    internal let rpcWorker: DispatchQueue
    internal let handlerWorker: DispatchQueue
    
    internal let cmdNotifCenter = NotificationCenter()
    internal let cmdTimeout = 1000
    
    internal var connectHandler: ((_ rpc: RPC, _ eventReady: EventReady) -> Void)?
    internal var eventHandler: ((_ rpc: RPC, _ eventType: EventType, _ event: Data) -> Void)?
    internal var disconnectHandler: ((_ rpc: RPC, _ closeError: EventClose) -> Void)?
    internal var responseHandler: ((_ rpc: RPC, _ nonce: String, _ commandType: CommandType, _ response: Data) -> Void)?
    internal var errorHandler:      ((_ rpc: RPC, _ nonce: String, _ eventError: EventError) -> Void)?
    
    init(clientId: String, clientSecret: String) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        
        self.rpcWorker = DispatchQueue(
            label: "discord.rpc.worker.\(ProcessInfo.processInfo.processIdentifier)",
            qos: .userInitiated
        )
        
        self.handlerWorker = DispatchQueue(
            label: "discord.handler.worker.\(ProcessInfo.processInfo.processIdentifier)",
            qos: .userInitiated
        )
    }
    
}

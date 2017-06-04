//
//  Server.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/9/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftUtilities

public class TCPServer {

    public let addresses: [Address]

    public var clientShouldConnect: ((Address) -> Bool)?
    public var clientWillConnect: ((TCPChannel) -> Void)?
    public var clientDidConnect: ((TCPChannel) -> Void)?
    public var clientDidDisconnect: ((TCPChannel) -> Void)?

    public var errorDidOccur: ((Swift.Error) -> Void)? = {
        (error) in
        log?.debug("Server got: \(error)")
    }

    public var listenersByAddress: [Address: TCPListener] = [:]
    public var connections = Atomic(Set <TCPChannel> ())

    fileprivate let queue = DispatchQueue(label: "io.schwa.TCPServer", attributes: [])

    public init(address: Address) throws {
        self.addresses = [address]
    }

    public func startListening() throws {
        for address in addresses {
            try startListening(address)
        }
    }

    fileprivate func startListening(_ address: Address) throws {

        let listener = try TCPListener(address: address, queue: queue)

        listener.clientShouldConnect = clientShouldConnect
        listener.clientWillConnect = {
            [weak self] channel in

            guard let strong_self = self else {
                return
            }

            channel.state.addObserver(strong_self, queue: DispatchQueue.main) {
                (old, new) in

                guard let strong_self = self else {
                    return
                }
                if new == .disconnected {
                    strong_self.connections.value.remove(channel)
                    strong_self.clientDidDisconnect?(channel)
                }
            }
            strong_self.clientWillConnect?(channel)
        }
        listener.clientDidConnect = {
            [weak self] channel in

            guard let strong_self = self else {
                return
            }

            strong_self.connections.value.insert(channel)
            strong_self.clientDidConnect?(channel)
        }
        listener.errorDidOccur = errorDidOccur

        try listener.startListening()

        listenersByAddress[address] = listener
    }

    public func stopListening() throws {
        for (address, listener) in listenersByAddress {
            try listener.stopListening()
            listenersByAddress[address] = nil
        }
    }

    public func disconnectAllClients() throws {
        for connection in connections.value {
            connection.disconnect() {
                (result) in
                log?.debug("Server disconnect all: \(result)")
            }
        }
    }
}

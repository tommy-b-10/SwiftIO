//
//  TCPListener.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 3/18/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import SwiftUtilities

public class TCPListener {

    public let address: Address
    public let queue: DispatchQueue
    public fileprivate(set) var listeningSocket: Socket?
    public var listening: Bool {
        return listeningSocket != nil
    }

    public var clientShouldConnect: ((Address) -> Bool)?
    public var clientWillConnect: ((TCPChannel) -> Void)?
    public var clientDidConnect: ((TCPChannel) -> Void)?
    public var errorDidOccur: ((Swift.Error) -> Void)? = {
        (error) in
        log?.debug("Server got: \(error)")
    }

    fileprivate var source: DispatchSource!

    public init(address: Address, queue: DispatchQueue? = nil) throws {
        self.address = address
        self.queue = queue ?? DispatchQueue(label: "io.schwa.TCPListener", attributes: [])
    }

    public func startListening() throws {

        listeningSocket = try Socket(domain: address.family.rawValue, type: SOCK_STREAM, protocol: IPPROTO_TCP)

        guard let listeningSocket = listeningSocket else {
            throw Error.generic("Socket() failed")
        }

        listeningSocket.socketOptions.reuseAddress = true

        try listeningSocket.bind(address)
        try listeningSocket.setNonBlocking(true)
        try listeningSocket.listen()

        source = DispatchSource.makeReadSource(fileDescriptor: listeningSocket.descriptor, queue: queue) /*Migrator FIXME: Use DispatchSourceRead to avoid the cast*/ as! DispatchSource
        source.setEventHandler {
            [weak self] in

            self?.accept()
        }
        source.resume()
    }

    public func stopListening() throws {
        if let source = source {
            source.cancel()
            self.source = nil
        }
        listeningSocket = nil
    }

    fileprivate func accept() {
        do {
            guard let listeningSocket = listeningSocket else {
                throw Error.generic("Socket() failed")
            }
            let (socket, address) = try listeningSocket.accept()

            if let clientShouldConnect = clientShouldConnect , clientShouldConnect(address) == false {
                return
            }

            let channel = TCPChannel(address: address, socket: socket) {
                (channel) in

                clientWillConnect?(channel)
            }
            clientDidConnect?(channel)
        }
        catch let error {
            errorDidOccur?(error)
        }

    }

}

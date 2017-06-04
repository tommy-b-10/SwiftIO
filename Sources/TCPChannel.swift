//
//  TCPChannel.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/23/15.
//
//  Copyright (c) 2014, Jonathan Wight
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Darwin
import Dispatch

import SwiftUtilities

public class TCPChannel: Connectable {
    public enum Error: Swift.Error {
        case incorrectState(String)
        case unknown
    }

    public let label: String?
    public let address: Address
    public let state = ObservableProperty(ConnectionState.disconnected)

    // MARK: Callbacks

    public var readCallback: ((Result <DispatchData>) -> Void)? {
        willSet {
            preconditionConnected()
        }
    }

    /// Return true from shouldReconnect to initiate a reconnect. Does not make sense on a server socket.
    public var shouldReconnect: ((Void) -> Bool)? {
        willSet {
            preconditionConnected()
        }
    }

    public var reconnectionDelay: TimeInterval = 5.0 {
        willSet {
            preconditionConnected()
        }
    }

    // MARK: Private properties
    fileprivate let queue: DispatchQueue
    fileprivate let lock = NSRecursiveLock()
    public fileprivate(set) var socket: Socket!
    fileprivate var channel: DispatchIO!
    fileprivate var disconnectCallback: ((Result <Void>) -> Void)?

    // MARK: Initialization

    public init(label: String? = nil, address: Address, qos: DispatchQoS = .default) {
        assert(address.port != nil)

        self.label = label
        self.address = address
        self.queue = DispatchQueue(label: "io.schwa.SwiftIO.TCP.queue", qos: qos)

    }

    public func connect(_ callback: @escaping (Result <Void>) -> Void) {
        connect(timeout: 30, callback: callback)
    }

    public func connect(timeout: TimeInterval, callback: @escaping (Result <Void>) -> Void) {
        queue.async {
            [weak self, address] in

            guard let strong_self = self else {
                return
            }

            if strong_self.state.value != .disconnected {
                callback(.failure(Error.incorrectState("Cannot connect channel in state \(strong_self.state.value)")))
                return
            }

            log?.debug("\(strong_self): Trying to connect.")

            do {
                strong_self.state.value = .connecting
                let socket: Socket

                socket = try Socket(domain: address.family.rawValue, type: SOCK_STREAM, protocol: IPPROTO_TCP)

                strong_self.configureSocket?(socket)
                try socket.connect(address, timeout: timeout)

                strong_self.socket = socket
                strong_self.state.value = .connected
                strong_self.createStream()
                log?.debug("\(strong_self): Connection success.")
                callback(.success())
            }
            catch let error {
                strong_self.state.value = .disconnected
                log?.debug("\(strong_self): Connection failure: \(error).")
                callback(.failure(error))
            }
        }

    }

    public func disconnect(_ callback: @escaping (Result <Void>) -> Void) {
        queue.async {
            [weak self] in

            guard let strong_self = self else {
                return
            }
            if Set([.disconnected, .disconnecting]).contains(strong_self.state.value) {
                callback(.failure(Error.incorrectState("Cannot disconnect channel in state \(strong_self.state.value)")))
                return
            }

            log?.debug("\(strong_self): Trying to disconnect.")

            strong_self.state.value = .disconnecting
            strong_self.disconnectCallback = callback
            strong_self.channel.close(flags: .stop)
        }
    }

    // MARK: -

    public func write(_ data: DispatchData, callback: @escaping (Result <Void>) -> Void) {
        (channel).write(offset: 0, data: data, queue: queue) {
            (done, data, error) in

            guard error == 0 else {
                callback(Result.failure(Errno(rawValue: error)!))
                return
            }
            callback(Result.success())
        }
    }

    fileprivate func createStream() {

        channel = DispatchIO(type: DispatchIO.StreamType.stream, fileDescriptor: socket.descriptor, queue: queue) {
            [weak self] (error: Int32) in

            guard let strong_self = self else {
                return
            }
            tryElseFatalError() {
                try strong_self.handleDisconnect()
            }
        }
        assert(channel != nil)
        precondition(state.value == .connected)

        channel.setLimit(lowWater: 0)

        channel.read(offset: 0, length: -1 /* Int(truncatingBitPattern:SIZE_MAX) */, queue: queue) {
            [weak self] (done, data, error) in

            guard let strong_self = self else {
                return
            }
            guard error == 0 else {
                if error == ECONNRESET {
                    tryElseFatalError() {
                        try strong_self.handleDisconnect()
                    }
                    return
                }
                strong_self.readCallback?(Result.failure(Errno(rawValue: error)!))
                return
            }

            guard let data = data else {
                // TODO: Swift3 - a bit fatal!
                fatalError("No error but no data")
            }


            switch (done, data.count > 0) {
                case (false, _), (true, true):
                    strong_self.readCallback?(Result.success(data))
                case (true, false):
                    strong_self.channel.close(flags: [])
            }
        }
    }

    fileprivate func handleDisconnect() throws {
        let remoteDisconnect = (state.value != .disconnecting)

        try socket.close()

        state.value = .disconnected

        if let shouldReconnect = shouldReconnect , remoteDisconnect == true {
            let reconnectFlag = shouldReconnect()
            if reconnectFlag == true {
                let time = DispatchTime.now() + Double(Int64(reconnectionDelay * 1000000000)) / Double(NSEC_PER_SEC)
                queue.asyncAfter(deadline: time) {
                    [weak self] (result) in

                    guard let strong_self = self else {
                        return
                    }

                    strong_self.reconnect()
                }
                return
            }
        }

        disconnectCallback?(Result.success())
        disconnectCallback = nil
    }

    fileprivate func reconnect() {
        connect() {
            [weak self] (result) in

            guard let strong_self = self else {
                return
            }

            if case .failure = result {
                strong_self.disconnectCallback?(result)
                strong_self.disconnectCallback = nil
            }
        }
    }

    fileprivate func preconditionConnected() {
        precondition(state.value == .disconnected, "Cannot change parameter while socket connected")
    }

    // MARK: -

    public var configureSocket: ((Socket) -> Void)?
}

// MARK: -

extension TCPChannel {

    /// Create a TCPChannel from a pre-existing socket. The setup closure is called after the channel is created but before the state has changed to `Connecting`. This gives consumers a chance to configure the channel before it is fully connected.
    public convenience init(label: String? = nil, address: Address, socket: Socket, qos: DispatchQoS = .default, setup: ((TCPChannel) -> Void)) {
        self.init(label: label, address: address, qos: qos)
        self.socket = socket
        setup(self)
        state.value = .connected
        createStream()
    }

}

// MARK: -

extension TCPChannel: CustomStringConvertible {
    public var description: String {
        return "TCPChannel(label: \(label), address: \(address)), state: \(state.value))"
    }
}

// MARK: -

extension TCPChannel: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

public func == (lhs: TCPChannel, rhs: TCPChannel) -> Bool {
    return lhs === rhs
}

//
//  UDPMavlinkReceiver.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 4/22/15.
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

/**
 *  A GCD based UDP listener.
 */
public class UDPChannel {

    public enum PreconditionError: Swift.Error {
        case queueSuspended
        case queueNotExist
    }

    public let label: String?

    public let address: Address

    public var readHandler: ((Datagram) -> Void)? = loggingReadHandler
    public var errorHandler: ((Swift.Error) -> Void)? = loggingErrorHandler

    fileprivate var resumed: Bool = false
    fileprivate let receiveQueue: DispatchQueue!
    fileprivate let sendQueue: DispatchQueue!
    fileprivate var source: DispatchSource!

    public fileprivate(set) var socket: Socket!
    public var configureSocket: ((Socket) -> Void)?

    // MARK: - Initialization

    public init(label: String? = nil, address: Address, qos: DispatchQoS = .default, readHandler: ((Datagram) -> Void)? = nil) {
        self.label = label
        self.address = address

        assert(address.port != nil)
        if let readHandler = readHandler {
            self.readHandler = readHandler
        }

        receiveQueue = DispatchQueue(label: "io.schwa.SwiftIO.UDP.receiveQueue", qos: qos)
        guard receiveQueue != nil else {
            fatalError("dispatch_queue_create() failed")
        }

        sendQueue = DispatchQueue(label: "io.schwa.SwiftIO.UDP.sendQueue", qos: qos)
        guard sendQueue != nil else {
            fatalError("dispatch_queue_create() failed")
        }
    }

    // MARK: - Actions

    public func resume() throws {
        do {
            socket = try Socket(domain: address.family.rawValue, type: SOCK_DGRAM, protocol: IPPROTO_UDP)
        }
        catch let error {
            cleanup()
            errorHandler?(error)
        }

        configureSocket?(socket)

        source = DispatchSource.makeReadSource(fileDescriptor: socket.descriptor, queue: receiveQueue) /*Migrator FIXME: Use DispatchSourceRead to avoid the cast*/ as! DispatchSource
        guard source != nil else {
            cleanup()
            throw Error.generic("dispatch_source_create() failed")
        }

        source.setCancelHandler {
            [weak self] in
            guard let strong_self = self else {
                return
            }

            strong_self.cleanup()
            strong_self.resumed = false
        }

        source.setEventHandler {
            [weak self] in
            guard let strong_self = self else {
                return
            }
            do {
                try strong_self.read()
            }
            catch let error {
                strong_self.errorHandler?(error)
            }
        }

        source.setRegistrationHandler {
            [weak self] in
            guard let strong_self = self else {
                return
            }
            do {
                try strong_self.socket.bind(strong_self.address)
                strong_self.resumed = true
            }
            catch let error {
                strong_self.errorHandler?(error)
                tryElseFatalError() {
                    try strong_self.cancel()
                }
                return
            }
        }
        source.resume()
    }

    public func cancel() throws {
        if resumed == true {
            assert(source != nil, "Cancel called with source = nil.")
            source.cancel()
        }
    }

    public func send(_ data: DispatchData, address: Address? = nil, callback: @escaping (Result <Void>) -> Void) {
        guard sendQueue != nil else {
            callback(.failure(PreconditionError.queueNotExist))
            return
        }
        guard resumed else {
            callback(.failure(PreconditionError.queueSuspended))
            return
        }

        sendQueue.async {
            [weak self] in

            guard let strong_self = self else {
                return
            }
            do {
                // use default address if address parameter is not set
                let address = address ?? strong_self.address

                if address.family != strong_self.address.family {
                    throw Error.generic("Cannot send UDP data down a IPV6 socket with a IPV4 address or vice versa.")
                }

                try strong_self.socket.sendto(data, address: address)
            }
            catch let error {
                strong_self.errorHandler?(error)
                callback(.failure(error))
                return
            }
            callback(.success())
        }
    }

    public static func send(_ data: DispatchData, address: Address, queue: DispatchQueue, writeHandler: @escaping (Result <Void>) -> Void) {
        let socket = try! Socket(domain: address.family.rawValue, type: SOCK_DGRAM, protocol: IPPROTO_UDP)
        queue.async {
            do {
                try socket.sendto(data, address: address)
            }
            catch let error {
                writeHandler(.failure(error))
                return
            }
            writeHandler(.success())
        }
    }
}

// MARK: -

extension UDPChannel: CustomStringConvertible {
    public var description: String {
        return "\(type(of: self))(\"\(label ?? "")\")"
    }
}

// MARK: -

private extension UDPChannel {

    func read() throws {

        // TODO: Swift3 - now way too many allocs and copies in this code. Need to work to get it back to Swift 2's levels.

        var readBuffer = Data(count: 4096)
        var socketAddrBuffer = Data(count: Int(SOCK_MAXADDRLEN))

        try readBuffer.withUnsafeMutableBytes() {
            (readBufferPointer: UnsafeMutablePointer <UInt8>) in

            try socketAddrBuffer.withUnsafeMutableBytes() {
                (socketBufferPointer: UnsafeMutablePointer <sockaddr>) in

                var socketlen = socklen_t(socketAddrBuffer.count)
                let result = recvfrom(socket.descriptor, readBufferPointer, readBuffer.count, 0, socketBufferPointer, &socketlen)
                guard result >= 0 else {
                    let error: Swift.Error = Errno(rawValue: Int32(result)) ?? Error.unknown
                    errorHandler?(error)
                    throw error
                }
                readBuffer.count = result
                socketAddrBuffer.count = max(Int(socketlen), MemoryLayout<sockaddr_storage>.size)
            }
        }

        let address = socketAddrBuffer.withUnsafeBytes() {
            (pointer: UnsafePointer <sockaddr_storage>) in
            return Address(sockaddr: pointer.pointee)
        }

        let readData = DispatchData(data: readBuffer)

        let datagram = Datagram(from: address, timestamp: Timestamp(), data: readData)
        readHandler?(datagram)
    }


    func cleanup() {
        defer {
            socket = nil
            source = nil
        }

        do {
            try socket.close()
        }
        catch let error {
            errorHandler?(error)
        }
    }
}

// MARK: -

public extension UDPChannel {
    public func send(_ data: Data, address: Address? = nil, callback: @escaping (Result <Void>) -> Void) {
        let data = DispatchData(data: data)
        send(data, address: address ?? self.address, callback: callback)
    }
}

// Private for now - make public soon?
private extension Socket {
    func sendto(_ data: DispatchData, address: Address) throws {
        let addr = sockaddr_storage(address: address)
        try addr.withSockaddr() {
            addrPtr in

            return try data.withUnsafeBytes() {
                (buffer: UnsafePointer <UInt8>) in

                let result = Darwin.sendto(descriptor, buffer, data.count, 0, addrPtr, socklen_t(addr.ss_len))
                // TODO: what about "partial" sends.
                if result < data.count {
                    throw Errno(rawValue: errno) ?? Error.unknown
                }
            }
        }




    }
}

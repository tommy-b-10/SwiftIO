//
//  Socket.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/9/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import Darwin

import SwiftUtilities

public  class Socket {

    public  fileprivate(set) var descriptor: Int32

    public init(_ descriptor: Int32) {
        self.descriptor = descriptor
    }

    deinit {
        if descriptor >= 0 {
            tryElseFatalError() {
                try close()
            }
        }
    }

    func close() throws {

        let result = Darwin.close(descriptor)
        descriptor = -1
        if result != 0 {
            throw Errno(rawValue: result) ?? Error.unknown
        }
    }

}

// MARK: Socket options

extension Socket {

    public typealias SocketType = Int32

    public var type: SocketType {
        get {
            return socketOptions.type
        }
    }

    public func setNonBlocking(_ nonBlocking: Bool) throws {
        let result = SwiftIO.setNonblocking(descriptor, nonBlocking)
        if result != 0 {
            throw Errno(rawValue: result) ?? Error.unknown
        }
    }

}

// MARK: -

public extension Socket {

    convenience init(domain: Int32, type: Int32, protocol: Int32) throws {
        let descriptor = Darwin.socket(domain, type, `protocol`)
        if descriptor < 0 {
            throw Errno(rawValue: errno) ?? Error.unknown
        }
        self.init(descriptor)
    }

}

// MARK: -

public extension Socket {

    func connect(_ address: Address, timeout: TimeInterval = 30) throws {
        // Set the socket to be non-blocking
        try setNonBlocking(true)
        defer {
            _ = try? setNonBlocking(false)
        }

        let addr = sockaddr_storage(address: address)

        // This connect call should error out with code EINPROGRESS, if any other error occurs, throw it
        let result: Int32 = addr.withSockaddr() {
            return Darwin.connect(descriptor, $0, socklen_t(addr.ss_len))
        }

        // If connected succeeded immediately.
        if result == 0 {
            return
        }

        guard result == -1 && errno == EINPROGRESS else {
            try close()
            throw Errno(rawValue: errno) ?? Error.unknown
        }

        do {
            try select(timeout: timeout)
        }
        catch let error {
            try close()
            throw error
        }
    }

    func bind(_ address: Address) throws {
        let addr = sockaddr_storage(address: address)
        try addr.withSockaddr() {
            let status = Darwin.bind(descriptor, $0, socklen_t(addr.ss_len))
            if status != 0 {
                throw Errno(rawValue: errno) ?? Error.unknown
            }
        }

    }

    func listen(_ backlog: Int = 1) throws {
        precondition(type == SOCK_STREAM, "\(#function) should only be used on `SOCK_STREAM` sockets")

        let status = Darwin.listen(descriptor, Int32(backlog))
        if status != 0 {
            throw Errno(rawValue: errno) ?? Error.unknown
        }
    }

    func accept() throws -> (Socket, Address) {
        precondition(type == SOCK_STREAM, "\(#function) should only be used on `SOCK_STREAM` sockets")
        var addr = sockaddr_storage()
        return try addr.withMutableSockaddr() {
            var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
            let socket = Darwin.accept(descriptor, $0, &length)
            if socket < 0 {
                throw Errno(rawValue: errno) ?? Error.unknown
            }
            // TODO: Validate length
            let address = Address(sockaddr: addr)
            return (Socket(socket), address)
        }
    }

    func getAddress() throws -> Address {
        // TODO: all this with with with stuff can be replaced by a new with_sockaddr on sockaddr_storage!
        var addr = sockaddr_storage()
        return try addr.withMutableSockaddr() {
            var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
            let status = getsockname(descriptor, $0, &length)
            if status != 0 {
                throw Errno(rawValue: errno) ?? Error.unknown
            }
            return Address(sockaddr: addr)
        }
    }

    func getPeer() throws -> Address {
        var addr = sockaddr_storage()
        return try addr.withMutableSockaddr() {
            var length = socklen_t(MemoryLayout<sockaddr_storage>.size)
            let status = getpeername(descriptor, $0, &length)
            if status != 0 {
                throw Errno(rawValue: errno) ?? Error.unknown
            }
            return Address(sockaddr: addr)
        }
    }

    func getSocketError() throws -> Swift.Error? {
        var socketError: Int32 = 0
        var len = socklen_t(MemoryLayout<Int32>.size)
        let result = Darwin.getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &socketError, &len)
        guard result == 0 else {
            throw Errno(rawValue: result) ?? Error.unknown
        }
        if socketError == 0 {
            return nil
        }
        else {
            return Errno(rawValue: socketError) ?? Error.unknown
        }
    }

    // Currently only used by connect()
    fileprivate func select(timeout: TimeInterval) throws {

        // Put descriptor in write set for monitoring set.
        var writeFileDescriptors = fd_set(set: descriptor)
        // Check for writeability and block until either descriptor is writable or timed out
        var time = timeval(timeInterval: timeout)
        let result = Darwin.select(descriptor + 1, nil, &writeFileDescriptors, nil, &time)
        // If the descriptor is not in the write set anymore, select call timed out, tear things down and throw timed out error
        if writeFileDescriptors.contains(value: descriptor) == false {
            // Socket not writable
            try close()
            throw Errno(rawValue: ETIMEDOUT) ?? Error.unknown
        }

        switch result {
        case -1:
            // Error occurred during select
            throw Errno(rawValue: errno) ?? Error.unknown
        case 0:
            // Connection has timed out
            throw Errno(rawValue: ETIMEDOUT) ?? Error.unknown
        default:
            // Select returned successfully with at least one descriptor.
            // Now check error flags in socket options
            if let error = try getSocketError() {
                try close()
                throw error
            }
        }
    }
}

fileprivate extension fd_set {
    init(set: Int32) {
        self = fd_set()
        fdZero(&self)
        fdSet(set, &self)
    }

    mutating func contains(value: Int32) -> Bool {
        return fdIsSet(value, &self) != 0
    }

}

fileprivate extension timeval {
    init(timeInterval: TimeInterval) {
        self = timeval(tv_sec: Int(timeInterval), tv_usec: Int32((timeInterval - floor(timeInterval)) * 1_000_000))
    }
}

//
//  sockaddr_storage.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/5/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Darwin

/**
    Convenience extension to construct sockaddr_storage from addr + port.
*/
public extension sockaddr_storage {

    /**
    Create a sockaddr_storage from a POSIX IPV4 address and port.

    - Parameters:
        - param: addr POSIX IPV4 in_addr structure
        - param: port A 16-bit port _in native-endianness_
    */
    init(addr: in_addr, port: UInt16) {
        var sockaddr = sockaddr_in()
        sockaddr.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        sockaddr.sin_family = sa_family_t(AF_INET)
        sockaddr.sin_port = in_port_t(port.networkEndian)
        sockaddr.sin_addr = addr
        self = sockaddr_storage(sockaddr: sockaddr)
    }

    /**
    Create a sockaddr_storage from a POSIX IPV6 address and port.

    - Parameters:
        - param: addr POSIX IPV6 in6_addr structure
        - param: port A 16-bit port _in native-endianness_
    */
    init(addr: in6_addr, port: UInt16) {
        var sockaddr = sockaddr_in6()
        sockaddr.sin6_len = __uint8_t(MemoryLayout<sockaddr_in6>.size)
        sockaddr.sin6_family = sa_family_t(AF_INET6)
        sockaddr.sin6_port = in_port_t(port.networkEndian)
        sockaddr.sin6_addr = addr
        self = sockaddr_storage(sockaddr: sockaddr)
    }

}

/**
    Convenience extension to make going from sockaddr_storage to/from other sockaddr structures easy
*/
public extension sockaddr_storage {

    init(sockaddr: sockaddr_in) {
        var copy = sockaddr
        self = sockaddr_storage()
        unsafeCopy(destination: &self, source: &copy)
    }

    init(sockaddr: sockaddr_in6) {
        var copy = sockaddr
        self = sockaddr_storage()
        unsafeCopy(destination: &self, source: &copy)
    }

    init(addr: UnsafePointer <sockaddr>, length: Int) {
        precondition((addr.pointee.sa_family == sa_family_t(AF_INET) && length == MemoryLayout<sockaddr_in>.size) || (addr.pointee.sa_family == sa_family_t(AF_INET6) && length == MemoryLayout<sockaddr_in6>.size))
        self = sockaddr_storage()
        unsafeCopy(destination: &self, source: addr, length: length)
    }

}

public extension sockaddr_in {

    /**
    Create a sockaddr_in from a sockaddr_storage

    - Precondition: Family of the sock addr _must_ be AF_INET.
    */
    init(_ addr: sockaddr_storage) {
        precondition(addr.ss_family == sa_family_t(AF_INET) && addr.ss_len >= __uint8_t(MemoryLayout<sockaddr_in>.size))
        var copy = addr
        self = sockaddr_in()
        unsafeCopy(destination: &self, source: &copy)
    }

}

public extension sockaddr_in6 {

    /**
    Create a sockaddr_in6 from a sockaddr_storage

    - Precondition: Family of the sock addr _must_ be AF_INET6.
    */
    init(_ addr: sockaddr_storage) {
        precondition(addr.ss_family == sa_family_t(AF_INET6) && addr.ss_len >= __uint8_t(MemoryLayout<sockaddr_in6>.size))
        var copy = addr
        self = sockaddr_in6()
        unsafeCopy(destination: &self, source: &copy)
    }

}

extension sockaddr_storage: CustomStringConvertible {

    /**
    Create a sockaddr_storage from a POSIX IPV4 address and port.

    - Precondition: Family of the sock addr _must_ be AF_INET or AF_INET6.
    - Warning: This code can fatalError if inet_ntop fails.
    */
    public var description: String {
        var addrStr = Array <CChar> (repeating: 0, count: Int(INET6_ADDRSTRLEN))
        do {
            return try addrStr.withUnsafeMutableBufferPointer() {
                buffer in
                switch Int32(ss_family) {
                    case AF_INET:
                        var addr = sockaddr_in(self)
                        let addrString = try inet_ntop(addressFamily: Int32(ss_family), address: &addr.sin_addr)
                        return "\(addrString):\(UInt16(networkEndian: addr.sin_port))"
                    case AF_INET6:
                        var addr = sockaddr_in6(self)
                        let addrString = try inet_ntop(addressFamily: Int32(ss_family), address: &addr.sin6_addr)
                        return "\(addrString):\(UInt16(networkEndian: addr.sin6_port))"
                    default:
                        preconditionFailure()
                }
            }
        }
        catch let error {
            fatalError("\(error)")
        }
    }
}


extension sockaddr_storage {

    func withSockaddr <R> (_ block: (UnsafePointer <sockaddr>) throws -> R) rethrows -> R {
        var copy = self
        return try withUnsafePointer(to: &copy) {
            pointer in
            return try pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                pointer in
                return try block(pointer)
            }
        }
    }

    mutating func withMutableSockaddr <R> (_ block: (UnsafeMutablePointer <sockaddr>) throws -> R) rethrows -> R {
        return try withUnsafeMutablePointer(to: &self) {
            return try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                return try block($0)
            }
        }
    }
}

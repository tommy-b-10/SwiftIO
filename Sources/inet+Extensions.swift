//
//  Inet+Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/20/15.
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

import SwiftUtilities

// MARK: in_addr extensions

extension in_addr: Equatable {
}

public func == (lhs: in_addr, rhs: in_addr) -> Bool {
    return unsafeBitwiseEquality(lhs, rhs)
}

extension in_addr: CustomStringConvertible {
    public var description: String {
        var s = self
        return tryElseFatalError() {
            return try Swift.withUnsafeMutablePointer(to: &s) {
                let ptr = UnsafeRawPointer($0)
                return try inet_ntop(addressFamily: AF_INET, address: ptr)
            }
        }

    }
}

// MARK: in6_addr extensions

extension in6_addr: Equatable {
}

public func == (lhs: in6_addr, rhs: in6_addr) -> Bool {
    return unsafeBitwiseEquality(lhs, rhs)
}

extension in6_addr: CustomStringConvertible {
    public var description: String {
        var s = self
        return tryElseFatalError() {
            return try Swift.withUnsafeMutablePointer(to: &s) {
                let ptr = UnsafeRawPointer($0)
                return try inet_ntop(addressFamily: AF_INET6, address: ptr)
            }
        }
    }
}

// MARK: Swift wrapper functions for useful (but fiddly) POSIX network functions

/**
`inet_ntop` wrapper that takes an address in network byte order (big-endian) to presentation format.

- parameter addressFamily: IPv4 (AF_INET) or IPv6 (AF_INET6) family.
- parameter address: The address structure to convert.

- throws: @schwa what's proper documentation for this?

- returns: The IP address in presentation format
*/
public func inet_ntop(addressFamily: Int32, address: UnsafeRawPointer) throws -> String {
    var buffer: Array <Int8>
    var size: Int

    switch addressFamily {
    case AF_INET:
        size = Int(INET_ADDRSTRLEN)
    case AF_INET6:
        size = Int(INET6_ADDRSTRLEN)
    default:
        fatalError("Unknown address family")
    }

    buffer = Array <Int8> (repeating: 0, count: size)

    return buffer.withUnsafeMutableBufferPointer() {
        (outputBuffer: inout UnsafeMutableBufferPointer <Int8>) -> String in
        let result = inet_ntop(addressFamily, address, outputBuffer.baseAddress, socklen_t(size))
        return String(cString: result!, encoding: .ascii)!
    }
}

// MARK: -

public func getnameinfo(_ addr: UnsafePointer<sockaddr>, addrlen: socklen_t, hostname: inout String?, service: inout String?, flags: Int32) throws {
    var hostnameBuffer = [Int8](repeating: 0, count: Int(NI_MAXHOST))
    var serviceBuffer = [Int8](repeating: 0, count: Int(NI_MAXSERV))
    let result = hostnameBuffer.withUnsafeMutableBufferPointer() {
        (hostnameBufferPtr: inout UnsafeMutableBufferPointer<Int8>) -> Int32 in
        serviceBuffer.withUnsafeMutableBufferPointer() {
            (serviceBufferPtr: inout UnsafeMutableBufferPointer<Int8>) -> Int32 in
            let result = getnameinfo(
                addr, addrlen,
                hostnameBufferPtr.baseAddress, socklen_t(NI_MAXHOST),
                serviceBufferPtr.baseAddress, socklen_t(NI_MAXSERV),
                flags)
            if result == 0 {
                hostname = String(cString: hostnameBufferPtr.baseAddress!, encoding: .ascii)
                service = String(cString: serviceBufferPtr.baseAddress!, encoding: .ascii)
            }
            return result
        }
    }
    guard result == 0 else {
        throw Errno(rawValue: errno) ?? SwiftUtilities.Error.unknown
    }
}

// MARK: -

public func getaddrinfo(hostname: String?, service: String? = nil, hints: addrinfo, block: (UnsafePointer<addrinfo>) throws -> Bool) throws {
    let hostname = hostname ?? ""
    let service = service ?? ""

    var hints = hints
    var info: UnsafeMutablePointer <addrinfo>? = nil
    let result = getaddrinfo(hostname, service, &hints, &info)
    guard result == 0 else {
        let ptr = gai_strerror(result)
        if let string = String(validatingUTF8: ptr!) {
            throw Error.generic(string)
        }
        else {
            throw Error.unknown
        }
    }

    var current = info
    while current != nil {
        if try block(current!) == false {
            break
        }
        current = current?.pointee.ai_next
    }
    freeaddrinfo(info)
}

public func getaddrinfo(hostname: String?, service: String? = nil, hints: addrinfo) throws -> [Address] {
    var addresses: [Address] = []

    try getaddrinfo(hostname: hostname, service: service, hints: hints) {
        let addr = sockaddr_storage(addr: $0.pointee.ai_addr, length: Int($0.pointee.ai_addrlen))
        let address = Address(sockaddr: addr)
        addresses.append(address)
        return true
    }
    return Array(Set(addresses)).sorted(by: <)
}

// MARK: -

public extension in_addr {
    var octets: (UInt8, UInt8, UInt8, UInt8) {
        let address = UInt32(networkEndian: s_addr)
        return (
            UInt8((address >> 24) & 0xFF),
            UInt8((address >> 16) & 0xFF),
            UInt8((address >> 8) & 0xFF),
            UInt8(address & 0xFF)
        )
    }
}

public extension in6_addr {
    var words: (UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16) {
        assert(MemoryLayout<in6_addr>.size == MemoryLayout<(UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16, UInt16)>.size)
        var copy = self

        return withUnsafePointer(to: &copy) {
            pointer in

            return pointer.withMemoryRebound(to: UInt16.self, capacity: 8) {
                wordPointer in

                let wordBuffer = UnsafeBufferPointer <UInt16> (start: wordPointer, count: 8)
                let words = wordBuffer.map() { UInt16(networkEndian: $0) }
                return (words[0], words[1], words[2], words[3], words[4], words[5], words[6], words[7])
            }
        }
    }
}

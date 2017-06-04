//
//  Address.swift
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
import Foundation


/**
 *  An internet address.
 *
 *  sockaddr generally stores IP address (either IPv4 or IPv6), port, protocol family and type.
 */
public struct Address {

    /// Enum representing the INET or INET6 address. Generally you can avoid this type.
    public enum InetAddress {
        case inet(in_addr)
        case inet6(in6_addr)
    }

    public let inetAddress: InetAddress

    /// Optional native endian port of the address
    public let port: UInt16?

    /**
     Note: You generally shouldn't need to use this. There are other init methods that might be more suitable.

     - parameter inetAddress: Enum representation of the address encapsulating either a in_addr (IPV4) or in6_addr (IPV6) structure.
     - parameter port: _native endian_ port number
     */
    public init(inetAddress: InetAddress, port: UInt16) {
        self.inetAddress = inetAddress
        self.port = port
    }

    /**
     Create a new Address with a different port but same inet address.

     - parameter port: _native endian_ port number
     */
    public func addressWithPort(_ port: UInt16) -> Address {
        return Address(inetAddress: inetAddress, port: port)
    }

}

// MARK: Equatable

extension Address: Equatable {
}

public func == (lhs: Address, rhs: Address) -> Bool {
    switch (lhs.inetAddress, rhs.inetAddress) {
        case (.inet(let lhs_addr), .inet(let rhs_addr)):
            return lhs_addr == rhs_addr && lhs.port == rhs.port
        case (.inet6(let lhs_addr), .inet6(let rhs_addr)):
            return lhs_addr == rhs_addr && lhs.port == rhs.port
        default:
            return false
    }
}

// MARK: Hashable

extension Address: Hashable {
    public var hashValue: Int {
        // TODO: cheating
        return description.hashValue
    }
}

// MARK: Comparable

extension Address: Comparable {
}

public func < (lhs: Address, rhs: Address) -> Bool {

    let lhsPort = lhs.port.map({ Int32($0) }) ?? -1
    let rhsPort = rhs.port.map({ Int32($0) }) ?? -1

    let comparisons = [
        compare(lhs.family.rawValue, rhs.family.rawValue),
        compare(lhs.address, rhs.address),
        compare(lhsPort, rhsPort),
    ]
    for comparison in comparisons {
        switch comparison {
            case .lesser:
                return true
            case .greater:
                return false
            default:
                break
        }
    }
    return false
}

// MARK: CustomStringConvertible

extension Address: CustomStringConvertible {
    public var description: String {
        if let port = port {
            switch family {
                case .inet:
                    return "\(address):\(port)"
                case .inet6:
                    return "[\(address)]:\(port)"
            }
        }
        else {
            switch family {
                case .inet:
                    return address
                case .inet6:
                    return "[\(address)]"
            }
        }
    }
}

// MARK: -

extension Address {

    // TODO: Rename to "name"

    /// A string representation of the Address _without_ the port
    public var address: String {
        return tryElseFatalError() {
            switch inetAddress {
                case .inet(var addr):
                    return try inet_ntop(addressFamily: self.family.rawValue, address: &addr)
                case .inet6(var addr):
                    return try inet_ntop(addressFamily: self.family.rawValue, address: &addr)
            }
        }
    }
}

// MARK: -

extension Address {

    /**
     Create an address from a POSIX in_addr (IPV4) structure and optional port

     - parameter addr: in_addr representation of address
     - parameter port: _native endian_ port number
     */
    public init(addr: in_addr, port: UInt16? = nil) {
        inetAddress = .inet(addr)
        self.port = port
    }

    /**
     Create an address from a (host endian) UInt32 representation. Example ```Address(0x7f000001)```

     - parameter addr: 32-bit _native endian_ integer representation of the address.
     - parameter port: _native endian_ port number
     */
    public init(addr: UInt32, port: UInt16? = nil) {
        let addr = in_addr(s_addr: addr.networkEndian)
        inetAddress = .inet(addr)
        self.port = port
    }

    /**
     Create an address from a POSIX in6_addr (IPV46) structure and optional port

     - parameter addr: in6_addr representation of address
     - parameter port: _native endian_ port number
     */
    public init(addr: in6_addr, port: UInt16? = nil) {
        inetAddress = .inet6(addr)
        self.port = port
    }

    public func to_in_addr() -> in_addr? {
        switch inetAddress {
            case .inet(let addr):
                return addr
            default:
                return nil
        }
    }

    public func to_in6_addr() -> in6_addr? {
        switch inetAddress {
            case .inet6(let addr):
                return addr
            default:
                return nil
        }
    }

    public var family: ProtocolFamily {
        switch inetAddress {
            case .inet:
                return ProtocolFamily(rawValue: AF_INET)!
            case .inet6:
                return ProtocolFamily(rawValue: AF_INET6)!
        }
    }
}

public extension Address {
    init(sockaddr: sockaddr_storage) {
        switch Int32(sockaddr.ss_family) {
            case AF_INET:
                var src = sockaddr
                var dst = sockaddr_in()
                unsafeCopy(destination: &dst, source: &src)
                inetAddress = .inet(dst.sin_addr)
                port = dst.sin_port != 0 ? UInt16(networkEndian: dst.sin_port) : nil
            case AF_INET6:
                var src = sockaddr
                var dst = sockaddr_in6()
                unsafeCopy(destination: &dst, source: &src)
                inetAddress = .inet6(dst.sin6_addr)
                port = dst.sin6_port != 0 ? UInt16(networkEndian: dst.sin6_port) : nil
            default:
                fatalError("Invalid sockaddr family")
        }
    }
}

public extension sockaddr_storage {

    init(address: Address) {
        guard let port = address.port else {
            fatalError("No port")
        }
        switch address.inetAddress {
            case .inet(let addr):
                self = sockaddr_storage(addr: addr, port: port)
            case .inet6(let addr):
                self = sockaddr_storage(addr: addr, port: port)
        }
    }

}

// MARK: Hostname support

public extension Address {

    static func addresses(_ hostname: String, service: String? = nil, protocol:InetProtocol? = nil, family: ProtocolFamily? = ProtocolFamily.preferred, passive: Bool = false, mappedIPV4: Bool = false) throws -> [Address] {
        var hints = addrinfo()
        if let `protocol` = `protocol` {
            hints.ai_protocol = `protocol`.rawValue
        }
        if let family = family {
            hints.ai_family = family.rawValue
        }
        if passive == true {
            hints.ai_flags |= AI_PASSIVE
        }
        if mappedIPV4 == true {
            hints.ai_flags |= AI_V4MAPPED
            guard family == nil || family == ProtocolFamily.inet6 else {
                fatalError("Cannot specify an IPV4 mapped IPV6 address if you insist on an IPV4 address.")
            }
            hints.ai_family = ProtocolFamily.inet6.rawValue

        }
        let addresses = try getaddrinfo(hostname: hostname, service: service, hints: hints)
        return addresses
    }
}

public extension Address {

    /**
     Create an address from string.

     Examples:
        ```
        try Address("127.0.0.1")
        try Address("127.0.0.1:80")
        try Address("localhost")
        try Address("localhost:80")
        try Address("[::1]")
        try Address("[::1]:80")
        ```
     */
    init(address: String, port: UInt16? = nil, protocol:InetProtocol? = nil, family: ProtocolFamily? = ProtocolFamily.preferred, passive: Bool = false, mappedIPV4: Bool = false) throws {

        var hostname: String?
        var service: String?

        let result = scanAddress(address, address: &hostname, service: &service)
        if let port = port {
            if service != nil {
                fatalError("Specified port in both address string and parameter")
            }
            else {
                service = String(port)
            }
        }

        if result == false {
            throw Error.generic("Not an address")
        }

        let addresses: [Address] = try Address.addresses(hostname!, service: service, protocol: `protocol`, family: family, passive: passive, mappedIPV4: mappedIPV4)

        guard var address = addresses.first else {
            throw Error.generic("Could not create address")
        }

        // Workaround issue in iOS 9 & OSX 11 with IPv6 networks.
        //
        // getaddrinfo() can return a sockaddr with a nil port if it is given a
        // numeric service name _and_ the device is connected to an IPv6 network.
        //
        // Workaround is to manually set the port under these circumstances.
        //
        // See https://developer.apple.com/videos/play/wwdc2015/719/ for how to set up a Mac for testing IPv6.
        if let service = service, let port = UInt16(service) , address.port == nil && Address.workaroundGetAddrInfo == true {
            address = address.addressWithPort(port)
            print(address)
        }

        self = address

        assert(port == nil || String(port!) == service)
    }

    static let workaroundGetAddrInfo: Bool = {
        #if os(iOS)
            let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
            return operatingSystemVersion.minorVersion < 10
        #elseif os(OSX)
            let operatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion
            return operatingSystemVersion.minorVersion < 12
        #endif
    }()

}

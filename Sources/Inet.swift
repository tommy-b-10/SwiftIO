//
//  Inet.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/8/15.
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

/**
 An enum representing Inet protocols supported by sockaddr.

 This is a subset of what is support by sockaddr. But we mostly care about TCP and UDP.
 */
public enum InetProtocol {
    case tcp
    case udp
}

public extension InetProtocol {
    init?(rawValue: Int32) {
        switch rawValue {
            case IPPROTO_TCP:
                self = .tcp
            case IPPROTO_UDP:
                self = .udp
            default:
                return nil
        }
    }

    var rawValue: Int32 {
        switch self {
            case .tcp:
                return IPPROTO_TCP
            case .udp:
                return IPPROTO_UDP
        }
    }
}

/**
 An enum representing protocol family supported by sockaddr.

 This is a subset of what is support by sockaddr. But we mostly care about INET and INET6.
 */
public enum ProtocolFamily {
    case inet
    case inet6
}

public extension ProtocolFamily {
    static var preferred: ProtocolFamily? {
        return nil
    }
}

public extension ProtocolFamily {

    init?(rawValue: Int32) {
        switch rawValue {
            case PF_INET:
                self = .inet
            case PF_INET6:
                self = .inet6
            default:
                return nil
        }
    }
    var rawValue: Int32 {
        switch self {
            case .inet:
                return PF_INET
            case .inet6:
                return PF_INET6
        }
    }
}

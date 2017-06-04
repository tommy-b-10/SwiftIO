//
//  Datagram.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/9/15.
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


import SwiftUtilities

public struct Datagram {
    public let from: Address
    public let timestamp: Timestamp
    public let data: DispatchData 

    public init(from: Address, timestamp: Timestamp = Timestamp(), data: DispatchData ) {
        self.from = from
        self.timestamp = timestamp
        self.data = data
    }
}

// MARK: -

extension Datagram: Equatable {
}

public func == (lhs: Datagram, rhs: Datagram) -> Bool {

    if lhs.from != rhs.from {
        return false
    }
    if lhs.timestamp != rhs.timestamp {
        return false
    }
    if lhs.data != rhs.data {
        return false
    }

    return true
}

// MARK: -

extension Datagram: CustomStringConvertible {
    public var description: String {
        return "Datagram(from: \(from), timestamp: \(timestamp): data: \(data.count) bytes)"
    }
}

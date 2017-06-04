//
//  Datagram+Streams.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/18/15.
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

extension Datagram: BinaryInputStreamable, BinaryOutputStreamable {

    public static func readFrom(_ stream: BinaryInputStream) throws -> Datagram {

        let jsonLength = Int32(networkEndian: try stream.read())
        guard jsonLength >= 0 else {
            throw Error.generic("Negative length")
        }

        let jsonData = Data(dispatchData: try stream.readData(count: Int(jsonLength)))

        let json = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions()) as! [String: AnyObject]

        guard let address = json["address"] as? String else {
            throw Error.generic("Could not get from address")
        }

        guard let port = json["port"] as? Int else {
            throw Error.generic("Could not get from port")
        }

        guard let absoluteTime = json["timestamp"] as? Double else {
            throw Error.generic("Could not get from port")
        }

        let dataLength = Int32(networkEndian: try stream.read())
        guard dataLength >= 0 else {
            throw Error.generic("Negative length")
        }

        let data: DispatchData = try stream.readData(count: Int(dataLength))
        let datagram = try Datagram(from: Address(address: address, port: UInt16(port)), timestamp: Timestamp(absoluteTime: absoluteTime), data: data)

        return datagram
    }

    public func writeTo(stream: BinaryOutputStream) throws {

        let metadata: [String: Any] = [
            "address": from.address as AnyObject,
            "port": Int(from.port ?? 0) as AnyObject,
            "timestamp": timestamp.absoluteTime,
        ]
        let json = try JSONSerialization.data(withJSONObject: metadata, options: JSONSerialization.WritingOptions())
        try stream.write(value: Int32(networkEndian: Int32(json.count)))
        try stream.write(data: json)
        try stream.write(value: Int32(networkEndian: Int32(data.count)))
        try stream.write(data: data)
    }
}

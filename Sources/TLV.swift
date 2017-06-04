//
//  TLV.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/7/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

// MARK: -

import SwiftUtilities

public typealias TLVType = BinaryStreamable & Equatable & EndianConvertable
public typealias TLVlength = BinaryStreamable & UnsignedInteger & EndianConvertable

public struct TLVRecord <Type: TLVType, Length: TLVlength> {
    public let type: Type
    public let data: DispatchData 

    public init(type: Type, data: DispatchData ) {
        self.type = type

        // TODO
//        guard data.length <= Length.max else {
//            throw Error.generic("Data too big")
//        }

        self.data = data
    }
}

// MARK: -

extension TLVRecord: Equatable {
}

public func == <Type, Length> (lhs: TLVRecord <Type, Length>, rhs: TLVRecord <Type, Length>) -> Bool {
    return lhs.type == rhs.type && lhs.data == rhs.data
}

// MARK: -

extension TLVRecord: BinaryInputStreamable {
    public static func readFrom(_ stream: BinaryInputStream) throws -> TLVRecord {
        let type: Type = try stream.read()
        let length: Length = try stream.read()
        let data: DispatchData = try stream.readData(count: Int(length.toUIntMax()))
        let record = TLVRecord(type: type, data: data)
        return record
     }
}

// MARK: -

extension TLVRecord: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try stream.write(value: type)
        let length = Length(UIntMax(data.count.toEndianness(stream.endianness)))

        // TODO
//        guard length <= Length.max else {
//            throw Error.generic("Data too big")
//        }

        try stream.write(value: length)
        try stream.write(data: data)
    }
}


// MARK: -

public extension TLVRecord {
    func toDispatchData(_ endianness: Endianness) throws -> DispatchData {
        let length = Length(UIntMax(self.data.count))
        let data = DispatchData ()
            + DispatchData (value: type.toEndianness(endianness))
            + DispatchData (value: length.toEndianness(endianness))
            + self.data
        return data
    }
}

// MARK: -

public extension TLVRecord {
    static func read(_ data: DispatchData , endianness: Endianness) throws -> (TLVRecord?, DispatchData ) {
        // If we don't have enough data to read the TLV header exit
        if data.count < (MemoryLayout<Type>.size + MemoryLayout<Length>.size) {
            return (nil, data)
        }
        return try data.split() {
            (type: Type, remaining: DispatchData) in
            // Convert the type from endianness
            let type = type.fromEndianness(endianness)
            return try remaining.split() {
                (length: Length, remaining: DispatchData) in
                // Convert the length from endianness
                let length = Int(length.fromEndianness(endianness).toIntMax())
                // If we don't have enough remaining data to read the payload: exit.
                if remaining.count < length {
                    return (nil, data)
                }
                // Get the payload.
                return try remaining.split(to: length) {
                    (payload, remaining) in
                    // Produce a record.
                    let record = TLVRecord(type: type.fromEndianness(endianness), data: payload)
                    return (record, remaining)
                }
            }
        }
    }

    static func readMultiple(_ data: DispatchData , endianness: Endianness) throws -> ([TLVRecord], DispatchData ) {
        var records: [TLVRecord] = []
        var data = data
        while true {
            let (maybeRecord, remainingData) = try read(data, endianness: endianness)
            guard let record = maybeRecord else {
                break
            }
            records.append(record)
            data = remainingData
        }
        return (records, data)
    }
}


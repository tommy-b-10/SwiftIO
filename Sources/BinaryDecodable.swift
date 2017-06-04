//
//  BinaryDecoding.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 6/25/15.
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

public protocol BinaryDecodable {
    static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> Self
}

// MARK: -

private func decode <T> (_ buffer: UnsafeBufferPointer <UInt8>) throws -> T {
    guard buffer.count >= MemoryLayout<T>.size else {
        throw Error.generic("Not enough bytes \(buffer.count) for \(T.self) decoding \(MemoryLayout<T>.size).")
    }
    guard let baseAddress = buffer.baseAddress else {
        throw Error.generic("Not enough bytes for \(T.self) decoding.")
    }
    return baseAddress.withMemoryRebound(to: T.self, capacity: MemoryLayout<T>.size) {
        pointer in
        let value = pointer.pointee
        return value
    }
}

// MARK: -

extension Int: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> Int {
        let value: Int = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

extension Int8: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> Int8 {
        let value: Int8 = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

extension Int16: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> Int16 {
        let value: Int16 = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

extension Int32: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> Int32 {
        let value: Int32 = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

extension Int64: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> Int64 {
        let value: Int64 = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

// MARK: -

extension UInt: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> UInt {
        let value: UInt = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

extension UInt8: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> UInt8 {
        let value: UInt8 = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

extension UInt16: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> UInt16 {
        let value: UInt16 = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

extension UInt32: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> UInt32 {
        let value: UInt32 = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

extension UInt64: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> UInt64 {
        let value: UInt64 = try SwiftIO.decode(buffer)
        return value.fromEndianness(endianness)
    }
}

// MARK: -

extension Float: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> Float {
        let value: UInt32 = try SwiftIO.decode(buffer)
        return unsafeBitCast(value.fromEndianness(endianness), to: Float.self)
    }
}

extension Double: BinaryDecodable {
    public static func decode(_ buffer: UnsafeBufferPointer <UInt8>, endianness: Endianness) throws -> Double {
        let value: UInt64 = try SwiftIO.decode(buffer)
        return unsafeBitCast(value.fromEndianness(endianness), to: Double.self)
    }
}

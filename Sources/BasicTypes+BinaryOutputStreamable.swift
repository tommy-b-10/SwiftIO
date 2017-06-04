//
//  IntegerType+BinaryOutputStreamable.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/5/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import SwiftUtilities

private func write <T: EndianConvertable> (stream: BinaryOutputStream, value: T) throws {
    var value = value.toEndianness(stream.endianness)
    try withUnsafePointer(to: &value) {
        (pointer: UnsafePointer <T>) in

        try pointer.withReboundBuffer(to: UInt8.self, capacity: MemoryLayout<T>.size) {
            buffer in
            try stream.write(buffer: buffer)
        }
    }
}

// MARK: -

extension Int: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

extension Int8: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

extension Int16: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

extension Int32: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

extension Int64: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

// MARK: -

extension UInt: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

extension UInt8: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

extension UInt16: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

extension UInt32: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

extension UInt64: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try write(stream: stream, value: self)
    }
}

// MARK: -

extension Float: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        let bitValue = unsafeBitCast(self, to: UInt32.self)
        try write(stream: stream, value: bitValue)
    }
}

extension Double: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        let bitValue = unsafeBitCast(self, to: UInt64.self)
        try write(stream: stream, value: bitValue)
    }
}

//
//  BinaryOutputStreams.swift
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

// MARK: BinaryOutputStream

public protocol BinaryOutputStream {
    var endianness: Endianness { get }
    func write(buffer: UnsafeBufferPointer <UInt8>) throws
}

// MARK: BinaryOutputStreamable

public protocol BinaryOutputStreamable {
    func writeTo(stream: BinaryOutputStream) throws
}

public extension BinaryOutputStream {
    func write(value: BinaryOutputStreamable) throws {
        try value.writeTo(stream: self)
    }
}

// MARK: -

public extension BinaryOutputStream {
    func write(data: Data) throws {
        try data.withUnsafeBuffer() {
            (buffer: UnsafeBufferPointer <UInt8>) in

            try write(buffer: buffer)
        }
    }

    func write(data: DispatchData) throws {
        try data.withUnsafeBuffer() {
            (buffer: UnsafeBufferPointer <UInt8>) in

            try write(buffer: buffer)
        }
    }
}

extension DispatchData: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try apply() {
            (range, buffer) in
            try stream.write(buffer: buffer)
            return true
        }
    }
}

//// MARK: -

extension Data: BinaryOutputStreamable {
    public func writeTo(stream: BinaryOutputStream) throws {
        try withUnsafeBytes() {
            (pointer: UnsafePointer <UInt8>) -> Void in

            let buffer = UnsafeBufferPointer <UInt8> (start: pointer, count: count)
            try stream.write(buffer: buffer)
        }

    }
}

//// MARK: -

public extension BinaryOutputStream {
    func write(string: String, appendNewline: Bool = false) throws {
        let string = appendNewline == true ? string : string + "\n"
        let data = string.data(using: String.Encoding.utf8)!
        try write(data: data)
    }
}

// MARK: -

public extension BinaryOutputStream {
    func write <T: UnsignedInteger> (value: T) throws {
        var copy: T = value
        try withUnsafePointer(to: &copy) {
            (ptr: UnsafePointer <T>) -> Void in

            try ptr.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
                ptr in

                let buffer = UnsafeBufferPointer <UInt8> (start: ptr, count: MemoryLayout<T>.size)
                try write(buffer: buffer)
            }
        }
    }
}

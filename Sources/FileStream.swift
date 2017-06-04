//
//  FileStream.swift
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

public struct Mode: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let read = Mode(rawValue: 1)
    public static let write = Mode(rawValue: 2)
    public static let readWrite = Mode(rawValue: read.rawValue | write.rawValue)

    public func oflags() -> Int32 {
        switch rawValue {
            case Mode.read.rawValue:
                return O_RDONLY
            case Mode.write.rawValue:
                return O_WRONLY
            case Mode.readWrite.rawValue:
                return O_RDWR
            default:
                preconditionFailure("Invalid flags")
        }
    }
}

// MARK: -

public class FileStream {

    public let endianness = Endianness.Native

    public let url: URL
    public internal(set) var isOpen: Bool = false
    public internal(set) var fd: Int32! // TODO: Replace with Socket() or make FileDescriptor type?

    public init(url: URL) {
        self.url = url
    }

    deinit {
        if isOpen == true {
            tryElseFatalError() {
                try close()
            }
        }
    }

    public func open(mode: Mode = Mode.read, append: Bool = false, create: Bool = false) throws {

        guard isOpen == false else {
            throw Error.generic("File already open.")
        }

        var flags: Int32 = mode.oflags()
        if (mode.rawValue & Mode.write.rawValue) != 0 {
            flags |= (append ? O_APPEND : 0) | (create ? O_CREAT : 0)
        }

        let fd = Darwin.open(url.path, flags, 0o644)
        guard fd > 0 else {
            throw Errno(rawValue: errno) ?? Error.unknown
        }

        isOpen = true
        self.fd = fd
    }

    public func close() throws {
        guard isOpen == true else {
            throw Error.generic("File already closed.")
        }

        let result = Darwin.close(fd)
        fd = nil
        if result != 0 {
            throw Errno(rawValue: result) ?? Error.unknown
        }
    }
}

// MARK: -

extension FileStream: BinaryInputStream {

    public func readData(count: Int) throws -> DispatchData {
        guard isOpen == true else {
            throw Error.generic("Stream not open")
        }

        if count <= 0 {
            throw Error.generic("Does not support nil length yet")
        }

        var data = Data(count: count)

        let result = data.withUnsafeMutableBytes() {
            (pointer: UnsafeMutablePointer <UInt8>) in

            return Darwin.read(fd, pointer, count)
        }
        if result < 0 {
            throw Errno(rawValue: errno) ?? Error.unknown
        }

        data.count = result

        return DispatchData(data: data)

    }

    public func readData() throws -> DispatchData {
        unimplementedFailure()
    }

}

// MARK: -

extension FileStream: BinaryOutputStream {

    public func write(buffer: UnsafeBufferPointer <UInt8>) throws {

        guard isOpen == true else {
            throw Error.generic("Stream not open")
        }

        let result = Darwin.write(fd, buffer.baseAddress, buffer.count)
        if result < 0 {
            throw Errno(rawValue: errno) ?? Error.unknown
        }
    }
}

// MARK: -

extension FileStream: RandomAccess {
    public func tell() throws -> Int {
        return Int(lseek(fd, 0, Int32(Whence.current.rawValue)))
    }

    public func seek(offset: Int, whence: Whence = .set) throws {
        lseek(fd, off_t(offset), Int32(whence.rawValue))
    }
}

extension FileStream: RandomAccessInput {
    public func read(offset: Int, count: Int) throws -> DispatchData {
        try seek(offset: offset)
        return try readData(count: count)
    }
}

extension FileStream: RandomAccessOutput {
    public func write(offset: Int, buffer: UnsafeBufferPointer <UInt8>) throws {
        try seek(offset: offset)
        try write(buffer: buffer)
    }
}

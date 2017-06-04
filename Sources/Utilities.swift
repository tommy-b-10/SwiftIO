//
//  Utilities.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 1/10/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Darwin

internal extension timeval {
    init(time: TimeInterval) {
        tv_sec = __darwin_time_t(time)
        tv_usec = __darwin_suseconds_t((time - floor(time)) * TimeInterval(USEC_PER_SEC))
    }

    var timeInterval: TimeInterval {
        return TimeInterval(tv_sec) + TimeInterval(tv_usec) / TimeInterval(USEC_PER_SEC)
    }
}

internal extension timeval64 {
    init(time: TimeInterval) {
        tv_sec = __int64_t(time)
        tv_usec = __int64_t((time - floor(time)) * TimeInterval(USEC_PER_SEC))
    }

    var timeInterval: TimeInterval {
        return TimeInterval(tv_sec) + TimeInterval(tv_usec) / TimeInterval(USEC_PER_SEC)
    }

}

internal func unsafeCopy <DST, SRC> (destination: UnsafeMutablePointer <DST>, source: UnsafePointer <SRC>) {
    let length = min(MemoryLayout<DST>.size, MemoryLayout<SRC>.size)
    unsafeCopy(destination: destination, source: source, length: length)
}

internal func unsafeCopy <DST> (destination: UnsafeMutablePointer <DST>, source: UnsafeRawPointer, length: Int) {
    precondition(MemoryLayout<DST>.size >= length)
    memcpy(destination, source, length)
}

// TODO: Swift3 - move to SwiftUtilities.

extension DispatchData: Equatable {
}


public func == (lhs: DispatchData, rhs: DispatchData) -> Bool {
    // TODO: Swift3 - might be quicker just to get the data and memcmp it

//    return zip(lhs, rhs).first(where: { $0 != $1 }) == nil


    if lhs.count != rhs.count {
        return false
    }

    let count = lhs.count

    return lhs.withUnsafeBytes() {
        (lhs: UnsafePointer <UInt8>) in

        return rhs.withUnsafeBytes() {
            (rhs: UnsafePointer <UInt8>) in

            return memcmp(lhs, rhs, count) == 0
        }
    }


}

// TODO: Swift3 - move to SwiftUtilities.

public extension DispatchData {

    // TODO: Deprecate
    init() {
        self = DispatchData.empty
    }

    init?(string: String) {
        // TODO: pass in encoding
        if let data = string.data(using: .utf8) {
            self = DispatchData(data: data)
        }
        else {
            return nil
        }
    }

    init <T> (value: T) {
        var copy = value
        self = withUnsafePointer(to: &copy) {
            return $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
                let buffer = UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size)
                return DispatchData(bytes: buffer)
            }
        }
    }

    init(data: Data) {
        self = data.withUnsafeBytes() {
            (pointer: UnsafePointer <UInt8>) in

            let buffer = UnsafeBufferPointer(start: pointer, count: data.count)
            return DispatchData(bytes: buffer)
        }
    }

    func apply(_ block: (Range <Int>, UnsafeBufferPointer <UInt8>) throws -> Bool) throws {
        var savedError: Swift.Error?

        enumerateBytes() {
            (buffer, offset, finish: inout Bool) in

            let range = Range(offset..<(offset + buffer.count))

            do {
                if try block(range, buffer) == false {
                    finish = true
                }
            }
            catch let error {
                savedError = error

                finish = true
            }
        }

        if let savedError = savedError {
            throw savedError
        }
    }

    func split(to: Int) -> (DispatchData, DispatchData) {
        let lhs = subdata(in: 0..<to)
        let rhs = subdata(in: to..<endIndex)
        return (lhs, rhs)
    }

    func split<T>() -> (T, DispatchData) {
        let (lhs, rhs) = split(to: MemoryLayout<T>.size)
        let value = lhs.withUnsafeBytes() {
            (pointer: UnsafePointer <T>) in

            return pointer.pointee
        }
        return (value, rhs)
    }

    // TODO: This split variant is only useful for SwiftIO i think?
    func split<T, R>(_ body: (T, DispatchData) throws -> R) rethrows -> R {
        let (lhs, rhs) = split(to: MemoryLayout<T>.size)
        let value = lhs.withUnsafeBytes() {
            (pointer: UnsafePointer <T>) in

            return pointer.pointee
        }
        return try body(value, rhs)
    }

    func split <R> (to: Int, body: (DispatchData, DispatchData) throws -> R) throws -> R {
        let lhs = subdata(in: 0..<to)
        let rhs = subdata(in: to..<endIndex)
        return try body(lhs, rhs)
    }
}

public func + (lhs: DispatchData, rhs: DispatchData) -> DispatchData {
    var result = lhs
    result.append(rhs)
    return result
}

public extension Data {
    init(dispatchData: DispatchData) {
        self = dispatchData.withUnsafeBytes() {
            (pointer: UnsafePointer <UInt8>) in
            return Data(bytes: pointer, count: dispatchData.count)
        }
    }
}

// TODO: Swift3
//public extension DispatchData {
//    func withUnsafeBytes<Result>(body: (UnsafeRawPointer) throws -> Result) rethrows -> Result {
//        fatalError()
//    }
//}

public extension UnsafePointer {
    func withReboundBuffer<T, Result>(to: T.Type, capacity count: Int, _ body: (UnsafeBufferPointer<T>) throws -> Result) rethrows -> Result {
        return try withMemoryRebound(to: T.self, capacity: count) {
            (pointer) in

            let buffer = UnsafeBufferPointer <T> (start: pointer, count: count)
            return try body(buffer)
        }
    }
}

public extension Data {
    func withUnsafeBuffer<ResultType, ContentType>(_ body: (UnsafeBufferPointer<ContentType>) throws -> ResultType) rethrows -> ResultType {
        return try withUnsafeBytes() {
            (pointer: UnsafePointer <ContentType>) in

            // TODO: Swift3
            precondition(MemoryLayout<ContentType>.size > 0)
            let bufferCount = count / MemoryLayout<ContentType>.size
            let buffer = UnsafeBufferPointer <ContentType> (start: pointer, count: bufferCount)
            return try body(buffer)
        }
    }
}

public extension DispatchData {
    func withUnsafeBuffer<ResultType, ContentType>(_ body: (UnsafeBufferPointer<ContentType>) throws -> ResultType) rethrows -> ResultType {
        return try withUnsafeBytes() {
            (pointer: UnsafePointer <ContentType>) in

            // TODO: Swift3
            precondition(MemoryLayout<ContentType>.size > 0)
            let bufferCount = count / MemoryLayout<ContentType>.size
            let buffer = UnsafeBufferPointer <ContentType> (start: pointer, count: bufferCount)
            return try body(buffer)
        }
    }
}

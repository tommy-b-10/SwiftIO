//
//  StreamTests.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/29/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import XCTest

import SwiftIO
import SwiftUtilities

class StreamTests: XCTestCase {
    func testNative() {
        try! readWriteValue(Int(100))
        try! readWriteValue(Int16(100))
        try! readWriteValue(Int32(100))
        try! readWriteValue(Int64(100))
        try! readWriteValue(UInt(100))
        try! readWriteValue(UInt16(100))
        try! readWriteValue(UInt32(100))
        try! readWriteValue(UInt64(100))
        try! readWriteValue(Float(100))
        try! readWriteValue(Double(100))
    }

    func testBig() {
        try! readWriteValue(Int(100), endianness: .big)
        try! readWriteValue(Int16(100), endianness: .big)
        try! readWriteValue(Int32(100), endianness: .big)
        try! readWriteValue(Int64(100), endianness: .big)
        try! readWriteValue(UInt(100), endianness: .big)
        try! readWriteValue(UInt16(100), endianness: .big)
        try! readWriteValue(UInt32(100), endianness: .big)
        try! readWriteValue(UInt64(100), endianness: .big)
        try! readWriteValue(Float(100), endianness: .big)
        try! readWriteValue(Double(100), endianness: .big)
    }

    func testLittle() {
        try! readWriteValue(Int(100), endianness: .little)
        try! readWriteValue(Int16(100), endianness: .little)
        try! readWriteValue(Int32(100), endianness: .little)
        try! readWriteValue(Int64(100), endianness: .little)
        try! readWriteValue(UInt(100), endianness: .little)
        try! readWriteValue(UInt16(100), endianness: .little)
        try! readWriteValue(UInt32(100), endianness: .little)
        try! readWriteValue(UInt64(100), endianness: .little)
        try! readWriteValue(Float(100), endianness: .little)
        try! readWriteValue(Double(100), endianness: .little)
    }
}

func readWriteValue <T: BinaryStreamable> (_ value: T, endianness: Endianness = .Native) throws where T: Equatable {
    let stream = MemoryStream()
    stream.endianness = endianness
    try stream.write(value: value)
    stream.rewind()
    let newValue: T = try stream.read()
    XCTAssertEqual(value, newValue)
}

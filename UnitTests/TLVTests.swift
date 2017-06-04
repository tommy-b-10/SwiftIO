//
//  TLVTests.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/7/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import XCTest

import SwiftIO
import SwiftUtilities


class TLVTests: XCTestCase {

    func testReadWrite16Native() throws {
        typealias RecordType = TLVRecord <UInt16, UInt16>
        let data = DispatchData(string: "Hello world")!
        let memory = MemoryStream()
        let original = RecordType(type: 100, data: data)
        try memory.write(value: original)
        let record: RecordType = try memory.read()
        XCTAssertEqual(record, original)
    }

    // TODO: Failing
//    func testReadWrite16Big() throws {
//        typealias RecordType = TLVRecord <UInt16, UInt16>
//        let data = DispatchData(string: "Hello world")!
//        let memory = MemoryStream()
//        memory.endianness = .big
//        let original = RecordType(type: 100, data: data)
//        try memory.write(value: original)
//        let record: RecordType = try memory.read()
//        XCTAssertEqual(record, original)
//    }

    func testReadWrite32Big() throws {
        typealias RecordType = TLVRecord <UInt32, UInt32>
        let data = DispatchData(string: "Hello world")!
        let memory = MemoryStream()
        let original = RecordType(type: 100, data: data)
        try memory.write(value: original)
        let record: RecordType = try memory.read()
        XCTAssertEqual(record, original)
    }

    func testMultipleFrames() {

        typealias RecordType = TLVRecord <UInt16, UInt16>
        let memory = MemoryStream()

        for _ in 0..<2 {
            let data = DispatchData(string: "Hello world")
            let original = RecordType(type: 100, data: data!)
            try! memory.write(value: original)
        }

        let data = memory.data

        let (records, _) = try! RecordType.readMultiple(data, endianness: .Native)

        // TODO: Actually test the data here!
    }

    func testDispatchDataSplit() {
        
        let data = DispatchData(string: "Hello world")!
        
        let splitdata = data.split(to: 5)
        XCTAssert(data.count == 11)
        XCTAssert(splitdata.0.count == 5)
        XCTAssert(splitdata.1.count == 6)
    }
}

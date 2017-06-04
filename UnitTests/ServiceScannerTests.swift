//
//  ServiceScannerTests.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 5/16/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import XCTest

@testable import SwiftIO

class ServiceScannerTests: XCTestCase {
    
    func testIPV4Address1() {
        let scanner = Scanner(string: "255.255.255.255")
        var address: String?
        let result = scanner.scanIPV4Address(&address)
        XCTAssertTrue(result)
        XCTAssertTrue(scanner.isAtEnd)
        XCTAssertEqual(address, "255.255.255.255")
    }
    
    func testIPV4Address2() {
        let scanner = Scanner(string: "X.255.255.255")
        var address: String?
        let result = scanner.scanIPV4Address(&address)
        XCTAssertFalse(result)
        XCTAssertNil(address)
    }

    func testDomain() {
        let scanner = Scanner(string: "test-domain.apple.com")
        var address: String?
        let result = scanner.scanDomain(&address)
        XCTAssertTrue(result)
        XCTAssertTrue(scanner.isAtEnd)
        XCTAssertEqual(address, "test-domain.apple.com")
    }

    func testDomainLocal() {
        let scanner = Scanner(string: "domain.local.")
        var address: String?
        let result = scanner.scanDomain(&address)
        XCTAssertTrue(result)
        XCTAssertTrue(scanner.isAtEnd)
        XCTAssertEqual(address, "domain.local.")
    }

    func testDomainBad() {
        let scanner = Scanner(string: ".apple.com")
        var address: String?
        let result = scanner.scanDomain(&address)
        XCTAssertFalse(result)
        XCTAssertNil(address)
    }

    func testScanAddressGood() {
        let inputs:[(String, String?, String?)] = [
            ("[::ffff:0.0.0.0]:14550", "::ffff:0.0.0.0", "14550"),
            ("[::ffff:0.0.0.0]", "::ffff:0.0.0.0", nil),
            ("0.0.0.0:14550", "0.0.0.0", "14550"),
            ("0.0.0.0", "0.0.0.0", nil),
            ("localhost", "localhost", nil),
//            ("localhost:14550", "localhost", "14550"),
        ]

        for input in inputs {
            var address: String?
            var port: String?
            let result = scanAddress(input.0, address: &address, service: &port)

            XCTAssertTrue(result)
            XCTAssertEqual(address, input.1)
            XCTAssertEqual(port, input.2)
        }
    }
    
    func testScanAddressBad() {
        let inputs = [
            "::ffff:0.0.0.0",
        ]

        for input in inputs {
            var address: String? = nil
            var port: String? = nil
            let result = scanAddress(input, address: &address, service: &port)
            
            XCTAssertFalse(result)
            XCTAssertNil(address)
            XCTAssertNil(port)
        }
    }
    
}




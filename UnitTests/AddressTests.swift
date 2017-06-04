//
//  AddressTests.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 8/8/15.
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


import XCTest

@testable import SwiftIO

class AddressTests: XCTestCase {

    func testInterfaces() {
        let addresses = try! Address.addressesForInterfaces()["lo0"]![0] // TODO: a bit crap
        XCTAssertEqual(addresses.address, "127.0.0.1")
    }

    func testIPV4Address() {

        let address = try! Address(address: "127.0.0.1", port: 1234)
        XCTAssertEqual(address.address, "127.0.0.1")
        XCTAssertEqual(String(describing: address), "127.0.0.1:1234")
        XCTAssertEqual(address.port, 1234)
        XCTAssertEqual(address.family, ProtocolFamily.inet)

        let addr = address.to_in_addr()!
        XCTAssertEqual(addr.s_addr, UInt32(0x7F000001).networkEndian)

        let octets = address.to_in_addr()!.octets
        XCTAssertEqual(octets.0, 0x7f)
        XCTAssertEqual(octets.1, 0x00)
        XCTAssertEqual(octets.2, 0x00)
        XCTAssertEqual(octets.3, 0x01)

//        let other = Address(addr: sockaddrIPV4.sin_addr, port: address.port)
//        XCTAssertEqual(address, other)
//        XCTAssertFalse(address < other)
    }

    func testStringBasedAddress() {
        XCTAssertEqual(String(describing: try! Address(address: "127.0.0.1")), "127.0.0.1")
        XCTAssertEqual(String(describing: try! Address(address: "127.0.0.1:80")), "127.0.0.1:80")
        XCTAssertEqual(String(describing: try! Address(address: "[::]")), "[::]")
        XCTAssertEqual(String(describing: try! Address(address: "[::]:80")), "[::]:80")
        XCTAssertEqual(String(describing: try! Address(address: "[::1]")), "[::1]")
        XCTAssertEqual(String(describing: try! Address(address: "[::1]:80")), "[::1]:80")
        XCTAssertEqual(String(describing: try! Address(address: "[2607:f8b0:4007:803:700::]")), "[2607:f8b0:4007:803:700::]")
        XCTAssertEqual(String(describing: try! Address(address: "[2607:f8b0:4007:803:700::]:80")), "[2607:f8b0:4007:803:700::]:80")


        // TODO: Those do a name lookup
        XCTAssertEqual(String(describing: try! Address(address: "localhost")), "127.0.0.1")
        XCTAssertEqual(String(describing: try! Address(address: "localhost:80")), "127.0.0.1:80")
        XCTAssertEqual(String(describing: try! Address(address: "apple.com")), "17.142.160.59")
        XCTAssertEqual(String(describing: try! Address(address: "apple.com:80")), "17.142.160.59:80")
    }


}



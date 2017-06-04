//
//  Address+Interfaces.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 3/18/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Darwin

public extension Address {
    static func addressesForInterfaces() throws -> [String: [Address]] {
        let addressesForInterfaces = getAddressesForInterfaces() as! [String: [Data]]
        let pairs: [(String, [Address])] = addressesForInterfaces.flatMap() {
            (interface, addressData) -> (String, [Address])? in

            if addressData.count == 0 {
                return nil
            }
            let addresses = addressData.map() {
                (addressData: Data) -> Address in
                let addr = sockaddr_storage(addr: (addressData as NSData).bytes.bindMemory(to: sockaddr.self, capacity: addressData.count), length: addressData.count)
                let address = Address(sockaddr: addr)
                return address
            }
            return (interface, addresses.sorted(by: <))
        }
        return Dictionary <String, [Address]> (pairs)
    }
}

// MARK: -


private extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
}

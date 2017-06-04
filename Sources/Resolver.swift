//
//  Resolver.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 3/18/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import SwiftUtilities

class Resolver {

    static let sharedInstance = Resolver()

    var lock = NSLock()
    var staticNames: [String: [Address]] = [:]
    var cache: [String: [Address]] = [:]
    let queue = DispatchQueue(label: "io.schwa.SwiftIO.Resolver", attributes: [])

    func addressesForName(_ name: String) throws -> [Address]? {
        return lock.with() {
            if let addresses = staticNames[name] {
                return addresses
            }
            return nil
        }
    }

    func addressesForName(_ name: String, callback: @escaping (Result <[Address]>) -> Void) {
        let found: Bool = lock.with() {
            if let addresses = staticNames[name] {
                callback(.success(addresses))
                return true
            }
            if let addresses = cache[name] {
                callback(.success(addresses))
                return true
            }
            return false
        }
        if found {
            return
        }
        queue.async {
            [weak self] in

            guard let strong_self = self else {
                return
            }
            let result = tryGivingResult() {
                () -> [Address] in
                var hints = addrinfo()
                hints.ai_flags = AI_ALL | AI_V4MAPPED
                let addresses = try getaddrinfo(hostname: name, service: "", hints: hints)
                strong_self.lock.with() {
                    strong_self.cache[name] = addresses
                }
                return addresses
            }
            callback(result)
        }
    }

}

// MARK: -

extension Resolver {

    func readHosts() throws {
//        let path = NSBundle.mainBundle().pathForResource("hosts", ofType: nil)!
        let path = "/etc/hosts"
        let hostsFile = try String(contentsOfFile: path)
        let items = hostsFile.components(separatedBy: CharacterSet.newlines)
//            .lazy // lazy takes compile time from 234.3ms to 8498.7ms
            // Filter out empty lines
            .filter() { $0.isEmpty == false }
            // Trim whitespace
            .map() { $0.trimWhitespace() }
            // Remove comments
            .filter() { $0.hasPrefix("#") == false }
            // Break into runs of non-whitespace
            .map() { $0.components(separatedBy: CharacterSet.whitespaces).filter() { $0.isEmpty == false } }

        var staticNames: [String: [Address]] = [:]
        try items.forEach() {
            components in
            let address = components[0]
            for name in components.dropFirst() {
                staticNames[name] = (staticNames[name] ?? []) + [try Address(address: address)]
            }
        }

        lock.with() {
            self.staticNames = staticNames
        }
    }
}

// MARK: -

private extension String {
    func trimWhitespace() -> String {
        return trimmingCharacters(in: CharacterSet.whitespaces)
    }
}


// TODO: Move to swiftutilities
private func tryGivingResult <R>(_ closure: () throws -> R) -> Result <R> {
    do {
        let value = try closure()
        return .success(value)
    }
    catch let error {
        return .failure(error)
    }

}

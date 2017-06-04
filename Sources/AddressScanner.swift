//
//  AddressScanner.swift
//  Addresses
//
//  Created by Jonathan Wight on 5/16/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Foundation

// MARK: -

internal func + (lhs: CharacterSet, rhs: CharacterSet) -> CharacterSet {
    let scratch = (lhs as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
    scratch.formUnion(with: rhs)
    return scratch as CharacterSet
}

internal extension CharacterSet {

    static func asciiLetterCharacterSet() -> CharacterSet {
        return asciiLowercaseLetterCharacterSet() + asciiUppercaseLetterCharacterSet()
    }

    static func asciiLowercaseLetterCharacterSet() -> CharacterSet {
        return CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")
    }

    static func asciiUppercaseLetterCharacterSet() -> CharacterSet {
        return CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    }

    static func asciiDecimalDigitsCharacterSet() -> CharacterSet {
        return CharacterSet(charactersIn: "0123456789")
    }

    static func asciiAlphanumericCharacterSet() -> CharacterSet {
        return asciiLetterCharacterSet() + asciiDecimalDigitsCharacterSet()
    }

    static func asciiHexDigitsCharacterSet() -> CharacterSet {
        return asciiDecimalDigitsCharacterSet() + CharacterSet(charactersIn: "ABCDEFabcdef")
    }
}

// MARK: -

internal extension Scanner {

    var remaining: String {
        return (string as NSString).substring(from: scanLocation)
    }

    func with(_ closure: () -> Bool) -> Bool {
        let savedCharactersToBeSkipped = charactersToBeSkipped
        let savedLocation = scanLocation
        let result = closure()
        if result == false {
            scanLocation = savedLocation
        }
        charactersToBeSkipped = savedCharactersToBeSkipped
        return result
    }

    func scanString(_ string: String) -> Bool {
        return scanString(string, into: nil)
    }

    func scanBracketedString(_ openBracket: String, closeBracket: String, intoString: inout String?) -> Bool {
        return with() {
            if scanString(openBracket) == false {
                return false
            }
            var temp: NSString?
            if scanUpTo(closeBracket, into: &temp) == false {
                return false
            }
            if scanString(closeBracket) == false {
                return false
            }
            intoString = temp! as String
            return true
        }
    }

    func scan(_ intoString: inout String?, closure: () -> Bool) -> Bool {
        let savedCharactersToBeSkipped = charactersToBeSkipped
        defer {
            charactersToBeSkipped = savedCharactersToBeSkipped
        }
        let savedLocation = scanLocation
        if closure() == false {
            scanLocation = savedLocation
            return false
        }
        let range = NSRange(location: savedLocation, length: scanLocation - savedLocation)
        intoString = (string as NSString).substring(with: range)
        return true
    }

}

// MARK: -

internal extension Scanner {
    func scanIPV6Address(_ intoString: inout String?) -> Bool {
        return with() {
            charactersToBeSkipped = nil
            let characterSet = CharacterSet.asciiHexDigitsCharacterSet() + CharacterSet(charactersIn: ":.")
            var temp: NSString?
            if scanCharacters(from: characterSet, into: &temp) == false {
                return false
            }
            intoString = temp! as String
            return true
        }
    }

    func scanIPV4Address(_ intoString: inout String?) -> Bool {
        return with() {
            charactersToBeSkipped = nil
            let characterSet = CharacterSet.asciiDecimalDigitsCharacterSet() + CharacterSet(charactersIn: ".")
            var temp: NSString?
            if scanCharacters(from: characterSet, into: &temp) == false {
                return false
            }
            intoString = temp! as String
            return true
        }
    }

    /// Scan a "domain". Domain is considered a sequence of hostnames seperated by dots.
    func scanDomain(_ intoString: inout String?) -> Bool {
        let savedLocation = scanLocation
        while true {
            var hostname: String?
            if scanHostname(&hostname) == false {
                break
            }
            if scanString(".") == false {
                break
            }
        }
        let range = NSRange(location: savedLocation, length: scanLocation - savedLocation)
        if range.length == 0 {
            return false
        }
        intoString = (string as NSString).substring(with: range)
        return true
    }

    /// Scan a "hostname".
    func scanHostname(_ intoString: inout String?) -> Bool {
        return with() {
            var output = ""
            var temp: NSString?
            if scanCharacters(from: CharacterSet.asciiAlphanumericCharacterSet(), into: &temp) == false {
                return false
            }
            output += temp! as String
            if scanCharacters(from: CharacterSet.asciiAlphanumericCharacterSet() + CharacterSet(charactersIn: "-"), into: &temp) == true {
                output += temp! as String
            }
            intoString = output
            return true
        }
    }

    /// Scan a port/service name. For purposes of this we consider this any alphanumeric sequence and rely on getaddrinfo
    func scanPort(_ intoString: inout String?) -> Bool {
        let characterSet = CharacterSet.asciiAlphanumericCharacterSet() + CharacterSet(charactersIn: "-")
        var temp: NSString?
        if scanCharacters(from: characterSet, into: &temp) == false {
            return false
        }
        intoString = temp! as String
        return true
    }

    /// Scan an address into a hostname and a port. Very crude. Rely on getaddrinfo.
    func scanAddress(_ address: inout String?, port: inout String?) -> Bool {
        var string: String?

        if scanBracketedString("[", closeBracket: "]", intoString: &string) == true {
            let scanner = Scanner(string: string!)
            if scanner.scanIPV6Address(&address) == false {
                return false
            }
            if scanner.isAtEnd == false {
                return false
            }

        }
        else if scanIPV4Address(&address) == true {
            // Nothing to do here
        }
        else if scanDomain(&address) == true {
            // Nothing to do here
        }

        if scanString(":") {
            _ = scanPort(&port)
        }
        return true
    }
}

// MARK: -

public func scanAddress(_ string: String, address: inout String?, service: inout String?) -> Bool {
    let scanner = Scanner(string: string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
    scanner.charactersToBeSkipped = nil
    var result = scanner.scanAddress(&address, port: &service)
    if scanner.isAtEnd == false {
        result = false
    }
    if result == false {
        address = nil
        service = nil
    }
    return result
}


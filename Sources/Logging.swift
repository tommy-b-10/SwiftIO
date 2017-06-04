//
//  Logging.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 9/29/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

public var logHandler: ((Any?) -> Void)? = nil

public class Logger {
    public func debug(_ subject: Any?) {
        logHandler?(subject)
    }
}

public let log: Logger? = Logger()

internal func loggingReadHandler(_ datagram: Datagram) {
    log?.debug(String(describing: datagram))
}

internal func loggingErrorHandler(_ error: Error) {
    log?.debug("ERROR: \(error)")
}

internal func loggingWriteHandler(_ success: Bool, error: Error?) {
    if success {
        log?.debug("WRITE")
    }
    else {
        loggingErrorHandler(error!)
    }
}

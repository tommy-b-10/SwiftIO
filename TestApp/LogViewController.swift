//
//  LogViewController.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 1/9/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Cocoa

import SwiftIO

class LogViewController: NSViewController {

    dynamic var logText: String = ""
    @IBOutlet var logTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        SwiftIO.logHandler = self.logHandler

    }

    func logHandler(_ subject: Any?) {
        DispatchQueue.main.async {
            if let subject = subject {
                let message = String(describing: subject)
                self.logText += message + "\n"
            }
            else {
                self.logText += "nil" + "\n"
            }

            self.logTextView.scrollToEndOfDocument(nil)
        }
    }

}

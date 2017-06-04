//
//  TCPServerViewController.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 12/8/15.
//  Copyright © 2015 schwa.io. All rights reserved.
//

import AppKit

import SwiftIO
import SwiftUtilities

class TCPServerViewController: NSViewController {

    let endianness = Endianness.big

    let port: UInt16 = 8888
    var server: TCPServer?

    dynamic var serving: Bool = false

    dynamic var addressString: String? = "0.0.0.0:8888"

}

extension TCPServerViewController {

    func createServer() throws -> TCPServer {

        let address = try Address(address: "0.0.0.0", port: self.port)
        let server = try TCPServer(address: address)

        server.clientWillConnect = {
            (client) in

            log?.debug("clientWillConnect: \(try! client.socket.getPeer())")

            client.readCallback = {
                (result) in

                if case .success(let data) = result {
                    log?.debug("Server Got data: \(String(data: data))")



                    client.write(data) {
                        _ in
                    }
                }
            }
        }
        server.clientDidDisconnect = {
            (client) in

            log?.debug("clientDidDisconnect")
        }
        return server
    }

}


extension TCPServerViewController {

    @IBAction func startStopServer(_ sender: SwitchControl) {
        if sender.on {
            log?.debug("Server start listening")

            let server = try! createServer()
            try! server.startListening()
            self.server = server
            serving = true
        }
        else {
            log?.debug("Server stop listening")
            try! server?.stopListening()
            server = nil
            serving = false
        }
    }

    @IBAction func disconnectAll(_ sender: AnyObject?) {
        try! server?.disconnectAllClients()
    }

}


extension String {
    init?(data: DispatchData, encoding: String.Encoding = String.Encoding.utf8) {
        let nsdata = Data(dispatchData: data)
        if let string = String(data: nsdata, encoding: encoding) {
            self = string
        }
        else {
            return nil
        }
    }
}


class BoxedAddressValueTransformer: ValueTransformer {

    override func transformedValue(_ value: Any?) -> Any? {
        guard let box = value as? Box <Address> else {
            return nil
        }
        let address = box.value
        return String(describing: address)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String else {
            return nil
        }
        guard let address = try? Address(address: string) else {
            return nil
        }
        let box = Box(address)
        return box
    }



}

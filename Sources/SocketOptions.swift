//
//  SocketOptions.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 1/25/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Darwin

import SwiftUtilities

public extension Socket {

    func getsockopt <T>(_ level: Int32, _ name: Int32) throws -> T {

        guard try getsockoptsize(level, name) == MemoryLayout<T>.size else {
            fatalError("Expected size of \(T.self) \(MemoryLayout<T>.size) doesn't match what getsocktopt expects: \(try? getsockoptsize(level, name))")
        }

        let ptr = UnsafeMutablePointer <T>.allocate(capacity: 1)
        defer {
            ptr.deallocate(capacity: 1)
        }
        var length = socklen_t(MemoryLayout<T>.size)
        let result = Darwin.getsockopt(descriptor, level, name, ptr, &length)
        if result != 0 {
            throw Errno(rawValue: errno) ?? Error.unknown
        }
        let value = ptr.pointee
        return value
    }

    func setsockopt <T>(_ level: Int32, _ name: Int32, _ value: T) throws {

        guard try getsockoptsize(level, name) == MemoryLayout<T>.size else {
            fatalError("Expected size of \(T.self) \(MemoryLayout<T>.size) doesn't match what getsocktopt expects: \(try? getsockoptsize(level, name))")
        }

        var value = value
        let result = Darwin.setsockopt(descriptor, level, name, &value, socklen_t(MemoryLayout<T>.size))
        if result != 0 {
            throw Errno(rawValue: errno) ?? Error.unknown
        }
    }

    // Just for bools

    func getsockopt(_ level: Int32, _ name: Int32) throws -> Bool {
        let value: Int32 = try getsockopt(level, name)
        return value != 0
    }

    func setsockopt(_ level: Int32, _ name: Int32, _ value: Bool) throws {
        let value: Int32 = value ? -1 : 0
        try setsockopt(level, name, value)
    }

    // Just for bools

    func getsockopt(_ level: Int32, _ name: Int32) throws -> TimeInterval {
        let value: timeval64 = try getsockopt(level, name)
        return value.timeInterval
    }

    func setsockopt(_ level: Int32, _ name: Int32, _ value: TimeInterval) throws {
        try setsockopt(level, name, timeval64(time: value))
    }

    // Test size of a socket option

    fileprivate func getsockoptsize(_ level: Int32, _ name: Int32) throws -> Int {
        var length = socklen_t(256)
        var buffer = Array <UInt8> (repeating: 0, count: Int(length))
        return try buffer.withUnsafeMutableBufferPointer() {
            (buffer: inout UnsafeMutableBufferPointer<UInt8>) -> Int in
            let result = Darwin.getsockopt(descriptor, level, name, buffer.baseAddress, &length)
            if result != 0 {
                throw Errno(rawValue: errno) ?? Error.unknown
            }
            return Int(length)
        }
    }

}

public extension Socket {

    var socketOptions: SocketOptions {
        return SocketOptions(socket: self)
    }

}

// MARK: -

public class SocketOptions {

    public fileprivate(set) weak var socket: Socket!

    public init(socket: Socket) {
        self.socket = socket
    }

}

// MARK: -

public extension SocketOptions {

    /// turn on debugging info recording
    var debug: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_DEBUG)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_DEBUG, newValue)
        }
    }

    /// socket has had listen()
    var acceptConnection: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_ACCEPTCONN)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_ACCEPTCONN, newValue)
        }
    }

    /// allow local address reuse
    var reuseAddress: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_REUSEADDR)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_REUSEADDR, newValue)
        }
    }

    /// keep connections alive
    var keepAlive: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_KEEPALIVE)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_KEEPALIVE, newValue)
        }
    }

    /// just use interface addresses
    var dontRoute: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_DONTROUTE)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_DONTROUTE, newValue)
        }
    }

    /// permit sending of broadcast msgs
    var broadcast: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_BROADCAST)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_BROADCAST, newValue)
        }
    }

    /// bypass hardware when possible
    var useLoopback: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_USELOOPBACK)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_USELOOPBACK, newValue)
        }
    }

    /// linger on close if data present (in ticks)
    var linger: Int64 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_LINGER)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_LINGER, newValue)
        }
    }

    /// leave received OOB data in line
    var outOfBandInline: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_OOBINLINE)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_OOBINLINE, newValue)
        }
    }

    /// allow local address & port reuse
    var reusePort: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_REUSEPORT)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_REUSEPORT, newValue)
        }
    }

    // SO_TIMESTAMP
    // SO_TIMESTAMP_MONOTONIC
    // SO_DONTTRUNC: APPLE: Retain unread data *
    // SO_WANTMORE: APPLE: Give hint when more data ready *
    // SO_WANTOOBFLAG: APPLE: Want OOB in MSG_FLAG on receive *

    /// send buffer size *
    var sendBufferSize: Int32 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_SNDBUF)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_SNDBUF, newValue)
        }
    }

    /// receive buffer size *
    var receiveBufferSize: Int32 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_RCVBUF)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_RCVBUF, newValue)
        }
    }

    /// send low-water mark *
    var sendLowWaterMark: Int32 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_SNDLOWAT)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_SNDLOWAT, newValue)
        }
    }

    /// receive low-water mark
    var receiveLowWaterMark: Int32 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_RCVLOWAT)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_RCVLOWAT, newValue)
        }
    }

    /// send timeout
    var sendTimeout: TimeInterval {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_SNDTIMEO)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_SNDTIMEO, newValue)
        }
    }

    /// receive timeout
    var receiveTimeout: TimeInterval {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_RCVTIMEO)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_RCVTIMEO, newValue)
        }
    }

    /// get error status and clear *
    var error: Int32 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_ERROR)
        }
    }

    /// get socket type *
    var type: Int32 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_TYPE)
        }
    }

    // SO_LABEL: socket's MAC label *
    // SO_PEERLABEL: socket's peer MAC label *
    // SO_NREAD: APPLE: get 1st-packet byte count *
    // SO_NKE: APPLE: Install socket-level NKE *
    // SO_NOSIGPIPE: APPLE: No SIGPIPE on EPIPE *
    // SO_NOADDRERR: APPLE: Returns EADDRNOTAVAIL when src is not available anymore *

    /// APPLE: Get number of bytes currently in send socket buffer *
    var nwrite: Int32 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_NWRITE)
        }
    }

    // SO_REUSESHAREUID: APPLE: Allow reuse of port/socket by different userids *
    /// APPLE: send notification if there is a bind on a port which is already in use *
    var notifyConflict: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_NOTIFYCONFLICT)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_NOTIFYCONFLICT, newValue)
        }
    }

    /// APPLE: block on close until an upcall returns *
    var upcallCloseWait: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_UPCALLCLOSEWAIT)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_UPCALLCLOSEWAIT, newValue)
        }
    }

    /// linger on close if data present (in seconds) *
    var lingerSeconds: Int64 {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_LINGER_SEC)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_LINGER_SEC, newValue)
        }
    }

    /// APPLE: request local port randomization *
    var randomPort: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_RANDOMPORT)
        }
        set {
            try! socket.setsockopt(SOL_SOCKET, SO_RANDOMPORT, newValue)
        }
    }

    // SO_NP_EXTENSIONS: To turn off some POSIX behavior *

    /// number of datagrams in receive socket buffer *
    var numberOfReceiveDatagrams: Bool {
        get {
            return try! socket.getsockopt(SOL_SOCKET, SO_NUMRCVPKT)
        }
    }

}

public extension SocketOptions {

    var all: [String: Any] {
        var all: [String: Any] = [:]
        all["debug"] = debug
//            all["acceptConnection"] = acceptConnection
        all["reuseAddress"] = reuseAddress
        all["keepAlive"] = keepAlive
        all["dontRoute"] = dontRoute
        all["broadcast"] = broadcast
        all["useLoopback"] = useLoopback
        all["linger"] = linger
        all["outOfBandInline"] = outOfBandInline
        all["reusePort"] = reusePort
//        all["dontTruncate"] = dontTruncate
//        all["wantMore"] = wantMore
//        all["wantOOBFlag"] = wantOOBFlag
        all["sendBufferSize"] = sendBufferSize
        all["receiveBufferSize"] = receiveBufferSize
        all["sendLowWaterMark"] = sendLowWaterMark
        all["receiveLowWaterMark"] = receiveLowWaterMark
        all["sendTimeout"] = sendTimeout
        all["receiveTimeout"] = receiveTimeout
        all["error"] = error
        all["type"] = type
        all["nwrite"] = nwrite
//            all["reuseShareUID"] = reuseShareUID
        all["notifyConflict"] = notifyConflict
        all["upcallCloseWait"] = upcallCloseWait
        all["lingerSeconds"] = lingerSeconds
        all["randomPort"] = randomPort
//        all["numberOfReceiveDatagrams"] = numberOfReceiveDatagrams
        return all
    }

}


// MARK: -

public extension SocketOptions {

    /// don't delay send to coalesce packets
    var noDelay: Bool {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_NODELAY)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_NODELAY, newValue)
        }
    }

    /// set maximum segment size
    var maxSegmentSize: Int32 {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_MAXSEG)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_MAXSEG, newValue)
        }
    }

    /// don't push last block of write
    var noPush: Bool {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_NOPUSH)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_NOPUSH, newValue)
        }
    }

    /// don't use TCP options
    var noOptions: Bool {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_NOOPT)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_NOOPT, newValue)
        }
    }

    /// idle time used when SO_KEEPALIVE is enabled
    var keepAliveIdleTime: Int32 {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_KEEPALIVE)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_KEEPALIVE, newValue)
        }
    }

    /// connection timeout
    var connectionTimeout: Int32 {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_CONNECTIONTIMEOUT)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_CONNECTIONTIMEOUT, newValue)
        }
    }

    /// time after which tcp retransmissions will be stopped and the connection will be dropped
    var retransmissionConnectionDropTime: Int32 {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_RXT_CONNDROPTIME)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_RXT_CONNDROPTIME, newValue)
        }
    }

    /// when this option is set, drop a connection after retransmitting the FIN 3 times. It will prevent holding too many mbufs in socket buffer queues.
    var retransmissionFINDrop: Bool {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_RXT_FINDROP)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_RXT_FINDROP, newValue)
        }
    }

    /// interval between keepalives
    var keepAliveInterval: Int32 {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_KEEPINTVL)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_KEEPINTVL, newValue)
        }
    }

    /// number of keepalives before close
    var keepAliveCount: Int32 {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_KEEPCNT)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_KEEPCNT, newValue)
        }
    }

    /// always ack every other packet
    var sendMoreACKS: Bool {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_SENDMOREACKS)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_SENDMOREACKS, newValue)
        }
    }

    /// Enable ECN on a connection
    var enableECN: Bool {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_ENABLE_ECN)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_ENABLE_ECN, newValue)
        }
    }

    /// Enable/Disable TCP Fastopen on this socket
    var fastOpen: Bool {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_FASTOPEN)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_FASTOPEN, newValue)
        }
    }

    /// State of TCP connection
    var connectionInfo: tcp_connection_info {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_CONNECTION_INFO)
        }
    }

    /// Low water mark for TCP unsent data
    var notSentLowWaterMark: Int32 {
        get {
            return try! socket.getsockopt(IPPROTO_TCP, TCP_NOTSENT_LOWAT)
        }
        set {
            try! socket.setsockopt(IPPROTO_TCP, TCP_NOTSENT_LOWAT, newValue)
        }
    }


}

// MARK: -

public extension SocketOptions {

    var tcpAll: [String: Any] {
        var all: [String: Any] = [:]
        all["noDelay"] = noDelay
        all["maxSegmentSize"] = maxSegmentSize
        all["noPush"] = noPush
        all["noOptions"] = noOptions
        all["keepAliveIdleTime"] = keepAliveIdleTime
        all["connectionTimeout"] = connectionTimeout
        all["retransmissionConnectionDropTime"] = retransmissionConnectionDropTime
        all["retransmissionFINDrop"] = retransmissionFINDrop
        all["keepAliveInterval"] = keepAliveInterval
        all["keepAliveCount"] = keepAliveCount
        all["sendMoreACKS"] = sendMoreACKS
        all["enableECN"] = enableECN
//        all["fastOpen"] = fastOpen
        all["connectionInfo"] = connectionInfo
        all["notSentLowWaterMark"] = notSentLowWaterMark
        return all
    }

}

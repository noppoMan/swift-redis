//
//  RedisConnection.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CHiredis
import CLibUv

private struct Context {
    var onConnect: Result -> () = { _ in}
    var onDisconnect: Result -> () = { _ in }
}

public enum ConnectionEvent {
    case Connect
    case Disconnect
}

public struct Connection {
    internal let ctx: UnsafeMutablePointer<redisAsyncContext>
    
    public init(loop: UnsafeMutablePointer<uv_loop_t>, host: String = "127.0.0.1", port: UInt = 6379) throws {
        self.ctx = redisAsyncConnect(host, Int32(port))

        if ctx.pointee.err > 0 {
            let message = String(validatingUTF8: ctx.pointee.errstr)!
            throw Error.ConnectionFailure(message)
        }
        
        // atach loop
        redisLibuvAttach(ctx, loop)
        
        let _ctx = UnsafeMutablePointer<Context>(allocatingCapacity: 1)
        _ctx.initialize(with: Context())
        ctx.pointee.data = UnsafeMutablePointer(_ctx)
    }
    
    public func on(evt: ConnectionEvent, callback: Result -> ()) {
        switch(evt) {
        case .Connect:
            UnsafeMutablePointer<Context>(ctx.pointee.data).pointee.onConnect = callback
            redisAsyncSetConnectCallback(ctx) { c, status in
                let ctx = UnsafeMutablePointer<Context>(c.pointee.data)
                if status != REDIS_OK {
                    let error = Error.ConnectionFailure(String(validatingUTF8: c.pointee.errstr)!)
                    return ctx.pointee.onConnect(.Error(error))
                }
                ctx.pointee.onConnect(.Success)
            }
        case .Disconnect:
            UnsafeMutablePointer<Context>(ctx.pointee.data).pointee.onDisconnect = callback
            redisAsyncSetDisconnectCallback(ctx) { c, status in
                // release context
                defer {
                    c.pointee.data.deinitialize()
                    c.pointee.data.deallocateCapacity(1)
                }
                
                let ctx = UnsafeMutablePointer<Context>(c.pointee.data)
                if status != REDIS_OK {
                    let error = Error.ConnectionFailure(String(validatingUTF8: c.pointee.errstr)!)
                    return ctx.pointee.onDisconnect(.Error(error))
                }
                ctx.pointee.onDisconnect(.Success)
            }
        }
    }
}
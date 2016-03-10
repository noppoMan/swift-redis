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

        if ctx.memory.err > 0 {
            let message = String.fromCString(ctx.memory.errstr)!
            throw Error.ConnectionFaild(message)
        }
        
        // atach loop
        redisLibuvAttach(ctx, loop)
        
        let _ctx = UnsafeMutablePointer<Context>.alloc(1)
        _ctx.initialize(Context())
        ctx.memory.data = UnsafeMutablePointer(_ctx)
    }
    
    public func on(evt: ConnectionEvent, callback: Result -> ()) {
        switch(evt) {
        case .Connect:
            UnsafeMutablePointer<Context>(ctx.memory.data).memory.onConnect = callback
            redisAsyncSetConnectCallback(ctx) { c, status in
                let ctx = UnsafeMutablePointer<Context>(c.memory.data)
                if status != REDIS_OK {
                    let error = Error.ConnectionFaild(String.fromCString(c.memory.errstr)!)
                    return ctx.memory.onConnect(.Error(error))
                }
                ctx.memory.onConnect(.Success)
            }
        case .Disconnect:
            UnsafeMutablePointer<Context>(ctx.memory.data).memory.onDisconnect = callback
            redisAsyncSetDisconnectCallback(ctx) { c, status in
                // release context
                defer {
                    c.memory.data.destroy()
                    c.memory.data.dealloc(1)
                }
                
                let ctx = UnsafeMutablePointer<Context>(c.memory.data)
                if status != REDIS_OK {
                    let error = Error.ConnectionFaild(String.fromCString(c.memory.errstr)!)
                    return ctx.memory.onDisconnect(.Error(error))
                }
                ctx.memory.onDisconnect(.Success)
            }
        }
    }
}
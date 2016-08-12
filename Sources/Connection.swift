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
    var onConnect: (Result) -> () = { _ in}
    var onDisconnect: (Result) -> () = { _ in }
}

public enum ConnectionEvent {
    case connect
    case disconnect
}

public struct Connection {
    internal let ctx: UnsafeMutablePointer<redisAsyncContext>
    
    public init(loop: UnsafeMutablePointer<uv_loop_t>, host: String = "127.0.0.1", port: UInt = 6379) throws {
        self.ctx = redisAsyncConnect(host, Int32(port))

        if ctx.pointee.err > 0 {
            let message = String(validatingUTF8: ctx.pointee.errstr)!
            throw SwiftRedisError.connectionFailure(message)
        }
        
        // atach loop
        redisLibuvAttach(ctx, loop)
        
        let _ctx = UnsafeMutablePointer<Context>.allocate(capacity: 1)
        _ctx.initialize(to: Context())
        ctx.pointee.data = UnsafeMutableRawPointer(_ctx)
    }
    
    public func on(_ evt: ConnectionEvent, callback: @escaping (Result) -> ()) {
        switch(evt) {
        case .connect:
            ctx.pointee.data.assumingMemoryBound(to: Context.self).pointee.onConnect = callback
            redisAsyncSetConnectCallback(ctx) { context, status in
                if let context = context {
                    let ctx = context.pointee.data.assumingMemoryBound(to: Context.self)
                    if status != REDIS_OK {
                        let error = SwiftRedisError.connectionFailure(String(validatingUTF8: context.pointee.errstr)!)
                        return ctx.pointee.onConnect(.error(error))
                    }
                    ctx.pointee.onConnect(.success)
                }
            }
        case .disconnect:
            ctx.pointee.data.assumingMemoryBound(to: Context.self).pointee.onDisconnect = callback
            redisAsyncSetDisconnectCallback(ctx) { context, status in
                if let context = context {
                    let ctx = context.pointee.data.assumingMemoryBound(to: Context.self)
                    // release context
                    defer {
                        context.pointee.data.deallocate(bytes: 1, alignedTo: 1)
                    }
                    
                    if status != REDIS_OK {
                        let error = SwiftRedisError.connectionFailure(String(validatingUTF8: context.pointee.errstr)!)
                        return ctx.pointee.onDisconnect(.error(error))
                    }
                    ctx.pointee.onDisconnect(.success)
                }
            }
        }
    }
}

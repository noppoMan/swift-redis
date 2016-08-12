//
//  SwiftRedis.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CHiredis


struct RedisContext {
    let autoRelease: Bool
    let onReply: (GenericResult<Any>) -> ()
    
    init(autoRelease: Bool = true, onReply: @escaping (GenericResult<Any>) -> ()){
        self.autoRelease = autoRelease
        self.onReply = onReply
    }
}

func redisCallbackFn(c: UnsafeMutablePointer<redisAsyncContext>?, r: UnsafeMutableRawPointer?, privdata: UnsafeMutableRawPointer?){
    guard let r = r, let privdata = privdata else {
        return
    }
    
    
    
    let ctx = privdata.assumingMemoryBound(to: RedisContext.self)
    
    // TODO It still has memory leak when the command is 'SUBSCRIBE'
    defer {
        if ctx.pointee.autoRelease {
            ctx.deinitialize()
            ctx.deallocate(capacity: 1)
        }
    }
    
    let reply = r.assumingMemoryBound(to: redisReply.self)
    let response: Any
    if reply.pointee.elements > 0 {
        var _response = [String]()
        for i in stride(from: 0, to: Int(reply.pointee.elements), by: 1) {
            if let element = reply.pointee.element[i] {
                var bytes = [UInt8]()
                for i in stride(from: 0, to: Int(element.pointee.len), by: 1) {
                    bytes.append(UInt8(bitPattern: element.pointee.str[i]))
                }
                if let str = String(bytes: bytes) {
                    _response.append(str)
                }
            }
        }
        
        response = _response
    } else {
        var bytes = [UInt8]()    
        for i in stride(from: 0, to: Int(reply.pointee.len), by: 1) {
            bytes.append(UInt8(bitPattern: reply.pointee.str[i]))
        }
        
        
        guard let _response = String(bytes: bytes) else {
            return ctx.pointee.onReply(.error(SwiftRedisError.commandFailure("No reply")))
        }
        
        if reply.pointee.type == REDIS_REPLY_ERROR {
            return ctx.pointee.onReply(.error(SwiftRedisError.commandFailure(_response)))
        }
        
        response = _response
    }
    
    ctx.pointee.onReply(.success(response))
}

public struct Redis {
    
    public static func command(_ connection: Connection, command: Commands, completion: @escaping (GenericResult<Any>) -> () = { _ in}) {
        
        do {
            let cmd = try command.parse()
            if cmd.count == 0 {
                throw SwiftRedisError.commandFailure("Command should not be empty")
            }
            
            let ctx = UnsafeMutablePointer<RedisContext>.allocate(capacity: 1)
            ctx.initialize(to: RedisContext(autoRelease: !command.isPermanent , onReply: completion))
            
            let privdata = UnsafeMutablePointer<Void>(ctx)
            
            redisAsyncCommandArgv(
                connection.ctx,
                redisCallbackFn,
                UnsafeMutablePointer(privdata),
                Int32(cmd.count),
                UnsafeMutablePointer(mutating: cmd.map { $0.buffer }),
                nil
            )
            
        } catch {
            completion(.error(error))
        }
    }
    
    public static func close(_ connection: Connection){
        redisAsyncDisconnect(connection.ctx)
    }
    
}

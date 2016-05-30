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
    
    init(autoRelease: Bool = true, onReply: (GenericResult<Any>) -> ()){
        self.autoRelease = autoRelease
        self.onReply = onReply
    }
}

func redisCallbackFn(c: UnsafeMutablePointer<redisAsyncContext>?, r: UnsafeMutablePointer<Void>?, privdata: UnsafeMutablePointer<Void>?){
    guard let r = r, privdata = privdata else {
        return
    }
    
    let ctx = UnsafeMutablePointer<RedisContext>(privdata)
    
    // TODO It still has memory leak when the command is 'SUBSCRIBE'
    defer {
        if ctx.pointee.autoRelease {
            ctx.deinitialize()
            ctx.deallocateCapacity(1)
        }
    }
    
    let reply = UnsafeMutablePointer<redisReply>(r)
    let response: Any
    if reply.pointee.elements > 0 {
        var _response = [String]()
        for i in stride(from: 0, to: Int(reply.pointee.elements), by: 1) {
            if let element = reply.pointee.element[i] {
                var bytes = [UInt8]()
                for i in stride(from: 0, to: Int(element.pointee.len), by: 1) {
                    bytes.append(UInt8(bitPattern: element.pointee.str[i]))
                }
                _response.append(String(bytes: bytes))
            }
        }
        
        response = _response
    } else {
        var bytes = [UInt8]()    
        for i in stride(from: 0, to: Int(reply.pointee.len), by: 1) {
            bytes.append(UInt8(bitPattern: reply.pointee.str[i]))
        }
        
        let _response = String(bytes: bytes)
        
        if reply.pointee.type == REDIS_REPLY_ERROR {
            return ctx.pointee.onReply(.Error(Error.CommandFailure(_response)))
        }
        
        response = _response
    }
    
    ctx.pointee.onReply(.Success(response))
}

public struct Redis {
    
    public static func command(_ connection: Connection, command: Commands, completion: (GenericResult<Any>) -> () = { _ in}) {
        
        do {
            let cmd = try command.parse()
            if cmd.count == 0 {
                throw Error.CommandFailure("Command should not be empty")
            }
            
            let ctx = UnsafeMutablePointer<RedisContext>(allocatingCapacity: 1)
            ctx.initialize(with: RedisContext(autoRelease: !command.isPermanent , onReply: completion))
            
            let privdata = UnsafeMutablePointer<Void>(ctx)
            
            redisAsyncCommandArgv(
                connection.ctx,
                redisCallbackFn,
                UnsafeMutablePointer(privdata),
                Int32(cmd.count),
                UnsafeMutablePointer(cmd.map { $0.buffer }),
                nil
            )
            
        } catch {
            completion(.Error(error))
        }
    }
    
    public static func close(_ connection: Connection){
        redisAsyncDisconnect(connection.ctx)
    }
    
}

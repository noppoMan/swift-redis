//
//  SwiftRedis.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CHiredis

func redisCallbackFn(c: UnsafeMutablePointer<redisAsyncContext>, r: UnsafeMutablePointer<Void>, privdata: UnsafeMutablePointer<Void>){
    
    let callback: GenericResult<String> -> () = releaseVoidPointer(privdata)!
    
    let reply = UnsafeMutablePointer<redisReply>(r)
    
    var bytes = [UInt8]()
    
    for i in stride(from: 0, to: Int(reply.pointee.len), by: 1) {
        bytes.append(UInt8(bitPattern: reply.pointee.str[i]))
    }
    
    let repStr = bytes2Str(bytes)
    
    if reply.pointee.type == REDIS_REPLY_ERROR {
        let error = Error.CommandFailure(repStr)
        return callback(.Error(error))
    }
    
    callback(.Success(repStr))
}

private func asyncSendCommand(connection: Connection, command: [String], completion: GenericResult<String> -> () = { _ in }) {
    
    let privdata = retainedVoidPointer(completion)
    
    redisAsyncCommandArgv(
        connection.ctx,
        redisCallbackFn,
        UnsafeMutablePointer(privdata),
        Int32(command.count),
        UnsafeMutablePointer(command.map { $0.buffer }),
        nil
    )
}

public struct SwiftRedis {
    
    public static func command(connection: Connection, command: Commands, completion: GenericResult<String> -> () = { _ in}) {
        
        if command.argv.count == 0 {
            return completion(.Error(Error.UnImplemented))
        }
        
        asyncSendCommand(connection, command: command.argv, completion: completion)
        
    }
    
    public static func close(connection: Connection){
        redisAsyncDisconnect(connection.ctx)
    }
    
}

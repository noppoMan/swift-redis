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
    
    if c.memory.err > 0 {
        let error = Error.ConnectionFaild(String.fromCString(c.memory.errstr)!)
        return callback(.Error(error))
    }
    
    
    let reply = UnsafeMutablePointer<redisReply>(r)
    
    var bytes = [UInt8]()
    
    for i in 0.stride(to: Int(reply.memory.len), by: 1) {
        bytes.append(UInt8(bitPattern: reply.memory.str[i]))
    }
    
    callback(.Success(bytes2Str(bytes)))
}

public func asyncSendCommand(connection: Connection, command: String, completion: GenericResult<String> -> () = { _ in }) {
    
    let argv = command.characters.split(allowEmptySlices: false) { $0 == " " }.map { String($0) }
    
    let privdata = retainedVoidPointer(completion)
    
    redisAsyncCommandArgv(
        connection.ctx,
        redisCallbackFn,
        UnsafeMutablePointer(privdata),
        Int32(argv.count),
        UnsafeMutablePointer(argv.map { $0.buffer }),
        nil
    )
}

public struct SwiftRedis {
    
    public static func command(connection: Connection, command: Commands, completion: GenericResult<String> -> () = { _ in}) {
        
        if command.description == "" {
            return completion(.Error(Error.UnImplemented))
        }
        
        asyncSendCommand(connection, command: command.description, completion: completion)
    }
    
    public static func close(connection: Connection){
        redisAsyncDisconnect(connection.ctx)
    }
    
}

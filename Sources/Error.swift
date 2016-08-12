//
//  Error.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

enum SwiftRedisError: Error, CustomStringConvertible {
    case connectionFailure(String)
    case unImplemented
    case commandFailure(String)
    
    var description: String {
        switch(self){
        case .connectionFailure(let message):
            return message
        case .commandFailure(let message):
            return message
        case .unImplemented:
            return "UnImplemented"
        }
    }
}

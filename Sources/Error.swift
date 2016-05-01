//
//  Error.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

enum Error: ErrorProtocol, CustomStringConvertible {
    case ConnectionFailure(String)
    case UnImplemented
    case Unexpexted
    case CommandFailure(String)
    
    var description: String {
        switch(self){
        case .ConnectionFailure(let message):
            return message
        case .CommandFailure(let message):
            return message
        case .UnImplemented:
            return "UnImplemented"
        case .Unexpexted:
            return "Unexpexted"
        }
    }
}

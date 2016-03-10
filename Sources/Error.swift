//
//  Error.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

enum Error: ErrorType, CustomStringConvertible {
    case ConnectionFaild(String)
    case UnImplemented
    
    var description: String {
        switch(self){
        case .ConnectionFaild(let message):
            return message
        case .UnImplemented:
            return "UnImplemented"
        }
    }
}

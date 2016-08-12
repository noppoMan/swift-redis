//
//  String.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 8/12/16.
//
//

import Foundation

extension String {
    var buffer: UnsafePointer<Int8>? {
        return NSString(string: self).utf8String
    }
    
    init?(bytes: [UInt8]){
        var encodedString = ""
        var decoder = UTF8()
        var generator = bytes.makeIterator()
        
        loop: while true {
            switch decoder.decode(&generator) {
            case .scalarValue(let char): encodedString.append(String(char))
            case .emptyInput: break loop
            case .error: break loop
            }
        }
        
        self.init(encodedString)
    }
}

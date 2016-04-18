//
//  support.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import CHiredis
import CLibUv
import Foundation

public enum GenericResult<T> {
    case Success(T)
    case Error(ErrorProtocol)
}

public enum Result {
    case Success
    case Error(ErrorProtocol)
}

final class Box<A> {
    let unbox: A
    init(_ value: A) { unbox = value }
}

func retainedVoidPointer<A>(x: A?) -> UnsafeMutablePointer<Void> {
    guard let value = x else { return UnsafeMutablePointer<Void>(allocatingCapacity: 0) }
    let unmanaged = OpaquePointer(bitPattern: Unmanaged.passRetained(Box(value)))
    return UnsafeMutablePointer(unmanaged)
}

func releaseVoidPointer<A>(x: UnsafeMutablePointer<Void>) -> A? {
    guard x != nil else { return nil }
    return Unmanaged<Box<A>>.fromOpaque(OpaquePointer(x)).takeRetainedValue().unbox
}

func unsafeFromVoidPointer<A>(x: UnsafeMutablePointer<Void>) -> A? {
    guard x != nil else { return nil }
    return Unmanaged<Box<A>>.fromOpaque(OpaquePointer(x)).takeUnretainedValue().unbox
}

func bytes2Str(bytes: [UInt8]) -> String {
    var encodedString = ""
    var decoder = UTF8()
    var generator = bytes.makeIterator()
    
    loop: while true {
        switch decoder.decode(&generator) {
        case .scalarValue(let char): encodedString.append(char)
        case .emptyInput: break loop
        case .error: break loop
        }
    }
    
    return encodedString
}

extension String {
    var buffer: UnsafePointer<Int8> {
        return NSString(string: self).utf8String
    }
}
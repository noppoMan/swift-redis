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
    case Error(ErrorType)
}

public enum Result {
    case Success
    case Error(ErrorType)
}

final class Box<A> {
    let unbox: A
    init(_ value: A) { unbox = value }
}

func retainedVoidPointer<A>(x: A?) -> UnsafeMutablePointer<Void> {
    guard let value = x else { return UnsafeMutablePointer() }
    let unmanaged = Unmanaged.passRetained(Box(value))
    return UnsafeMutablePointer(unmanaged.toOpaque())
}

func releaseVoidPointer<A>(x: UnsafeMutablePointer<Void>) -> A? {
    guard x != nil else { return nil }
    return Unmanaged<Box<A>>.fromOpaque(COpaquePointer(x)).takeRetainedValue().unbox
}

func unsafeFromVoidPointer<A>(x: UnsafeMutablePointer<Void>) -> A? {
    guard x != nil else { return nil }
    return Unmanaged<Box<A>>.fromOpaque(COpaquePointer(x)).takeUnretainedValue().unbox
}

func bytes2Str(bytes: [UInt8]) -> String {
    var encodedString = ""
    var decoder = UTF8()
    var generator = bytes.generate()
    var decoded: UnicodeDecodingResult
    repeat {
        decoded = decoder.decode(&generator)
        
        switch decoded {
        case .Result(let unicodeScalar):
            encodedString.append(unicodeScalar)
        default:
            break
        }
    } while (!decoded.isEmptyInput())
    
    return encodedString
}

extension String {
    var buffer: UnsafePointer<Int8> {
        return NSString(string: self).UTF8String
    }
}
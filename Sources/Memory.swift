//
//  support.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

final class Box<A> {
    let unbox: A
    init(_ value: A) { unbox = value }
}

func retainedVoidPointer<A>(_ x: A) -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(Box(x)).toOpaque()
}

func releaseVoidPointer<A>(_ x: UnsafeMutableRawPointer) -> A {
    return Unmanaged<Box<A>>.fromOpaque(x).takeRetainedValue().unbox
}

func unsafeFromVoidPointer<A>(_ x: UnsafeMutableRawPointer) -> A {
    return Unmanaged<Box<A>>.fromOpaque(x).takeUnretainedValue().unbox
}

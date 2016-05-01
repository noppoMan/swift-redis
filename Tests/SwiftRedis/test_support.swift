//
//  test_support.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import Foundation
import CLibUv

internal func setTimeout(_ delay: UInt = 0, callback: () -> ()){
    let handle = UnsafeMutablePointer<uv_timer_t>(allocatingCapacity: 1)
    
    handle.pointee.data = retainedVoidPointer(callback)
    uv_timer_init(uv_default_loop(), handle)
    uv_timer_start(handle, { handle in
        defer {
            handle.deinitialize()
            handle.deallocateCapacity(1)
        }
        uv_timer_stop(handle)
        let cb: () -> () = releaseVoidPointer(handle.pointee.data)!
        cb()
    }, UInt64(delay), 0)
}

final class Box<A> {
    let unbox: A
    init(_ value: A) { unbox = value }
}

func retainedVoidPointer<A>(_ x: A?) -> UnsafeMutablePointer<Void> {
    guard let value = x else { return UnsafeMutablePointer<Void>(allocatingCapacity: 0) }
    let unmanaged = OpaquePointer(bitPattern: Unmanaged.passRetained(Box(value)))
    return UnsafeMutablePointer(unmanaged)
}

func releaseVoidPointer<A>(_ x: UnsafeMutablePointer<Void>?) -> A? {
    guard let x = x else {
        return nil
    }
    return Unmanaged<Box<A>>.fromOpaque(OpaquePointer(x)).takeRetainedValue().unbox
}

func unsafeFromVoidPointer<A>(_ x: UnsafeMutablePointer<Void>?) -> A? {
    guard let x = x else {
        return nil
    }
    return Unmanaged<Box<A>>.fromOpaque(OpaquePointer(x)).takeUnretainedValue().unbox
}


private class AsynchronousTestSupporter {
    
    init(timeout: NSTimeInterval, description: String, callback: (() -> ()) -> ()){
        print("Starting the \(description) test")
        
        var breakFlag = false
        
        let done = {
            breakFlag = true
        }
        
        callback(done)
        
        let runLoop = NSRunLoop.current()
        let timeoutDate = NSDate(timeIntervalSinceNow: timeout)
        
        while NSDate().compare(timeoutDate) == NSComparisonResult.orderedAscending {
            if(breakFlag) {
                break
            }
            runLoop.run(until: NSDate(timeIntervalSinceNow: 0.01))
        }
        
        if(!breakFlag) {
            XCTFail("Test is timed out")
        }
    }
}

extension XCTestCase {
    func waitUntil(timeout: NSTimeInterval = 1, description: String, callback: (() -> ()) -> ()){
        let _ = AsynchronousTestSupporter(timeout: timeout, description: description, callback: callback)
    }
}


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

internal func setTimeout(_ delay: UInt = 0, callback: @escaping () -> ()){
    let handle = UnsafeMutablePointer<uv_timer_t>.allocate(capacity: 1)
    
    handle.pointee.data = retainedVoidPointer(callback)
    uv_timer_init(uv_default_loop(), handle)
    uv_timer_start(handle, { handle in
        defer {
            handle!.deinitialize()
            handle!.deallocate(capacity: 1)
        }
        uv_timer_stop(handle)
        let cb: () -> () = releaseVoidPointer(handle!.pointee.data)
        cb()
    }, UInt64(delay), 0)
}

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


private class AsynchronousTestSupporter {
    
    init(timeout: TimeInterval, description: String, callback: (@escaping () -> ()) -> ()){
        print("Starting the \(description) test")
        
        var breakFlag = false
        
        let done = {
            breakFlag = true
        }
        
        callback(done)
        
        let runLoop = RunLoop.current
        let timeoutDate = NSDate(timeIntervalSinceNow: timeout)
        
        while NSDate().compare(timeoutDate as Date) == ComparisonResult.orderedAscending {
            if(breakFlag) {
                break
            }
            runLoop.run(until: NSDate(timeIntervalSinceNow: 0.01) as Date)
        }
        
        if(!breakFlag) {
            XCTFail("Test is timed out")
        }
    }
}

extension XCTestCase {
    func waitUntil(timeout: TimeInterval = 1, description: String, callback: (@escaping () -> ()) -> ()){
        let _ = AsynchronousTestSupporter(timeout: timeout, description: description, callback: callback)
    }
}


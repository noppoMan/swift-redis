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

internal func setTimeout(delay: UInt = 0, callback: () -> ()){
    let handle = UnsafeMutablePointer<uv_timer_t>.alloc(1)
    
    handle.memory.data = retainedVoidPointer(callback)
    uv_timer_init(uv_default_loop(), handle)
    uv_timer_start(handle, { handle in
        defer {
            handle.destroy()
            handle.dealloc(1)
        }
        uv_timer_stop(handle)
        let cb: () -> () = releaseVoidPointer(handle.memory.data)!
        cb()
    }, UInt64(delay), 0)
}


private class AsynchronousTestSupporter {
    
    init(timeout: NSTimeInterval, description: String, callback: (() -> ()) -> ()){
        print("Starting the \(description) test")
        
        var breakFlag = false
        
        let done = {
            breakFlag = true
        }
        
        callback(done)
        
        let runLoop = NSRunLoop.currentRunLoop()
        let timeoutDate = NSDate(timeIntervalSinceNow: timeout)
        
        while NSDate().compare(timeoutDate) == NSComparisonResult.OrderedAscending {
            if(breakFlag) {
                break
            }
            runLoop.runUntilDate(NSDate(timeIntervalSinceNow: 0.01))
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


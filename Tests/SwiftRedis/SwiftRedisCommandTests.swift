//
//  SwiftRedisTests.swift
//  SwiftRedis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import CLibUv
@testable import SwiftRedis

class SwiftRedisCommandTests: XCTestCase {
    
    func testConnect(){
        waitUntil(description: "connect") { done in
            let loop = uv_default_loop()
            
            do {
                let con = try Connection(loop: loop)
                
                con.on(.Connect) { result in
                    XCTAssert(true)
                }
                
                con.on(.Disconnect) { result in
                    done()
                }
                
                setTimeout(100) {
                    SwiftRedis.close(con)
                }
                
                uv_run(loop, UV_RUN_DEFAULT)
                
            } catch {
                XCTFail("\(error)")
            }
            
        }
    }
    
    func testPing(){
        waitUntil(description: "ping") { done in
            let loop = uv_default_loop()
            
            do {
                let con = try Connection(loop: loop)
                
                SwiftRedis.command(con, command: .PING) { result in
                    
                    if case .Success(let reply) = result {
                        XCTAssertEqual(reply, "PONG")
                    }
                
                    SwiftRedis.close(con)
                }
                
                con.on(.Disconnect) { result in
                    done()
                }
                
                uv_run(loop, UV_RUN_DEFAULT)
                
            } catch {
                XCTFail("\(error)")
            }
            
        }
    }
    
    func testPipelining(){
        waitUntil(description: "pipelining") { done in
            let loop = uv_default_loop()
            
            do {
                let con = try Connection(loop: loop)
                
                SwiftRedis.command(con, command: .SET("test", "foobar")) { result in
                    if case .Success(let rep) = result {
                        XCTAssertEqual(rep, "OK")
                    }
                    SwiftRedis.command(con, command: .GET("test")) { result in
                        if case .Success(let rep) = result {
                            XCTAssertEqual(rep, "foobar")
                        }
                        SwiftRedis.command(con, command: .DEL(["test"])) { result in
                            if case .Success(_) = result {
                                SwiftRedis.close(con)
                            }
                        }
                    }
                }
                
                con.on(.Disconnect) { result in
                    done()
                }
                
                uv_run(loop, UV_RUN_DEFAULT)
                
            } catch {
                XCTFail("\(error)")
            }
            
        }
    }
    
}
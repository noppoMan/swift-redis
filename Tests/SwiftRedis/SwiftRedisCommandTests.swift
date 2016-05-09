//
//  RedisTests.swift
//  Redis
//
//  Created by Yuki Takei on 3/11/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
import CLibUv
@testable import SwiftRedis

let key = "swift-redis-test-key"

class RedisCommandTests: XCTestCase {
    
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
                    Redis.close(con)
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
                
                Redis.command(con, command: .PING) { result in
                    
                    if case .Success(let reply) = result {
                        XCTAssertEqual(reply as? String, "PONG")
                    }
                
                    Redis.close(con)
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
                
                Redis.command(con, command: .SET(key, "foobar")) { result in
                    if case .Success(let rep) = result {
                        XCTAssertEqual(rep as? String, "OK")
                    }
                    Redis.command(con, command: .GET(key)) { result in
                        if case .Success(let rep) = result {
                            XCTAssertEqual(rep as? String, "foobar")
                        }
                        Redis.command(con, command: .DEL([key])) { result in
                            if case .Success(_) = result {
                                Redis.close(con)
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
    
    func testJsonSet(){
        waitUntil(description: "jsonSet") { done in
            let loop = uv_default_loop()
            
            do {
                let con = try Connection(loop: loop)
                
                Redis.command(con, command: .SET(key, "{\"foo\": \"bar\"}")) { result in
                    if case .Success(let rep) = result {
                        XCTAssertEqual(rep as? String, "OK")
                    }
                    Redis.command(con, command: .GET(key)) { result in
                        if case .Success(let rep) = result {
                            XCTAssertEqual(rep as? String, "{\"foo\": \"bar\"}")
                        }
                        Redis.command(con, command: .DEL([key])) { result in
                            if case .Success(_) = result {
                                Redis.close(con)
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
    
    func testUnImplemented(){
        waitUntil(description: "unimplemented") { done in
            let loop = uv_default_loop()
            
            do {
                let con = try Connection(loop: loop)
                
                Redis.command(con, command: .HSET("key", "foo", "bar")) { result in
                    if case .Error(let err) = result {
                        if case Error.UnImplemented = err {
                            done()
                        }
                    } else {
                        XCTFail("Here is never called")
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
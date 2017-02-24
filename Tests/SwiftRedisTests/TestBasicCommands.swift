/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import SwiftRedis

#if os(Linux)
    import Glibc
    import Dispatch
#else
    import Darwin
#endif

import Foundation
import XCTest

public class TestBasicCommands: XCTestCase {
    
    static var allTests: [(String, (TestBasicCommands) -> () throws -> Void)] {
        return [
            ("test_bitfieldGet", test_bitfieldGet),
            ("test_bitfieldSet", test_bitfieldSet),
            ("test_bitfieldIncrby", test_bitfieldIncrby),
            ("test_bitfieldOffsetMultiplier", test_bitfieldOffsetMultiplier),
            ("test_bitfieldWRAP", test_bitfieldWRAP),
            ("test_bitfieldSAT", test_bitfieldSAT),
            ("test_bitfieldFAIL", test_bitfieldFAIL),
            ("test_bitfieldMultiSubcommands", test_bitfieldMultiSubcommands),
            ("test_setAndGet", test_setAndGet),
            ("test_SetExistOptions", test_SetExistOptions),
            ("test_SetExpireOptions", test_SetExpireOptions),
            ("test_keys", test_keys),
            ("test_randomkey", test_randomkey),
            ("test_incrDecr", test_incrDecr),
            ("test_incrFloats", test_incrFloats),
            ("test_empty", test_empty),
            ("test_scan", test_scan),
            ("test_scanPattern", test_scanPattern),
            ("test_scanCount", test_scanCount),
            ("test_sort", test_sort),
            ("test_sortDesc", test_sortDesc),
            ("test_sortAlpha", test_sortAlpha),
            ("test_sortLimit", test_sortLimit),
            ("test_sortMultiModifiers", test_sortMultiModifiers),
            ("test_sortBy", test_sortBy),
            ("test_sortByNoSort", test_sortByNoSort),
            ("test_sortGet", test_sortGet),
            ("test_sortGetMulti", test_sortGetMulti),
            ("test_sortStore", test_sortStore),
            ("test_sortByGetHashes", test_sortByGetHashes),
            ("test_touchNone", test_touchNone),
            ("test_touchOne", test_touchOne),
            ("test_touchMulti", test_touchMulti),
            ("test_type", test_type),
            ("test_typeBadKey", test_typeBadKey)
        ]
    }
    
    var key1 = "test1"
    var key2 = "test2"
    var key3 = "test3"
    var key4 = "test4"
    var exp: XCTestExpectation?
    
    func localSetup(block: () -> Void) {
        connectRedis() {(err) in
            guard err == nil else {
                XCTFail()
                return
            }
            
            redis.flushdb(callback: { (res, err) in
                block()
            })
        }
    }
    
    private func setup(major: Int, minor: Int, micro: Int, callback: () -> Void) {
        connectRedis() {(err) in
            guard err == nil else {
                XCTFail()
                return
            }
            redis.info { (info: RedisInfo?, _) in
                if let info = info, info.server.checkVersionCompatible(major: major, minor: minor, micro: micro) {
                    redis.flushdb(callback: { (_, _) in
                        callback()
                    })
                }
            }
        }
    }
    
    func test_bitfieldGet() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the specified bit field.")
            
            redis.bitfield(key: key1, subcommands: .get("u4", 0), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
                exp?.fulfill()
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldSet() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the specified bit field.")
            
            redis.bitfield(key: key1, subcommands: .set("i5", "4", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
                exp?.fulfill()
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldIncrby() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Increment bitfield and return new value.")
            
            redis.bitfield(key: key1, subcommands: .incrby("i5", "100", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 1)
                exp?.fulfill()
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldOffsetMultiplier() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Use # to multiply offset by integer type.")
            
            redis.bitfield(key: key1, subcommands: .incrby("u8", "#0", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 1)
                exp?.fulfill()
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldWRAP() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "On overflows, wraps back to min value, and vise versa.")
            
            redis.bitfield(key: key1, subcommands: .overflow(.WRAP), .incrby("u2", "0", 2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 2)
                
                redis.bitfield(key: key1, subcommands: .overflow(.WRAP), .incrby("u2", "0", 2), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asInteger, 0)
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldSAT() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "On underflows the value is set to the minimum integer value, and on overflows to the maximum integer value.")
            
            redis.bitfield(key: key1, subcommands: .overflow(.SAT), .incrby("i4", "100", -900), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, -8)
                exp?.fulfill()
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldFAIL() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "No operation is performed on overflows or underflows.")
            
            redis.bitfield(key: key1, subcommands: .overflow(.FAIL), .incrby("u2", "102", 5), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0], RedisResponse.Nil)
                exp?.fulfill()
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldMultiSubcommands() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Chain multiple subcommands in a BITFIELD command.")
            
            redis.bitfield(key: key1, subcommands: .overflow(.SAT), .set("i2", "1", 3), .incrby("i5", "100", 1), .get("u4", 0), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
                XCTAssertEqual(res?[1]?.asInteger, 1)
                XCTAssertEqual(res?[2]?.asInteger, 2)
                exp?.fulfill()
            })

            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_setAndGet() {
        localSetup() {
            let expectedValue = "testing 1 2 3"
            let newValue = "xyzzy-plover"
            
            redis.set(self.key1, value: expectedValue) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key1)")
                
                redis.get(self.key1) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")
                    
                    redis.getSet(self.key1, value: newValue) {(returnedValue: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")
                        
                        redis.get(self.key1) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertEqual(returnedValue!.asString, newValue, "Returned value was not '\(newValue)'")
                        }
                    }
                }
            }
        }
    }
    
    func test_SetExistOptions() {
        localSetup() {
            let expectedValue = "hi ho, hi ho, it's off to test we go"
            let newValue = "A testing we go, a testing we go"
            
            redis.set(self.key2, value: expectedValue, exists: true) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertFalse(wasSet, "Shouldn't have set \(self.key2)")
                
                redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNil(returnedValue, "\(self.key2) shouldn't exist")
                    
                    redis.set(self.key2, value: expectedValue, exists: false) {(wasSet: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssert(wasSet, "Failed to set \(self.key2)")
                        
                        redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")
                            
                            redis.set(self.key2, value: newValue, exists: false) {(wasSet: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertFalse(wasSet, "Shouldn't have set \(self.key2)")
                                
                                redis.del(self.key2) {(deleted: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    
                                    redis.set(self.key2, value: newValue, exists: false) {(wasSet: Bool, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssert(wasSet, "Failed to set \(self.key2)")
                                        
                                        redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                            XCTAssertEqual(returnedValue!.asString, newValue, "Returned value was not '\(newValue)'")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_SetExpireOptions() {
        localSetup() {
            let expectedValue = "hi ho, hi ho, it's off to test we go"
            
            redis.set(self.key3, value: expectedValue, expiresIn: 2.750) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key3)")
                
                redis.get(self.key3) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")
                    
                    usleep(3000000)
                    
                    redis.get(self.key3) {(returnedValue: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNil(returnedValue, "\(self.key3) shouldn't exist any more")
                    }
                }
            }
        }
    }
    
    func test_keys() {
        localSetup {
            exp = expectation(description: "Return all keys matching `pattern`.")
            
            redis.mset((key1, "1"), (key2, "2"), (key3, "3"), (key4, "4"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.keys(pattern: "*1", callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res?.count, 1)
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_randomkey() {
        localSetup {
            exp = expectation(description: "Return a random key from the currently selected database.")
            
            redis.mset((key1, "1"), (key2, "2"), (key3, "3"), (key4, "4"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.randomkey(callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_incrDecr() {
        localSetup() {
            var theValue=101
            
            redis.set(self.key1, value: String(theValue)) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key1)")
                
                redis.incr(self.key1) {(newValue: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(newValue, "Result of an INCR shouldn't be nil")
                    XCTAssertEqual(theValue+1, newValue!, "The returned value wasn't \(theValue+1)")
                    theValue = newValue!
                    
                    redis.decr(self.key1) {(newValue: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(newValue, "Result of an DECR shouldn't be nil")
                        XCTAssertEqual(theValue-1, newValue!, "The returned value wasn't \(theValue-1)")
                        theValue = newValue!
                        
                        redis.decr(self.key2) {(newValue: Int?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(newValue, "Result of an DECR shouldn't be nil")
                            XCTAssertEqual(-1, newValue!, "The returned value wasn't \(-1)")
                            
                            redis.incr(self.key1, by: 10) {(newValue: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(newValue, "Result of an INCR shouldn't be nil")
                                XCTAssertEqual(theValue+10, newValue!, "The returned value wasn't \(theValue+10)")
                                theValue = newValue!
                                
                                redis.decr(self.key1, by: 5) {(newValue: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(newValue, "Result of an DECR shouldn't be nil")
                                    XCTAssertEqual(theValue-5, newValue!, "The returned value wasn't \(theValue-5)")
                                    theValue = newValue!
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_incrFloats() {
        localSetup() {
            var theValue: Double = 84.75
            
            redis.set(self.key3, value: String(theValue)) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key3)")
                
                let incValue: Float = 12.5
                redis.incr(self.key3, byFloat: incValue) {(newValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(newValue, "Result of an INCRBYFLOAT shouldn't be nil")
                    XCTAssertEqual(theValue+Double(incValue), newValue!.asDouble, "The returned value wasn't \(theValue+Double(incValue))")
                    theValue = newValue!.asDouble
                }
            }
        }
    }
    
    func test_empty() {
        localSetup() {
            let emptyValue = ""
            
            redis.set(self.key1, value: emptyValue) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key1)")
                
                redis.get(self.key1) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(returnedValue!.asString, emptyValue, "Returned value was not '\(emptyValue)'")
                }
            }
        }
    }
    
    func test_scan() {
        localSetup {
            exp = expectation(description: "Iterate over some elements.")
            
            redis.mset((key1, "val1"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.scan(cursor: 0, callback: { (newCursor, res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(newCursor)
                    XCTAssertEqual(res?.count, 2)
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_scanPattern() {
        localSetup {
            exp = expectation(description: "Iterate over elements matching a pattern.")
            
            redis.mset((key1, "val1"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.scan(cursor: 0, match: "*1", callback: { (newCursor, res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(newCursor)
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_scanCount() {
        localSetup {
            exp = expectation(description: "Iterate over a certain number of elements.")
            
            redis.mset((key1, "val1"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.scan(cursor: 0, count: 2, callback: { (newCursor, res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(newCursor)
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sort() {
        localSetup {
            exp = expectation(description: "Return sorted list at `key`.")
            
            let val1 = "20"
            let val2 = "5"
            let val3 = "90"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val2)
                    XCTAssertEqual(res?[1]?.asString, val1)
                    XCTAssertEqual(res?[2]?.asString, val3)
                    exp?.fulfill()
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortDesc() {
        localSetup {
            exp = expectation(description: "Return list at `key` sorted in descending order.")
            
            let val1 = "20"
            let val2 = "5"
            let val3 = "90"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, desc: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val3)
                    XCTAssertEqual(res?[1]?.asString, val1)
                    XCTAssertEqual(res?[2]?.asString, val2)
                    exp?.fulfill()
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortAlpha() {
        localSetup {
            exp = expectation(description: "Return lexicograpically sorted list at `key`.")
            
            let val1 = "red"
            let val2 = "blue"
            let val3 = "green"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, alpha: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val2)
                    XCTAssertEqual(res?[1]?.asString, val3)
                    XCTAssertEqual(res?[2]?.asString, val1)
                    exp?.fulfill()
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortLimit() {
        localSetup {
            exp = expectation(description: "Return sorted list with `offset` and `count`.")
            
            let val1 = "20"
            let val2 = "5"
            let val3 = "90"
            let val4 = "35"
            let val5 = "600"
            redis.lpush(key1, values: val1, val2, val3, val4, val5) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 5)
                
                redis.sort(key: key1, limit: (1, 3), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val1)
                    XCTAssertEqual(res?[1]?.asString, val4)
                    XCTAssertEqual(res?[2]?.asString, val3)
                    exp?.fulfill()
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortMultiModifiers() {
        localSetup {
            exp = expectation(description: "SORT with many modifiers.")
            
            let val1 = "red"
            let val2 = "blue"
            let val3 = "green"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, limit: (0, 10), desc: true, alpha: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val1)
                    XCTAssertEqual(res?[1]?.asString, val3)
                    XCTAssertEqual(res?[2]?.asString, val2)
                    exp?.fulfill()
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortBy() {
        localSetup {
            exp = expectation(description: "Sort by external keys.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.mset(("weight_1", "40"), ("weight_2", "5"), ("weight_3", "210"), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    
                    redis.sort(key: key1, by: "weight_*", callback: { (res, err) in
                        XCTAssertNil(err)
                        XCTAssertEqual(res?[0]?.asString, val2)
                        XCTAssertEqual(res?[1]?.asString, val1)
                        XCTAssertEqual(res?[2]?.asString, val3)
                        exp?.fulfill()
                    })
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortByNoSort() {
        localSetup {
            exp = expectation(description: "Give bad key to return unsorted list.")
            
            let val1 = "345"
            let val2 = "8"
            let val3 = "90"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, by: "nosort", callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val3)
                    XCTAssertEqual(res?[1]?.asString, val2)
                    XCTAssertEqual(res?[2]?.asString, val1)
                    exp?.fulfill()
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortGet() {
        localSetup {
            exp = expectation(description: "Sort by external keys and retrieve external keys.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                let obj1 = "baby"
                let obj2 = "watermelon"
                let obj3 = "panda"
                redis.mset(("weight_1", "40"), ("weight_2", "5"), ("weight_3", "210"), ("object_1", obj1), ("object_2", obj2), ("object_3", obj3), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    
                    redis.sort(key: key1, by: "weight_*", get: "object_*", callback: { (res, err) in
                        XCTAssertNil(err)
                        XCTAssertEqual(res?[0]?.asString, obj2)
                        XCTAssertEqual(res?[1]?.asString, obj1)
                        XCTAssertEqual(res?[2]?.asString, obj3)
                        exp?.fulfill()
                    })
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortGetMulti() {
        localSetup {
            exp = expectation(description: "Sort by external keys and retrieve multiple external keys.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                let obj1 = "baby"
                let obj2 = "watermelon"
                let obj3 = "panda"
                redis.mset(("weight_1", "40"), ("weight_2", "5"), ("weight_3", "210"), ("object_1", obj1), ("object_2", obj2), ("object_3", obj3), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    
                    redis.sort(key: key1, by: "weight_*", get: "object_*", "#", callback: { (res, err) in
                        XCTAssertNil(err)
                        XCTAssertEqual(res?[0]?.asString, obj2)
                        XCTAssertEqual(res?[1]?.asString, val2)
                        XCTAssertEqual(res?[2]?.asString, obj1)
                        XCTAssertEqual(res?[3]?.asString, val1)
                        XCTAssertEqual(res?[4]?.asString, obj3)
                        XCTAssertEqual(res?[5]?.asString, val3)
                        exp?.fulfill()
                    })
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortStore() {
        localSetup {
            exp = expectation(description: "Sort list and store at `store key`.")
            
            let val1 = "20"
            let val2 = "5"
            let val3 = "90"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                let store = "store"
                redis.sort(key: key1, store: store, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asInteger
                    XCTAssertEqual(res0, 3)
                    
                    redis.sort(key: store, by: "nosort", callback: { (res, err) in
                        XCTAssertNil(err)
                        let res0 = res?[0]?.asString
                        let res1 = res?[1]?.asString
                        let res2 = res?[2]?.asString
                        XCTAssertEqual(res0, val2)
                        XCTAssertEqual(res1, val1)
                        XCTAssertEqual(res2, val3)
                        exp?.fulfill()
                    })
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortByGetHashes() {
        localSetup {
            exp = expectation(description: "Sort list and use BY and GET options against hash fields.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                let obj1 = "baby"
                let obj2 = "watermelon"
                let obj3 = "panda"
                let dispatchGroup = DispatchGroup()
                for _ in 0...5 {
                    dispatchGroup.enter()
                }
                redis.hmset("weight_1", fieldValuePairs: ("kg", "20"), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("weight_2", fieldValuePairs: ("kg", "5"), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("weight_3", fieldValuePairs: ("kg", "250"), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("object_1", fieldValuePairs: ("name", obj1), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("object_2", fieldValuePairs: ("name", obj2), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("object_3", fieldValuePairs: ("name", obj3), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                dispatchGroup.wait()
                
                redis.sort(key: key1, by: "weight_*->kg", get: "object_*->name", callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, obj2)
                    XCTAssertEqual(res?[1]?.asString, obj1)
                    XCTAssertEqual(res?[2]?.asString, obj3)
                    exp?.fulfill()
                })
            }
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_touchNone() {
        setup(major: 3, minor: 2, micro: 1) {
            exp = expectation(description: "Return 0 for bad key.")
            
            redis.touch(key: key1, callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertEqual(res, 0)
                exp?.fulfill()
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_touchOne() {
        setup(major: 3, minor: 2, micro: 1) {
            exp = expectation(description: "Alters the last access time of a key(s).")
            
            redis.set(key1, value: "Hello", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.touch(key: key1, callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res, 1)
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_touchMulti() {
        setup(major: 3, minor: 2, micro: 1) {
            exp = expectation(description: "Alters the last access time of a key(s).")
            
            redis.mset((key1, "val2"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.touch(key: key1, keys: key2, callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res, 2)
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_type() {
        localSetup {
            exp = expectation(description: "Returns the string representation of the type of the value stored at key.")
            
            redis.set(key1, value: "Hello", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.type(key: key1, callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res, "string")
                    exp?.fulfill()
                })
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_typeBadKey() {
        localSetup {
            exp = expectation(description: "Return `none` for bad key.")
            
            redis.type(key: key1, callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertEqual(res, "none")
                exp?.fulfill()
            })
            
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
}

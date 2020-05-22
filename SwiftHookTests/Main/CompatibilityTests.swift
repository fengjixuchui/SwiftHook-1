//
//  CompatibilityTests.swift
//  SwiftHookTests
//
//  Created by Yanni Wang on 21/5/20.
//  Copyright © 2020 Yanni. All rights reserved.
//

import XCTest
@testable import SwiftHook

// TODO: 兼容性测试 （KVO, swizzling, aspects）
class CompatibilityTests: XCTestCase {
    
    // MARK: KVO
    func testKVO() {
        var called = false
        let object = ObjectiveCTestObject()
        let kvo = object.observe(\.number) { (_, _) in
            called = true
        }
        
        XCTAssertFalse(called)
        object.number = 2
        XCTAssertTrue(called)
        
        called = false
        kvo.invalidate()
        XCTAssertFalse(called)
        object.number = 3
        XCTAssertFalse(called)
    }
    
    func testBeforeKVO() {
        do {
            let object = ObjectiveCTestObject()
            var expectation = [Int]()
            
            let token = try hookInstead(object: object, selector: #selector(setter: ObjectiveCTestObject.number), closure: { original, number in
                expectation.append(1)
                original(number)
                expectation.append(2)
                } as @convention(block) ((Int) -> Void, Int) -> Void)
            XCTAssertTrue(try testIsSwiftHookDynamicClass(object: object))
            let kvo = object.observe(\.number) { (_, _) in
                expectation.append(3)
            }
            XCTAssertTrue(try testIsSwiftHookDynamicThenKVOClass(object: object))
            XCTAssertEqual(expectation, [])
            
            object.number = 9
            XCTAssertEqual(expectation, [1, 2, 3])
            XCTAssertEqual(object.number, 9)
            
            expectation = []
            kvo.invalidate()
            XCTAssertTrue(try testIsSwiftHookDynamicClass(object: object))
            object.number = 10
            XCTAssertEqual(expectation, [1, 2])
            XCTAssertEqual(object.number, 10)
            
            expectation = []
            guard let hookToken = token as? HookToken else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertTrue(internalCancelHook(token: hookToken)!)
            XCTAssertTrue(try testIsNormalClass(object: object))
            object.number = 11
            XCTAssertEqual(expectation, [])
            XCTAssertEqual(object.number, 11)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testBeforeKVOReverseCancel() {
        do {
            let object = ObjectiveCTestObject()
            var expectation = [Int]()
            
            let token = try hookInstead(object: object, selector: #selector(setter: ObjectiveCTestObject.number), closure: { original, number in
                expectation.append(1)
                original(number)
                expectation.append(2)
                } as @convention(block) ((Int) -> Void, Int) -> Void)
            XCTAssertTrue(try testIsSwiftHookDynamicClass(object: object))
            let kvo = object.observe(\.number) { (_, _) in
                expectation.append(3)
            }
            XCTAssertTrue(try testIsSwiftHookDynamicThenKVOClass(object: object))
            XCTAssertEqual(expectation, [])
            
            object.number = 9
            XCTAssertEqual(expectation, [1, 2, 3])
            XCTAssertEqual(object.number, 9)
            
            expectation = []
            guard let hookToken = token as? HookToken else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertTrue(internalCancelHook(token: hookToken)!)
            XCTAssertTrue(try testIsSwiftHookDynamicThenKVOClass(object: object))
            object.number = 10
            XCTAssertEqual(expectation, [3])
            XCTAssertEqual(object.number, 10)
            
            expectation = []
            kvo.invalidate()
            XCTAssertTrue(try testIsSwiftHookDynamicClass(object: object))
            object.number = 11
            XCTAssertEqual(expectation, [])
            XCTAssertEqual(object.number, 11)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testAfterKVO() {
        do {
            let object = ObjectiveCTestObject()
            var expectation = [Int]()

            let kvo = object.observe(\.number) { (_, _) in
                expectation.append(3)
            }
            XCTAssertTrue(try testIsKVOClass(object: object))
            let token = try hookInstead(object: object, selector: #selector(setter: ObjectiveCTestObject.number), closure: { original, number in
                expectation.append(1)
                original(number)
                expectation.append(2)
                } as @convention(block) ((Int) -> Void, Int) -> Void)
            XCTAssertTrue(try testIsKVOClass(object: object))
            XCTAssertEqual(expectation, [])

            object.number = 9
            XCTAssertEqual(expectation, [1, 3, 2])
            XCTAssertEqual(object.number, 9)

            expectation = []
            guard let hookToken = token as? HookToken else {
                XCTAssertTrue(false)
                return
            }
            XCTAssertTrue(internalCancelHook(token: hookToken)!)
            XCTAssertTrue(try testIsKVOClass(object: object))
            object.number = 10
            XCTAssertEqual(expectation, [3])
            XCTAssertEqual(object.number, 10)

            expectation = []
            kvo.invalidate()
            XCTAssertTrue(try testIsNormalClass(object: object))
            object.number = 11
            XCTAssertEqual(expectation, [])
            XCTAssertEqual(object.number, 11)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    func testAfterKVOReverseCancel() {
        do {
            let object = ObjectiveCTestObject()
            var expectation = [Int]()

            let kvo = object.observe(\.number) { (_, _) in
                expectation.append(3)
            }
            XCTAssertTrue(try testIsKVOClass(object: object))
            let token = try hookInstead(object: object, selector: #selector(setter: ObjectiveCTestObject.number), closure: { original, number in
                expectation.append(1)
                original(number)
                expectation.append(2)
                } as @convention(block) ((Int) -> Void, Int) -> Void)
            XCTAssertTrue(try testIsKVOClass(object: object))
            XCTAssertEqual(expectation, [])

            object.number = 9
            XCTAssertEqual(expectation, [1, 3, 2])
            XCTAssertEqual(object.number, 9)

            expectation = []
            kvo.invalidate()
            XCTAssertTrue(try testIsSwiftHookDynamicClass(object: object))
            object.number = 11
            XCTAssertEqual(expectation, [1, 2])
            XCTAssertEqual(object.number, 11)

//            expectation = []
//            guard let hookToken = token as? HookToken else {
//                XCTAssertTrue(false)
//                return
//            }
//            XCTAssertTrue(internalCancelHook(token: hookToken)!)
//            XCTAssertTrue(try testIsNormalClass(object: object))
//            object.number = 10
//            XCTAssertEqual(expectation, [])
//            XCTAssertEqual(object.number, 10)
        } catch {
            XCTAssertNil(error)
        }
    }
    
    // MARK: Aspects
    
    func testBeforeAspects() {
        
    }
    
    func testAfterAspects() {
        
    }
    
    func testAComplicatedCase() {
        
    }
    
}

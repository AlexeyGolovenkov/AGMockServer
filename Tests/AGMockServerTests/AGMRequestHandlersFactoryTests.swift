//
//  AGMRequestHandlersFactory.swift
//  
//
//  Created by Alex Golovenkov on 15.12.2021.
//

import XCTest

@testable import AGMockServer

class AGMRequestHandlersFactoryTests: XCTestCase {
    override func tearDown() {
        AGMRequestHandlersFactory.clearAll()
        XCTAssertTrue(AGMRequestHandlersFactory.handlers.count == 0, "Factory must be empty")
    }
    
    func testAdd() {
        AGMRequestHandlersFactory.add(handler: ErrorHandler())
        XCTAssertTrue(AGMRequestHandlersFactory.handlers.count == 1, "Wrong number of handlers count: \(AGMRequestHandlersFactory.handlers.count)")
        guard let firstHandler = AGMRequestHandlersFactory.handlers.first else {
            XCTFail("Handler not found")
            return
        }
        XCTAssertTrue(firstHandler is ErrorHandler, "Wrong type of handler")
    }
    
    func testHandlerForUrl() {
        let echoHandler = EchoHandler()
        AGMRequestHandlersFactory.add(handler: echoHandler)
        let url = URL(string: "https://example.com/echo")!
        XCTAssertTrue(AGMRequestHandlersFactory.handler(for: url) === echoHandler, "Wrong handler for \(url)")
        
        let notHackedUrl = URL(string: "https://example.com")!
        XCTAssertNil(AGMRequestHandlersFactory.handler(for: notHackedUrl), "Some handler found for clear url")
    }
    
    func testRemove() {
        let errorHandler = ErrorHandler()
        let echoHandler = EchoHandler()
        AGMRequestHandlersFactory.add(handler: errorHandler)
        AGMRequestHandlersFactory.add(handler: echoHandler)
        XCTAssertEqual(AGMRequestHandlersFactory.handlers.count, 2, "Wrong content of handlers array")
        AGMRequestHandlersFactory.remove(handler: errorHandler)
        XCTAssertEqual(AGMRequestHandlersFactory.handlers.count, 1, "Removing doesn't work")
        XCTAssertTrue(AGMRequestHandlersFactory.handlers.first is EchoHandler, "Wrong type of handler")
    }
    
    func testRemoveByType() {
        AGMRequestHandlersFactory.add(handler: ErrorHandler())
        AGMRequestHandlersFactory.add(handler: EchoHandler())
        AGMRequestHandlersFactory.remove(handlerByClass: ErrorHandler.self)
        XCTAssertEqual(AGMRequestHandlersFactory.handlers.count, 1, "Removing doesn't work")
        XCTAssertTrue(AGMRequestHandlersFactory.handlers.first is EchoHandler, "Wrong type of handler")
    }
}

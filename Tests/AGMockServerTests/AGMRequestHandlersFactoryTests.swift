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
        AGMRequestHandlersFactory.main.clearAll()
        XCTAssertTrue(AGMRequestHandlersFactory.main.handlers.count == 0, "Factory must be empty")
    }
    
    func testAdd() {
        AGMRequestHandlersFactory.main.add(handler: ErrorHandler())
        XCTAssertTrue(AGMRequestHandlersFactory.main.handlers.count == 1, "Wrong number of handlers count: \(AGMRequestHandlersFactory.main.handlers.count)")
        guard let firstHandler = AGMRequestHandlersFactory.main.handlers.first else {
            XCTFail("Handler not found")
            return
        }
        XCTAssertTrue(firstHandler is ErrorHandler, "Wrong type of handler")
    }
    
    func testHandlerForUrl() {
        let echoHandler = EchoHandler()
        AGMRequestHandlersFactory.main.add(handler: echoHandler)
        let url = URL(string: "https://example.com/echo")!
        XCTAssertTrue(AGMRequestHandlersFactory.main.handler(for: url) === echoHandler, "Wrong handler for \(url)")
        
        let notHackedUrl = URL(string: "https://example.com")!
        XCTAssertNil(AGMRequestHandlersFactory.main.handler(for: notHackedUrl), "Some handler found for clear url")
    }
    
    func testRemove() {
        let errorHandler = ErrorHandler()
        let echoHandler = EchoHandler()
        AGMRequestHandlersFactory.main.add(handler: errorHandler)
        AGMRequestHandlersFactory.main.add(handler: echoHandler)
        XCTAssertEqual(AGMRequestHandlersFactory.main.handlers.count, 2, "Wrong content of handlers array")
        AGMRequestHandlersFactory.main.remove(handler: errorHandler)
        XCTAssertEqual(AGMRequestHandlersFactory.main.handlers.count, 1, "Removing doesn't work")
        XCTAssertTrue(AGMRequestHandlersFactory.main.handlers.first is EchoHandler, "Wrong type of handler")
    }
    
    func testRemoveByType() {
        AGMRequestHandlersFactory.main.add(handler: ErrorHandler())
        AGMRequestHandlersFactory.main.add(handler: EchoHandler())
        AGMRequestHandlersFactory.main.remove(handlerByClass: ErrorHandler.self)
        XCTAssertEqual(AGMRequestHandlersFactory.main.handlers.count, 1, "Removing doesn't work")
        XCTAssertTrue(AGMRequestHandlersFactory.main.handlers.first is EchoHandler, "Wrong type of handler")
    }
}

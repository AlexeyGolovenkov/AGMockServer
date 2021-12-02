//
//  File.swift
//  
//
//  Created by Alexey Golovenkov on 02.12.2021.
//

import XCTest
@testable import AGFakeServer

class FakeURLTests: XCTestCase {
    
    func testUrlWithoutParameters() {
        let url = URL(string: "https://localhost/path?param1=value1&param2=value2")
        
        let urlWithoutFirstParam = url?.withoutParameters(["param1"])
        XCTAssertTrue(urlWithoutFirstParam?.absoluteString == "https://localhost/path?param2=value2", "Wrong url: \(String(describing: urlWithoutFirstParam?.absoluteString))")
        
        let urlWithoutSecondParam = url?.withoutParameters(["param2"])
        XCTAssertTrue(urlWithoutSecondParam?.absoluteString == "https://localhost/path?param1=value1", "Wrong url: \(String(describing: urlWithoutSecondParam?.absoluteString))")
        
        let urlWithoutAllParams = url?.withoutParameters(["param2", "param1"])
        XCTAssertTrue(urlWithoutAllParams?.absoluteString == "https://localhost/path", "Wrong url: \(String(describing: urlWithoutAllParams?.absoluteString))")
        
        let sameUrl = url?.withoutParameters(["WrongParam"])
        XCTAssertTrue(sameUrl?.absoluteString == "https://localhost/path?param1=value1&param2=value2", "Wrong url: \(String(describing: sameUrl?.absoluteString))")
    }

    func testEquality() {
        let url = URL(string: "https://localhost/path?param1=value1&param2=value2")!
        let anotherUrl = URL(string: "https://localhost/path?param1=value2&param2=value1")!
        let urlWithFirstParam = URL(string: "https://localhost/path?param1=value1&param2=value1")!
        let urlWithSecondParam = URL(string: "https://localhost/path?param1=value2&param2=value2")!
        
        XCTAssertFalse(url ~ anotherUrl, "Parameters must not be equal")
        
        AGFakeServer.shared.ignoredParameters = ["param1", "param2"]
        XCTAssertTrue(url ~ anotherUrl, "Parameters must be equal")
        
        AGFakeServer.shared.ignoredParameters = ["param2"]
        XCTAssertTrue(url ~ urlWithFirstParam, "Parameters must be equal")
        XCTAssertFalse(url ~ urlWithSecondParam, "Parameters must be equal")
        
        AGFakeServer.shared.ignoredParameters = ["param1"]
        XCTAssertFalse(url ~ urlWithFirstParam, "Parameters must not be equal")
        XCTAssertTrue(url ~ urlWithSecondParam, "Parameters must be equal")
        
        AGFakeServer.shared.ignoredParameters = []
    }
}

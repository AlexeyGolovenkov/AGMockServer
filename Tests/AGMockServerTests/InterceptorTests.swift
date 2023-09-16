//
//  InterceptorTests.swift
//  
//
//  Created by Alexey Golovenkov on 16.09.2023.
//

import XCTest
@testable import AGMockServer

final class InterceptorTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
        if session == nil {
            session = server.hackedSession(for: URLSession.shared)
        }
        AGMRequestLog.main.clear()
    }

    override func tearDownWithError() throws {
        server.unregisterAllHandlers()
        server.removeAllInterceptors()
        XCTAssertTrue(AGMURLProtocol.interceptors.log().count == 0, "Interseptors not removed")
        super.tearDown()
    }

    func testSeveralInterceptors() throws {
        server.registerHandler(EchoHandler())
        (1...10).forEach { _ in
            server.addInterceptor(CounterHeader())
        }
        let url = URL(string: "https://localhost/echo?param1=value1&param2=value2")!
        let expectation = self.expectation(description: "Echo expectation")
        session.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                XCTFail("Error: \(String(describing: error))")
                expectation.fulfill()
                return
            }
            if let response = response as? HTTPURLResponse {
                let header = response.value(forHTTPHeaderField: CounterHeader.header)
                XCTAssertEqual("10", header, "Wrong header: \(String(describing: header)) instead of 10")
                XCTAssertEqual(response.url, url, "Wrong URL: \(String(describing: response.url))")
            } else {
                XCTFail("Response is not a HTTPURLResponse")
            }
            do {
                let response = try JSONDecoder().decode([String:String].self, from: data)
                XCTAssertTrue(response.count == 2, "Wrong response: \(response)")
                XCTAssertTrue(response["param1"] == "value1", "Wrong response: \(response)")
                XCTAssertTrue(response["param2"] == "value2", "Wrong response: \(response)")
            } catch {
                XCTFail("Can't parse request: \(error)")
            }
            expectation.fulfill()
        }.resume()
        wait(for: [expectation], timeout: 5)
    }
}

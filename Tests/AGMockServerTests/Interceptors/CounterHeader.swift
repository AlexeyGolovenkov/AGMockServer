//
//  CounterHeader.swift
//
//
//  Created by Alexey Golovenkov on 16.09.2023.
//

import AGMockServer
import Foundation

struct CounterHeader: AGMInterceptor {
    
    static let header = "Counter"
    
    func response(for response: URLResponse, from data: Data?) -> (response: URLResponse, data: Data?) {
        guard let httpResponse = response as? HTTPURLResponse else {
            return (response: response, data: data)
        }
        
        let headerValue = httpResponse.value(forHTTPHeaderField: Self.header) ?? ""
        var allHeaders = (httpResponse.allHeaderFields as? [String: String]) ?? [:]
        allHeaders[Self.header] = "\((Int(headerValue) ?? 0) + 1)"
        let handledResponse = HTTPURLResponse(
            url: httpResponse.url ?? URL(string: "https://localhost")!,
            statusCode: httpResponse.statusCode,
            httpVersion: "1.0",
            headerFields: allHeaders
        ) ?? HTTPURLResponse()
        
        return (response: handledResponse, data: data)
    }
}

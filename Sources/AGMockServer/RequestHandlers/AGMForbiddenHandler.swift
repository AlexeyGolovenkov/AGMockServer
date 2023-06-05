//
//  AGMForbiddenHandler.swift
//  
//
//  Created by Alexey Golovenkov on 05.06.2023.
//

import Foundation

class AGMForbiddenHandler: AGMRequestHandler {
    var urlFormat = ""
    
    func response(for url: URL, from body: Data?) -> (response: HTTPURLResponse, data: Data) {
        let response = HTTPURLResponse(url: url,
                                       statusCode: Constants.forbiddenStatus,
                                       httpVersion: Constants.httpVersion,
                                       headerFields: [:]) ?? HTTPURLResponse()
        return (response: response, data: defaultData(for: url))
    }
    
    func defaultData(for url: URL) -> Data {
        let response = #"{"error": "Forbidden"}"#.data(using: .utf8)
        return response ?? Data()
    }
}

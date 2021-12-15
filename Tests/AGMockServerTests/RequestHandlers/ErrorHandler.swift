//
//  File.swift
//  
//
//  Created by Alex Golovenkov on 15.12.2021.
//

import Foundation
import AGMockServer

class ErrorHandler: AGMRequestHandler {
    let urlFormat = "error"
    
    func defaultData(for url: URL) -> Data {
        return "{\"error\": \"Error\"}".data(using: .utf8) ?? Data()
    }
}

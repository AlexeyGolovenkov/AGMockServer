//
//  EchoHandler.swift
//  
//
//  Created by Alexey Golovenkov on 05.12.2021.
//

import Foundation
import AGMockServer


/// Sample handler
class EchoHandler: AGMRequestHandler {
    
    // This handler will be called for every URL containing 'echo'
    var urlFormat = "echo"
    
    func defaultData(for url: URL) -> Data {
        let response = self.parameters(from: url)
        let data = (try? JSONEncoder().encode(response)) ?? Data()
        return data
    }
    
    private func parameters(from url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        guard let parameters = components?.queryItems else {
            return [:]
        }
        var parsedParameters = [String: String]()
        for item in parameters {
            parsedParameters[item.name] = item.value
        }
        return parsedParameters
    }
}

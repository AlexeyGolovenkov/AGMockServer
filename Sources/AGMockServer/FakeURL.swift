//
//  File.swift
//  
//
//  Created by Alexey Golovenkov on 02.12.2021.
//

import Foundation

extension URL {
    func withoutParameters(_ names: [String]) -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        var parameters = components?.queryItems
        names.forEach {
            parameters?.removeParameter($0)
        }
        if parameters?.count == 0 {
            // necessary to prevent extra ? in url
            parameters = nil
        }
        components?.queryItems = parameters
        return components?.url ?? self
    }
}

infix operator ~ : ComparisonPrecedence
func ~ (left: URL, right: URL) -> Bool {
    let ignoredParameters = AGMockServer.shared.ignoredParameters
    return left.withoutParameters(ignoredParameters) == right.withoutParameters(ignoredParameters)
}

fileprivate extension Array where Element == URLQueryItem {
    mutating func removeParameter(_ name: String) {
        let index = self.firstIndex(where: { (item) -> Bool in
            item.name == name
        })
        guard let itemIndex = index else {
            // parameter not found
            return
        }
        self.remove(at: itemIndex)
    }
}

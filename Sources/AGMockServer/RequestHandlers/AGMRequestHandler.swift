//
//  AGFakeRESTRequestHandler.swift
//  
//
//  Created by Alexey Golovenkov on 04.12.2021.
//

import Foundation

/// Handler for hacked HTTP request
public protocol AGMRequestHandler: AnyObject {
    
    /// Format of URL path that can be handled by the handler. Supports regex.
    var urlFormat: String { get }
    
    /// Checks if  the provided url can be processed by the handler.
    /// Default implementation checks urlFormat. Implement your own version of this method if you need more complex logic here.
    /// - Parameter url: URL to be checked (and possibly processed)
    /// - Returns: Returns true if response for provided url be prepared by this hander
    func canHandle(_ url: URL) -> Bool
    
    /// Prepares response for provided url
    /// - Parameter url: URL to be handled
    /// - Parameter data: Body of HTTP request
    /// - Returns: Response and data to be sent to network client
    func response(for url: URL, from body: Data?) -> (response: HTTPURLResponse, data: Data)
            
    /// Implement this method to provide data for response(for:from:) method if no incomming data analysis is needed. Default implementation returns empty Data object.
    /// - Returns: Data to be sent to network client.
    func defaultData(for url: URL) -> Data
}

// MARK: - Default implementation

public extension AGMRequestHandler {
    
    func response(for url: URL, from data: Data?) -> (response: HTTPURLResponse, data: Data) {
        let response = HTTPURLResponse(url: url,
                                       statusCode: Constants.successStatus,
                                       httpVersion: Constants.httpVersion,
                                       headerFields: [:]) ?? HTTPURLResponse()
        return (response: response, data: data ?? defaultData(for: url))
    }
    
    func canHandle(_ url: URL) -> Bool {
        let urlString = url.absoluteString
        let range = NSRange(location: 0, length: urlString.utf16.count)
        do {
            let regex = try NSRegularExpression(pattern: self.urlFormat)
            return regex.firstMatch(in: urlString, options: [], range: range) != nil
        } catch {
            return false
        }
    }
    
    func defaultData(for url: URL) -> Data {
        return Data()
    }
}

// MARK: - Constants

enum Constants {
    static let successStatus = 200
    static let forbiddenStatus = 403
    static let notFoundStatus = 404
    static let httpVersion = "1.0"
}

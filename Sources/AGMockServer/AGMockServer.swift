//
//  AGRequestLog.swift
//
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

public class AGMockServer {
        
    enum AGMockError: Error {
        case autohandling(String)
        case noHandler(String)
    }
    
    public struct CustomResponse {
        var data: Data = Data()
        var statusCode: Int = 200
        var headers: [String:String]? = nil
        
        mutating func setString(_ string: String) {
            data = string.data(using: .utf8) ?? Data()
        }
        
        mutating func setValue<T>(_ value: T) where T : Encodable {
            data = (try? JSONEncoder().encode(value)) ?? Data()
        }
        
        func HTTPResponse(for url: URL) -> HTTPURLResponse {
            return HTTPURLResponse(url: url,
                                   statusCode: self.statusCode,
                                   httpVersion: Constants.httpVersion,
                                   headerFields: self.headers) ?? HTTPURLResponse()
        }
    }
    
    public static var shared = AGMockServer()
    
    public var ignoredParameters = [String]()
    
    private var session: URLSession?
           
    public func hackedSession(for session: URLSession) -> URLSession {
        let configuration = session.configuration
        var protocols = configuration.protocolClasses ?? []
        protocols.insert(AGMURLProtocol.self, at: 0)
        configuration.protocolClasses = protocols
        self.session = session
        return URLSession(configuration: configuration)
    }
    
    /// Prepares custom response for specified URL. It will be sent once as a response when clinet app tryes to get data from the url.
    /// - Parameters:
    ///   - response: Response to be sent to client
    ///   - url: URL to be handled
    ///   - count: number of times the client should receive our response. Default value is 1
    /// - Note: Use this method as a lightweight alternative to AGMRequestHandler
    public func prepareResponse(_ response: CustomResponse, for url: URL, count: Int = 1) {
        guard count > 0 else {
            return
        }
        for _ in 0 ..< count {
            AGMURLProtocol.predefinedResponses.addResponse(response, for: url)
        }        
    }
        
    /// Removes predefined response for specified URL
    ///
    /// Don't  use this method to remove response you've created in prepareResponse(:,:,:) method when you already received the response. AGMockServer removes the used response automatically, so don't worry about clearing the garbage.
    ///
    /// - Parameters:
    ///   - url: url you don't want to handle any more
    ///   - count: Number of responses you want to delete
    public func removeResponse(for url: URL, count: Int = 1) {
        guard count > 0 else {
            return
        }
        for _ in 0 ..< count {
            AGMURLProtocol.predefinedResponses.removeResponse(for: url)
        }
    }
    
    /// Registers a new handler
    /// - Parameter handler: New handler to be added to handlers list
    public func registerHandler(_ handler: AGMRequestHandler) {
        AGMRequestHandlersFactory.add(handler: handler)
    }
    
    /// Removes handler from handlers list
    /// - Parameter handler: Handler to be removed
    public func unregisterHandler(_ handler: AGMRequestHandler) {
        AGMRequestHandlersFactory.remove(handler: handler)
    }
    
    /// Removes all handlers
    public func unregisterAllHandlers() {
        AGMRequestHandlersFactory.clearAll()
    }
}

fileprivate enum Constants {
    static let defaultStatus = 200
    static let httpVersion = "1.0"
}

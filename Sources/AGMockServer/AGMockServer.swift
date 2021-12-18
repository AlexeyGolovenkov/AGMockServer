//
//  AGRequestLog.swift
//
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

public class AGMockServer {
    
    public static let handlerReadyNotification = Notification.Name("AGMHandlerReady")
    
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
    }
    
    public static var shared = AGMockServer()
    
    public var ignoredParameters = [String]()
    
    public var autoHandling = true {
        didSet {
            AGMURLProtocol.autoHandling = autoHandling
            if autoHandling {
                sendAllResponses()
            }
        }
    }
    
    private var session: URLSession?
           
    public func hackedSession(for session: URLSession) -> URLSession {
        let configuration = session.configuration
        var protocols = configuration.protocolClasses ?? []
        protocols.insert(AGMURLProtocol.self, at: 0)
        configuration.protocolClasses = protocols
        self.session = session
        return URLSession(configuration: configuration)
    }
    
    public func send(_ userResponse: CustomResponse, for url: URL) throws {
        guard !autoHandling else {
            throw AGMockError.autohandling("Set autohandling to false when use send method")
        }
        
        guard let urlProtocol = AGMHandlersStorage.shared.handler(for: url) else {
            throw AGMockError.noHandler("No handlers found for \(url.absoluteString)")
        }
        AGMHandlersStorage.shared.handlers.remove(urlProtocol)
        DispatchQueue.global(qos: .background).async() {
            let response = HTTPURLResponse(url: url,
                                           statusCode: userResponse.statusCode,
                                           httpVersion: Constants.httpVersion,
                                           headerFields: userResponse.headers) ?? HTTPURLResponse()
            urlProtocol.send(response, data: userResponse.data)
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
    
    // MARK: - Private methods
        
    private func sendAllResponses() {
        let handlers = AGMHandlersStorage.shared.handlers.allObjects
        AGMHandlersStorage.shared.handlers.removeAllObjects()
        DispatchQueue.global(qos: .background).async() {
            for urlProtocol in handlers {
                guard let url = urlProtocol.request.url else {
                    continue
                }
                let answer = urlProtocol.handler.response(for: url, from: nil)
                urlProtocol.send(answer.response, data: answer.data)
            }
        }
    }
}

fileprivate enum Constants {
    static let defaultStatus = 200
    static let httpVersion = "1.0"
}

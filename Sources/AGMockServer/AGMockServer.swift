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
    
    struct CustomResponse {
        var data: Data
        var statusCode: Int
        var headers: [String:String]?
    }
    
    public static var shared = AGMockServer()
    
    public var ignoredParameters = [String]()
    
    var autoHandling = true {
        didSet {
            AGMURLProtocol.autoHandling = autoHandling
            if autoHandling {
                sendAllResponses()
            }
        }
    }
    
    private var session: URLSession?
           
    func hackedSession(for session: URLSession) -> URLSession {
        let configuration = session.configuration
        var protocols = configuration.protocolClasses ?? []
        protocols.insert(AGMURLProtocol.self, at: 0)
        configuration.protocolClasses = protocols
        self.session = session
        return URLSession(configuration: configuration)
    }
    
    func finishResponse(for url: URL, with data: Data?) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + Constants.timeout) {
            guard let urlProtocol = AGMHandlersStorage.shared.handler(for: url) else {
                return
            }
            let answer = urlProtocol.handler.response(for: url, from: data)
            urlProtocol.send(answer.response, data: answer.data)
        }
    }
    
    func send(_ userResponse: CustomResponse, for url: URL) throws {
        guard autoHandling else {
            throw AGMockError.autohandling("Set autohandling to false when use send method")
        }
        
        guard let urlProtocol = AGMHandlersStorage.shared.handler(for: url) else {
            throw AGMockError.noHandler("No handlers found for \(url.absoluteString)")
        }
        AGMHandlersStorage.shared.handlers.remove(urlProtocol)
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + Constants.timeout) {
            let response = HTTPURLResponse(url: url,
                                           statusCode: userResponse.statusCode,
                                           httpVersion: Constants.httpVersion,
                                           headerFields: userResponse.headers) ?? HTTPURLResponse()
            urlProtocol.send(response, data: userResponse.data)
        }
    }
    
    // MARK: - Private methods
        
    private func sendAllResponses() {
        let handlers = AGMHandlersStorage.shared.handlers.allObjects
        AGMHandlersStorage.shared.handlers.removeAllObjects()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + Constants.timeout) {
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
    static let timeout: TimeInterval = 0.200
}

//
//  AGRequestLog.swift
//
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

public class AGFakeServer {
    public static var shared = AGFakeServer()
    
    public var ignoredParameters = [String]()
    
    var autoHandling = true {
        didSet {
            FakeURLProtocol.autoHandling = autoHandling
            if autoHandling {
                sendAllResponses()
            }
        }
    }
    
    private let config: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FakeURLProtocol.self]
        return configuration
    }()
    
    private var session: URLSession?
           
    func register(for session: URLSession) -> URLSession {
        let configuration = session.configuration
        var protocols = configuration.protocolClasses ?? []
        protocols.insert(FakeURLProtocol.self, at: 0)
        configuration.protocolClasses = protocols
        self.session = session
        return URLSession(configuration: configuration)
    }
    
    func unregister() -> URLSession? {
        return self.session
    }
    
    func finishResponse(for url: URL, with data: Data?) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + Constants.timeout) {
            guard let urlProtocol = FakeHandlersStorage.shared.handler(for: url) else {
                return
            }
            let answer = urlProtocol.handler.response(for: url, from: data)
            urlProtocol.send(answer.response, data: answer.data)
        }
    }
    
    // MARK: - Private methods
    
    private func setupURLSession() {
        session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
    }
        
    private func sendAllResponses() {
        let handlers = FakeHandlersStorage.shared.handlers.allObjects
        FakeHandlersStorage.shared.handlers.removeAllObjects()
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

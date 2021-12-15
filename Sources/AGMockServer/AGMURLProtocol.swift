//
//  File.swift
//  
//
//  Created by Alexey Golovenkov on 02.12.2021.
//

import Foundation

final class AGMURLProtocol: URLProtocol {
    var handler: AGMRequestHandler!
    static var autoHandling = true
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return AGMRequestHandlersFactory.handler(for: url) != nil
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let url = task.originalRequest?.url else { return false }
        let result = AGMRequestHandlersFactory.handler(for: url) != nil
        if result {
            AGMRequestLog.main.add(url)
        }
        return result
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        handler = AGMRequestHandlersFactory.handler(for: url)
        if AGMURLProtocol.autoHandling {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2) {
                let answer = self.handler.response(for: url, from: nil)
                self.send(answer.response, data: answer.data)
            }
        } else {
            AGMHandlersStorage.shared.add(self)
        }
    }
        
    override func stopLoading() {}
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    func send(_ response: URLResponse, data: Data) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}

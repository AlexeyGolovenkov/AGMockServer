//
//  File.swift
//  
//
//  Created by Alexey Golovenkov on 02.12.2021.
//

import Foundation

final class FakeURLProtocol: URLProtocol {
    var handler: AGFakeRESTRequestHandler!
    static var autoHandling = false
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return FakeRESTRequestHandlersFactory.handler(for: url) != nil
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let url = task.originalRequest?.url else { return false }
        let result = FakeRESTRequestHandlersFactory.handler(for: url) != nil
        if result {
            AGRequestLog.main.add(url)
        }
        return result
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        handler = FakeRESTRequestHandlersFactory.handler(for: url)
        if FakeURLProtocol.autoHandling {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.2) {
                let answer = self.handler.response(for: url, from: nil)
                self.send(answer.response, data: answer.data)
            }
        } else {
            FakeHandlersStorage.shared.add(self)
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

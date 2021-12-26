//
//  File.swift
//  
//
//  Created by Alexey Golovenkov on 02.12.2021.
//

import Foundation

final class AGMURLProtocol: URLProtocol {
    var handler: AGMRequestHandler!
    static var predefinedResponses = AGMPredefinedResponsesStorage()
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return AGMRequestHandlersFactory.handler(for: url) != nil || Self.predefinedResponses.response(for: url) != nil
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let url = task.originalRequest?.url else { return false }
        let result = AGMRequestHandlersFactory.handler(for: url) != nil || Self.predefinedResponses.response(for: url) != nil
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
        
        if let response = Self.predefinedResponses.response(for: url) {
            DispatchQueue.global(qos: .background).async {
                self.send(response.HTTPResponse(for: url), data: response.data)
            }
            Self.predefinedResponses.removeResponse(for: url)
            return
        }
        
        handler = AGMRequestHandlersFactory.handler(for: url)
        DispatchQueue.global(qos: .background).async {
            let answer = self.handler.response(for: url, from: nil)
            self.send(answer.response, data: answer.data)
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

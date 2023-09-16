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
    static var interceptors = AGMInterceptorStorage()
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return AGMRequestHandlersFactory.main.handler(for: url) != nil || Self.predefinedResponses.response(for: url) != nil
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let url = task.originalRequest?.url else { return false }
        let result = AGMRequestHandlersFactory.main.handler(for: url) != nil || Self.predefinedResponses.response(for: url) != nil
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
                let httpResponse = response.HTTPResponse(for: url)
                let handledAnswer = self.applyInterceptors(to: httpResponse, with: response.data)
                AGMResponseLog.main.add((response: handledAnswer.response, data: handledAnswer.data))
                self.send(handledAnswer.response, data: handledAnswer.data ?? Data())
            }
            Self.predefinedResponses.removeResponse(for: url)
            return
        }
        
        handler = AGMRequestHandlersFactory.main.handler(for: url)
        DispatchQueue.global(qos: .background).async {
            let answer = self.handler.response(for: url, from: nil)
            let handledAnswer = self.applyInterceptors(to: answer.response, with: answer.data)
            AGMResponseLog.main.add(handledAnswer)
            self.send(handledAnswer.response, data: handledAnswer.data ?? Data())
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
    
    func applyInterceptors(to response: URLResponse, with data: Data?) -> (response: URLResponse, data: Data?) {
        var responseWithData = (response: response, data: data)
        let interceptors = Self.interceptors.log()
        interceptors.forEach { interceptor in
            responseWithData = interceptor.response(for: responseWithData.response, from: responseWithData.data)
        }
        return responseWithData
    }
}

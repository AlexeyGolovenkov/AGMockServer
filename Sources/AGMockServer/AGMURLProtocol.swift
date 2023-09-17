//
//  File.swift
//  
//
//  Created by Alexey Golovenkov on 02.12.2021.
//

import Foundation

final class AGMURLProtocol: URLProtocol {
    static var predefinedResponses = AGMPredefinedResponsesStorage()
    static var interceptorStorage = AGMInterceptorStorage()
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        guard let url = task.originalRequest?.url else { return false }
        let result = AGMRequestHandlersFactory.main.handler(for: url) != nil || Self.predefinedResponses.response(for: url) != nil
        return result
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        
        AGMRequestLog.main.add(url)
        
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
        
        guard let handler = AGMRequestHandlersFactory.main.handler(for: url) else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        DispatchQueue.global(qos: .background).async {
            let answer = handler.response(for: url, from: nil)
            let handledAnswer = self.applyInterceptors(to: answer.response, with: answer.data)
            AGMResponseLog.main.add(handledAnswer)
            self.send(handledAnswer.response, data: handledAnswer.data ?? Data())
        }
    }
        
    override func stopLoading() {
        // This method must be implemented as a part of URLProtocol
    }
    
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
        let interceptors = Self.interceptorStorage.log()
        interceptors.forEach { interceptor in
            responseWithData = interceptor.response(for: responseWithData.response, from: responseWithData.data)
        }
        return responseWithData
    }
}

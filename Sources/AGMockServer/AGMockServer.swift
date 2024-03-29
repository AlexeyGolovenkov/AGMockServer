//
//  AGRequestLog.swift
//
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

open class AGMockServer {
        
    enum AGMockError: Error {
        case autohandling(String)
        case noHandler(String)
    }
    
    public struct CustomResponse {
        public var data: Data
        public var statusCode: Int
        public var headers: [String:String]?
        
        public init(data: Data = Data(), statusCode: Int = 200, headers: [String : String]? = nil) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
        }
        
        public mutating func setResponseBody(_ string: String) {
            data = string.data(using: .utf8) ?? Data()
        }
        
        public mutating func setResponseBody<T>(_ value: T) where T : Encodable {
            data = (try? JSONEncoder().encode(value)) ?? Data()
        }
        
        public func HTTPResponse(for url: URL) -> HTTPURLResponse {
            return HTTPURLResponse(url: url,
                                   statusCode: self.statusCode,
                                   httpVersion: Constants.httpVersion,
                                   headerFields: self.headers) ?? HTTPURLResponse()
        }
    }
    
    public static var shared = AGMockServer()
    
    public var ignoredParameters = [String]()
    
    /// If true, MockServer return 403 response for all requests without registered handlers. Else these requests are handled by system network services as usual.
    ///
    /// This property is useful to find unit tests that use real network instead of mocked data.
    public var isNetworkBlocked: Bool = false
    
    /// if true, MockServer stores detailed information for every request and it's resonse, including response data
    ///
    /// Detailed log may take a lot of memory resources. So sometimes it's useful to block collecting this data if it is not important for current tasks
    public var isCollectingDetailedData = true
    
    public var requests: [URL] {
        AGMRequestLog.main.log()
    }
    
    public var responses: [(response: URLResponse, data: Data?)] {
        AGMResponseLog.main.log()
    }
    
    public var detailedLog: [AGMDetailedLogItem] {
        AGMDetailedLog.main.log()        
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
        AGMRequestHandlersFactory.main.add(handler: handler)
    }
    
    /// Removes handler from handlers list
    /// - Parameter handler: Handler to be removed
    public func unregisterHandler(_ handler: AGMRequestHandler) {
        AGMRequestHandlersFactory.main.remove(handler: handler)
    }
    
    /// Removes all handlers
    public func unregisterAllHandlers() {
        AGMRequestHandlersFactory.main.clearAll()
    }
    
    /// Registers resource file as data source for some requests
    ///
    /// See also: ``AGMResourceBasedHandler``
    ///
    /// - Parameters:
    ///   - format: Format of URL to be handled with provided file. Supports regex.
    ///   - fileName: Name of file with answer
    ///   - bundle: Bundle that contains the file
    @discardableResult
    public func registerResponse(for format: String, with fileName: String, in bundle: Bundle = .main) -> some AGMRequestHandler {
        let splittedName = fileName.splitFileName()
        let handler = AGMResourceBasedHandler(for: format, with: splittedName.fileName, ext: splittedName.fileNameExtention, in: bundle)
        registerHandler(handler)
        return handler
    }
    
    /// Executes closure with provided handlers and unregisters these handlers
    /// - Parameters:
    ///   - handlers: Handlers to be used with closure
    ///   - block: Closure to be executed
    public func execute(withHandlers handlers: [AGMRequestHandler], block: () async throws -> ()) async throws {
        handlers.forEach { registerHandler($0) }
        try await block()
        handlers.forEach { unregisterHandler($0) }
    }
    
    public func addInterceptor(_ interceptor: AGMInterceptor) {
        AGMURLProtocol.interceptorStorage.add(interceptor)
    }
    
    public func removeAllInterceptors() {
        AGMURLProtocol.interceptorStorage.clear()
    }
    
    /// Removes all data from the list of requested urls
    public func clearRequestLog() {
        AGMRequestLog.main.clear()
    }
    
    /// Removes all data from the list of sent responses
    public func clearResponseLog() {
        AGMResponseLog.main.clear()
    }
    
    public func clearDetailedLog() {
        AGMDetailedLog.main.clear()
    }
    
    /// Clears all available logs
    public func clearLogs() {
        clearRequestLog()
        clearResponseLog()
        clearDetailedLog()
    }
}

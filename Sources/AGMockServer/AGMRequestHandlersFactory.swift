//
//  FakeRESTRequestHandlersFactory.swift
//  
//
//  Created by Alexey Golovenkov on 04.12.2021.
//

import Foundation

final class AGMRequestHandlersFactory {
    
    private(set) static var main = AGMRequestHandlersFactory()
    
    internal var handlers = [AGMRequestHandler]()
    
    private var handlersLock = NSLock()
    
    func handler(for url: URL) -> AGMRequestHandler? {
        var foundHandler: AGMRequestHandler?
        handlersLock.lock()
        for handler in handlers {
            if handler.canHandle(url) {
                foundHandler = handler
                break
            }
        }
        handlersLock.unlock()
        if let foundHandler {
            return foundHandler
        }
        if AGMockServer.shared.isNetworkBlocked {
            return AGMForbiddenHandler()
        }
        return nil
    }
    
    func add(handler requestHandler: AGMRequestHandler) {
        handlersLock.lock()
        handlers.append(requestHandler)
        handlersLock.unlock()
    }
    
    func clearAll() {
        handlersLock.lock()
        handlers.removeAll()
        handlersLock.unlock()
    }
    
    func remove(handler requestHandler: AGMRequestHandler) {
        handlersLock.lock()
        guard let index = handlers.firstIndex(where: {$0 === requestHandler}) else {
            handlersLock.unlock()
            return
        }
        handlers.remove(at: index)
        handlersLock.unlock()
    }

    func remove<T>(handlerByClass handlerClass: T.Type) {
        handlersLock.lock()
        guard let index = handlers.firstIndex(where: {type(of: $0) == handlerClass}) else {
            handlersLock.unlock()
            return
        }
        handlers.remove(at: index)
        handlersLock.unlock()
    }
}

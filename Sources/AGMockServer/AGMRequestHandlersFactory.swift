//
//  FakeRESTRequestHandlersFactory.swift
//  
//
//  Created by Alexey Golovenkov on 04.12.2021.
//

import Foundation

final class AGMRequestHandlersFactory {
    private static var handlers = [AGMRequestHandler]()
    
    static func handler(for url: URL) -> AGMRequestHandler? {
        for handler in handlers {
            if handler.canHandle(url) {
                return handler
            }
        }
        return nil
    }
    
    static func add(handler requestHandler: AGMRequestHandler) {
        handlers.append(requestHandler)
    }
    
    static func clearAll() {
        handlers.removeAll()
    }
    
    static func remove(handler requestHandler: AGMRequestHandler) {
        guard let index = handlers.firstIndex(where: {$0 === requestHandler}) else {
            return
        }
        handlers.remove(at: index)
    }

    static func remove<T>(handlerByClass handlerClass: T.Type) {
        guard let index = handlers.firstIndex(where: {type(of: $0) == handlerClass}) else {
            return
        }
        handlers.remove(at: index)
    }
}

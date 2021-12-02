//
//  FakeHandlersStorage.swift
//  
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

class FakeHandlersStorage {
    static var shared = FakeHandlersStorage()
    var handlers = NSHashTable<FakeURLProtocol>(options: .weakMemory)
    
    func add(_ handler: FakeURLProtocol) {
        handlers.add(handler)
    }
    
    func handler(for url: URL) -> FakeURLProtocol? {
        return handlers.allObjects.first {
            guard let existingURL = $0.request.url else {
                return false
            }
            return existingURL ~ url
        }
    }
}

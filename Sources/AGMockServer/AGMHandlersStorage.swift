//
//  FakeHandlersStorage.swift
//  
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

class AGMHandlersStorage {
    static var shared = AGMHandlersStorage()
    var handlers = NSHashTable<AGMURLProtocol>(options: .weakMemory)
    
    func add(_ handler: AGMURLProtocol) {
        handlers.add(handler)
    }
    
    func handler(for url: URL) -> AGMURLProtocol? {
        return handlers.allObjects.first {
            guard let existingURL = $0.request.url else {
                return false
            }
            return existingURL ~ url
        }
    }
}

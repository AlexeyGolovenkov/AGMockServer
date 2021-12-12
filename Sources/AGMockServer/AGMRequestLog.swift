//
//  AGRequestLog.swift
//  
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

public class AGMRequestLog {
    
    static var main = AGMRequestLog()
    
    private var storage = [URL]()
    
    func add(_ url: URL) {
        storage.append(url)
    }
    
    func clear() {
        storage.removeAll()
    }
    
    func log() -> [URL] {
        return storage
    }
}

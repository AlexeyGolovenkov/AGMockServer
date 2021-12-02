//
//  File.swift
//  
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

public class AGRequestLog {
    
    static var main = AGRequestLog()
    
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

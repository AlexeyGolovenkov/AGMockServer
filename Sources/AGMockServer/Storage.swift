//
//  File.swift
//  
//
//  Created by Alexey Golovenkov on 16.09.2023.
//

import Foundation

public protocol AGMStorage: AnyObject {
    
    associatedtype Item
    
    var data: AGMStorageData<Item> { get }
    
    func add(_ item: Item)
    
    func clear()
    
    func log() -> [Item]
}

public extension AGMStorage {
        
    func add(_ item: Item) {
        data.storageLock.lock()
        data.storage.append(item)
        data.storageLock.unlock()
    }
    
    func clear() {
        data.storageLock.lock()
        data.storage.removeAll()
        data.storageLock.unlock()
    }
    
    func log() -> [Item] {
        defer {
            data.storageLock.unlock()
        }
        data.storageLock.lock()
        return data.storage
    }
}

public class AGMStorageData<Item> {
    
    fileprivate var storage = [Item]()
    fileprivate var storageLock = NSLock()
}


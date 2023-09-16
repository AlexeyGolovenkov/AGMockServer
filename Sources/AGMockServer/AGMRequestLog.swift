//
//  AGRequestLog.swift
//  
//
//  Created by Alexey Golovenkov on 03.12.2021.
//

import Foundation

public class AGMRequestLog: AGMStorage {
    
    public typealias Item = URL
    
    public private(set) static var main = AGMRequestLog()
    
    public var data = AGMStorageData<Item>()
}

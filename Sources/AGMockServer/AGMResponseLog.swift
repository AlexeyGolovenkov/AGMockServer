//
//  AGMResponseLog.swift
//
//
//  Created by Alexey Golovenkov on 16.09.2023.
//

import Foundation

public class AGMResponseLog: AGMStorage {
    
    public typealias Item = (response: URLResponse, data: Data?)
    
    public var data = AGMStorageData<Item>()
    
    public private(set) static var main = AGMResponseLog()
}

//
//  AGMInterceptorStorage.swift
//
//
//  Created by Alexey Golovenkov on 16.09.2023.
//

import Foundation

class AGMInterceptorStorage: AGMStorage {
    
    typealias Item = AGMInterceptor
    
    var data = AGMStorageData<Item>()
}

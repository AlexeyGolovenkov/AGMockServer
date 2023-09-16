//
//  AGMInterceptor.swift
//
//
//  Created by Alexey Golovenkov on 16.09.2023.
//

import Foundation

public protocol AGMInterceptor {
    
    func response(for response: URLResponse, from data: Data?) -> (response: URLResponse, data: Data?)
}

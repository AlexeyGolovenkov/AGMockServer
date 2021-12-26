//
//  AGMPredefinedResponsesStorage.swift
//  
//
//  Created by Alex Golovenkov on 26.12.2021.
//

import Foundation

class AGMPredefinedResponsesStorage {
    struct PredefinedResponse {
        let url: URL
        let response: AGMockServer.CustomResponse
    }
    
    private var storage: [PredefinedResponse] = []
    
    func addResponse(_ response: AGMockServer.CustomResponse, for url: URL) {
        storage.append(PredefinedResponse(url: url, response: response))
    }
    
    func response(for url: URL) -> AGMockServer.CustomResponse? {
        return storage.first { $0.url == url }?.response
    }
    
    func removeResponse(for url: URL) {
        guard let index = storage.firstIndex(where: { $0.url == url }) else {
            return
        }
        storage.remove(at: index)
    }
}

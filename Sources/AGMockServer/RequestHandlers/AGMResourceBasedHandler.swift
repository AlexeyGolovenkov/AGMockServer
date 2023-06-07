//
//  AGMResourceBasedHandler.swift
//  
//
//  Created by Alexey Golovenkov on 03.06.2023.
//

import Foundation

public class AGMResourceBasedHandler: AGMRequestHandler {
    
    public let urlFormat: String
    public let fileName: String
    public let fileNameExtension: String?
    public let bundle: Bundle
    
    public init(for format: String, with fileName: String, ext: String?, in bundle: Bundle = .main) {
        urlFormat = format
        self.fileName = fileName
        fileNameExtension = ext
        self.bundle = bundle
    }
    
    public func defaultData(for _: URL) -> Data {
        guard
            let fileUrl = bundle.url(forResource: fileName, withExtension: fileNameExtension),
            let data = try? Data(contentsOf: fileUrl)
        else {
            return Data()
        }
        return data
    }
    
    public func response(for url: URL, from data: Data?) -> (response: HTTPURLResponse, data: Data) {
        let data = defaultData(for: url)
        let statusCode = data.isEmpty ?
            Constants.notFoundStatus :
            Constants.successStatus
        let response = HTTPURLResponse(url: url,
                                       statusCode: statusCode,
                                       httpVersion: Constants.httpVersion,
                                       headerFields: [:]) ?? HTTPURLResponse()
        return (response: response, data: data)
    }
}

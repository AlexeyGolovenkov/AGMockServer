//
//  String+Tools.swift
//  
//
//  Created by Alexey Golovenkov on 05.06.2023.
//

import Foundation

extension String {
    
    func splitFileName() -> (fileName: String, fileNameExtention: String?) {
        let splitted = split(separator: ".").map { String($0) }
        if splitted.count == 1 {
            return (fileName: self, fileNameExtention: nil)
        }
        
        let ext = splitted.last ?? ""
        let splittedFileName = splitted.dropLast()
        let fileName = splittedFileName.joined(separator: ".")
        return (fileName: fileName, fileNameExtention: String(ext))
    }
}

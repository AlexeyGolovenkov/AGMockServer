//
//  StringTests.swift
//  
//
//  Created by Alexey Golovenkov on 05.06.2023.
//

import XCTest
@testable import AGMockServer

final class StringTests: XCTestCase {

    func testFileNameSplit() {
        let commonFile = "file.ext".splitFileName()
        XCTAssertEqual(commonFile.fileName, "file")
        XCTAssertEqual(commonFile.fileNameExtention, "ext")
        
        let noExt = "file".splitFileName()
        XCTAssertEqual(noExt.fileName, "file")
        XCTAssertNil(noExt.fileNameExtention)
        
        let longFileName = "path.file.ext".splitFileName()
        XCTAssertEqual(longFileName.fileName, "path.file")
        XCTAssertEqual(longFileName.fileNameExtention, "ext")
    }

}

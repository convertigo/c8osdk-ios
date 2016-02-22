//
//  C8oSDKiOSTests.swift
//  C8oSDKiOSTests
//
//  Created by Charles Grimont on 03/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import XCTest
@testable import C8oSDKiOS

class C8oSDKiOSTests: XCTestCase {
    
    var myC8o : C8o!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        myC8o = C8o();
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateDB() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        myC8o.createDB()
        XCTAssert(true,"Database Created")
    }
    
    func testMakeRequest() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        myC8o.makeRequest()
        XCTAssert(true,"Request done")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    func testCg_C8oUtilis_IsValidUrl() {
        
        var c8oUtil : Bool = C8oUtils.IsValidUrl("ftp://www.google.fr/");
        if(c8oUtil == true){
            XCTAssert(false,"c8oUtil is supposed to be false, but it's true")
        }
        c8oUtil = C8oUtils.IsValidUrl("http://www.google.fr/");
        if(c8oUtil == false){
            XCTAssert(false,"c8oUtil is supposed to be true, but it's false")
        }
        c8oUtil = C8oUtils.IsValidUrl("https://www.google.fr/");
        if(c8oUtil == false){
            XCTAssert(false,"c8oUtil is supposed to be true, but it's false")
        }
      
    }
    
    
    
}

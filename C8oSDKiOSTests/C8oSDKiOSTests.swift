//
//  C8oSDKiOSTests.swift
//  C8oSDKiOSTests
//
//  Created by Charles Grimont on 03/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import XCTest
import Foundation
import SwiftyJSON
import Alamofire

@testable import C8oSDKiOS

class C8oSDKiOSTests: XCTestCase {
    
    var myC8o : C8o!
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        //myC8o = C8o();
        myC8o = try! C8o(endpoint: "https://192.168.100.95:18080/convertigo/projects/Sample05", c8oSettings: C8oSettings().SetDefaultDatabaseName("sample05").SetLogLevelLocal(C8oLogLevel.ERROR))
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
    
    func testCg_C8oUtilis_IsValidEndpoint()
    {
        var endpoint : String = "https://192.168.100.95:18080/convertigo/projects/Sample05"
        let regex : NSRegularExpression = C8o.RE_ENDPOINT
        var regexV  = regex.matchesInString(endpoint, options: [], range: NSMakeRange(0, endpoint.characters.count ))
        if(regexV.first == nil){
            XCTAssert(false,"regex is supposed to be ok")
        }
        print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(0)))
        print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(1)))
        print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(2)))
        print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(3)))
        print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(4)))
        
        endpoint = "htp://192.168.100.95:18080/convertigo/projects/Sample05"
        regexV = regex.matchesInString(endpoint, options: [], range: NSMakeRange(0, endpoint.characters.count ))
        if( regexV.first != nil){
            XCTAssert(false,"regex is not supposed to be ok")
        }
    }
    func atest01()
    {
        myC8o.Log.Trace("Test 01 trace");
        myC8o.Log.Debug("Test 01 debug");
        myC8o.Log.Info("Test 01 info");
        myC8o.Log.Warn("Test 01 warn");
        myC8o.Log.Error("Test 01 error");
        myC8o.Log.Fatal("Test 01 fatal");
        
        if (myC8o.Log.IsTrace) {
            myC8o.Log.Fatal("Test 01.bis trace");
            myC8o.Log.Trace("Test 01 bis trace");
        }
        if (myC8o.Log.IsDebug) {
            myC8o.Log.Fatal("Test 01.bis debug");
            myC8o.Log.Debug("Test 01 bis debug");
        }
        if (myC8o.Log.IsInfo) {
            myC8o.Log.Fatal("Test 01.bis info");
            myC8o.Log.Info("Test 01 bis info");
        }
        if (myC8o.Log.IsWarn) {
            myC8o.Log.Fatal("Test 01.bis warn");
            myC8o.Log.Warn("Test 01 bis warn");
        }
        if (myC8o.Log.IsError) {
            myC8o.Log.Fatal("Test 01.bis error");
            myC8o.Log.Error("Test 01 bis error");
        }
        if (myC8o.Log.IsFatal) {
            myC8o.Log.Fatal("Test 01.bis fatal");
            myC8o.Log.Fatal("Test 01 bis fatal");
        }

        
        
        print("Test 01\n")
        print("==========\n")
        myC8o.CallXml(".sample05.GetServerInfo")?.ThenUI({
            (response : NSXMLParser?, parameters : Dictionary<String, NSObject>?)->() in
            
                //return C8oPromise<NSXMLParser>
                print(C8oTranslator.XmlToString(response!))
                print("\n==========\n")

                self.myC8o.CallJson(("\n==========\n"))?.ThenUI({
                    (response : NSObject?, parameters : Dictionary<String, NSObject>?)->() in
                    print(String(JSON(response!).rawString()))
                    print("\n==========\n")
                   
                    
                })
            
            })
        
            
        }
    
    func testCgAlamo(){
        /*Alamofire.request(.GET, "", parameters: ["consumer_key": "MKfScrf1JOGPilOkrTifJVutkyYOFskZtVeKqk6z"]).responseJSON(){
            (data) in
            print(data)
            print("aaaaaaa")
        }*/
        
        //let semaphore = dispatch_semaphore_create(0)
        print("1")
        Alamofire.request(.GET, "https://api.500px.com/v1/photos", parameters: ["consumer_key": "MKfScrf1JOGPilOkrTifJVutkyYOFskZtVeKqk6z"])
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                    
                }
                print(response)
                print("2")
                 //dispatch_semaphore_signal(semaphore);
                print("3")
            }
        print("4")
        //dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
            }
}
    


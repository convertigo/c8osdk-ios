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
import Fuzi


@testable import C8oSDKiOS

class C8oSDKiOSTests: XCTestCase {
    
    var myC8o : C8o!
    let HOST = "buildus.twinsoft.fr"
    let PROJECT_PATH = "/convertigo/projects/ClientSDKtesting"
    let PORT = ":28080"
    let PREFIX = "http://"
    let PREFIXS = "https://"
    
    
    enum Stuff {
        case C8O, C8O_BIS, C8O_FS, C8O_FS_PULL, C8O_FS_PUSH, C8O_LC, SetGetInSession
    }
    func Get(enu : Stuff)throws ->C8o?
    {
        switch (enu){
        case .C8O :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: nil)
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            return c8o
        break
            
        case .C8O_BIS :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: nil)
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            return c8o
        break
            
        case .C8O_FS :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetDefaultDatabaseName("clientsdktesting"))
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            return c8o
        break
            
        /*case .C8O_FS_PULL :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetDefaultDatabaseName("clientsdktesting"))
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            let json : JSON = c8o.callJso
            return c8o
        break*/
            
        default:
            return nil
            break
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        //myC8o = C8o();
        myC8o = try! C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetDefaultDatabaseName("sample05").SetLogLevelLocal(C8oLogLevel.ERROR))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCreateDB() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        myC8o.createDB()
        
        XCTAssert(true,"testCreateDB succesfull")
    }
    
    func testMakeRequest() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        myC8o.makeRequest()
        
        XCTAssert(true,"testMakeRequest succesfull")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
    
    func testC8oBadEndpoint(){
        do {
            try _ = C8o(endpoint: PREFIX + HOST + PORT, c8oSettings: nil)
        }
        catch {
            XCTAssert(true,"testC8oBadEndpoint succesfull")
        }
    }
    
    func testC8oDefault(){
        try! _ = Get(.C8O)
        XCTAssert(true,"testC8oDefault succesfull")
    }
    
    func testC8oDefaultPing(){
        let c8o: C8o = try! Get(.C8O)!
        print("avant doc")
        let doc  = try! c8o.CallXml(".Ping")?.Sync()
        print("apres doc")
        //let pong = (doc! as XMLDocument).xpath("/document/pong")
        //print(pong)
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
        
        XCTAssert(true,"testCg_C8oUtilis_IsValidUrl succesfull")
      
    }
    
    func testCg_C8oUtilis_IsValidEndpoint()
    {
        var endpoint : String = "http://192.168.100.95:18080/convertigo/projects/Sample05"
        let regex : NSRegularExpression = C8o.RE_ENDPOINT
        var regexV  = regex.matchesInString(endpoint, options: [], range: NSMakeRange(0, endpoint.characters.count ))
        if(regexV.first == nil){
            XCTAssert(false,"regex is supposed to be ok")
        }
        print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(0)))
        print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(1)))
        if(regexV[0].rangeAtIndex(2).location != NSNotFound)
        {
            print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(2)))
        }
        
        print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(3)))
        //print((endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(4)))
        
        endpoint = "htp://192.168.100.95:18080/convertigo/projects/Sample05"
        regexV = regex.matchesInString(endpoint, options: [], range: NSMakeRange(0, endpoint.characters.count ))
        if( regexV.first != nil){
            XCTAssert(false,"regex is not supposed to be ok")
        }
        
        XCTAssert(true,"testCg_C8oUtilis_IsValidEndpoint succesfull")
    }
    func test01()
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

        //let expectation = expectationWithDescription("Alamofire")
        
        /*print("Test 01\n")
        print("==========\n")
        myC8o.CallXml(".sample05.GetServerInfo")?.ThenUI({
            (response : XMLDocument?, parameters : Dictionary<String, NSObject>?)->() in
                //return C8oPromise<NSXMLParser>
                print(C8oTranslator.XmlToString(response!))
                print("\n==========\n")
            })
        myC8o.CallJson(("\n==========\n"))?.ThenUI({
            (response : NSObject?, parameters : Dictionary<String, NSObject>?)->() in
                print(String(JSON(response!).rawString()))
                print("\n==========\n")
            })
            
        expectation.fulfill()
        waitForExpectationsWithTimeout(100.0, handler: nil)
        */
        XCTAssert(true,"test01 succesfull")
        }
    
    func testCgAlamoRequestJsonSampleExpetation(){

        let expectation = expectationWithDescription("Alamofire")
        
        print("1) : Before Alamofire request")
        Alamofire.request(.GET, "https://api.500px.com/v1/photos", parameters: ["consumer_key": "MKfScrf1JOGPilOkrTifJVutkyYOFskZtVeKqk6z"])
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    expectation.fulfill()
                    print("2) Request must be print just after this")
                    print("JSON: \(JSON)")
                    
                }
                //print(response)
                print("3) Request must has been printed")
            }
        
        print("4) Waiting for Alamofire request's response with a time out set to 10 seconds")
        waitForExpectationsWithTimeout(10.0, handler: nil)
        print("5) All must be done")
        
        XCTAssert(true,"testCgAlamoRequestJsonSampleExpetation succesfull")
        
    }
    
    func testCgAlamoRequestJsonSample()
    {
        let semaphore = dispatch_semaphore_create(0)
        let queue = dispatch_queue_create("com.convertigo.co8.queue", DISPATCH_QUEUE_CONCURRENT)
        
        let request = Alamofire.request(.GET, "http://httpbin.org/get", parameters: ["foo": "bar"])
        
        request.response(
            queue: queue,
            responseSerializer: Request.JSONResponseSerializer(options: .AllowFragments),
            completionHandler: { response in
                    print("Parsing JSON on thread: \(NSThread.currentThread()) is main thread: \(NSThread.isMainThread())")
                
                    print(response.result.value)
                
                    dispatch_async(dispatch_get_main_queue()) {
                        print("Am I back on the main thread: \(NSThread.isMainThread())")
                    }
                dispatch_semaphore_signal(semaphore);
            })
                
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        
        XCTAssert(true,"testCgAlamoRequestJsonSample succesfull")

    }
    
    
    
}
    


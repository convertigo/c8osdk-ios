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
            
        case .C8O_BIS :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: nil)
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            return c8o
            
        case .C8O_FS :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetDefaultDatabaseName("clientsdktesting"))
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            return c8o
            
        case .C8O_FS_PULL :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetDefaultDatabaseName("qa_fs_pull"))
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            let json = try! c8o.CallJson(".InitFsPull")!.Sync()
            XCTAssertTrue(json!["document"]["ok"].boolValue)
            return c8o
            
        case .C8O_FS_PUSH :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetDefaultDatabaseName("qa_fs_push"))
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            let json = try! c8o.CallJson(".InitFsPush")!.Sync()
            XCTAssertTrue(json!["document"]["ok"].boolValue)
            return c8o
            
        case .C8O_LC :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: nil)
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            return c8o
            
        case .SetGetInSession :
            let c8o : C8o = try Get(.C8O_BIS)!
            let ts : String = String(NSTimeIntervalSince1970 * 1000)
            var doc = try c8o.CallXml(".SetInSession", parameters: "ts", ts).Sync()
            var newTs = doc?.xpath("/document/pong/ts").first!.stringValue
            XCTAssertEqual(ts, newTs)
            doc = try c8o.CallXml(".GetFromSession").Sync()
            newTs = doc?.xpath("/document/session/expression").first!.stringValue
            XCTAssertEqual(ts, newTs)
            return c8o
            
        default:
            return nil
        }
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testC8oBadEndpoint(){
        do {
            try _ = C8o(endpoint: PREFIX + HOST + PORT, c8oSettings: nil)
        }
        catch let e as ErrorType{
            XCTAssertEqual(e._code, C8oError.ArgumentException("")._code)
        }
        
    }
    
    func testC8oDefault(){
        try! _ = Get(.C8O)
    }
    
    func testC8oDefaultPing(){
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping").Sync()
        var pong : NSObject = (doc?.xpath("/document/pong").count)!
        XCTAssertEqual(1,pong)
        pong = (doc?.xpath("/document/pong").first?.tag)!
        XCTAssertEqual(pong, "pong")

    }
    
    func testC8oDefaultPingWait(){
        let c8o: C8o = try! Get(.C8O)!
        let promise : C8oPromise<XMLDocument> = c8o.CallXml(".Ping")
        NSThread.sleepForTimeInterval(0.5)
        let doc : XMLDocument = try! promise.Sync()!
        var pong : NSObject = (doc.xpath("/document/pong").count)
        XCTAssertEqual(1,pong)
        pong = (doc.xpath("/document/pong").first?.tag)!
        XCTAssertEqual(pong, "pong")
    }
    
    
    func testC8oUnknownHostCallAndLog() {
        var exceptionLog : C8oException? = nil
        var exception : C8oException? = nil
        do {
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + "ee:28080" + PROJECT_PATH,
                                    c8oSettings: C8oSettings().SetLogOnFail{
                                        clos in
                                            exceptionLog = clos.exception
                                        
                                            
                                    })
            let C8oP : C8oPromise<XMLDocument> = c8o.CallXml(".Ping")
            NSThread.sleepForTimeInterval(3)
            try C8oP.Sync()
        }
        catch let ex as C8oException{
            exception = ex
        }
        catch{
            XCTAssertTrue(false)
        }
        XCTAssertNotNil(exception)
        XCTAssertTrue(exception! is C8oException)
        XCTAssertNotNil(exceptionLog)
        XCTAssertTrue(exceptionLog! is C8oException)
        //TODO finish tests...

    }
    
    func testC8oUnknownHostCallWait(){
        var exception : C8oException? = nil
        do {
            let c8o : C8o = try C8o(endpoint : PREFIX + HOST + "ee:28080" + PROJECT_PATH, c8oSettings: nil)
            let promise : C8oPromise = c8o.CallXml(".Ping")
            NSThread.sleepForTimeInterval(0.5)
            try promise.Sync()
        }
        catch let ex as C8oException{
            exception = ex
        }
        catch {
            
        }
        XCTAssertNotNil(exception)
        XCTAssertTrue(exception! is C8oException)
        //TODO finish tests...
        
    }
    
    func testC8oDefaultPingOneSingleValue() {
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping",  parameters: "var1", "value one").Sync()
        let value = doc?.xpath("/document/pong/var1").first?.stringValue
        XCTAssertEqual("value one", value)
    }
    
    func testC8oDefaultPingTwoSingleValues(){
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping", parameters: "var1", "value one", "var2","value two").Sync()
        var value = doc?.xpath("/document/pong/var1").first?.stringValue
        XCTAssertEqual("value one", value)
        value = doc?.xpath("/document/pong/var2").first?.stringValue
        XCTAssertEqual("value two", value)
    }
    
    func testC8oDefaultPingTwoSingleValuesOneMulti(){
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping",
            parameters: "var1", "value one",
            "var2","value two",
            "mvar1", ["mvalue one", "mvalue two", "mvalue three"]
        ).Sync()
        var value = doc?.xpath("/document/pong/var1").first?.stringValue
        XCTAssertEqual("value one", value)
        value = doc?.xpath("/document/pong/var2").first?.stringValue
        XCTAssertEqual("value two", value)
        value = doc?.xpath("/document/pong/mvar1[1]").first?.stringValue
        XCTAssertEqual("mvalue one", value)
        value = doc?.xpath("/document/pong/mvar1[2]").first?.stringValue
        XCTAssertEqual("mvalue two", value)
        value = doc?.xpath("/document/pong/mvar1[3]").first?.stringValue
        XCTAssertEqual("mvalue three", value)
        let count = doc?.xpath("/document/pong/mvar1").count
        XCTAssertEqual(3,count)
    }
    
    func testC8oDefaultPingTwoSingleValuesTwoMulti(){
        
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping",
            parameters: "var1", "value one",
            "var2","value two",
            "mvar1", ["mvalue one", "mvalue two", "mvalue three"],
            "mvar2", ["mvalue2 one"]
        ).Sync()
        var value = doc?.xpath("/document/pong/var1").first?.stringValue
        XCTAssertEqual("value one", value)
        value = doc?.xpath("/document/pong/var2").first?.stringValue
        XCTAssertEqual("value two", value)
        value = doc?.xpath("/document/pong/mvar1[1]").first?.stringValue
        XCTAssertEqual("mvalue one", value)
        value = doc?.xpath("/document/pong/mvar1[2]").first?.stringValue
        XCTAssertEqual("mvalue two", value)
        value = doc?.xpath("/document/pong/mvar1[3]").first?.stringValue
        XCTAssertEqual("mvalue three", value)
        var count = doc?.xpath("/document/pong/mvar1").count
        XCTAssertEqual(3,count)
        value = doc?.xpath("/document/pong/mvar2[1]").first?.stringValue
        XCTAssertEqual("mvalue2 one", value)
        count = doc?.xpath("/document/pong/mvar2").count
        XCTAssertEqual(1,count)
        
    }
    
    func testC8oCheckJsonTypes(){
        let c8o: C8o = try! Get(.C8O)!
        var json = try! c8o.CallJson(".JsonTypes",
            parameters: "var1", "value one",
            "mvar1", ["mvalue one", "mvalue two", "mvalue three"]
            )!.Sync()
        json = json!["document"]
        let pong = json!["pong"]
        var value : NSObject = pong["var1"].stringValue
        XCTAssertEqual("value one",value)
        let mvar1 = pong["mvar1"]
        value = mvar1[0].stringValue
        XCTAssertEqual("mvalue one",value)
        value = mvar1[1].stringValue
        XCTAssertEqual("mvalue two",value)
        value = mvar1[2].stringValue
        XCTAssertEqual("mvalue three",value)
        let count = mvar1.count
        XCTAssertEqual(3,count)
        let complex = json!["complex"]
        let aa : AnyObject? = complex["isNull"].string
        let exist = complex["isNull"].isExists()
        XCTAssertNil(aa)
        XCTAssertTrue(exist)
        //XCTAssertEqual(NSNull(), value)
        value = complex["isInt3615"].numberValue
        XCTAssertEqual(3615, value)
        value = complex["isStringWhere"].stringValue
        XCTAssertEqual("where is my string?!", value)
        value = complex["isDoublePI"].doubleValue
        XCTAssertEqual(3.141592653589793, value)
        value = complex["isBoolTrue"].boolValue
        XCTAssert(value as! Bool)
        value = complex["ÉlŸz@-node"].stringValue
        XCTAssertEqual("that's ÉlŸz@", value)
    }
    
    func testSetGetInSession(){
        try! Get(.SetGetInSession)
    }
    
    func testCheckNoMixSession(){
        try! Get(.SetGetInSession)
        let c8o : C8o = try! Get(.C8O)!
        let doc = try! c8o.CallXml(".GetFromSession").Sync()
        let expression = doc?.xpath("/document/session/expression").count
        XCTAssertEqual(0, expression)
    }
    
    func CheckLogRemoteHelper(c8o : C8o, lvl : String, msg : String) throws ->() {
        /*let doc : XMLDocument = try! c8o.CallXml(".GetLogs").Sync()!
        print(doc)
        print((doc.xpath("/document/line/text()").first?.rawXML))
        let line : JSON = JSON((doc.xpath("/document/line/text()")))
        XCTAssertEqual(lvl, line[2].stringValue)
        var newMsg = line[4].stringValue
        newMsg  = newMsg[newMsg.rangeOfString("logID=")!]
        XCTAssertEqual(msg,newMsg)*/
    }
    
    func testCheckLogRemote() {
        /*let c8o : C8o = try! C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH , c8oSettings: nil)
        c8o.LogC8o = false
        let id : String = "logID=" + String(NSTimeIntervalSince1970 * 1000)
        try! c8o.CallXml(".GetLogs", parameters: "init", id).Sync()
        c8o.Log.Error(id)
        try! CheckLogRemoteHelper(c8o, lvl: "ERROR", msg: id)
        c8o.Log.Error(id, exceptions: C8oException(message: "for test", exception: nil))
        c8o.Log.Error(id)*/
    }
    
}



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
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetLogRemote(false))
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            return c8o
            
        case .C8O_BIS :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetLogRemote(false))
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
            var doc2 = try c8o.CallXml(".GetFromSession").Sync()
            newTs = doc2?.xpath("/document/session/expression").first?.stringValue
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
        let isnil : AnyObject? = complex["isNull"].string
        let exist = complex["isNull"].isExists()
        XCTAssertNil(isnil)
        XCTAssertTrue(exist)
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
        let doc : XMLDocument = try! c8o.CallXml(".GetLogs").Sync()!
        let jsonString : String = (doc.xpath("/document/line").first?.stringValue)!
        if let dataFromString = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let line = JSON(data: dataFromString)
            XCTAssertEqual(lvl, line[2].string)
            var newMsg = line[4].stringValue
            newMsg  = newMsg.substringWithRange(Range<String.Index>(start: newMsg.rangeOfString("logID=")!.startIndex, end: newMsg.endIndex))
            print(newMsg)
            XCTAssertEqual(msg,newMsg)
        }

        
    }
    
    func testCheckLogRemote() {
        let c8o : C8o = try! C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH , c8oSettings: C8oSettings().SetLogC8o(false))
        let id : String = "logID=" + String(NSTimeIntervalSince1970 * 1000)
        try! c8o.CallXml(".GetLogs", parameters: "init", id).Sync()
        c8o.Log.Error(id)
        try! CheckLogRemoteHelper(c8o, lvl: "ERROR", msg: id)
        c8o.Log.Error(id, exceptions: C8oException(message: "for test"))
        try! CheckLogRemoteHelper(c8o, lvl: "ERROR", msg: (id + "\nOptional(Error Domain=com.convertigo.clientsdk.exception.C8oException Code=1 \"for test\" UserInfo={NSLocalizedFailureReason=for test})"))
        c8o.Log.Warn(id)
        try! CheckLogRemoteHelper(c8o, lvl: "WARN", msg: id)
        c8o.Log.Info(id)
        try! CheckLogRemoteHelper(c8o, lvl: "INFO", msg: id)
        c8o.Log.Debug(id)
        try! CheckLogRemoteHelper(c8o, lvl: "DEBUG", msg: id)
        c8o.Log.Trace(id)
        try! CheckLogRemoteHelper(c8o, lvl: "TRACE", msg: id)
        c8o.Log.Fatal(id)
        try! CheckLogRemoteHelper(c8o, lvl: "FATAL", msg: id)
        c8o.LogRemote = false
        c8o.Log.Info(id)
        NSThread.sleepForTimeInterval(0.05)
        let doc = try! c8o.CallXml(".GetLogs").Sync()
        let value = doc?.xpath("/document/line").first?.stringValue
        XCTAssertNil(value);
        
    }
    
    func testC8oDefaultPromiseXmlOne() {
        let c8o : C8o = try! Get(.C8O)!
        var xdoc : [XMLDocument] = [XMLDocument]()
        var xthread : [NSThread] = [NSThread]()
        var xparam : [Dictionary<String, NSObject>] = [Dictionary<String, NSObject>]()
        
        let condition : NSCondition = NSCondition()
        condition.lock()
            c8o.CallXml(".Ping", parameters: "var1", "step 1").Then { (doc, param) -> (C8oPromise<XMLDocument>?) in
                xdoc.append(doc)
                xthread.append(NSThread.currentThread())
                xparam.append(param)
                condition.lock()
                    condition.signal()
                condition.unlock()
                return nil
        }
        condition.wait()
        condition.unlock()
        let value = xdoc[0].xpath("/document/pong/var1").first?.stringValue
        XCTAssertEqual("step 1", value)
        XCTAssertNotEqual(NSThread.currentThread(), xthread[0])
        XCTAssertEqual("step 1", xparam[0]["var1"])
    }
    
    func testC8oDefaultPromiseJsonThree(){
        let c8o : C8o = try! Get(.C8O)!
        var xjson : [JSON] = [JSON]()
        let condition : NSCondition = NSCondition()
        condition.lock()
        c8o.CallJson(".Ping", parameters: "var1", "step 1")!
            .Then{ (json, param) -> (C8oPromise<JSON>?) in
                xjson.append(json)
                return c8o.CallJson(".Ping", parameters: "var1", "step 2")!
            }!.Then{(json, param) -> (C8oPromise<JSON>?) in
                xjson.append(json)
                return c8o.CallJson(".Ping", parameters: "var1", "step 3")!
            }!.Then{(json, param) -> (C8oPromise<JSON>?) in
                xjson.append(json)
                condition.lock()
                    condition.signal()
                condition.unlock()
                return nil
            }
        
        condition.waitUntilDate(NSDate(timeIntervalSinceNow: 5.0))
        condition.unlock()
        var value = xjson[0]["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        value = xjson[1]["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 2", value)
        value = xjson[2]["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 3", value)


    }
    

    func testC8oDefaultPromiseUI(){
        
        let asyncExpectation = expectationWithDescription("longRunningFunction")
        let UiThread = NSThread.currentThread()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        let c8o : C8o = try! self.Get(.C8O)!
        var xjson : [JSON] = [JSON]()
        var xthread : [NSThread] = [NSThread]()
        let condition : NSCondition = NSCondition()
        condition.lock()
        c8o.CallJson(".Ping", parameters: "var1", "step 1")?.ThenUI({ (json, param) -> (C8oPromise<JSON>?) in
            xjson.append(json)
            xthread.append(NSThread.currentThread())
            return c8o.CallJson(".Ping", parameters: "var1", "step 2")
        })?.Then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson.append(json)
            xthread.append(NSThread.currentThread())
            return c8o.CallJson(".Ping", parameters: "var1", "step 3")
        })?.ThenUI({ (json, param) -> (C8oPromise<JSON>?) in
            xjson.append(json)
            xthread.append(NSThread.currentThread())
            condition.lock()
                condition.signal()
            condition.unlock()
            return nil
        })
        condition.wait()
        condition.unlock()
            var value = xjson[0]["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 1", value)
            value = xjson[1]["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 2", value)
            value = xjson[2]["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 3", value)
            XCTAssertEqual(UiThread, xthread[0])
            XCTAssertNotEqual(UiThread, xthread[1])
            XCTAssertEqual(UiThread, xthread[2])
            asyncExpectation.fulfill()
        });
        self.waitForExpectationsWithTimeout(20) { error in
        }
    }
    
    func testC8oDefaultPromiseFail(){
        
        let c8o : C8o = try! Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 3, repeatedValue: nil)
        var xfail : [NSError] = [NSError]()
        var xparam : [Dictionary<String, NSObject>] = [Dictionary<String, NSObject>]()
        let condition : NSCondition = NSCondition()
        condition.lock()
        c8o.CallJson(".Ping", parameters: "var1", "step 1")?
            .Then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[0] = json
            return c8o.CallJson(".Ping", parameters: "var1", "step 2")!
            })?.Then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[1] = json
                if(json != nil)
                {
                    throw  C8oException(message: "random failure")
                }
                return c8o.CallJson("Ping", parameters: "var1", "step 3")!
            })?.Then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[2]? = json
                condition.lock()
                    condition.signal()
                condition.unlock()
                return nil
            })?.Fail({ (ex, param) -> () in
                xfail.append(ex)
                xparam.append(param)
                condition.lock()
                    condition.signal()
                condition.unlock()
            })
        condition.waitUntilDate(NSDate(timeIntervalSinceNow: 5.0))
        condition.unlock()
        var value = xjson[0]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        value = xjson[1]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 2", value)
        XCTAssertNil(xjson[2])
        XCTAssertEqual("random failure", (xfail[0] as! C8oException).message)
        XCTAssertEqual("step 2", xparam[0]["var1"])
    }
    
    func testC8oDefaultPromiseFailUI(){
        
        let asyncExpectation = expectationWithDescription("testC8oDefaultPromiseFailUI")
        let UiThread = NSThread.currentThread()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        let c8o : C8o = try! self.Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 3, repeatedValue: nil)
        var xfail : [NSError] = [NSError]()
        var xparam : [Dictionary<String, NSObject>] = [Dictionary<String, NSObject>]()
        var xthread : [NSThread] = [NSThread]()
        let condition : NSCondition = NSCondition()
        condition.lock()
        c8o.CallJson(".Ping", parameters: "var1", "step 1")?
            .Then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[0] = json
                return c8o.CallJson(".Ping", parameters: "var1", "step 2")!
            })?.Then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[1] = json
                if(json != nil)
                {
                    throw  C8oException(message: "random failure")
                }
                return c8o.CallJson("Ping", parameters: "var1", "step 3")!
            })?.Then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[2]? = json
                condition.lock()
                condition.signal()
                condition.unlock()
                return nil
            })?.FailUI{ (ex, param) -> () in
                xfail.append(ex)
                xparam.append(param)
                xthread.append(NSThread.currentThread())
                condition.lock()
                condition.signal()
                condition.unlock()
            }
        condition.waitUntilDate(NSDate(timeIntervalSinceNow: 5.0))
        condition.unlock()
        var value = xjson[0]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        value = xjson[1]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 2", value)
        XCTAssertNil(xjson[2])
        XCTAssertEqual("random failure", (xfail[0] as! C8oException).message)
        XCTAssertEqual("step 2", xparam[0]["var1"])
        XCTAssertEqual(UiThread, xthread[0])
        asyncExpectation.fulfill()
        });
        self.waitForExpectationsWithTimeout(20) { error in
        }
    }
    
    func testC8oDefaultPromiseSync(){
        
        let c8o : C8o = try! Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 2, repeatedValue: nil)
        xjson[1] = try! c8o.CallJson(".Ping", parameters: "var1", "step 1")?.Then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[0] = json
            return c8o.CallJson(".Ping", parameters: "var1", "step 2")
        })?.Sync()
        var value = xjson[0]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        value = xjson[1]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 2", value)

    }
    
    func testC8oDefaultPromiseSyncFail(){
        
        let c8o : C8o = try! Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 2, repeatedValue: nil)
        var exception : C8oException? = nil as C8oException?
        do{
            xjson[1] = try c8o.CallJson(".Ping", parameters: "var1", "step 1")?.Then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[0] = json
                if(json != nil){
                    throw C8oException(message: "random failure")
                }
                return c8o.CallJson(".Ping", parameters: "var1", "step 2")
            })?.Sync()
        }
        catch let ex as C8oException {
            exception = ex
        }
        catch{
            
        }
        
        let value = xjson[0]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        XCTAssertNil(xjson[1])
        XCTAssertNotNil(exception)
        XCTAssertEqual("random failure", exception?.message)
        
    }
    
    func testC8oDefaultPromiseNested(){
        let c8o : C8o = try! self.Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 6, repeatedValue: nil)
        xjson[5] = try! c8o.CallJson(".Ping", parameters: "var1", "step 1")?.Then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[0] = json
            return c8o.CallJson(".Ping", parameters: "var1", "step 2")?.Then({ (json2, param2) -> (C8oPromise<JSON>?) in
                xjson[1] = json2
                return c8o.CallJson(".Ping", parameters: "var1", "step 3")?.Then({ (json3, param3) -> (C8oPromise<JSON>?) in
                    xjson[2] = json3
                    return c8o.CallJson(".Ping", parameters: "var1", "step 4")
                })
            })
        })?.Then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[3] = json
            return c8o.CallJson(".Ping", parameters: "var1", "step 5")?.Then({ (json2, param2) -> (C8oPromise<JSON>?) in
                xjson[4] = json2
                return nil
            })
        })?.Sync()
        var value = xjson[0]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        value = xjson[1]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 2", value)
        value = xjson[2]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 3", value)
        value = xjson[3]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 4", value)
        value = xjson[4]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 5", value)
        value = xjson[5]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 5", value)
     
    }
    
    func testC8oDefaultPromiseNestedFail(){
        
        /*let c8o : C8o = try! self.Get(.C8O)!
        var xjson : [JSON] = [JSON]()
        var xfail : [C8oException?] = [C8oException?](count: 2, repeatedValue: nil)
        var ed : C8oException
        do{
            xjson[5] = try! c8o.CallJson(".Ping", parameters: "var1", "step 1")?.Then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[0] = json
                return c8o.CallJson(".Ping", parameters: "var1", "step 2")?.Then({ (json2, param2) -> (C8oPromise<JSON>?) in
                    xjson[1] = json2
                    return c8o.CallJson(".Ping", parameters: "var1", "step 3")?.Then({ (json3, param3) -> (C8oPromise<JSON>?) in
                        xjson[2] = json3
                        throw C8oException(message: "random failure")
                    })
                })
            })?.Then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[3] = json
                return c8o.CallJson(".Ping", parameters: "var1", "step 5")?.Then({ (json2, param2) -> (C8oPromise<JSON>?) in
                    xjson[4] = json2
                    return nil
                })
            })?.Fail({ (C8oException, param) -> () in
                xfail[0] = C8oException
            }).Sync()!!
        }
        catch let e as C8oException{
            xfail[1] = e
            var value = xjson[0]["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 1", value)
            value = xjson[1]["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 2", value)
            value = xjson[2]["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 3", value)
            value = xjson[3]["document"]["pong"]["var1"].stringValue
            XCTAssertNil(value)
            value = xjson[4]["document"]["pong"]["var1"].stringValue
            XCTAssertNil(value)
            value = xjson[5]["document"]["pong"]["var1"].stringValue
            XCTAssertNil(value)
            XCTAssertEqual("random failure", xfail[0]?.message)
            XCTAssertEqual(xfail[0], xfail[1])
        }
        */
    }
    
}



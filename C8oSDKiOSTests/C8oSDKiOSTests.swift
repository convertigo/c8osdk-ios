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
import AEXML


@testable import C8o

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
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setLogRemote(false))
            c8o.logLevelLocal = C8oLogLevel.ERROR
            return c8o
            
        case .C8O_BIS :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setLogRemote(false))
            c8o.logLevelLocal = C8oLogLevel.ERROR
            return c8o
            
        case .C8O_FS :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setDefaultDatabaseName("clientsdktesting").setLogRemote(false))
            //c8o.logRemote = false
            c8o.logLevelLocal = C8oLogLevel.ERROR
            return c8o
            
        case .C8O_FS_PULL :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setDefaultDatabaseName("qa_fs_pull"))
            c8o.logRemote = false
            c8o.logLevelLocal = C8oLogLevel.ERROR
            let json = try! c8o.callJson(".InitFsPull")!.sync()
            XCTAssertTrue(json!["document"]["ok"].boolValue)
            return c8o
            
        case .C8O_FS_PUSH :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setDefaultDatabaseName("qa_fs_push"))
            c8o.logRemote = false
            c8o.logLevelLocal = C8oLogLevel.ERROR
            let json = try! c8o.callJson(".InitFsPush")!.sync()
            XCTAssertTrue(json!["document"]["ok"].boolValue)
            return c8o
            
        case .C8O_LC :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: nil)
            c8o.logRemote = false
            c8o.logLevelLocal = C8oLogLevel.ERROR
            return c8o
            
        case .SetGetInSession :
            let c8o : C8o = try Get(.C8O_BIS)!
            let ts : String = String(NSTimeIntervalSince1970 * 1000)
            let doc = try c8o.callXml(".SetInSession", parameters: "ts", ts).sync()
            var newTs = doc?.root["pong"]["ts"].stringValue      //xpath("/document/pong/ts").first!.stringValue
            XCTAssertEqual(ts, newTs)
            let doc2 = try c8o.callXml(".GetFromSession").sync()
            newTs = doc2?.root["session"]["expression"].stringValue
            XCTAssertEqual(ts, newTs)
            return c8o
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
        let doc  = try! c8o.callXml(".Ping").sync()
        let pong = doc?.root["pong"].count
        print(doc!.xmlString)
        XCTAssertEqual(1,pong)

    }
    
    func testC8oDefaultPingWait(){
        let c8o: C8o = try! Get(.C8O)!
        let promise : C8oPromise<AEXMLDocument> = c8o.callXml(".Ping")
        NSThread.sleepForTimeInterval(0.5)
        let doc : AEXMLDocument = try! promise.sync()!
        let pong : NSObject = (doc.root["pong"].count)
        XCTAssertEqual(1,pong)

    }
    
    
    func testC8oUnknownHostCallAndLog() {
        var exceptionLog : C8oException? = nil
        var exception : C8oException? = nil
        do {
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + "ee:28080" + PROJECT_PATH,
                                    c8oSettings: C8oSettings().setLogOnFail{
                                        clos in
                                            exceptionLog = clos.exception
                                        
                                            
                                    })
            let C8oP : C8oPromise<AEXMLDocument> = c8o.callXml(".Ping")
            NSThread.sleepForTimeInterval(3)
            try C8oP.sync()
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
            let promise : C8oPromise = c8o.callXml(".Ping")
            NSThread.sleepForTimeInterval(0.5)
            try promise.sync()
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
        let doc  = try! c8o.callXml(".Ping",  parameters: "var1", "value one").sync()
        let value = doc?.root["pong"]["var1"].stringValue
        XCTAssertEqual("value one", value)
    }
    
    func testC8oDefaultPingTwoSingleValues(){
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.callXml(".Ping", parameters: "var1", "value one", "var2","value two").sync()
        var value = doc?.root["pong"]["var1"].stringValue
        XCTAssertEqual("value one", value)
        value = doc?.root["pong"]["var2"].stringValue
        XCTAssertEqual("value two", value)
    }
    
    func testC8oDefaultPingTwoSingleValuesOneMulti(){
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.callXml(".Ping",
            parameters: "var1", "value one",
            "var2","value two",
            "mvar1", ["mvalue one", "mvalue two", "mvalue three"]
        ).sync()
        print(doc?.xmlString)
        var value = doc?.root["pong"]["var1"].stringValue
        XCTAssertEqual("value one", value)
        value = doc?.root["pong"]["var2"].stringValue
        XCTAssertEqual("value two", value)
        value = doc?.root["pong"]["mvar1"].all![0].stringValue
        XCTAssertEqual("mvalue one", value)
        value = doc?.root["pong"]["mvar1"].all![1].stringValue
        XCTAssertEqual("mvalue two", value)
        value = doc?.root["pong"]["mvar1"].all![2].stringValue
        XCTAssertEqual("mvalue three", value)
        let count = doc?.root["pong"]["mvar1"].all?.count
        XCTAssertEqual(3,count)
    }
    
    func testC8oDefaultPingTwoSingleValuesTwoMulti(){
        
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.callXml(".Ping",
            parameters: "var1", "value one",
            "var2","value two",
            "mvar1", ["mvalue one", "mvalue two", "mvalue three"],
            "mvar2", ["mvalue2 one"]
        ).sync()
        var value = doc?.root["pong"]["var1"].stringValue
        XCTAssertEqual("value one", value)
        value = doc?.root["pong"]["var2"].stringValue
        XCTAssertEqual("value two", value)
        value = doc?.root["pong"]["mvar1"].all![0].stringValue
        XCTAssertEqual("mvalue one", value)
        value = doc?.root["pong"]["mvar1"].all![1].stringValue
        XCTAssertEqual("mvalue two", value)
        value = doc?.root["pong"]["mvar1"].all![2].stringValue
        XCTAssertEqual("mvalue three", value)
        var count = doc?.root["pong"]["mvar1"].all!.count
        XCTAssertEqual(3,count)
        value = doc?.root["pong"]["mvar2"].all![0].stringValue
        XCTAssertEqual("mvalue2 one", value)
        count = doc?.root["pong"]["mvar2"].all!.count
        XCTAssertEqual(1,count)
        
    }
    
    func testC8oCheckJsonTypes(){
        let c8o: C8o = try! Get(.C8O)!
        var json = try! c8o.callJson(".JsonTypes",
            parameters: "var1", "value one",
            "mvar1", ["mvalue one", "mvalue two", "mvalue three"]
            )!.sync()
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
        let doc = try! c8o.callXml(".GetFromSession").sync()
        let expression = doc?.root["session"]["expression"].count
        XCTAssertEqual(0, expression)
    }
    
    func CheckLogRemoteHelper(c8o : C8o, lvl : String, msg : String) throws ->() {
        let doc : AEXMLDocument = try! c8o.callXml(".GetLogs").sync()!
        let jsonString : String = doc.root["line"].stringValue
        if let dataFromString = jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let line = JSON(data: dataFromString)
            XCTAssertEqual(lvl, line[2].string)
            var newMsg = line[4].stringValue
            newMsg  = newMsg.substringWithRange(Range<String.Index>(newMsg.rangeOfString("logID=")!.startIndex ..< newMsg.endIndex))
            print(newMsg)
            XCTAssertEqual(msg,newMsg)
        }

        
    }
    
    func testCheckLogRemote() {
        let c8o : C8o = try! C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH , c8oSettings: C8oSettings().setLogC8o(false))
        let id : String = "logID=" + String(NSTimeIntervalSince1970 * 1000)
        try! c8o.callXml(".GetLogs", parameters: "init", id).sync()
        c8o.log.error(id)
        try! CheckLogRemoteHelper(c8o, lvl: "ERROR", msg: id)
        c8o.log.error(id, exceptions: C8oException(message: "for test"))
        try! CheckLogRemoteHelper(c8o, lvl: "ERROR", msg: (id + "\nOptional(Error Domain=com.convertigo.clientsdk.exception.C8oException Code=1 \"for test\" UserInfo={NSLocalizedFailureReason=for test})"))
        c8o.log.warn(id)
        try! CheckLogRemoteHelper(c8o, lvl: "WARN", msg: id)
        c8o.log.info(id)
        try! CheckLogRemoteHelper(c8o, lvl: "INFO", msg: id)
        c8o.log.debug(id)
        try! CheckLogRemoteHelper(c8o, lvl: "DEBUG", msg: id)
        c8o.log.trace(id)
        try! CheckLogRemoteHelper(c8o, lvl: "TRACE", msg: id)
        c8o.log.fatal(id)
        try! CheckLogRemoteHelper(c8o, lvl: "FATAL", msg: id)
        c8o.logRemote = false
        c8o.log.info(id)
        NSThread.sleepForTimeInterval(0.05)
        let doc = try! c8o.callXml(".GetLogs").sync()
        let value : NSObject? = doc?.root["line"].value
        XCTAssertEqual("element <line> not found", value)
        //XCTAssertNil(value)
        
    }
    
    func testC8oDefaultPromiseXmlOne() {
        let c8o : C8o = try! Get(.C8O)!
        var xdoc : [AEXMLDocument] = [AEXMLDocument]()
        var xthread : [NSThread] = [NSThread]()
        var xparam : [Dictionary<String, AnyObject>] = [Dictionary<String, AnyObject>]()
        
        let condition : NSCondition = NSCondition()
        condition.lock()
            c8o.callXml(".Ping", parameters: "var1", "step 1").then { (doc, param) -> (C8oPromise<AEXMLDocument>?) in
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
        let value = xdoc[0].root["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        XCTAssertNotEqual(NSThread.currentThread(), xthread[0])
        XCTAssertEqual("step 1", xparam[0]["var1"] as! String)
    }
    
    func testC8oDefaultPromiseJsonThree(){
        let c8o : C8o = try! Get(.C8O)!
        var xjson : [JSON] = [JSON]()
        let condition : NSCondition = NSCondition()
        condition.lock()
        c8o.callJson(".Ping", parameters: "var1", "step 1")!
            .then{ (json, param) -> (C8oPromise<JSON>?) in
                xjson.append(json)
                return c8o.callJson(".Ping", parameters: "var1", "step 2")!
            }!.then{(json, param) -> (C8oPromise<JSON>?) in
                xjson.append(json)
                return c8o.callJson(".Ping", parameters: "var1", "step 3")!
            }!.then{(json, param) -> (C8oPromise<JSON>?) in
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
        c8o.callJson(".Ping", parameters: "var1", "step 1")?.thenUI({ (json, param) -> (C8oPromise<JSON>?) in
            xjson.append(json)
            xthread.append(NSThread.currentThread())
            return c8o.callJson(".Ping", parameters: "var1", "step 2")
        })?.then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson.append(json)
            xthread.append(NSThread.currentThread())
            return c8o.callJson(".Ping", parameters: "var1", "step 3")
        })?.thenUI({ (json, param) -> (C8oPromise<JSON>?) in
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
        })
        self.waitForExpectationsWithTimeout(20) { error in
        }
    }
    
    func testC8oDefaultPromiseFail(){
        
        let c8o : C8o = try! Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 3, repeatedValue: nil)
        var xfail : [NSError] = [NSError]()
        var xparam : [Dictionary<String, AnyObject>] = [Dictionary<String, AnyObject>]()
        let condition : NSCondition = NSCondition()
        condition.lock()
        c8o.callJson(".Ping", parameters: "var1", "step 1")?
            .then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[0] = json
            return c8o.callJson(".Ping", parameters: "var1", "step 2")!
            })?.then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[1] = json
                if(json != nil)
                {
                    throw  C8oException(message: "random failure")
                }
                return c8o.callJson("Ping", parameters: "var1", "step 3")!
            })?.then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[2]? = json
                condition.lock()
                    condition.signal()
                condition.unlock()
                return nil
            })?.fail({ (ex, param) -> () in
                xfail.append(ex)
                xparam.append(param!)
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
        XCTAssertEqual("step 2", xparam[0]["var1"] as! String)
    }
    
    func testC8oDefaultPromiseFailUI(){
        
        let asyncExpectation = expectationWithDescription("testC8oDefaultPromiseFailUI")
        let UiThread = NSThread.currentThread()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        let c8o : C8o = try! self.Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 3, repeatedValue: nil)
        var xfail : [NSError] = [NSError]()
        var xparam : [Dictionary<String, AnyObject>] = [Dictionary<String, AnyObject>]()
        var xthread : [NSThread] = [NSThread]()
        let condition : NSCondition = NSCondition()
        condition.lock()
        c8o.callJson(".Ping", parameters: "var1", "step 1")?
            .then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[0] = json
                return c8o.callJson(".Ping", parameters: "var1", "step 2")!
            })?.then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[1] = json
                if(json != nil)
                {
                    throw  C8oException(message: "random failure")
                }
                return c8o.callJson("Ping", parameters: "var1", "step 3")!
            })?.then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[2]? = json
                condition.lock()
                condition.signal()
                condition.unlock()
                return nil
            })?.failUI{ (ex, param) -> () in
                xfail.append(ex)
                xparam.append(param!)
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
        XCTAssertEqual("step 2", xparam[0]["var1"] as? String)
        XCTAssertEqual(UiThread, xthread[0])
        asyncExpectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(20) { error in
        }
    }
    
    func testC8oDefaultPromiseSync(){
        
        let c8o : C8o = try! Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 2, repeatedValue: nil)
        xjson[1] = try! c8o.callJson(".Ping", parameters: "var1", "step 1")?.then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[0] = json
            return c8o.callJson(".Ping", parameters: "var1", "step 2")
        })?.sync()
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
            xjson[1] = try c8o.callJson(".Ping", parameters: "var1", "step 1")?.then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[0] = json
                if(json != nil){
                    throw C8oException(message: "random failure")
                }
                return c8o.callJson(".Ping", parameters: "var1", "step 2")
            })?.sync()
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
        xjson[5] = try! c8o.callJson(".Ping", parameters: "var1", "step 1")?.then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[0] = json
            return c8o.callJson(".Ping", parameters: "var1", "step 2")?.then({ (json2, param2) -> (C8oPromise<JSON>?) in
                xjson[1] = json2
                return c8o.callJson(".Ping", parameters: "var1", "step 3")?.then({ (json3, param3) -> (C8oPromise<JSON>?) in
                    xjson[2] = json3
                    return c8o.callJson(".Ping", parameters: "var1", "step 4")
                })
            })
        })?.then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[3] = json
            return c8o.callJson(".Ping", parameters: "var1", "step 5")?.then({ (json2, param2) -> (C8oPromise<JSON>?) in
                xjson[4] = json2
                return nil
            })
        })?.sync()
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
        
        let c8o : C8o = try! self.Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 6, repeatedValue: nil)
        var xfail : [C8oException?] = [C8oException?](count: 2, repeatedValue: nil)
        do{
            xjson[5] = try c8o.callJson(".Ping", parameters: "var1", "step 1")?.then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[0] = json
                return c8o.callJson(".Ping", parameters: "var1", "step 2")?.then({ (json2, param2) -> (C8oPromise<JSON>?) in
                    xjson[1] = json2
                    return c8o.callJson(".Ping", parameters: "var1", "step 3")?.then({ (json3, param3) -> (C8oPromise<JSON>?) in
                        xjson[2] = json3
                        throw C8oException(message: "random failure")
                    })
                })
            })?.then({ (json, param) -> (C8oPromise<JSON>?) in
                xjson[3] = json
                return c8o.callJson(".Ping", parameters: "var1", "step 5")?.then({ (json2, param2) -> (C8oPromise<JSON>?) in
                    xjson[4] = json2
                    return nil
                })
            })?.fail({ (C8oException, param) -> () in
                xfail[0] = C8oException
            }).sync()
        }
        catch let e as C8oException{
            xfail[1] = e
        }
        catch{
            XCTFail()
        }
            var value = xjson[0]!["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 1", value)
            value = xjson[1]!["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 2", value)
            value = xjson[2]!["document"]["pong"]["var1"].stringValue
            XCTAssertEqual("step 3", value)
            var valueNil : String? = xjson[3]?["document"]["pong"]["var1"].string
            XCTAssertNil(valueNil)
            valueNil = xjson[4]?["document"]["pong"]["var1"].string
            XCTAssertNil(valueNil)
            valueNil = xjson[5]?["document"]["pong"]["var1"].string
            XCTAssertNil(valueNil)
            XCTAssertEqual("random failure", xfail[0]?.message)
            XCTAssertEqual(xfail[0], xfail[1])
    }
    
    func testC8oDefaultPromiseInVar(){
        let c8o : C8o = try! self.Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 3, repeatedValue: nil)
        let promise = c8o.callJson(".Ping", parameters: "var1", "step 1")
        promise?.then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[0] = json
            return c8o.callJson(".Ping", parameters: "var1", "step 2")
        })
        promise?.then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[1] = json
            return c8o.callJson(".Ping", parameters: "var1", "step 3")
        })
        xjson[2] = try! promise?.sync()
        var value = xjson[0]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        value = xjson[1]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 2", value)
        value = xjson[2]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 3", value)
    }
    
    func testC8oDefaultPromiseInVarSleep(){
        let c8o : C8o = try! self.Get(.C8O)!
        var xjson : [JSON?] = [JSON?](count: 3, repeatedValue: nil)
        let promise = c8o.callJson(".Ping", parameters: "var1", "step 1")
        NSThread.sleepForTimeInterval(0.5)
        promise?.then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[0] = json
            return c8o.callJson(".Ping", parameters: "var1", "step 2")
        })
        NSThread.sleepForTimeInterval(0.5)
        promise?.then({ (json, param) -> (C8oPromise<JSON>?) in
            xjson[1] = json
            return c8o.callJson(".Ping", parameters: "var1", "step 3")
        })
        NSThread.sleepForTimeInterval(0.5)
        xjson[2] = try! promise?.sync()
        var value = xjson[0]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 1", value)
        value = xjson[1]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 2", value)
        value = xjson[2]!["document"]["pong"]["var1"].stringValue
        XCTAssertEqual("step 3", value)
    }
    //TODO...
    /*func testC8o0Ssl1TrustFail(){
        var exception : C8oException? = nil
        do{
            let c8o = try! C8o(endpoint: PREFIX + HOST + ":443" + PROJECT_PATH, c8oSettings: nil)
            let doc = try! c8o.callXml(".Ping", parameters: "var1", "value one").sync()
            let value = doc?.xpath("/document/pong/var1").first?.stringValue
            //XCTFail("not possible")
        }
        catch let e as C8oException{
            exception = e
        }
        catch{
            XCTFail("not possible")
        }
        
        XCTAssertNotNil(exception)
        XCTAssertTrue(exception! is C8oException)
    }*/
    
    //TODO...
    /*func testC8o0Ssl2TrustAll(){
        
    }*/
    func testC8oFsPostGetDelete(){
        let c8o : C8o = try! Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON? = try! c8o.callJson("fs://.reset")!.sync()
        XCTAssertTrue(json!["ok"].boolValue)
        let myId : String =  "C8oFsPostGetDelete-" + String(NSDate(timeIntervalSince1970: 0).timeIntervalSinceNow * 1000)
        json = try! c8o.callJson("fs://.post", parameters: "_id", myId)?.sync()
        XCTAssertTrue(json!["ok"].boolValue)
        var id : String = json!["id"].stringValue
        XCTAssertEqual(id, myId)
        json = try! c8o.callJson("fs://.get", parameters: "docid", id)!.sync()
        id = json!["_id"].stringValue
        XCTAssertEqual(myId, id)
        json = try! c8o.callJson("fs://.delete", parameters: "docid", id)!.sync()
        XCTAssertTrue(json!["ok"].boolValue)
        do{
            try c8o.callJson("fs://.get", parameters: "docid", id)!.sync()
            XCTAssertTrue(false, "not possible")
        }
        catch _ as C8oRessourceNotFoundException{
            XCTAssertTrue(true)
        }
        catch{
            XCTAssertTrue(false)
        }
        
        
    }
    func testC8oFsPostGetDeleteRev(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON? = try! c8o.callJson("fs://.reset")?.sync()
        XCTAssertTrue(json!["ok"].boolValue)
        let id =  "C8oFsPostGetDelete-Rev" + String(NSDate(timeIntervalSince1970: 0).timeIntervalSinceNow * 1000)
        json = try! c8o.callJson("fs://.post", parameters: "_id", id)?.sync()
        XCTAssertTrue(json!["ok"].boolValue)
        let rev : String = json!["rev"].stringValue
        do{
            try c8o.callJson("fs://.delete", parameters: "docid", id, "rev", "1-123456")!.sync()
            XCTAssertTrue(false, "not possible")
        }
        catch _ as C8oRessourceNotFoundException{
            XCTAssertTrue(true)
        }
        catch{
            XCTAssertTrue(false)
        }
        do{
            json = try c8o.callJson("fs://.delete", parameters: "docid", id, "rev", rev)!.sync()
        }
        catch _ as NSError{
            XCTAssert(false)
        }
        XCTAssertTrue(json!["ok"].boolValue)
        do{
            try c8o.callJson("fs://.get", parameters: "docid", id)!.sync()
            XCTAssertTrue(false, "not possible")
        }
        catch _ as C8oRessourceNotFoundException{
            XCTAssertTrue(true)
        }
        catch{
            XCTAssertTrue(false)
        }
        condition.unlock()
    }
    func testC8oFsPostGetDestroyCreate(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let ts : String = "ts=" + String(NSDate(timeIntervalSince1970: 0).timeIntervalSinceNow * 1000)
        let ts2 : String = ts + "@test"
        json = try! c8o.callJson("fs://.post", parameters: "ts", ts)!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let id = json["id"].stringValue
        let rev = json["rev"].stringValue
        json = try! c8o.callJson("fs://.post",
                            parameters: "_id", id,
                            "_rev", rev,
                            "ts", ts,
                            "ts2", ts2
            )!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        json = try! c8o.callJson("fs://.get", parameters: "docid", id)!.sync()!
        XCTAssertEqual(ts, json["ts"].stringValue)
        XCTAssertEqual(ts2, json["ts2"].stringValue)
        json = try! c8o.callJson("fs://.destroy")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        json = try! c8o.callJson("fs://.create")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        do{
            try c8o.callJson("fs://.get", parameters: "docid", id)!.sync()
            XCTAssertTrue(false, "not possible")
        }
        catch _ as C8oRessourceNotFoundException{
           XCTAssertTrue(true)
        }
        catch{
            XCTAssertTrue(false)
        }
        condition.unlock()
    
    }
    
    func testC8oFsPostReset(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        json = try! c8o.callJson("fs://.post")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let id : String = json["id"].stringValue
        json = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        do {
            try c8o.callJson("fs://.get", parameters: "docid", id)!.sync()
            XCTAssertTrue(false, "not possible")
        }
        catch _ as C8oRessourceNotFoundException{
            XCTAssertTrue(true)
        }
        catch{
            XCTAssertTrue(false)
        }
        
        condition.unlock()
    
    }
    
    func testC8oFsPostExisting(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        json = try! c8o.callJson("fs://.post")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let id : String = json["id"].stringValue
        do {
            try c8o.callJson("fs://.post", parameters: "_id", id)!.sync()
            XCTAssertTrue(false, "not possible")
        } catch _ as c8oCouchbaseLiteException {
            XCTAssertTrue(true)
        }
        catch{
            XCTAssertTrue(false)
        }
        condition.unlock()
    }
    
    func testC8oFsPostExistingPolicyNone(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        json = try! c8o.callJson("fs://.post", parameters: C8o.FS_POLICY, C8o.FS_POLICY_NONE)!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let id : String = json["id"].stringValue
        do {
            try c8o.callJson("fs://.post",
                         parameters: C8o.FS_POLICY, C8o.FS_POLICY_NONE,
                         "_id", id
                )!.sync()
            XCTAssertTrue(false, "not possible")
        } catch _ as c8oCouchbaseLiteException {
            XCTAssertTrue(true)
        }
        catch{
            XCTAssertTrue(false)
        }

    }
    
    func testC8oFsPostExistingPolicyCreate(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let myId : String = "C8oFsPostExistingPolicyCreate-" +  String(NSDate(timeIntervalSince1970: 0).timeIntervalSinceNow * 1000)
        json = try! c8o.callJson("fs://.post", parameters: "_id", myId)!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        var id : String = json["id"].stringValue
        XCTAssertEqual(myId, id)
        json = try! c8o.callJson("fs://.post",
                            parameters: C8o.FS_POLICY, C8o.FS_POLICY_CREATE,
                            "_id", id
            )!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        id = json["id"].stringValue
        XCTAssertNotEqual(myId, id)
        
    }
    
    func testC8oFsPostExistingPolicyOverride(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let myId : String = "C8oFsPostExistingPolicyOverride-" + String(NSDate(timeIntervalSince1970: 0).timeIntervalSinceNow * 1000)
        json = try! c8o.callJson("fs://.post",
                            parameters: C8o.FS_POLICY, C8o.FS_POLICY_OVERRIDE,
                            "_id", myId,
                            "a", 1,
                            "b", 2
            )!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        var id : String = json["id"].stringValue
        XCTAssertEqual(myId, id)
        json = try! c8o.callJson("fs://.post",
                            parameters: C8o.FS_POLICY, C8o.FS_POLICY_OVERRIDE,
                            "_id", myId,
                            "a", 3,
                            "c", 4
            )!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        id = json["id"].stringValue
        XCTAssertEqual(myId, id)
        json = try! c8o.callJson("fs://.get", parameters: "docid", myId)!.sync()!
        XCTAssertEqual(3, json["a"].intValue)
        XCTAssertFalse(json["b"].isExists())
        XCTAssertEqual(4, json["c"].intValue)
    }
    
    func testC8oFsPostExistingPolicyMerge(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let myId : String = "C8oFsPostExistingPolicyMerge-" + String(NSDate(timeIntervalSince1970: 0).timeIntervalSinceNow * 1000)
        json = try! c8o.callJson("fs://.post",
                            parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                            "_id", myId,
                            "a", 1,
                            "b", 2
            )!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        var id : String = json["id"].stringValue
        XCTAssertEqual(myId, id)
        json = try! c8o.callJson("fs://.post",
                            parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                            "_id", myId,
                            "a", 3,
                            "c", 4
            )!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        id = json["id"].stringValue
        XCTAssertEqual(myId, id)
        json = try! c8o.callJson("fs://.get", parameters: "docid", myId)!.sync()!
        XCTAssertEqual(3, json["a"].intValue)
        XCTAssertEqual(2, json["b"].intValue)
        XCTAssertEqual(4, json["c"].intValue)
    }
    func testC8oFsPostExistingPolicyMergeSub(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let myId : String = "C8oFsPostExistingPolicyMergeSub-" + String(NSDate(timeIntervalSince1970: 0).timeIntervalSinceNow * 1000)
        let sub_f : JSON = ["g": true, "h": ["one", "two", "three", "four"]]
        var sub_c : JSON = ["d":3, "e":"four", "f": sub_f.object]
        json = try! c8o.callJson("fs://.post",
                            parameters: "_id", myId,
                            "a", 1,
                            "b", -2,
                            "c", sub_c.object
            )!.sync()!
        XCTAssert(json["ok"].boolValue)
        json = try! c8o.callJson("fs://.post",
                            parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                            "_id", myId,
                            "i", JSON(arrayLiteral: ["5","6","7.1","nil"]).object,
                            "c.f.j", "good",
                            "c.f.h", JSON(arrayLiteral: [true,false]).object
        )!.sync()!
        XCTAssert(json["ok"].boolValue)
        json = try! c8o.callJson("fs://.post",
                            parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
                            C8o.FS_SUBKEY_SEPARATOR, "<>",
                            "_id", myId,
                            "c<>i-j", "great"
            )!.sync()!
        XCTAssert(json["ok"].boolValue)
        json = try! c8o.callJson("fs://.get", parameters: "docid", myId)!.sync()!
        json.dictionaryObject?.removeValueForKey("_rev")
        XCTAssertEqual(myId, json.dictionaryObject?.removeValueForKey("_id") as? String)
        let expectedJson = JSON(arrayLiteral: "{\"a\":1,\"i\":[\"5\",6,7.1,null],\"b\":-2,\"c\":{\"d\":3,\"i-j\":\"great\",\"f\":{\"j\":\"good\",\"g\":true,\"h\":[true,false,\"three\",\"four\"]},\"e\":\"four\"}}").stringValue
        let sJson = json.stringValue
        XCTAssertEqual(expectedJson, sJson)
    }
    
    func testC8oFsPostGetMultibase(){
        let c8o : C8o = try! self.Get(.C8O_FS)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        json = try! c8o.callJson("fs://notdefault.reset")!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        let myId : String =  "C8oFsPostGetMultibase-" + String(NSDate(timeIntervalSince1970: 0).timeIntervalSinceNow * 1000)
        json = try! c8o.callJson("fs://.post", parameters: "_id", myId)!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        do{
            try c8o.callJson("fs://notdefault.get", parameters: "docid", myId)!.sync()
            XCTAssertTrue(false, "not possible")
        }
        catch _ as C8oRessourceNotFoundException{
            XCTAssertTrue(true)
        }
        catch{
            XCTAssertTrue(false)
        }
        json = try! c8o.callJson("fs://notdefault.post", parameters: "_id", myId)!.sync()!
        XCTAssertTrue(json["ok"].boolValue)
        json = try! c8o.callJson("fs://notdefault.get", parameters: "docid", myId)!.sync()!
        let id : String = json["_id"].stringValue
        XCTAssertEqual(myId, id)
    }
    func atestC8oFsReplicateAnoAndAuth(){
        let c8o : C8o = try! self.Get(.C8O_FS_PULL)!
        let condition : NSCondition = NSCondition()
        condition.lock()
        do{
            var json : JSON = try! c8o.callJson("fs://.reset")!.sync()!
            XCTAssertTrue(json["ok"].boolValue)
            do{
                try c8o.callJson("fs://.get", parameters: "docid", "258")!.sync()
                XCTAssertTrue(false, "not possible")
            }
            catch _ as C8oRessourceNotFoundException{
                XCTAssertTrue(true)
            }
            catch{
                XCTAssertTrue(false)
            }
            json = try! c8o.callJson("fs://.replicate_pull")!.sync()!
            XCTAssertTrue(json["ok"].boolValue)
            json = try! c8o.callJson("fs://.get", parameters: "docid", "258")!.sync()!
            var value : String = json["data"].stringValue
            XCTAssertEqual("258", value)
            /*do{
                try c8o.callJson("fs://.get", parameters: "docid", "456")!.sync()
                XCTAssertTrue(false, "not possible")
            }
            catch _ as C8oRessourceNotFoundException{
                XCTAssertTrue(true)
            }
            catch{
                XCTAssertTrue(false)
            }
            try! json = c8o.callJson(".LoginTesting")!.sync()!
            value = json["document"]["authenticatedUserID"].stringValue
            XCTAssertEqual("testing_user", value)
            json = try! c8o.callJson("fs://.replicate_pull")!.sync()!
            XCTAssertTrue(json["ok"].boolValue)
            json = try! c8o.callJson("fs://.get", parameters: "docid", "456")!.sync()!
            value = json["data"].stringValue
            XCTAssertEqual("456", value)*/
            
        }
        catch{
        }
        try! c8o.callJson(".LogoutTesting")!.sync()
    }
}



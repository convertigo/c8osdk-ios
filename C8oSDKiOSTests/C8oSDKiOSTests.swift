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
            
        case .C8O_FS_PULL :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetDefaultDatabaseName("qa_fs_pull"))
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            let json = try! c8o.CallJson(".InitFsPull")!.Sync()
            XCTAssertTrue(json!["document"]["ok"].boolValue)
            return c8o
            break
            
        case .C8O_FS_PUSH :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().SetDefaultDatabaseName("qa_fs_push"))
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            let json = try! c8o.CallJson(".InitFsPush")!.Sync()
            XCTAssertTrue(json!["document"]["ok"].boolValue)
            return c8o
            break
            
        case .C8O_LC :
            let c8o : C8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: nil)
            c8o.LogRemote = false
            c8o.LogLevelLocal = C8oLogLevel.ERROR
            return c8o
            break
            
        case .SetGetInSession :
            let c8o : C8o = try Get(.C8O_BIS)!
            let ts : String = String(NSTimeIntervalSince1970 * 1000)
            var doc = try c8o.CallXml(".SetInSession", parameters: "ts", ts).Sync()
            var newTs : String = (doc?.xpath("/document/pong/ts/text()").first)!.rawXML
            XCTAssertEqual(ts, newTs)
            doc = try c8o.CallXml(".GetFromSession").Sync();
            newTs = (doc?.xpath("/document/session/expression/text()").first)!.rawXML
            XCTAssertEqual(ts, newTs)
            return c8o
            break
            
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
    
    func testC8oBadEndpoint(){
        do {
            try _ = C8o(endpoint: PREFIX + HOST + PORT, c8oSettings: nil)
        }
        catch {
            XCTAssert(true)
        }
        
    }
    
    func testC8oDefault(){
        try! _ = Get(.C8O)
    }
    
    func testC8oDefaultPing(){
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping").Sync()
        var pong : Int
        pong = (doc?.xpath("/document/pong").count)!
        XCTAssertEqual(1,pong)
    }
    
    func testC8oDefaultPingOneSingleValue() {
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping",  parameters: "var1", "value one").Sync()
        let pong = (doc?.xpath("/document/pong/var1/text()").count)!
        XCTAssertEqual(1,pong)
    }
    
    func testC8oUnknownHostCallAndLog() {
        
        /*var exception : NSException? = nil
        let exceptionLog : NSException? = nil
        var exceptio : Errs? = nil
        let c8o : C8o = try! C8o(endpoint: PREFIX + HOST + "ee:28080" + PROJECT_PATH, c8oSettings: C8oSettings().SetLogOnFail{ logOnFail in
            (exceptionLog, Dictionary<String, NSObject>())
            })
        do {
            try c8o.CallXml("Ping").Sync()
        }
        catch let ex as NSException {
            exception = ex
        }
        catch let ex as Errs{
            exceptio = ex
        }
        catch{
        }
        XCTAssertNotNil(exceptio)*/
        
        
    }
    
    func testC8oDefaultPingTwoSingleValues(){
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping", parameters: "var1", "value one", "var2","value two").Sync()
        let pong = (doc?.xpath("/document/pong/var1/text()").count)!
        let pong2 = (doc?.xpath("/document/pong/var2/text()").count)!
        XCTAssertEqual(1,pong)
        XCTAssertEqual(1,pong2)
    }
    
    func testC8oDefaultPingTwoSingleValuesOneMulti(){
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping",
            parameters: "var1", "value one",
            "var2","value two",
            "mvar1", ["mvalue one", "mvalue two", "mvalue three"]
            ).Sync()
        let pong = (doc?.xpath("/document/pong/var1/text()").count)!
        let pong2 = (doc?.xpath("/document/pong/var2/text()").count)!
        let pong3 = (doc?.xpath("/document/pong/mvar1[1]/text()").count)!
        let pong4 = (doc?.xpath("/document/pong/mvar1[2]/text()").count)!
        let pong5 = (doc?.xpath("/document/pong/mvar1[3]/text()").count)!
        let pong6 = (doc?.xpath("/document/pong/mvar1").count)!
        XCTAssertEqual(1,pong)
        XCTAssertEqual(1,pong2)
        XCTAssertEqual(1,pong3)
        XCTAssertEqual(1,pong4)
        XCTAssertEqual(1,pong5)
        XCTAssertEqual(3,pong6)
    }
    
    func testC8oDefaultPingTwoSingleValuesTwoMulti(){
        
        let c8o: C8o = try! Get(.C8O)!
        let doc  = try! c8o.CallXml(".Ping",
            parameters: "var1", "value one",
            "var2","value two",
            "mvar1", ["mvalue one", "mvalue two", "mvalue three"],
            "mvar2", ["mvalue2 one"]
            ).Sync()
        let pong = (doc?.xpath("/document/pong/var1/text()").count)!
        let pong2 = (doc?.xpath("/document/pong/var2/text()").count)!
        let pong3 = (doc?.xpath("/document/pong/mvar1[1]/text()").count)!
        let pong4 = (doc?.xpath("/document/pong/mvar1[2]/text()").count)!
        let pong5 = (doc?.xpath("/document/pong/mvar1[3]/text()").count)!
        let pong6 = (doc?.xpath("/document/pong/mvar1").count)!
        let pong7 = (doc?.xpath("/document/pong/mvar2[1]").count)!
        let pong8 = (doc?.xpath("/document/pong/mvar2").count)!
        XCTAssertEqual(1,pong)
        XCTAssertEqual(1,pong2)
        XCTAssertEqual(1,pong3)
        XCTAssertEqual(1,pong4)
        XCTAssertEqual(1,pong5)
        XCTAssertEqual(3,pong6)
        XCTAssertEqual(1,pong7)
        XCTAssertEqual(1,pong8)
        
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
        let expression : String? = doc?.xpath("/document/session/expression").first?.rawXML
        //XCTAssertNil(expression)
    }
    
}



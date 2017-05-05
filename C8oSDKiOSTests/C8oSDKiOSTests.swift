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
	
	var myC8o: C8o!
	let HOST = "buildus.twinsoft.fr" // "192.168.100.95"
	let PROJECT_PATH = "/convertigo/projects/ClientSDKtesting"
	let PORT = ":28080" // 18080
	let PREFIX = "http://"
	let PREFIXS = "https://"
	
	enum Stuff {
		case C8O, C8O_BIS, C8O_FS, C8O_FS_PULL, C8O_FS_PUSH, C8O_LC, SetGetInSession
	}
	func get(enu: Stuff) throws -> C8o {
		switch (enu) {
		case .C8O:
			let c8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setLogRemote(false).setLogLevelLocal(C8oLogLevel.ERROR))
			// c8o.logLevelLocal = C8oLogLevel.ERROR
			return c8o
			
		case .C8O_BIS:
			let c8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setLogRemote(false).setLogLevelLocal(C8oLogLevel.ERROR))
			// c8o.logLevelLocal = C8oLogLevel.ERROR
			return c8o
			
		case .C8O_FS:
			let c8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setDefaultDatabaseName("clientsdktesting").setLogRemote(false).setLogLevelLocal(C8oLogLevel.ERROR))
			// c8o.logRemote = false
			// c8o.logLevelLocal = C8oLogLevel.ERROR
			return c8o
			
		case .C8O_FS_PULL:
			let c8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setDefaultDatabaseName("qa_fs_pull").setLogRemote(false).setLogLevelLocal(C8oLogLevel.ERROR))
			// c8o.logRemote = false
			// c8o.logLevelLocal = C8oLogLevel.ERROR
			let json = try! c8o.callJson(".InitFsPull").sync()
			XCTAssertTrue(json!["document"]["ok"].boolValue)
			return c8o
			
		case .C8O_FS_PUSH:
			let c8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setDefaultDatabaseName("qa_fs_push").setLogRemote(false).setLogLevelLocal(C8oLogLevel.ERROR))
			// c8o.logRemote = false
			// c8o.logLevelLocal = C8oLogLevel.ERROR
			let json = try! c8o.callJson(".InitFsPush").sync()
			XCTAssertTrue(json!["document"]["ok"].boolValue)
			return c8o
			
		case .C8O_LC:
			let c8o = try C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setLogRemote(false).setLogLevelLocal(C8oLogLevel.ERROR))
			// c8o.logRemote = false
			// c8o.logLevelLocal = C8oLogLevel.ERROR
			return c8o
			
		case .SetGetInSession:
			let c8o = try get(.C8O_BIS)
			let ts: String = String(NSTimeIntervalSince1970 * 1000)
			let doc = try c8o.callXml(".SetInSession", parameters: "ts", ts).sync()
			var newTs = doc?.root["pong"]["ts"].stringValue
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
	
	func testC8oBadEndpoint() {
		do {
			try _ = C8o(endpoint: PREFIX + HOST + PORT, c8oSettings: nil)
		}
		catch let e {
			XCTAssertEqual(e._code, C8oError.ArgumentException("")._code)
		}
		
	}
	
	func testC8oDefault() {
		try! _ = get(.C8O)
	}
	
	func testC8oDefaultPing() {
		do {
			let c8o = try get(.C8O)
			let doc = try c8o.callXml(".Ping").sync()
			let pong = doc?.root["pong"].count
			XCTAssertEqual(1, pong)
		}
		catch let e as NSError {
			XCTFail(e.description)
		}
		
	}
	
	func testC8oDefaultPingWait() {
		do {
			let c8o = try get(.C8O)
			let promise: C8oPromise<AEXMLDocument> = c8o.callXml(".Ping")
			NSThread.sleepForTimeInterval(0.5)
			let doc: AEXMLDocument = try promise.sync()!
			let pong: NSObject = (doc.root["pong"].count)
			XCTAssertEqual(1, pong)
		}
		catch let e as NSError {
			XCTFail(e.description)
		}
		
	}
	
	func testC8oCallInAsyncTask() {
		var doc: AEXMLDocument? = nil
		let asyncExpectation = expectationWithDescription("longRunningFunction")
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			
			let c8o = try! self.get(.C8O)
			doc = try! c8o.callXml(".Ping").sync()
			asyncExpectation.fulfill()
		})
		self.waitForExpectationsWithTimeout(20) { error in
		}
		let pong = doc!["document"]["pong"]
		XCTAssertNotNil(pong)
	}
	
	func testC8oUnknownHostCallAndLog() {
		var exceptionLog: C8oException? = nil
		var exception: C8oException? = nil
		do {
			let c8o = try C8o(endpoint: PREFIX + HOST + "ee:28080" + PROJECT_PATH,
				c8oSettings: C8oSettings().setLogOnFail {
					clos in
					exceptionLog = clos.exception
					
			})
			let C8oP: C8oPromise<AEXMLDocument> = c8o.callXml(".Ping")
			NSThread.sleepForTimeInterval(3)
			try C8oP.sync()
		}
		catch let ex as C8oException {
			exception = ex
		}
		catch {
			XCTAssertTrue(false)
		}
		XCTAssertNotNil(exception)
		XCTAssertNotNil(exceptionLog)
		// TODO finish tests...
	}
	
	func testC8oUnknownHostCallWait() {
		var exception: C8oException? = nil
		do {
			let c8o = try C8o(endpoint: PREFIX + HOST + "ee:28080" + PROJECT_PATH, c8oSettings: nil)
			let promise: C8oPromise = c8o.callXml(".Ping")
			NSThread.sleepForTimeInterval(0.5)
			try promise.sync()
		}
		catch let ex as C8oException {
			exception = ex
		}
		catch {
			
		}
		XCTAssertNotNil(exception)
		// TODO finish tests...
	}
	
	func testC8oDefaultPingOneSingleValue() {
		let c8o = try! get(.C8O)
		let doc = try! c8o.callXml(".Ping", parameters: "var1", "value one").sync()
		let value = doc?.root["pong"]["var1"].stringValue
		XCTAssertEqual("value one", value)
	}
	
	func testC8oDefaultPingTwoSingleValues() {
		let c8o = try! get(.C8O)
		let doc = try! c8o.callXml(".Ping", parameters: "var1", "value one", "var2", "value two").sync()
		var value = doc?.root["pong"]["var1"].stringValue
		XCTAssertEqual("value one", value)
		value = doc?.root["pong"]["var2"].stringValue
		XCTAssertEqual("value two", value)
	}
	
	func testC8oDefaultPingTwoSingleValuesOneMulti() {
		let c8o = try! get(.C8O)
		let doc = try! c8o.callXml(".Ping",
			parameters: "var1", "value one",
			"var2", "value two",
			"mvar1", ["mvalue one", "mvalue two", "mvalue three"]
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
		let count = doc?.root["pong"]["mvar1"].all?.count
		XCTAssertEqual(3, count)
	}
	
	func testC8oDefaultPingTwoSingleValuesTwoMulti() {
		
		let c8o = try! get(.C8O)
		let doc = try! c8o.callXml(".Ping",
			parameters: "var1", "value one",
			"var2", "value two",
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
		XCTAssertEqual(3, count)
		value = doc?.root["pong"]["mvar2"].all![0].stringValue
		XCTAssertEqual("mvalue2 one", value)
		count = doc?.root["pong"]["mvar2"].all!.count
		XCTAssertEqual(1, count)
		
	}
	
	func testC8oCheckJsonTypes() {
		let c8o = try! get(.C8O)
		var json = try! c8o.callJson(".JsonTypes",
			parameters: "var1", "value one",
			"mvar1", ["mvalue one", "mvalue two", "mvalue three"]
		).sync()
		json = json!["document"]
		let pong = json!["pong"]
		var value: NSObject = pong["var1"].stringValue
		XCTAssertEqual("value one", value)
		let mvar1 = pong["mvar1"]
		value = mvar1[0].stringValue
		XCTAssertEqual("mvalue one", value)
		value = mvar1[1].stringValue
		XCTAssertEqual("mvalue two", value)
		value = mvar1[2].stringValue
		XCTAssertEqual("mvalue three", value)
		let count = mvar1.count
		XCTAssertEqual(3, count)
		let complex = json!["complex"]
		let isnil: AnyObject? = complex["isNull"].string
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
	
	func testSetGetInSession() {
		try! get(.SetGetInSession)
	}
	
	func testCheckNoMixSession() {
		try! get(.SetGetInSession)
		let c8o = try! get(.C8O)
		let doc = try! c8o.callXml(".GetFromSession").sync()
		let expression = doc?.root["session"]["expression"].count
		XCTAssertEqual(0, expression)
	}
	
	func CheckLogRemoteHelper(c8o: C8o, lvl: String, msg: String) throws -> () {
		NSThread.sleepForTimeInterval(0.333)
		let doc: AEXMLDocument = try! c8o.callXml(".GetLogs").sync()!
		let sLine = doc.root["line"].stringValue
		XCTAssertTrue(!sLine.isEmpty, "[" + lvl + "] sLine='" + sLine + "'")
		let line = JSON(data: sLine.dataUsingEncoding(NSUTF8StringEncoding)!)
		XCTAssertEqual(lvl, line[2].string)
		var newMsg = line[4].stringValue
		newMsg = newMsg.substringWithRange(Range<String.Index>(newMsg.rangeOfString("logID=")!.startIndex ..< newMsg.endIndex))
		XCTAssertEqual(msg, newMsg)
	}
	
	func testCheckLogRemote() {
		let c8o = try! C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH)
		c8o.logC8o = false
		let id = "logID=" + String(NSTimeIntervalSince1970)
		try! c8o.callXml(".GetLogs", parameters: "init", id).sync()!
		NSThread.sleepForTimeInterval(0.333)
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
		NSThread.sleepForTimeInterval(0.333)
		let doc = try! c8o.callXml(".GetLogs").sync()
		let value = doc?.root["line"].error
		XCTAssertNotNil(value)
	}
	
	func testC8oDefaultPromiseXmlOne() {
		let c8o = try! get(.C8O)
		var xdoc: [AEXMLDocument] = [AEXMLDocument]()
		var xthread: [NSThread] = [NSThread]()
		var xparam: [Dictionary<String, AnyObject>] = [Dictionary<String, AnyObject>]()
		
		let condition: NSCondition = NSCondition()
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
		XCTAssertEqual("step 1", xparam[0]["var1"] as? String)
	}
	
	func testC8oDefaultPromiseJsonThree() {
		let c8o = try! get(.C8O)
		var xjson: [JSON] = [JSON]()
		let condition: NSCondition = NSCondition()
		condition.lock()
		c8o.callJson(".Ping", parameters: "var1", "step 1")
			.then { (json, param) -> (C8oPromise<JSON>?) in
				xjson.append(json)
				return c8o.callJson(".Ping", parameters: "var1", "step 2")
		}.then { (json, param) -> (C8oPromise<JSON>?) in
				xjson.append(json)
				return c8o.callJson(".Ping", parameters: "var1", "step 3")
		}.then { (json, param) -> (C8oPromise<JSON>?) in
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
	
	func testC8oDefaultPromiseUI() {
		let asyncExpectation = expectationWithDescription("longRunningFunction")
		let UiThread = NSThread.currentThread()
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			let c8o = try! self.get(.C8O)
			var xjson: [JSON] = [JSON]()
			var xthread: [NSThread] = [NSThread]()
			let condition: NSCondition = NSCondition()
			condition.lock()
			c8o.callJson(".Ping", parameters: "var1", "step 1").thenUI({ (json, param) -> (C8oPromise<JSON>?) in
				xjson.append(json)
				xthread.append(NSThread.currentThread())
				return c8o.callJson(".Ping", parameters: "var1", "step 2")
			}).then({ (json, param) -> (C8oPromise<JSON>?) in
				xjson.append(json)
				xthread.append(NSThread.currentThread())
				return c8o.callJson(".Ping", parameters: "var1", "step 3")
			}).thenUI({ (json, param) -> (C8oPromise<JSON>?) in
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
	
	func testC8oDefaultPromiseFail() {
		
		let c8o = try! get(.C8O)
		var xjson: [JSON?] = [JSON?](count: 3, repeatedValue: nil)
		var xfail: [NSError] = [NSError]()
		var xparam: [Dictionary<String, AnyObject>] = [Dictionary<String, AnyObject>]()
		let condition: NSCondition = NSCondition()
		condition.lock()
		c8o.callJson(".Ping", parameters: "var1", "step 1")
			.then({ (json, param) -> (C8oPromise<JSON>?) in
				xjson[0] = json
				return c8o.callJson(".Ping", parameters: "var1", "step 2")
		}).then({ (json, param) -> (C8oPromise<JSON>?) in
				xjson[1] = json
				if (json != nil) {
					throw C8oException(message: "random failure")
				}
				return c8o.callJson("Ping", parameters: "var1", "step 3")
		}).then({ (json, param) -> (C8oPromise<JSON>?) in
				xjson[2]? = json
				condition.lock()
				condition.signal()
				condition.unlock()
				return nil
		}).fail({ (ex, param) -> () in
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
		XCTAssertEqual("step 2", xparam[0]["var1"] as? String)
	}
	
	func testC8oDefaultPromiseFailUI() {
		
		let asyncExpectation = expectationWithDescription("testC8oDefaultPromiseFailUI")
		let UiThread = NSThread.currentThread()
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			let c8o = try! self.get(.C8O)
			var xjson: [JSON?] = [JSON?](count: 3, repeatedValue: nil)
			var xfail: [NSError] = [NSError]()
			var xparam: [Dictionary<String, AnyObject>] = [Dictionary<String, AnyObject>]()
			var xthread: [NSThread] = [NSThread]()
			let condition: NSCondition = NSCondition()
			condition.lock()
			c8o.callJson(".Ping", parameters: "var1", "step 1")
				.then({ (json, param) -> (C8oPromise<JSON>?) in
					xjson[0] = json
					return c8o.callJson(".Ping", parameters: "var1", "step 2")
			}).then({ (json, param) -> (C8oPromise<JSON>?) in
					xjson[1] = json
					if (json != nil) {
						throw C8oException(message: "random failure")
					}
					return c8o.callJson("Ping", parameters: "var1", "step 3")
			}).then({ (json, param) -> (C8oPromise<JSON>?) in
					xjson[2]? = json
					condition.lock()
					condition.signal()
					condition.unlock()
					return nil
			}).failUI { (ex, param) -> () in
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
	
	func testC8oDefaultPromiseSync() {
		
		let c8o = try! get(.C8O)
		var xjson: [JSON?] = [JSON?](count: 2, repeatedValue: nil)
		xjson[1] = try! c8o.callJson(".Ping", parameters: "var1", "step 1").then({ (json, param) -> (C8oPromise<JSON>?) in
			xjson[0] = json
			return c8o.callJson(".Ping", parameters: "var1", "step 2")
		}).sync()
		var value = xjson[0]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 1", value)
		value = xjson[1]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 2", value)
		
	}
	
	func testC8oDefaultPromiseSyncFail() {
		
		let c8o = try! get(.C8O)
		var xjson: [JSON?] = [JSON?](count: 2, repeatedValue: nil)
		var exception: C8oException? = nil as C8oException?
		do {
			xjson[1] = try c8o.callJson(".Ping", parameters: "var1", "step 1").then({ (json, param) -> (C8oPromise<JSON>?) in
				xjson[0] = json
				if (json != nil) {
					throw C8oException(message: "random failure")
				}
				return c8o.callJson(".Ping", parameters: "var1", "step 2")
			}).sync()
		}
		catch let ex as C8oException {
			exception = ex
		}
		catch {
			
		}
		
		let value = xjson[0]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 1", value)
		XCTAssertNil(xjson[1])
		XCTAssertNotNil(exception)
		XCTAssertEqual("random failure", exception?.message)
		
	}
	
	func testC8oDefaultPromiseNested() {
		let c8o = try! self.get(.C8O)
		var xjson: [JSON?] = [JSON?](count: 6, repeatedValue: nil)
		xjson[5] = try! c8o.callJson(".Ping", parameters: "var1", "step 1").then({ (json, param) -> (C8oPromise<JSON>?) in
			xjson[0] = json
			return c8o.callJson(".Ping", parameters: "var1", "step 2").then({ (json2, param2) -> (C8oPromise<JSON>?) in
				xjson[1] = json2
				return c8o.callJson(".Ping", parameters: "var1", "step 3").then({ (json3, param3) -> (C8oPromise<JSON>?) in
					xjson[2] = json3
					return c8o.callJson(".Ping", parameters: "var1", "step 4")
				})
			})
		}).then({ (json, param) -> (C8oPromise<JSON>?) in
			xjson[3] = json
			return c8o.callJson(".Ping", parameters: "var1", "step 5").then({ (json2, param2) -> (C8oPromise<JSON>?) in
				xjson[4] = json2
				return nil
			})
		}).sync()
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
	
	func testC8oDefaultPromiseNestedFail() {
		
		let c8o = try! self.get(.C8O)
		var xjson: [JSON?] = [JSON?](count: 6, repeatedValue: nil)
		var xfail: [C8oException?] = [C8oException?](count: 2, repeatedValue: nil)
		do {
			xjson[5] = try c8o.callJson(".Ping", parameters: "var1", "step 1").then({ (json, param) -> (C8oPromise<JSON>?) in
				xjson[0] = json
				return c8o.callJson(".Ping", parameters: "var1", "step 2").then({ (json2, param2) -> (C8oPromise<JSON>?) in
					xjson[1] = json2
					return c8o.callJson(".Ping", parameters: "var1", "step 3").then({ (json3, param3) -> (C8oPromise<JSON>?) in
						xjson[2] = json3
						throw C8oException(message: "random failure")
					})
				})
			}).then({ (json, param) -> (C8oPromise<JSON>?) in
				xjson[3] = json
				return c8o.callJson(".Ping", parameters: "var1", "step 5").then({ (json2, param2) -> (C8oPromise<JSON>?) in
					xjson[4] = json2
					return nil
				})
			}).fail({ (C8oException, param) -> () in
				xfail[0] = C8oException
			}).sync()
		}
		catch let e as C8oException {
			xfail[1] = e
		}
		catch {
			XCTFail()
		}
		var value = xjson[0]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 1", value)
		value = xjson[1]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 2", value)
		value = xjson[2]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 3", value)
		var valueNil: String? = xjson[3]?["document"]["pong"]["var1"].string
		XCTAssertNil(valueNil)
		valueNil = xjson[4]?["document"]["pong"]["var1"].string
		XCTAssertNil(valueNil)
		valueNil = xjson[5]?["document"]["pong"]["var1"].string
		XCTAssertNil(valueNil)
		XCTAssertEqual("random failure", xfail[0]?.message)
		XCTAssertEqual(xfail[0], xfail[1])
	}
	
	func testC8oDefaultPromiseInVar() {
		let c8o = try! self.get(.C8O)
		var xjson: [JSON?] = [JSON?](count: 3, repeatedValue: nil)
		let promise = c8o.callJson(".Ping", parameters: "var1", "step 1")
		promise.then({ (json, param) -> (C8oPromise<JSON>?) in
			xjson[0] = json
			return c8o.callJson(".Ping", parameters: "var1", "step 2")
		})
		promise.then({ (json, param) -> (C8oPromise<JSON>?) in
			xjson[1] = json
			return c8o.callJson(".Ping", parameters: "var1", "step 3")
		})
		xjson[2] = try! promise.sync()
		var value = xjson[0]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 1", value)
		value = xjson[1]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 2", value)
		value = xjson[2]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 3", value)
	}
	
	func testC8oDefaultPromiseInVarSleep() {
		let c8o = try! self.get(.C8O)
		var xjson: [JSON?] = [JSON?](count: 3, repeatedValue: nil)
		let promise = c8o.callJson(".Ping", parameters: "var1", "step 1")
		NSThread.sleepForTimeInterval(0.5)
		promise.then({ (json, param) -> (C8oPromise<JSON>?) in
			xjson[0] = json
			return c8o.callJson(".Ping", parameters: "var1", "step 2")
		})
		NSThread.sleepForTimeInterval(0.5)
		promise.then({ (json, param) -> (C8oPromise<JSON>?) in
			xjson[1] = json
			return c8o.callJson(".Ping", parameters: "var1", "step 3")
		})
		NSThread.sleepForTimeInterval(0.5)
		xjson[2] = try! promise.sync()
		var value = xjson[0]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 1", value)
		value = xjson[1]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 2", value)
		value = xjson[2]!["document"]["pong"]["var1"].stringValue
		XCTAssertEqual("step 3", value)
	} /*
	 //TODO...
	 func testC8o0Ssl1TrustFail(){
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
	
	// TODO...
	/*func testC8o0Ssl2TrustAll(){

	 }*/
	func testC8oFsPostGetDelete() {
		let c8o = try! get(.C8O_FS)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON? = try! c8o.callJson("fs://.reset").sync()
		XCTAssertTrue(json!["ok"].boolValue)
		let myId: String = "C8oFsPostGetDelete-" + String(NSDate().timeIntervalSince1970 * 1000)
		json = try! c8o.callJson("fs://.post", parameters: "_id", myId).sync()
		XCTAssertTrue(json!["ok"].boolValue)
		var id: String = json!["id"].stringValue
		XCTAssertEqual(id, myId)
		json = try! c8o.callJson("fs://.get", parameters: "docid", id).sync()
		id = json!["_id"].stringValue
		XCTAssertEqual(myId, id)
		json = try! c8o.callJson("fs://.delete", parameters: "docid", id).sync()
		XCTAssertTrue(json!["ok"].boolValue)
		do {
			try c8o.callJson("fs://.get", parameters: "docid", id).sync()
			XCTAssertTrue(false, "not possible")
		}
		catch _ as C8oRessourceNotFoundException {
			XCTAssertTrue(true)
		}
		catch {
			XCTAssertTrue(false)
		}
		
	}
	func testC8oFsPostGetDeleteRev() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON? = try! c8o.callJson("fs://.reset").sync()
		XCTAssertTrue(json!["ok"].boolValue)
		let id = "C8oFsPostGetDelete-Rev" + String(NSDate().timeIntervalSince1970 * 1000)
		json = try! c8o.callJson("fs://.post", parameters: "_id", id).sync()
		XCTAssertTrue(json!["ok"].boolValue)
		let rev: String = json!["rev"].stringValue
		do {
			try c8o.callJson("fs://.delete", parameters: "docid", id, "rev", "1-123456").sync()
			XCTAssertTrue(false, "not possible")
		}
		catch _ as C8oRessourceNotFoundException {
			XCTAssertTrue(true)
		}
		catch {
			XCTAssertTrue(false)
		}
		do {
			json = try c8o.callJson("fs://.delete", parameters: "docid", id, "rev", rev).sync()
		}
		catch _ as NSError {
			XCTAssert(false)
		}
		XCTAssertTrue(json!["ok"].boolValue)
		do {
			try c8o.callJson("fs://.get", parameters: "docid", id).sync()
			XCTAssertTrue(false, "not possible")
		}
		catch _ as C8oRessourceNotFoundException {
			XCTAssertTrue(true)
		}
		catch {
			XCTAssertTrue(false)
		}
		condition.unlock()
	}
	func testC8oFsPostGetDestroyCreate() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let ts: String = "ts=" + String(NSDate().timeIntervalSince1970 * 1000)
		let ts2: String = ts + "@test"
		json = try! c8o.callJson("fs://.post", parameters: "ts", ts).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let id = json["id"].stringValue
		let rev = json["rev"].stringValue
		json = try! c8o.callJson("fs://.post",
			parameters: "_id", id,
			"_rev", rev,
			"ts", ts,
			"ts2", ts2
		).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		json = try! c8o.callJson("fs://.get", parameters: "docid", id).sync()!
		XCTAssertEqual(ts, json["ts"].stringValue)
		XCTAssertEqual(ts2, json["ts2"].stringValue)
		json = try! c8o.callJson("fs://.destroy").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		json = try! c8o.callJson("fs://.create").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		do {
			try c8o.callJson("fs://.get", parameters: "docid", id).sync()
			XCTAssertTrue(false, "not possible")
		}
		catch _ as C8oRessourceNotFoundException {
			XCTAssertTrue(true)
		}
		catch {
			XCTAssertTrue(false)
		}
		condition.unlock()
		sleep(1)
	}
	
	func testC8oFsPostReset() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		json = try! c8o.callJson("fs://.post").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let id: String = json["id"].stringValue
		json = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		do {
			try c8o.callJson("fs://.get", parameters: "docid", id).sync()
			XCTAssertTrue(false, "not possible")
		}
		catch _ as C8oRessourceNotFoundException {
			XCTAssertTrue(true)
		}
		catch {
			XCTAssertTrue(false)
		}
		
		condition.unlock()
		
	}
	
	func testC8oFsPostExisting() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		json = try! c8o.callJson("fs://.post").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let id: String = json["id"].stringValue
		do {
			try c8o.callJson("fs://.post", parameters: "_id", id).sync()
			XCTAssertTrue(false, "not possible")
		} catch _ as c8oCouchbaseLiteException {
			XCTAssertTrue(true)
		}
		catch {
			XCTAssertTrue(false)
		}
		condition.unlock()
	}
	
	func testC8oFsPostExistingPolicyNone() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		json = try! c8o.callJson("fs://.post", parameters: C8o.FS_POLICY, C8o.FS_POLICY_NONE).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let id: String = json["id"].stringValue
		do {
			try c8o.callJson("fs://.post",
				parameters: C8o.FS_POLICY, C8o.FS_POLICY_NONE,
				"_id", id
			).sync()
			XCTAssertTrue(false, "not possible")
		} catch _ as c8oCouchbaseLiteException {
			XCTAssertTrue(true)
		}
		catch {
			XCTAssertTrue(false)
		}
		
	}
	
	/*func test0101(){

	 for i in 1...25 {
	 testC8oFsPostExistingPolicyCreate()
	 }
	 }*/
	func testC8oFsPostExistingPolicyCreate() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let myId: String = "C8oFsPostExistingPolicyCreate-" + String(NSDate().timeIntervalSince1970 * 1000)
		json = try! c8o.callJson("fs://.post", parameters: "_id", myId).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		var id: String = json["id"].stringValue
		XCTAssertEqual(myId, id)
		json = try! c8o.callJson("fs://.post",
			parameters: C8o.FS_POLICY, C8o.FS_POLICY_CREATE,
			"_id", id
		).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		id = json["id"].stringValue
		XCTAssertNotEqual(myId, id)
		
	}
	
	func testC8oFsPostExistingPolicyOverride() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let myId: String = "C8oFsPostExistingPolicyOverride-" + String(NSDate().timeIntervalSince1970 * 1000)
		json = try! c8o.callJson("fs://.post",
			parameters: C8o.FS_POLICY, C8o.FS_POLICY_OVERRIDE,
			"_id", myId,
			"a", 1,
			"b", 2
		).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		var id: String = json["id"].stringValue
		XCTAssertEqual(myId, id)
		json = try! c8o.callJson("fs://.post",
			parameters: C8o.FS_POLICY, C8o.FS_POLICY_OVERRIDE,
			"_id", myId,
			"a", 3,
			"c", 4
		).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		id = json["id"].stringValue
		XCTAssertEqual(myId, id)
		json = try! c8o.callJson("fs://.get", parameters: "docid", myId).sync()!
		XCTAssertEqual(3, json["a"].intValue)
		XCTAssertFalse(json["b"].isExists())
		XCTAssertEqual(4, json["c"].intValue)
	}
	
	func testC8oFsPostExistingPolicyMerge() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let myId: String = "C8oFsPostExistingPolicyMerge-" + String(NSDate().timeIntervalSince1970 * 1000)
		json = try! c8o.callJson("fs://.post",
			parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
			"_id", myId,
			"a", 1,
			"b", 2
		).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		var id: String = json["id"].stringValue
		XCTAssertEqual(myId, id)
		json = try! c8o.callJson("fs://.post",
			parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
			"_id", myId,
			"a", 3,
			"c", 4
		).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		id = json["id"].stringValue
		XCTAssertEqual(myId, id)
		json = try! c8o.callJson("fs://.get", parameters: "docid", myId).sync()!
		XCTAssertEqual(3, json["a"].intValue)
		XCTAssertEqual(2, json["b"].intValue)
		XCTAssertEqual(4, json["c"].intValue)
	}
	
	func testC8oFsPostExistingPolicyMergeSub() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let myId: String = "C8oFsPostExistingPolicyMergeSub-" + String(NSDate().timeIntervalSince1970 * 1000)
		let sub_f: JSON = ["g": true, "h": ["one", "two", "three", "four"]]
		var sub_c: JSON = ["d": 3, "e": "four", "f": sub_f.object]
		json = try! c8o.callJson("fs://.post",
			parameters: "_id", myId,
			"a", 1,
			"b", -2,
			"c", sub_c.object
		).sync()!
		XCTAssert(json["ok"].boolValue)
		json = try! c8o.callJson("fs://.post",
			parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
			"_id", myId,
			"i", (["5", 6, 7.1, NSNull()] as JSON).arrayObject!,
			"c.f.j", "good",
			"c.f.h", ([true, false] as JSON).arrayObject!
		).sync()!
		XCTAssert(json["ok"].boolValue)
		json = try! c8o.callJson("fs://.post",
			parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
			C8o.FS_SUBKEY_SEPARATOR, "<>",
			"_id", myId,
			"c<>i-j", "great"
		).sync()!
		XCTAssert(json["ok"].boolValue)
		json = try! c8o.callJson("fs://.get", parameters: "docid", myId).sync()!
		json.dictionaryObject?.removeValueForKey("_rev")
		XCTAssertEqual(myId, json.dictionaryObject?.removeValueForKey("_id") as? String)
		let expectedJson = "{\n  \"b\" : -2,\n  \"a\" : 1,\n  \"i\" : [\n    \"5\",\n    6,\n    7.1,\n    null\n  ],\n  \"c\" : {\n    \"f\" : {\n      \"g\" : true,\n      \"j\" : \"good\",\n      \"h\" : [\n        true,\n        false,\n        \"three\",\n        \"four\"\n      ]\n    },\n    \"i-j\" : \"great\",\n    \"e\" : \"four\",\n    \"d\" : 3\n  }\n}"
		
		if let dataFromString = expectedJson.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
			let jsonex = JSON(data: dataFromString)
			XCTAssertEquals(jsonex, actual: json)
		}
	}
	
	internal class PlainObjectA {
		internal var name: String?
		internal var bObjects: Array<PlainObjectB>?
		internal var bObject: PlainObjectB?
	}
	
	internal class PlainObjectB {
		internal var name: String?
		internal var num: Int?
		internal var enabled: Bool?
	}
	
	func testC8oFsMergeObject() {
		let c8o = try! get(.C8O_FS_PUSH)
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let myId: String = "C8oFsPostExistingPolicyMergeSub-" + String(NSDate().timeIntervalSince1970 * 1000)
		
		let plainObjectA = PlainObjectA()
		plainObjectA.name = "plain A"
		plainObjectA.bObjects = []
		
		plainObjectA.bObject = PlainObjectB()
		plainObjectA.bObject?.name = "plain B 1"
		plainObjectA.bObject?.num = 1
		plainObjectA.bObject?.enabled = true
		plainObjectA.bObjects?.append(plainObjectA.bObject!)
		
		plainObjectA.bObject = PlainObjectB()
		plainObjectA.bObject?.name = "plain B 2"
		plainObjectA.bObject?.num = 2
		plainObjectA.bObject?.enabled = false
		plainObjectA.bObjects?.append(plainObjectA.bObject!)
		
		plainObjectA.bObject = PlainObjectB()
		plainObjectA.bObject?.name = "plain B -777"
		plainObjectA.bObject?.num = -777
		plainObjectA.bObject?.enabled = true
		
		json = try! c8o.callJson("fs://.post",
			parameters: "_id", myId,
			"a obj", plainObjectA
		).sync()!
		XCTAssert(json["ok"].boolValue)
		plainObjectA.bObjects![1].name = "plain B 2 bis"
		
		json = try! c8o.callJson("fs://.post", parameters:
				C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
			"_id", myId,
			"a obj.bObjects", plainObjectA.bObjects!
		).sync()!
		XCTAssert(json["ok"].boolValue)
		
		plainObjectA.bObject = PlainObjectB()
		plainObjectA.bObject?.name = "plain B -666"
		plainObjectA.bObject?.num = -666
		plainObjectA.bObject?.enabled = false
		
		json = try! c8o.callJson("fs://.post", parameters:
				C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
			"_id", myId,
			"a obj.bObject", plainObjectA.bObject!
		).sync()!
		XCTAssert(json["ok"].boolValue)
		
		json = try! c8o.callJson("fs://.post", parameters:
				C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
			"_id", myId,
			"a obj.bObject.enabled", true
		).sync()!
		XCTAssert(json["ok"].boolValue)
		
		json = try! c8o.callJson("fs://.get", parameters: "docid", myId).sync()!
		json.dictionaryObject?.removeValueForKey("_rev")
		XCTAssertEqual(myId, json["_id"].stringValue)
		XCTAssertEqual(myId, json.dictionaryObject?.removeValueForKey("_id") as? String)
		
		let expectedJson = "{\n  \"a obj\" : {\n    \"bObject\" : {\n      \"enabled\" : true,\n      \"num\" : -666,\n      \"name\" : \"plain B -666\"\n    },\n    \"bObjects\" : [\n      {\n        \"name\" : \"plain B 1\",\n        \"num\" : 1,\n        \"enabled\" : true\n      },\n      {\n        \"name\" : \"plain B 2 bis\",\n        \"num\" : 2,\n        \"enabled\" : false\n      }\n    ],\n    \"name\" : \"plain A\"\n  }\n}"
		
		if let dataFromString = expectedJson.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
			let jsonex = JSON(data: dataFromString)
			XCTAssertEquals(jsonex, actual: json)
		}
		
	}
	
	func testC8oFsPostGetMultibase() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		var json: JSON = try! c8o.callJson("fs://.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		json = try! c8o.callJson("fs://notdefault.reset").sync()!
		XCTAssertTrue(json["ok"].boolValue)
		let myId: String = "C8oFsPostGetMultibase-" + String(NSDate().timeIntervalSince1970 * 1000)
		json = try! c8o.callJson("fs://.post", parameters: "_id", myId).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		do {
			try c8o.callJson("fs://notdefault.get", parameters: "docid", myId).sync()
			XCTAssertTrue(false, "not possible")
		}
		catch _ as C8oRessourceNotFoundException {
			XCTAssertTrue(true)
		}
		catch {
			XCTAssertTrue(false)
		}
		json = try! c8o.callJson("fs://notdefault.post", parameters: "_id", myId).sync()!
		XCTAssertTrue(json["ok"].boolValue)
		json = try! c8o.callJson("fs://notdefault.get", parameters: "docid", myId).sync()!
		let id: String = json["_id"].stringValue
		XCTAssertEqual(myId, id)
	}
	
	/*
	 func testC8oCBLpull() {
	 let manager = CBLManager()
	 let options = CBLDatabaseOptions()
	 options.create = true
	 //options.storageType = kCBLForestDBStorage
	 options.storageType = kCBLSQLiteStorage
	 let db = try! manager.openDatabaseNamed("testing4", withOptions: options)
	 //let url = NSURL(string: "http://buildus.twinsoft.fr:28080/convertigo/fullsync/qa_fs_pull")
	 let url = NSURL(string: "http://buildus.twinsoft.fr:5984/qa_fs_pull")
	 let rep = db.createPullReplication(url!)
	 rep.start()
	 sleep(4)
	 let changes = rep.completedChangesCount
	 XCTAssertNotEqual(0, changes)
	 }
	 */
	
	func testC8oFsReplicateAnoAndAuth() {
		
		let c8o = try! get(.C8O_FS_PULL)
		c8o.fullSyncStorageEngine = C8o.FS_STORAGE_SQL
		let condition: NSCondition = NSCondition()
		condition.lock()
		do {
			var json: JSON = try! c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			do {
				try c8o.callJson("fs://.get", parameters: "docid", "258").sync()
				XCTAssertTrue(false, "not possible")
			}
			catch _ as C8oRessourceNotFoundException {
				XCTAssertTrue(true)
			}
			catch {
				XCTAssertTrue(false)
			}
			json = try! c8o.callJson("fs://.replicate_pull").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson("fs://.get", parameters: "docid", "258").sync()!
			var value: String = json["data"].stringValue
			XCTAssertEqual("258", value)
			do {
				try c8o.callJson("fs://.get", parameters: "docid", "456").sync()
				XCTAssertTrue(false, "not possible")
			}
			catch _ as C8oRessourceNotFoundException {
				XCTAssertTrue(true)
			}
			catch {
				XCTAssertTrue(false)
			}
			
			try! json = c8o.callJson(".LoginTesting").sync()!
			value = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value)
			json = try! c8o.callJson("fs://.replicate_pull").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson("fs://.get", parameters: "docid", "456").sync()!
			value = json["data"].stringValue
			XCTAssertEqual("456", value)
			
		}
		
		try! c8o.callJson(".LogoutTesting").sync()
	}
	
	func testC8oFsReplicatePullProgress() {
		let c8o = try! get(.C8O_FS_PULL)
		let condition: NSCondition = NSCondition()
		condition.lock()
		do {
			var json: JSON = try! c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			try! json = c8o.callJson(".LoginTesting").sync()!
			var value = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value)
			var count: [Int] = [0]
			var first: [String?] = [nil]
			var last: [String?] = [nil]
			var uiThread: [Bool] = [false]
			let doc = try! c8o.callXml("fs://.replicate_pull").progress({ (C8oProgress) in
				count[0] += 1
				if (NSThread.mainThread() == NSThread.currentThread()) {
					uiThread[0] = true
				} else {
					uiThread[0] = false
				}
				if (first[0] == nil) {
					first[0] = C8oProgress.description
				}
				last[0] = C8oProgress.description
				
			}).sync()!
            
			XCTAssertEqual("true", doc["document"]["couchdb_output"]["ok"].stringValue)
			json = try! c8o.callJson("fs://.get", parameters: "docid", "456").sync()!
			value = json["data"].stringValue
			XCTAssertEqual("456", value)
			XCTAssertFalse(uiThread[0], "uiThread must be False")
			XCTAssertEqual("pull: 0/0 (running)", first[0])
			XCTAssertEqual("pull: 8/8 (done)", last[0])
			XCTAssertTrue(count[0] > 2, "count > 5")
		}
		
		try! c8o.callJson(".LogoutTesting").sync()!
		
	}
	
	func testC8oFsReplicatePullProgressUI() {
		
		let c8o = try! get(.C8O_FS_PULL)
		let condition: NSCondition = NSCondition()
		condition.lock()
		do {
			var json: JSON = try c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			try json = c8o.callJson(".LoginTesting").sync()!
			var value = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value)
			var count: [Int] = [0]
			var first: [String?] = [nil]
			var last: [String?] = [nil]
			var uiThread: [Bool] = [false]
			let asyncExpectation = expectationWithDescription("longRunningFunction")
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
				json = try! c8o.callJson("fs://.replicate_pull").progressUI({ (C8oProgress) in
					count[0] += 1
					if (NSThread.mainThread() == NSThread.currentThread()) {
						uiThread[0] = true
					} else {
						uiThread[0] = false
					}
					if (first[0] == nil) {
						first[0] = C8oProgress.description
					}
					last[0] = C8oProgress.description
					
				}).sync()!
				asyncExpectation.fulfill()
			})
			self.waitForExpectationsWithTimeout(20) { error in
			}
			XCTAssertTrue(json["ok"].boolValue)
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson("fs://.get", parameters: "docid", "456").sync()!
			value = json["data"].stringValue
			XCTAssertEqual("456", value)
			XCTAssertTrue(uiThread[0], "uiThread must be False")
			XCTAssertEqual("pull: 0/0 (running)", first[0])
			XCTAssertEqual("pull: 8/8 (done)", last[0])
			XCTAssertTrue(count[0] > 2, "count > 5")
		}
		catch let e as NSError {
			XCTFail(e.description)
		}
		try! c8o.callJson(".LogoutTesting").sync()!
		
	}
	
	func testC8oFsReplicatePullAnoAndAuthView() {
		let c8o = try! get(.C8O_FS_PULL)
		let condition: NSCondition = NSCondition()
		condition.lock()
		do {
			var json: JSON = try! c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson("fs://.replicate_pull").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson("fs://.view",
				parameters: "ddoc", "design",
				"view", "reverse"
			).sync()!
			var value: AnyObject = json["rows"][0]["value"].doubleValue
			XCTAssertEqual(774.0, value as? Double)
			json = try! c8o.callJson("fs://.view",
				parameters: "ddoc", "design",
				"view", "reverse",
				"reduce", false
			).sync()!
			value = json["count"].intValue
			XCTAssertEqual(3, value as? Int)
			value = json["rows"][1]["key"].stringValue
			XCTAssertEqual("852", value as? String)
			json = try! c8o.callJson("fs://.view",
				parameters: "ddoc", "design",
				"view", "reverse",
				"startkey", "0",
				"endkey", "9"
			).sync()!
			value = json["rows"][0]["value"].doubleValue
			XCTAssertEqual(405.0, value as? Double)
			json = try! c8o.callJson(".LoginTesting").sync()!
			value = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value as? String)
			json = try! c8o.callJson("fs://.replicate_pull").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson("fs://.view",
				parameters: "ddoc", "design",
				"view", "reverse"
			).sync()!
			value = json["rows"][0]["value"].doubleValue
			XCTAssertEqual(2142.0, value as? Double)
			json = try! c8o.callJson("fs://.view",
				parameters: "ddoc", "design",
				"view", "reverse",
				"reduce", false
			).sync()!
			value = json["count"].intValue
			XCTAssertEqual(6, value as? Int)
			value = json["rows"][1]["key"].stringValue
			XCTAssertEqual("654", value as? String)
			json = try! c8o.callJson("fs://.post", parameters: "_id", "111", "data", "16").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson("fs://.view",
				parameters: "ddoc", "design",
				"view", "reverse",
				"startkey", "0",
				"endkey", "9"
			).sync()!
			value = json["rows"][0]["value"].doubleValue
			XCTAssertEqual(1000.0, value as? Double)
			
		}
		
		try! c8o.callJson(".LogoutTesting").sync()!
	}
	
	func testC8oFsViewArrayKey() {
		let c8o = try! get(Stuff.C8O_FS_PULL)
		do {
			var json = try! c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson(".LoginTesting").sync()!
			let value = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value)
			json = try! c8o.callJson("fs://.replicate_pull").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson("fs://.view",
				parameters: "ddoc", "design",
				"view", "array",
				"startkey", "[\"1\"]"
			).sync()!
		}
		try! c8o.callJson(".LogoutTesting").sync()!
	}
	
	func testC8oFsReplicatePullGetAll() {
		let c8o = try! get(.C8O_FS_PULL)
		let condition: NSCondition = NSCondition()
		condition.lock()
		do {
			var json: JSON = try c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			try! json = c8o.callJson(".LoginTesting").sync()!
			let value = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value)
			json = try c8o.callJson("fs://.replicate_pull").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try c8o.callJson("fs://.all").sync()!
			XCTAssertEqual(8, json["count"].intValue)
			XCTAssertEqual(8, json["rows"].count)
			XCTAssertEqual("789", json["rows"][5]["key"].stringValue)
			XCTAssertFalse(json["rows"][5]["doc"].isExists())
			json = try c8o.callJson("fs://.all",
				parameters: "include_docs", true
			).sync()!
			XCTAssertEqual(8, json["count"].intValue)
			XCTAssertEqual(8, json["rows"].count)
			XCTAssertEqual("789", json["rows"][5]["key"].stringValue)
			XCTAssertEqual("testing_user", json["rows"][5]["doc"]["~c8oAcl"].stringValue)
			json = try c8o.callJson("fs://.all",
				parameters: "limit", 2
			).sync()!
			XCTAssertEqual(2, json["count"].intValue)
			XCTAssertEqual(2, json["rows"].count)
			XCTAssertEqual("147", json["rows"][1]["key"].stringValue)
			XCTAssertFalse(json["rows"][1]["doc"].isExists())
			json = try c8o.callJson("fs://.all",
				parameters: "include_docs", true,
				"limit", 3,
				"skip", 2
			).sync()!
			XCTAssertEqual(3, json["count"].intValue)
			XCTAssertEqual(3, json["rows"].count)
			XCTAssertEqual("369", json["rows"][1]["key"].stringValue)
			XCTAssertEqual("doc", json["rows"][1]["doc"]["type"].stringValue)
		}
		catch let e as NSError {
			try! c8o.callJson(".LogoutTesting").sync()!
			XCTFail(e.description)
		}
		try! c8o.callJson(".LogoutTesting").sync()!
	}
	
	func testC8oFsReplicatePushAuth() {
		
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		do {
			var json: JSON = try c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			let id: String = "C8oFsReplicatePushAnoAndAuth-" + String(NSDate().timeIntervalSince1970 * 1000)
			json = try c8o.callJson("fs://.post",
				parameters: "_id", id,
				"data", "777",
				"bool", true,
				"int", 777
			).sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try c8o.callJson(".LoginTesting").sync()!
			var value: AnyObject = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value as? String)
			json = try c8o.callJson("fs://.replicate_push").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try c8o.callJson(".qa_fs_push.GetDocument", parameters: "_use_docid", id).sync()!
			value = json["document"]["couchdb_output"]["data"].stringValue
			XCTAssertEqual("777", value as? String)
			value = json["document"]["couchdb_output"]["int"].intValue
			XCTAssertEqual(777, value as? Int)
			value = json["document"]["couchdb_output"]["~c8oAcl"].stringValue
			XCTAssertEqual("testing_user", value as? String)
			
		}
		catch let e as NSError {
			try! c8o.callJson(".LogoutTesting").sync()!
			XCTFail(e.description)
		}
		try! c8o.callJson(".LogoutTesting").sync()!
		
	}
	
	func testC8oFsReplicatePushAuthProgress() {
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		do {
			var json: JSON = try c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			let id: String = "C8oFsReplicatePushAuthProgress-" + String(NSDate().timeIntervalSince1970 * 1000)
			for index in 0...9 {
				json = try! c8o.callJson("fs://.post",
					parameters: "_id", id + "-" + index.description,
					"index", index.description
				).sync()!
				XCTAssertTrue(json["ok"].boolValue)
			}
			json = try c8o.callJson(".LoginTesting").sync()!
			var value: AnyObject = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value as? String)
			var count: [Int] = [0]
			var first: [String?] = [nil]
			var last: [String?] = [nil]
			var uiThread: [Bool] = [false]
			json = try! c8o.callJson("fs://.replicate_push").progress({ (C8oProgress) in
				count[0] += 1
				if (NSThread.mainThread() == NSThread.currentThread()) {
					uiThread[0] = true
				} else {
					uiThread[0] = false
				}
				if (first[0] == nil) {
					first[0] = C8oProgress.description
				}
				last[0] = C8oProgress.description
				
			}).sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson(".qa_fs_push.AllDocs",
				parameters: "startkey", id,
				"endkey", id + "z"
			).sync()!
			let array: JSON = json["document"]["couchdb_output"]["rows"]
			XCTAssertEqual(10, array.count)
			for index in 0...9 {
				value = array[index]["doc"]["_id"].stringValue
				XCTAssertEqual(id + "-" + index.description, value as? String)
				value = array[index]["doc"]["index"].intValue
				XCTAssertEqual(index, value as? Int)
				value = array[index]["doc"]["~c8oAcl"].stringValue
				XCTAssertEqual("testing_user", value as? String)
			}
			XCTAssertFalse(uiThread[0], "uiThread must be False")
			XCTAssertEqual(first[0], "push: 0/0 (running)")
			XCTAssertEqual(last[0], "push: 10/10 (done)")
			XCTAssertTrue(count[0] > 2, "count > 3")
			
		}
		catch let e as NSError {
			try! c8o.callJson(".LogoutTesting").sync()!
			XCTFail(e.description)
		}
		try! c8o.callJson(".LogoutTesting").sync()!
		
	}
	
	func testC8oFsReplicateSyncContinuousProgress() {
		
		let c8o = try! get(.C8O_FS_PUSH)
		let condition: NSCondition = NSCondition()
		condition.lock()
		do {
			var json: JSON = try c8o.callJson("fs://.reset").sync()!
			XCTAssertTrue(json["ok"].boolValue)
			let id: String = "C8oFsReplicateSyncContinuousProgress-" + String(NSDate().timeIntervalSince1970 * 1000)
			for index in 0...2 {
				json = try! c8o.callJson("fs://.post",
					parameters: "_id", id + "-" + index.description,
					"index", index.description
				).sync()!
				XCTAssertTrue(json["ok"].boolValue)
			}
			json = try! c8o.callJson(".LoginTesting").sync()!
			var value: AnyObject = json["document"]["authenticatedUserID"].stringValue
			XCTAssertEqual("testing_user", value as? String)
			var firstPush: [String?] = [nil]
			var lastPush: [String?] = [nil]
			var livePush: [String?] = [nil]
			var firstPull: [String?] = [nil]
			var lastPull: [String?] = [nil]
			var livePull: [String?] = [nil]
			
			json = try! c8o.callJson("fs://.sync", parameters: "continuous", true).progress({ (progress) in
				if (progress.continuous) {
					if (progress.push) {
						livePush[0] = progress.description
					}
					if (progress.pull) {
						livePull[0] = progress.description
					}
				} else {
					if (progress.push) {
						if (firstPush[0] == nil) {
							firstPush[0] = progress.description
						}
						lastPush[0] = progress.description
					}
					if (progress.pull) {
						if (firstPull[0] == nil) {
							firstPull[0] = progress.description
						}
						lastPull[0] = progress.description
					}
				}
			}).sync()!
			
			XCTAssertTrue(json["ok"].boolValue)
			XCTAssertEqual(firstPush[0], "push: 0/0 (running)")
			var range = NSMakeRange(0, (lastPush[0] as String!).characters.count)
			var regexV = try! NSRegularExpression(pattern: "push: \\d+/\\d+ \\(done\\)", options: []).matchesInString(lastPush[0]!, options: [], range: range)
			XCTAssertTrue(regexV.first != nil, "push: \\d+/\\d+ \\(done\\) for " + lastPush[0]!)
			XCTAssertEqual(firstPull[0], "pull: 0/0 (running)")
			range = NSMakeRange(0, (lastPull[0] as String!).characters.count)
			regexV = try! NSRegularExpression(pattern: "pull: \\d+/\\d+ \\(done\\)", options: []).matchesInString(lastPull[0]!, options: [], range: range)
			XCTAssertTrue(regexV.first != nil, "pull: \\d+/\\d+ \\(done\\) for " + lastPull[0]!)
			
			json = try! c8o.callJson(".qa_fs_push.AllDocs",
				parameters: "startkey", id,
				"endkey", id + "z"
			).sync()!
			let array: JSON = json["document"]["couchdb_output"]["rows"]
			XCTAssertEqual(3, array.count)
			for index in 0...2 {
				value = array[index]["doc"]["_id"].stringValue
				XCTAssertEqual(id + "-" + index.description, value as? String)
			}
			json = try! c8o.callJson("fs://.get", parameters: "docid", "def").sync()!
			value = json["_id"].stringValue
			XCTAssertEqual("def", value as? String)
			json.dictionaryObject!["custom"] = id
			json = try! c8o.callJson("fs://.post", parameters: json).sync()!
			XCTAssertTrue(json["ok"].boolValue)
			json = try! c8o.callJson(".qa_fs_push.PostDocument", parameters: "_id", "ghi", "custom", id).sync()!
			XCTAssertTrue(json["document"]["couchdb_output"]["ok"].boolValue)
			sleep(2)
			json = try! c8o.callJson("fs://.get", parameters: "docid", "ghi").sync()!
			value = json["custom"].stringValue
			
			XCTAssertEqual(id, value as? String)
			json = try! c8o.callJson(".qa_fs_push.GetDocument", parameters: "_use_docid", "def").sync()!
			value = json["document"]["couchdb_output"]["custom"].stringValue
			print(json["document"].description)
			XCTAssertEqual(id, value as? String)
			range = NSMakeRange(0, (livePull[0] as String!).characters.count)
			regexV = try! NSRegularExpression(pattern: "pull: \\d+/\\d+ \\(live\\)", options: []).matchesInString(livePull[0]!, options: [], range: range)
			XCTAssertTrue(regexV.first != nil, "pull: \\d+/\\d+ \\(live\\) for " + livePull[0]!)
			range = NSMakeRange(0, (livePush[0] as String!).characters.count)
			regexV = try! NSRegularExpression(pattern: "push: \\d+/\\d+ \\(live\\)", options: []).matchesInString(livePush[0]!, options: [], range: range)
			XCTAssertTrue(regexV.first != nil, "push: \\d+/\\d+ \\(live\\) for " + livePush[0]!)
		}
		catch let e as NSError {
			try! c8o.callJson(".LogoutTesting").sync()!
			XCTFail(e.description)
		}
		try! c8o.callJson(".LogoutTesting").sync()!
	}
	
    func testC8oFsReplicateCancel() {
        let c8o = try! get(.C8O_FS)
        do {
            var json: JSON = try c8o.callJson("fs://.reset").sync()!
            XCTAssertTrue(json["ok"].boolValue)
            json = try c8o.callJson("fs://.replicate_push", parameters: "cancel", true).sync()!
            XCTAssertTrue(json["ok"].boolValue)
            json = try c8o.callJson("fs://.replicate_pull", parameters: "cancel", true).sync()!
            XCTAssertTrue(json["ok"].boolValue)
            json = try c8o.callJson("fs://.sync", parameters: "cancel", true).sync()!
            XCTAssertTrue(json["ok"].boolValue)
        } catch let e as NSError {
           XCTFail(e.description)
        }
    }
    
	func testC8oLocalCacheXmlPriorityLocal() {
		let c8o = try! get(.C8O_FS_PUSH)
		let id: String = "C8oFsReplidateFormattercateSyncContinuousProgress-" + String(NSDate().timeIntervalSince1970 * 1000)
		var doc: AEXMLDocument = try! c8o.callXml(".Ping",
			parameters:
				C8oLocalCache.PARAM, C8oLocalCache(priority: C8oLocalCache.Priority.LOCAL, ttl: 3000),
			"var1", id
		).sync()!
		var value = doc["document"]["pong"]["var1"].stringValue
		XCTAssertEqual(id, value)
		let signature: String = doc["document"].attributes["signature"]!
		sleep(1)
		doc = try! c8o.callXml(".Ping",
			parameters: C8oLocalCache.PARAM, C8oLocalCache(priority: C8oLocalCache.Priority.LOCAL, ttl: 3000),
			"var1", id + "bis"
		).sync()!
		value = doc["document"]["pong"]["var1"].stringValue
		XCTAssertEqual(id + "bis", value)
		var signature2: String = doc["document"].attributes["signature"]!
		XCTAssertNotEqual(signature, signature2)
		sleep(1)
		doc = try! c8o.callXml(".Ping",
			parameters: C8oLocalCache.PARAM, C8oLocalCache(priority: C8oLocalCache.Priority.LOCAL, ttl: 3000),
			"var1", id
		).sync()!
		value = doc["document"]["pong"]["var1"].stringValue
		XCTAssertEqual(id, value)
		signature2 = doc["document"].attributes["signature"]!
		XCTAssertEqual(signature, signature2)
		sleep(2)
		doc = try! c8o.callXml(".Ping",
			parameters: C8oLocalCache.PARAM, C8oLocalCache(priority: C8oLocalCache.Priority.LOCAL, ttl: 3000),
			"var1", id
		).sync()!
		value = doc["document"]["pong"]["var1"].stringValue
		XCTAssertEqual(id, value)
		signature2 = doc["document"].attributes["signature"]!
		XCTAssertNotEqual(signature, signature2)
	}
	
	func testC8oLocalCacheJsonPriorityLocal() {
		let c8o = try! get(.C8O_FS_PUSH)
		let id: String = "C8oLocalCacheJsonPriorityLocal-" + String(NSDate().timeIntervalSince1970 * 1000)
		var json: JSON = try! c8o.callJson(".Ping",
			parameters: C8oLocalCache.PARAM, C8oLocalCache(priority: C8oLocalCache.Priority.LOCAL, ttl: 3000),
			"var1", id
		).sync()!
		var value: String = json["document"]["pong"]["var1"].stringValue
		XCTAssertEqual(id, value)
		let signature = json["document"]["attr"]["signature"].stringValue
		sleep(1)
		json = try! c8o.callJson(".Ping",
			parameters: C8oLocalCache.PARAM, C8oLocalCache(priority: C8oLocalCache.Priority.LOCAL, ttl: 3000),
			"var1", id + "bis"
		).sync()!
		value = json["document"]["pong"]["var1"].stringValue
		XCTAssertEqual(id + "bis", value)
		var signature2: String = json["document"]["attr"]["signature"].stringValue
		XCTAssertNotEqual(signature, signature2)
		sleep(1)
		json = try! c8o.callJson(".Ping",
			parameters: C8oLocalCache.PARAM, C8oLocalCache(priority: C8oLocalCache.Priority.LOCAL, ttl: 3000),
			"var1", id
		).sync()!
		value = json["document"]["pong"]["var1"].stringValue
		XCTAssertEqual(id, value)
		signature2 = json["document"]["attr"]["signature"].stringValue
		XCTAssertEqual(signature, signature2)
		sleep(3)
		json = try! c8o.callJson(".Ping",
			parameters: C8oLocalCache.PARAM, C8oLocalCache(priority: C8oLocalCache.Priority.LOCAL, ttl: 3000),
			"var1", id
		).sync()!
		value = json["document"]["pong"]["var1"].stringValue
		XCTAssertEqual(id, value)
		signature2 = json["document"]["attr"]["signature"].stringValue
		XCTAssertNotEqual(signature, signature2)
	}
	
	func testC8oFileTransferDownloadSimple() {
		let c8o = try! get(.C8O)
		let ft = try! C8oFileTransfer(c8o: c8o, c8oFileTransferSettings: C8oFileTransferSettings())
		try! c8o.callJson("fs://" + ft.taskDb + ".destroy").sync()
		var status: [C8oFileTransferStatus?] = [nil]
		let __status: NSCondition = NSCondition()
		var error: [NSError?] = [nil]
		ft.raiseTransferStatus({ (source, event) in
			if (event.state == C8oFileTransferStatus.StateFinished) {
				__status.lock()
				status[0] = event
				__status.signal()
				__status.unlock()
			}
		})
		ft.raiseException({ (source, event) in
			__status.lock()
			error[0] = event
			__status.signal()
			__status.unlock()
		})
		ft.start()
		let uuid = try! c8o.callXml(".PrepareDownload4M").sync()!["document"]["uuid"].stringValue
		XCTAssertNotNil(uuid)
		let file = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] + "/4m.jpg"
		let fm = NSFileManager.defaultManager()
		do {
			try fm.removeItemAtPath(file)
		} catch { }
		do {
			__status.lock()
			try ft.downloadFile(uuid, filePath: file)
			__status.waitUntilDate(NSDate(timeIntervalSinceNow: 20.0))
			__status.unlock()
			if (error[0] != nil) {
				throw error[0]!
			}
			XCTAssertNotNil(status[0])
			XCTAssertTrue(fm.fileExistsAtPath(file))
			let length: Int = try fm.attributesOfItemAtPath(file)[NSFileSize] as! Int
			XCTAssertEqual(4237409, length)
			do {
				try fm.removeItemAtPath(file)
			} catch { }
		} catch {
			do {
				try fm.removeItemAtPath(file)
			} catch { }
		}
	}
	
	func testC8oFileTransferUploadSimple() {
		let c8o = try! get(.C8O)
		let ft = try! C8oFileTransfer(c8o: c8o, c8oFileTransferSettings: C8oFileTransferSettings())
		try! c8o.callJson("fs://" + ft.taskDb + ".destroy").sync()
		var status: [C8oFileTransferStatus?] = [nil]
		let __status: NSCondition = NSCondition()
		var error: [NSError?] = [nil]
		ft.raiseTransferStatus({ (source, event) in
			if (event.state == C8oFileTransferStatus.StateFinished) {
				__status.lock()
				status[0] = event
				__status.signal()
				__status.unlock()
			}
		})
		ft.raiseException({ (source, event) in
			__status.lock()
			error[0] = event
			__status.signal()
			__status.unlock()
		})
		ft.start()
		__status.lock()
		let path = NSBundle(forClass: C8oSDKiOSTests.self).pathForResource("4m", ofType: "jpg")
		let ins: NSInputStream = NSInputStream(fileAtPath: path!)!
		try! ft.uploadFile("4m.jpg", fileStream: ins)
		__status.waitUntilDate(NSDate(timeIntervalSinceNow: 20.0))
		__status.unlock()
		if (error[0] != nil) {
			// throw error[0]!
		}
		XCTAssertNotNil(status[0])
		let filepath = status[0]?.serverFilepath
		let length = try! c8o.callXml(".GetSizeAndDelete", parameters: "filepath", filepath!).sync()!["document"]["length"].stringValue
		XCTAssertEqual("5120000", length)
	}
	
    func disable_testC8oFsLiveChanges() {
        let c8o = try! get(.C8O_FS_PUSH)
        var lastChanges: JSON? = nil
        let _lastChanges = NSCondition()
        
        let changeListener = C8oFullSyncChangeListener(handler: {(changes: JSON) -> () in
            _lastChanges.lock()
            lastChanges = changes
            _lastChanges.signal()
            _lastChanges.unlock()
        })
        
        let condition: NSCondition = NSCondition()
        condition.lock()
        do {
            var json: JSON = try! c8o.callJson("fs://.reset").sync()!
            XCTAssertTrue(json["ok"].boolValue)
            json = try! c8o.callJson("fs://.replicate_pull", parameters: "continuous", true).sync()!
            XCTAssertTrue(json["ok"].boolValue)
            var cptlive: Int = 0
            let _cptlive = NSCondition()
            try! c8o.callJson("fs://.get", parameters: "docid", "abc", C8o.FS_LIVE, "getabc").then({ (response, parameters) -> (C8oPromise<JSON>?) in
                _cptlive.lock()
                if (response["_id"].stringValue == "abc") {
                    cptlive = cptlive + 1
                }
                _cptlive.signal()
                _cptlive.unlock()
                return nil
            }).sync()
            XCTAssertEqual(1, cptlive)
            _cptlive.lock()
            json = try! c8o.callJson(".qa_fs_push.PostDocument", parameters: "_id", "ghi").sync()!
            XCTAssertTrue(json["document"]["couchdb_output"]["ok"].boolValue)
            _cptlive.waitUntilDate(NSDate(timeIntervalSinceNow: 1.0))
            XCTAssertEqual(2, cptlive)
            _cptlive.unlock()
            
            try! c8o.addFullSyncChangeListener("", listener: changeListener)
            _lastChanges.lock()
            _cptlive.lock()
            json = try! c8o.callJson(".qa_fs_push.PostDocument", parameters: "_id", "jkl").sync()!
            XCTAssertTrue(json["document"]["couchdb_output"]["ok"].boolValue)
            _lastChanges.waitUntilDate(NSDate(timeIntervalSinceNow: 3.0))
            _cptlive.waitUntilDate(NSDate(timeIntervalSinceNow: 1.0))
            XCTAssertEqual(3, cptlive)
            XCTAssertNotNil(lastChanges)
            XCTAssertEqual(1, lastChanges!["changes"].arrayValue.count)
            XCTAssertEqual("jkl", lastChanges!["changes"][0]["id"].stringValue)
            _cptlive.unlock()
            _lastChanges.unlock()
            
            _lastChanges.lock()
            _cptlive.lock()
            try! c8o.cancelLive("getabc")
            json = try! c8o.callJson(".qa_fs_push.PostDocument", parameters: "_id", "mno").sync()!
            XCTAssertTrue(json["document"]["couchdb_output"]["ok"].boolValue)
            _lastChanges.waitUntilDate(NSDate(timeIntervalSinceNow: 3.0))
            _cptlive.waitUntilDate(NSDate(timeIntervalSinceNow: 1.0))
            XCTAssertEqual(3, cptlive)
            XCTAssertNotNil(lastChanges)
            XCTAssertEqual(1, lastChanges!["changes"].arrayValue.count)
            XCTAssertEqual("mno", lastChanges!["changes"][0]["id"].stringValue)
            _cptlive.unlock()
            _lastChanges.unlock()
        }
        try! c8o.cancelLive("getabc")
        try! c8o.removeFullSyncChangeListener("", listener: changeListener)
    }

    
	// TODO...
	/*
	 func testC8oSslValid(){

	 }
	 func testC8oSslTrustAllClientFail(){

	 }
	 func testC8oSslTrustAllClientOk(){

	 }*/
	
    func testSslTrustAllClientFail() {
        do {
            let c8o = try C8o(endpoint: PREFIXS + HOST + ":444" + PROJECT_PATH, c8oSettings: C8oSettings().setTrustAllCertificates(false))
            _ = try c8o.callXml(".Ping", parameters: "var1", "value one").sync()
            XCTAssertTrue(false, "not possible")
        }
        catch let _ as C8oException {
            XCTAssertTrue(true, "should happen")
        }
        catch {
            XCTAssertTrue(false, "must no happen")
        }
    }

    func testSslTrustAllClientOk() {
        let c8o = try! C8o(endpoint: PREFIXS + HOST + ":444" + PROJECT_PATH, c8oSettings: C8oSettings().setTrustAllCertificates(true))
        let doc = try! c8o.callXml(".Ping", parameters: "var1", "value one").sync()
        let value = doc?.root["pong"]["var1"].stringValue
        XCTAssertEqual("value one", value)
    }
    
	func testC8oWithTimeout() {
		let c8o = try! C8o(endpoint: PREFIX + HOST + PORT + PROJECT_PATH, c8oSettings: C8oSettings().setTimeout(1000))
		let doc: AEXMLDocument = try! c8o.callXml(".Sleep2sec").sync()!
		let value: String = doc["document"]["element"].stringValue
		XCTAssertEqual("ok", value)
		
	}
	
	func testBadExec() {
		do {
			_ = try C8o(endpoint: PREFIX + HOST + PORT + "hdhhdhd", c8oSettings: C8oSettings().setTimeout(1000))
			XCTAssertFalse(false, "not possible")
		}
		catch _ as C8oException {
			// XCTAssertTrue(e is NSError)
			// print(e.description)
		}
		catch {
			XCTAssertTrue(false, "must not happen")
		}
		// let c8o : C8o = try! C8o(endpoint: PREFIX + HOST + PORT + "hdhhdhd", c8oSettings: C8oSettings().setTimeout(1000))
		
	}
	
	func XCTAssertEqualsJsonChild(expectedObject: JSON, actualObject: JSON) {
		if (expectedObject.dictionary?.count >= 0) {
			XCTAssertNotNil(actualObject, "must not be null")
			XCTAssertEquals(expectedObject, actual: actualObject)
		}
		else if (expectedObject.array?.count >= 0) {
			XCTAssertNotNil(actualObject, "must not be null")
			XCTAssertEquals(expectedObject, actual: actualObject)
		}
		else if (expectedObject.int != nil) {
			XCTAssertNotNil(actualObject, "must not be null")
			XCTAssertEqual(expectedObject.int, actualObject.int)
		}
		else if (expectedObject.string != nil) {
			XCTAssertNotNil(actualObject, "must not be null")
			XCTAssertEqual(expectedObject.string, actualObject.string)
		}
	}
	
	func XCTAssertEquals(expected: JSON, actual: JSON) {
		do {
			if (expected.dictionary?.count >= 0) { // || expected.array?.count >= 0 ){
				let expectedD = expected.dictionary
				let actualD = actual.dictionary
				let expectedNames = expectedD?.keys
				let actualNames = actualD?.keys
				XCTAssertEqual(expectedNames!.count, actualNames!.count, "missing keys: " + expectedNames.debugDescription + " and " + actualNames.debugDescription)
				for (key, _) in expectedD! {
					XCTAssertTrue(actualD![key] != nil, "missing key: " + key)
					XCTAssertEqualsJsonChild(expectedD![key]!, actualObject: actualD![key]!)
				}
			}
			else if (expected.array?.count >= 0) {
				XCTAssertEqual(expected.array!, actual.array!, "array")
			}
			else if (expected.int != nil) {
				XCTAssertEqual(expected, actual, "int equals")
			}
			else if (expected.string != nil) {
				XCTAssertEqual(expected, actual, "string equals")
			}
		} catch let t as NSError {
			XCTAssertTrue(false, "exception: " + t.description)
		}
	}
	
}


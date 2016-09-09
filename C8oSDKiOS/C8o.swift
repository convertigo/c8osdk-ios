//
//  C8o.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 03/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import AEXML

/**
 Allows to send requests to a Convertigo Server (or Studio), these requests are called c8o calls.

 C8o calls are done thanks to a HTTP request or a CouchbaseLite usage.

 An instance of C8o is connected to only one Convertigo and can't change it.

 To use it, you have to first initialize the C8o instance with the Convertigo endpoint, then use call methods with Convertigo variables as parameter.
 */
public class C8o: C8oBase {
	
	/* Regular Expression */
	private static let RE_REQUESTABLE: NSRegularExpression = try! NSRegularExpression(pattern: "^([^.]*)\\.(?:([^.]+)|(?:([^.]+)\\.([^.]+)))$", options: [])
	
	private static let RE_ENDPOINT: NSRegularExpression = try! NSRegularExpression(pattern: "^(http(s)?://([^:]+)(:[0-9]+)?/?.*?)/projects/([^/]+)$", options: [])
	
	/* Engine reserved parameters */
	internal static var ENGINE_PARAMETER_PROJECT: String = "__project"
	internal static var ENGINE_PARAMETER_SEQUENCE: String = "__sequence"
	internal static var ENGINE_PARAMETER_CONNECTOR: String = "__connector"
	internal static var ENGINE_PARAMETER_TRANSACTION: String = "__transaction"
	internal static var ENGINE_PARAMETER_ENCODED: String = "__encoded"
	internal static var ENGINE_PARAMETER_DEVICE_UUID: String = "__uuid"
	internal static var ENGINE_PARAMETER_PROGRESS: String = "__progress"
	
	/* FULLSYNC parameters */
	
	/**
	 Constant to use as a parameter for a Call of "fs://.post" and must be followed by a FS_POLICY_* constant.

	 c8o.callJson("fs://.post", parameters:
	 C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
	 "docid", myid,
	 "mykey", myvalue
	 ).sync();
	 */
	public static var FS_POLICY: String = "_use_policy"
	/**
	 Use it with "fs://.post" and C8o.FS_POLICY.

	 This is the default post policy that don't alter the document before the CouchbaseLite's insertion.
	 */
	public static var FS_POLICY_NONE: String = "none"
	/**
	 Use it with "fs://.post" and C8o.FS_POLICY.

	 This post policy remove the "_id" and "_rev" of the document before the CouchbaseLite's insertion.
	 */
	public static var FS_POLICY_CREATE: String = "create"
	/**
	 Use it with "fs://.post" and C8o.FS_POLICY.

	 This post policy inserts the document in CouchbaseLite even if a document with the same "_id" already exists.
	 */
	public static var FS_POLICY_OVERRIDE: String = "override"
	/**
	 Use it with "fs://.post" and C8o.FS_POLICY.

	 This post policy merge the document with an existing document with the same "_id" before the CouchbaseLite's insertion.
	 */
	public static var FS_POLICY_MERGE: String = "merge"
	/**
	 Use it with "fs://.post". Default value is ".".

	 This key allow to override the sub key separator in case of document depth modification.
	 */
	public static var FS_SUBKEY_SEPARATOR: String = "_use_subkey_separator"
	
	public static var FS_STORAGE_SQL: String = "SQL"
	public static var FS_STORAGE_FORESTDB: String = "FORESTDB"
	
	/* Local cache keys */
	
	internal static var LOCAL_CACHE_DOCUMENT_KEY_RESPONSE: String = "response"
	internal static var LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE: String = "responseType"
	internal static var LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE: String = "expirationDate"
	
	internal static var LOCAL_CACHE_DATABASE_NAME: String = "c8olocalcache"
	
	/* Response type */
	
	internal static var RESPONSE_TYPE_XML: String = "pxml"
	internal static var RESPONSE_TYPE_JSON: String = "json"
	
	/* Static configuration */
	internal static var defaultUiDispatcher: AnyObject?// ACTION<ACTION>?
	internal static var deviceUUID: String = UIDevice.currentDevice().identifierForVendor!.UUIDString
	
	/**
	 Returns the current version of the SDK as "x.y.z".
	 - returns: Current version of the SDK as "x.y.z".
	 */
	public static func getSdkVersion() -> String {
		return "2.0.5"
	}
	
	/* Attributes */
	
	private var _endpoint: String?
	private var _endpointConvertigo: String?
	private var _endpointIsSecure: Bool?
	private var _endpointHost: String?
	private var _endpointPort: String?
	private var _endpointProject: String?
	
	/* Used to run HTTP requests.*/
	internal var httpInterface: C8oHttpInterface?
	
	/* Allows to log locally and remotely to the Convertigo server.*/
	internal var c8oLogger: C8oLogger?
	
	/* Allows to make fullSync calls. */
	internal var c8oFullSync: C8oFullSync?
	
	/* Constructors */
	/**
	 This is the base object representing a Convertigo Server end point. This object should be instanciated when the apps starts and be accessible from any class of the app. Although this is not common, you may have several C8o objects instantiated in your app.

	 - parameter endpoint : The Convertigo endpoint, syntax : {protocol}://{server}:{port}/{Convertigo web app path}/projects/{project name}
	 Example : http://computerName:18080/convertigo/projects/MyProject
	 - parameter c8oSettings : Initialization options. Example : new C8oSettings().setLogRemote(false).setDefaultDatabaseName("sample")
	 */
	public init(endpoint: String, c8oSettings: C8oSettings? = nil) throws {
		super.init()
		// Checks the URL validity
		if (!C8oUtils.isValidUrl(endpoint)) {
			// throw NSC8oError(domain: NSURLC8oErrorDomain, code: NSURLC8oErrorCannotOpenFile, userInfo: nil)
			throw C8oException(message: C8oExceptionMessage.InvalidArgumentInvalidURL(endpoint))
		}
		
		// Checks the endpoint validty
		let regexV = C8o.RE_ENDPOINT.matchesInString(endpoint, options: [], range: NSMakeRange(0, endpoint.characters.count))
		
		if (regexV.first == nil) {
			throw C8oException(message: C8oExceptionMessage.InvalidArgumentInvalidEndpoint(endpoint))
		}
		
		_endpoint = endpoint
		_endpointConvertigo = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(1))
		
		if (regexV[0].rangeAtIndex(2).location != NSNotFound) {
			_endpointIsSecure = !(endpoint as NSString?)!.substringWithRange(regexV[0].rangeAtIndex(2)).isEmpty
		} else {
			_endpointIsSecure = false
		}
		_endpointHost = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(3))
		if (regexV[0].rangeAtIndex(4).location != NSNotFound) {
			_endpointPort = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(4))
		}
		_endpointProject = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(5))
		
		if (c8oSettings != nil) {
			copyProperties(c8oSettings!)
		}
		
		self.httpInterface = C8oHttpInterface(c8o: self)
		self.c8oLogger = C8oLogger(c8o: self)
		self.c8oLogger!.logMethodCall("C8o constructor")
		self.c8oFullSync = C8oFullSyncCbl(c8o: self)
	}
	
	/**
	 This calls a Convertigo requestable.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 myC8o.Call(requestable, parameters, c8oResponseXmlListener, c8oExceptionListener)
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 */
	public func call(requestable: String?, parameters: Dictionary<String, AnyObject>? = nil, c8oResponseListener: C8oResponseListener, c8oExceptionListener: C8oExceptionListener) -> Void {
		var parameters = parameters
		do {
			if (requestable == nil) {
				throw C8oException(message: C8oExceptionMessage.InvalidArgumentNullParameter("requestable"))
			}
			
			// Checks parameters validity
			if (parameters == nil) {
				parameters = Dictionary<String, AnyObject>()
			} else {
				// Clone parameters in order to modify them
				parameters = Dictionary<String, AnyObject>?(parameters!)
			}
			
			// Use the requestable string to add parameters corresponding to the c8o project, sequence, connector and transaction (<project>.<sequence> or <project>.<connector>.<transaction>)
			let regex: NSRegularExpression = C8o.RE_REQUESTABLE
			let regexV = regex.matchesInString(requestable!, options: [], range: NSMakeRange(0, requestable!.characters.count))
			
			if (regexV.first == nil) {
				throw C8oException(message: C8oExceptionMessage.InvalidArgumentInvalidEndpoint(_endpoint!)) // Exception(C8oExceptionMessage.InvalidArgumentInvalidEndpoint(endpoint))
			}
			
			// If the project name is specified
			if ((requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(1)) != "") {
				parameters![C8o.ENGINE_PARAMETER_PROJECT] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(1))
			}
			
			// If the C8o call use a sequence
			let rangeLenght = regexV[0].rangeAtIndex(2).length - 1
			let requestableLenght = (requestable! as NSString?)?.length
			if (rangeLenght < requestableLenght && rangeLenght > 0) {
				
				if (((requestable! as NSString?)!.substringWithRange(regexV[0].rangeAtIndex(2)) as String?) != "") {
					parameters![C8o.ENGINE_PARAMETER_SEQUENCE] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(2))
				} else {
					parameters![C8o.ENGINE_PARAMETER_CONNECTOR] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(3))
					
					parameters![C8o.ENGINE_PARAMETER_TRANSACTION] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(4))
					
				}
				
			} else {
				parameters![C8o.ENGINE_PARAMETER_CONNECTOR] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(3))
				
				parameters![C8o.ENGINE_PARAMETER_TRANSACTION] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(4))
			}
			
			try! call(parameters, c8oResponseListener: c8oResponseListener, c8oExceptionListener: c8oExceptionListener)
		}
		catch let e as C8oException {
			handleCallException(c8oExceptionListener, requestParameters: parameters!, exception: e)
		}
		catch {
			let _: String
		}
	}
	
	public func call(parameters: Dictionary<String, AnyObject>? = nil, c8oResponseListener: C8oResponseListener? = nil, c8oExceptionListener: C8oExceptionListener? = nil) throws {
		var parameters = parameters
		// IMPORTANT : all c8o calls have to end here !
		
		c8oLogger!.logMethodCall("Call", parameters: parameters!)
		
		// Checks parameters validity
		if (parameters == nil) {
			parameters = Dictionary<String, AnyObject>()
		} else {
			// Clones parameters in order to modify them
			// parameters = parameters
			parameters = Dictionary<String, AnyObject>?(parameters!)
		}
		
		// Creates a async task running on another thread
		// Exceptions have to be handled by the C8oExceptionListener
		let task = C8oCallTask(c8o: self, parameters: parameters!, c8oResponseListener: c8oResponseListener!, c8oExceptionListener: c8oExceptionListener!)
		task.execute()
		
	}
	
	/**
	 Call a Convertigo Server backend service and return data in a JSON Object.
	 CallJSON will asynchrously call a "requestable" (Sequence, transaction or FullSync database) and return a C8oPromise object.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 myC8o.CallJSON(requestable, parameters)
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @param requestable : String
	 A "requestable" object of this form :
	 <list type ="bullet">
	 <item>project.sequence to call a Sequence in the convertigo server. If project is not specified explicitly here,
	 (.sequence) the default project specified in the enpoint will be used.</item>
	 <item>
	 project.connector.transaction to call a transaction in the convertigo server. if project is not specified explicitly here,
	 (.connector.transaction) the default project specified in the enpoint will be used. If
	 connector is not specified (..transaction) the default connector will be used.</item>
	 <item>fs://database.fullsync_verb   to call the local NoSQL database for quering, updating and syncing according to the full_sync
	 verb used. See FullSync documentation for a list of verbs and parameters.</item>
	 </list>
	 @return A C8oPromise object on which you can chain other requests to get the data with the Then(), ThenUI() methods or
	 use the Async() to wait for the server response without blocking the request thread. You can also use the .Fail() and
	 FailUI() methods to handle C8oErrors.

	 */
	public func callJson (requestable: String, parameters: Dictionary<String, AnyObject>?) -> C8oPromise<JSON> {
		let promise = C8oPromise<JSON>(c8o: self)
		
		call(requestable,
			parameters: parameters,
			c8oResponseListener: C8oResponseJsonListener(onJsonResponse: {
				(response, requestParameters) -> () in
				
				if (response == nil) {
					if (requestParameters!.keys.contains(C8o.ENGINE_PARAMETER_PROGRESS) == true) {
						
						promise.onProgress((((requestParameters! as Dictionary<String, AnyObject>?)![C8o.ENGINE_PARAMETER_PROGRESS]) as? C8oProgress)!)
					}
				} else {
					promise.onResponse(response, parameters: requestParameters)
				}
				
			}),
			c8oExceptionListener: C8oExceptionListener(onException: {
				(params: Pair<C8oException, Dictionary<String, AnyObject>?>?) -> () in
				
				promise.onFailure(params?.key as C8oException?, parameters: params?.value)
			}))
		return promise
	}
	
	public func callJson(requestable: String, parameters: AnyObject...) -> C8oPromise<JSON> {
		
		return try! callJson(requestable, parameters: C8o.toParameters(parameters))
		
	}
	
	public func callJson(requestable: String, parameters: JSON) -> C8oPromise<JSON> {
		
		return callJson(requestable, parameters: (parameters.object as! Dictionary<String, AnyObject>))
	}
	
	public func callXml(requestable: String, parameters: Dictionary<String, AnyObject>) -> C8oPromise<AEXMLDocument> {
		
		let promise = C8oPromise<AEXMLDocument>(c8o: self)
		
		call(requestable,
			parameters: parameters,
			c8oResponseListener: C8oResponseXmlListener(onXmlResponse: {
				(response, requestParameters) -> () in
				
				if (response == nil) {
					if (requestParameters!.keys.contains(C8o.ENGINE_PARAMETER_PROGRESS) == true) {
						
						promise.onProgress((((requestParameters! as Dictionary<String, AnyObject>?)![C8o.ENGINE_PARAMETER_PROGRESS]) as? C8oProgress)!)
					}
				} else {
					promise.onResponse(response as? AEXMLDocument, parameters: requestParameters)
				}
				
			})
			, c8oExceptionListener: C8oExceptionListener(onException: {
				(params: Pair<C8oException, Dictionary<String, AnyObject>?>?) -> () in
				
				promise.onFailure((params?.key) as C8oException?, parameters: params?.value)
				
			}))
		return promise
		
	}
	
	public func callXml(requestable: String, parameters: AnyObject...) -> C8oPromise<AEXMLDocument> {
		return try! callXml(requestable, parameters: C8o.toParameters(parameters))
	}
	
	/**
	 Add a cookie to the cookie store.<br/>
	 Automatically set the domain and secure flag using the c8o endpoint.
	 Example usage:
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @param name : String
	 @param value : String

	 */
	public func addCookie(name: String, value: String) -> Void {
		httpInterface!.addCookie(name, value: value)
	}
	
	public override var logC8o: Bool {
		get { return _logC8o! }
		set(value) { _logC8o = value }
	}
	
	public override var logRemote: Bool {
		get { return _logRemote! }
		set(value) { _logRemote = value }
	}
	
	public override var logLevelLocal: C8oLogLevel {
		get { return _logLevelLocal }
		set(value) { _logLevelLocal = value }
	}
	
	public override var fullSyncStorageEngine: String {
		get { return _fullSyncStorageEngine }
		set(value) {
			if (C8o.FS_STORAGE_SQL == value || C8o.FS_STORAGE_FORESTDB == value) {
				_fullSyncStorageEngine = value
			}
		}
	}
	
	public override var fullSyncEncryptionKey: String? {
		get { return _fullSyncEncryptionKey }
		set(value) { _fullSyncEncryptionKey = value }
	}
	
	public var log: C8oLogger {
		get { return c8oLogger! }
	}
	
	public func isUI () -> Bool {
		return NSThread.isMainThread()
	}
	
	public func runUI (block: dispatch_block_t) {
		if (isUI()) {
			block()
		} else {
			dispatch_async(dispatch_get_main_queue(), {
				block()
			})
		}
	}
	
	public func runBG (block: dispatch_block_t) {
		let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
		dispatch_async(dispatch_get_global_queue(priority, 0)) {
			block()
		}
	}
	
	public override var description: String {
		get {
			return "C8o[" + _endpoint! + "] " + super.description
		}
	}
	
	public var endpoint: String {
		get { return _endpoint! }
	}
	
	public var endpointConvertigo: String {
		get { return _endpointConvertigo! }
	}
	
	public var endpointIsSecure: Bool {
		get { return _endpointIsSecure! }
	}
	
	public var endpointHost: String {
		get { return _endpointHost! }
	}
	
	public var endpointPort: String {
		get { return _endpointPort! }
	}
	
	public var endpointProject: String {
		get { return _endpointProject! }
	}
	
	public var deviceUUID: String {
		get { return C8o.deviceUUID }
	}
	
	public var cookieStore: C8oCookieStorage {
		get { return httpInterface!.cookieStore! }
	}
	
	private static func toParameters(parameters: [AnyObject]?) throws -> Dictionary<String, AnyObject> {
		if (parameters!.count % 2 != 0) {
			throw C8oException(message: C8oExceptionMessage.invalidParameterValue("parameters", details: "needs pairs of values"))
		}
		
		var newParameters = Dictionary<String, AnyObject>()
		
		for i in 0.stride(to: parameters!.count, by: 2) {
			newParameters[String(parameters![i])] = parameters![i + 1]
		}
		
		return newParameters
	}
	
	internal func handleCallException(c8oExceptionListener: C8oExceptionListener?, requestParameters: Dictionary<String, AnyObject>, exception: C8oException) {
		c8oLogger!._warn("Handle a call exception", exceptions: exception)
		
		if (c8oExceptionListener != nil) {
			c8oExceptionListener!.onException(Pair<C8oException, Dictionary<String, AnyObject>?>(key: exception, value: requestParameters))
		}
	}
}


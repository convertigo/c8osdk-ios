//
//  FullSyncEnum.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 06/04/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON
import AEXML

internal class FullSyncRequestable {
	internal static var GET: FullSyncRequestable = FullSyncRequestable(value: "get", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) throws -> (AnyObject) in
		
		let docid: String = try! C8oUtils.peekParameterStringValue(parameters, name: FullSyncGetDocumentParameter.DOCID.name, exceptionIfMissing: true)!
		return try c8oFullSync.handleGetDocumentRequest(databaseName, docid: docid, parameters: parameters)
	})
	
	internal static var DELETE: FullSyncRequestable = FullSyncRequestable(value: "delete", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) throws -> (AnyObject) in
		
		let docid: String = try! C8oUtils.peekParameterStringValue(parameters, name: FullSyncGetDocumentParameter.DOCID.name, exceptionIfMissing: true)!
		do {
			return try c8oFullSync.handleDeleteDocumentRequest(databaseName, docid: docid, parameters: parameters)!
		}
		catch let e as NSError {
			throw e
		}
		
	})
	
	internal static var POST: FullSyncRequestable = FullSyncRequestable(value: "post", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (AnyObject) in
		
		// Gets the policy parameter
		let fullSyncPolicyParameter: String? = try! C8oUtils.peekParameterStringValue(parameters, name: FullSyncPostDocumentParameter.POLICY.name, exceptionIfMissing: false)
		
		// Finds the policy corresponding to the parameter value if it exists
		let fullSyncPolicy: FullSyncPolicy = FullSyncPolicy.getFullSyncPolicy(fullSyncPolicyParameter)
		
		return try c8oFullSync.handlePostDocumentRequest(databaseName, fullSyncPolicy: fullSyncPolicy, parameters: parameters)!
	})
	
	internal static var PUT_ATTACHMENT: FullSyncRequestable = FullSyncRequestable(value: "put_attachment") { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (AnyObject) in
		
		// Gets the docid parameter
		let docid: String? = C8oUtils.getParameterStringValue(parameters, name: FullSyncAttachmentParameter.DOCID.name, useName: false)
		
		// Gets the attachment name parameter
		let name: String? = C8oUtils.getParameterStringValue(parameters, name: FullSyncAttachmentParameter.NAME.name, useName: false)
		
		// Gets the attachment content_type parameter
		let contentType: String? = C8oUtils.getParameterStringValue(parameters, name: FullSyncAttachmentParameter.CONTENT_TYPE.name, useName: false)
		
		// Gets the attachment content parameter
		let a = C8oUtils.getParameterObjectValue(parameters, name: FullSyncAttachmentParameter.CONTENT.name, useName: false)
		let content: NSData? = C8oUtils.getParameterObjectValue(parameters, name: FullSyncAttachmentParameter.CONTENT.name, useName: false) as! NSData?
		
		return try c8oFullSync.handlePutAttachmentRequest(databaseName, docid: docid!, attachmentName: name!, attachmentType: contentType!, attachmentContent: content!)
	}
	internal static var DELETE_ATTACHMENT: FullSyncRequestable = FullSyncRequestable(value: "delete_attachment") { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (AnyObject) in
		
		// Gets the docid parameter
		let docid: String = C8oUtils.getParameterStringValue(parameters, name: FullSyncAttachmentParameter.DOCID.name, useName: false)!
		
		// Gets the attachment name parameter
		let name: String = C8oUtils.getParameterStringValue(parameters, name: FullSyncAttachmentParameter.NAME.name, useName: false)!
		
		return try c8oFullSync.handleDeleteAttachmentRequest(databaseName, docid: docid, attachmentName: name)
		
	}
	
	internal static var ALL: FullSyncRequestable = FullSyncRequestable(value: "all", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (AnyObject) in
		
		return try! c8oFullSync.handleAllDocumentsRequest(databaseName, parameters: parameters)!
	})
	
	internal static var VIEW: FullSyncRequestable = FullSyncRequestable(value: "view", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) throws -> (AnyObject) in
		
		// Gets the design doc parameter value
		let ddoc: String = try! C8oUtils.peekParameterStringValue(parameters, name: FullSyncGetViewParameter.DDOC.name, exceptionIfMissing: false)!
		// Gets the view name parameter value
		let view: String = try! C8oUtils.peekParameterStringValue(parameters, name: FullSyncGetViewParameter.VIEW.name, exceptionIfMissing: false)!
		
		return try c8oFullSync.handleGetViewRequest(databaseName, ddocName: ddoc, viewName: view, parameters: parameters)!
	})
	
	internal static var SYNC: FullSyncRequestable = FullSyncRequestable(value: "sync", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (AnyObject) in
		let thread: NSThread = NSThread.currentThread()
		var mutex: Bool = false
		var pullFinish: Bool = false
		var pushFinish: Bool = false
		let condition: NSCondition = NSCondition()
		condition.lock()
		
		try! c8oFullSync.handleSyncRequest(databaseName, parameters: parameters, c8oResponseListener: C8oResponseProgressListener(onProgressResponse: { (progress, param) -> () in
			
			if (!mutex) {
				if (!pullFinish && progress.pull && progress.finished) {
					pullFinish = true
					c8oFullSync.c8o!.log._debug("handleFullSyncRequest pullFinish = true: " + progress.description)
				}
				
				if (!pushFinish && progress.push && progress.finished) {
					pushFinish = true
					c8oFullSync.c8o!.log._debug("handleFullSyncRequest pushFinish = true: " + progress.description)
				}
			}
			
			if (progress.total != -1) {
				if (c8oResponseListener is C8oResponseJsonListener) {
					c8oFullSync.c8o!.log._debug("handleFullSyncRequest onJsonResponse: " + progress.description)
					let varNil: C8oJSON? = nil
					(c8oResponseListener as! C8oResponseJsonListener).onJsonResponse(varNil?.myJSON, param)
				} else if (c8oResponseListener is C8oResponseXmlListener) {
					let varNil: AEXMLDocument? = nil
					(c8oResponseListener as! C8oResponseXmlListener).onXmlResponse(varNil, param)
				}
			}
			
			if (!mutex && pullFinish && pushFinish) {
				if (NSThread.currentThread() == thread) {
					mutex = true
				} else {
					condition.lock()
					mutex = true
					c8oFullSync.c8o!.log._debug("handleFullSyncRequest notify: " + progress.description)
					condition.signal()
					condition.unlock()
				}
			}
			}))
		if (!mutex) {
			condition.wait()
		}
		c8oFullSync.c8o!.log._debug("handleFullSyncRequest after wait")
		let myjson: C8oJSON = C8oJSON()
		let json: JSON = ["ok": true]
		myjson.myJSON = json
		condition.unlock()
		return myjson
	})
	
	internal static var REPLICATE_PULL: FullSyncRequestable = FullSyncRequestable(value: "replicate_pull", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (AnyObject) in
		
		let condition: NSCondition = NSCondition()
		let thread: NSThread = NSThread.currentThread()
		var syncMutex: [Bool] = [Bool]()
		syncMutex.append(false)
		condition.lock()
		try! c8oFullSync.handleReplicatePullRequest(databaseName, parameters: parameters, c8oResponseListener: C8oResponseProgressListener(onProgressResponse: { (progress, param) -> () in
			
			if (progress.finished) {
				if (NSThread.currentThread() == thread) {
					syncMutex[0] = true
				} else {
					syncMutex[0] = true
					// condition.lock()
					condition.signal()
					// condition.unlock()
				}
			}
			
			if (progress.total != -1) {
				if (c8oResponseListener is C8oResponseJsonListener) {
					let varNil: C8oJSON? = nil
					(c8oResponseListener as! C8oResponseJsonListener).onJsonResponse(varNil?.myJSON, param)
				} else if (c8oResponseListener is C8oResponseXmlListener) {
					let varNil: AEXMLDocument? = nil
					(c8oResponseListener as! C8oResponseXmlListener).onXmlResponse(varNil, param)
				}
			}
			
			}))
		if (!syncMutex[0]) {
			condition.wait()
		}
		let myjson: C8oJSON = C8oJSON()
		let json: JSON = ["ok": true]
		myjson.myJSON = json
		
		condition.unlock()
		return myjson
	})
	
	internal static var REPLICATE_PUSH: FullSyncRequestable = FullSyncRequestable(value: "replicate_push", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (AnyObject) in
		
		let condition: NSCondition = NSCondition()
		let thread: NSThread = NSThread.currentThread()
		var syncMutex: [Bool] = [Bool]()
		syncMutex.append(false)
		condition.lock()
		
		try! c8oFullSync.handleReplicatePushRequest(databaseName, parameters: parameters, c8oResponseListener: C8oResponseProgressListener(onProgressResponse: { (progress, param) -> () in
			
			if (progress.finished) {
				if (NSThread.currentThread() == thread) {
					syncMutex[0] = true
				} else {
					syncMutex[0] = true
					// condition.lock()
					condition.signal()
					// condition.unlock()
				}
			}
			
			if (progress.total != -1) {
				if (c8oResponseListener is C8oResponseJsonListener) {
					let varNil: C8oJSON? = nil
					(c8oResponseListener as! C8oResponseJsonListener).onJsonResponse(varNil?.myJSON, param)
				} else if (c8oResponseListener is C8oResponseXmlListener) {
					let varNil: AEXMLDocument? = nil
					(c8oResponseListener as! C8oResponseXmlListener).onXmlResponse(varNil, param)
				}
			}
			}))
		if (!syncMutex[0]) {
			condition.wait()
		}
		let myjson: C8oJSON = C8oJSON()
		let json: JSON = ["ok": true]
		myjson.myJSON = json
		
		condition.unlock()
		return myjson
	})
	
	internal static var RESET: FullSyncRequestable = FullSyncRequestable(value: "reset", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (NSObject) in
		
		return try! c8oFullSync.handleResetDatabaseRequest(databaseName)!
	})
	
	internal static var CREATE: FullSyncRequestable = FullSyncRequestable(value: "create", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (NSObject) in
		
		return try c8oFullSync.handleCreateDatabaseRequest(databaseName)!
	})
	
	internal static var DESTROY: FullSyncRequestable = FullSyncRequestable(value: "destroy", handleFullSyncrequestOp: { (c8oFullSync, databaseName, parameters, c8oResponseListener) -> (NSObject) in
		return try! c8oFullSync.handleDestroyDatabaseRequest(databaseName)! // HandleDestroyDatabaseRequest(databaseName)!
	})
	
	internal var value: String
	private var handleFullSyncrequestOp: (C8oFullSyncCbl, String, Dictionary<String, AnyObject>, C8oResponseListener) throws -> (AnyObject)
	
	private init(value: String, handleFullSyncrequestOp: (C8oFullSyncCbl, String, Dictionary<String, AnyObject>, C8oResponseListener) throws -> (AnyObject)) {
		self.value = value
		self.handleFullSyncrequestOp = handleFullSyncrequestOp
	}
	
	internal func handleFullSyncRequest(c8oFullSync: C8oFullSyncCbl, databaseNameName: String, parameters: Dictionary<String, AnyObject>, c8oResponseListner: C8oResponseListener) throws -> AnyObject {
		do {
			return try handleFullSyncrequestOp(c8oFullSync, databaseNameName, parameters, c8oResponseListner)
		}
		catch let e as NSError {
			throw e
		}
		
	}
	
	internal static func getFullSyncRequestable(value: String) -> FullSyncRequestable? {
		let fullSyncRequestableValues: [FullSyncRequestable] = FullSyncRequestable.values()
		for fullSyncRequestable in fullSyncRequestableValues {
			if (fullSyncRequestable.value == value) {
				return fullSyncRequestable
			}
		}
		return nil
	}
	
	internal static func values() -> [FullSyncRequestable] {
		let array: [FullSyncRequestable] = [GET, DELETE, POST, ALL, VIEW, SYNC, REPLICATE_PULL, REPLICATE_PUSH, RESET, CREATE, DESTROY, PUT_ATTACHMENT, DELETE_ATTACHMENT]
		return array
	}
}

//*** Common parameters ***//

public class FullSyncRequestParameter {
	public static let DESCENDING: FullSyncRequestParameter = FullSyncRequestParameter(name: "descending", isJson: true, action: { query, value in
		
		query.descending = value as! Bool
		
	})
	public static let ENDKEY: FullSyncRequestParameter = FullSyncRequestParameter(name: "endkey", isJson: true, action: { query, value in
		
		query.endKey = value
		
	})
	public static let ENDKEY_DOCID: FullSyncRequestParameter = FullSyncRequestParameter(name: "endkey_docid", action: { query, value in
		query.endKeyDocID = value as? String
	})
	public static let GROUP_LEVEL: FullSyncRequestParameter = FullSyncRequestParameter(name: "group_level", isJson: true, action: { query, value in
		query.groupLevel = value as! UInt
	})
	public static let INCLUDE_DELETED: FullSyncRequestParameter = FullSyncRequestParameter(name: "include_deleted", isJson: true, action: { query, value in
		fatalError("must be done")
		// query.allDocsMode. //= value as! Bool
	})
	public static let INDEX_UPDATE_MODE: FullSyncRequestParameter = FullSyncRequestParameter(name: "index_update_mode", action: { query, value in
		fatalError("must be done")
		/*let valueStr : String = value as! String
		 var indexUpdateModeValues =   CBLIndexUpdateMode()
		 var indexUpdateModeEnumerator =*/
	})
	public static let KEY: FullSyncRequestParameter = FullSyncRequestParameter(name: "keys", isJson: true, action: { query, value in
		query.keys = [value]
	})
	public static let KEYS: FullSyncRequestParameter = FullSyncRequestParameter(name: "keys", isJson: true, action: { query, value in
		query.keys = value as? [AnyObject]
	})
	public static let LIMIT: FullSyncRequestParameter = FullSyncRequestParameter(name: "limit", isJson: true, action: { query, value in
		query.limit = value as! UInt
	})
	public static let INCLUDE_DOCS: FullSyncRequestParameter = FullSyncRequestParameter(name: "include_docs", isJson: true, action: { query, value in
		query.prefetch = value as! Bool
	})
	public static let REDUCE: FullSyncRequestParameter = FullSyncRequestParameter(name: "reduce", isJson: true, action: { query, value in
		query.mapOnly = !(value as! Bool)
	})
	public static let GROUP: FullSyncRequestParameter = FullSyncRequestParameter(name: "group", isJson: true, action: { query, value in
		query.groupLevel = (value as! Bool) ? 99 : 0
	})
	public static let SKIP: FullSyncRequestParameter = FullSyncRequestParameter(name: "skip", isJson: true, action: { query, value in
		query.skip = value as! UInt
	})
	public static let STARTKEY: FullSyncRequestParameter = FullSyncRequestParameter(name: "startkey", isJson: true, action: { query, value in
		query.startKey = value
	})
	public static let STARTKEY_DOCID: FullSyncRequestParameter = FullSyncRequestParameter(name: "startkey_docid", action: { query, value in
		query.startKeyDocID = value as? String
	})
	
	public var name: String
	public var isJson: Bool
	public var action: (CBLQuery, AnyObject) -> ()
	
	private init(name: String, action: (CBLQuery, AnyObject) -> ()) {
		self.name = name
		self.isJson = false
		self.action = action
	}
	
	private init(name: String, isJson: Bool, action: (CBLQuery, AnyObject) -> ()) {
		self.name = name
		self.isJson = isJson
		self.action = action
	}
	
	public static func values() -> [FullSyncRequestParameter] {
		let array: [FullSyncRequestParameter] = [DESCENDING, ENDKEY, ENDKEY_DOCID, GROUP_LEVEL, INCLUDE_DELETED, INDEX_UPDATE_MODE, KEYS, LIMIT, REDUCE, GROUP, SKIP, STARTKEY, STARTKEY_DOCID, INCLUDE_DOCS]
		return array
	}
	
	public static func getFullSyncRequestParameter(name: String?) -> FullSyncRequestParameter? {
		if (name != nil) {
			for fullSyncRequestParameter in FullSyncRequestParameter.values() {
				if (name == fullSyncRequestParameter.name) {
					return fullSyncRequestParameter
				}
			}
		}
		return nil
	}
	
}

//*** Specific parameters ***//

public class FullSyncGetViewParameter {
	public static let VIEW: FullSyncGetViewParameter = FullSyncGetViewParameter(name: "view")
	public static let DDOC: FullSyncGetViewParameter = FullSyncGetViewParameter(name: "ddoc")
	
	public var name: String
	
	private init(name: String) {
		self.name = name
	}
}

public class FullSyncGetDocumentParameter {
	public static let DOCID: FullSyncGetDocumentParameter = FullSyncGetDocumentParameter(name: "docid")
	
	public var name: String
	
	private init(name: String) {
		self.name = name
	}
	
}

public class FullSyncDeleteDocumentParameter {
	public static let DOCID: FullSyncDeleteDocumentParameter = FullSyncDeleteDocumentParameter(name: "docid")
	public static let REV: FullSyncDeleteDocumentParameter = FullSyncDeleteDocumentParameter(name: "rev")
	
	public var name: String
	
	private init(name: String) {
		self.name = name
	}
}

public class FullSyncAttachmentParameter {
	public static let DOCID: FullSyncAttachmentParameter = FullSyncAttachmentParameter(name: "docid")
	public static let NAME: FullSyncAttachmentParameter = FullSyncAttachmentParameter(name: "name")
	public static let CONTENT_TYPE: FullSyncAttachmentParameter = FullSyncAttachmentParameter(name: "content_type")
	public static let CONTENT: FullSyncAttachmentParameter = FullSyncAttachmentParameter(name: "content")
	
	public var name: String
	
	private init(name: String) {
		self.name = name
	}
}
public class FullSyncPostDocumentParameter {
	public static let POLICY: FullSyncPostDocumentParameter = FullSyncPostDocumentParameter(name: C8o.FS_POLICY)
	public static let SUBKEY_SEPARATOR: FullSyncPostDocumentParameter = FullSyncPostDocumentParameter(name: C8o.FS_SUBKEY_SEPARATOR)
	
	public var name: String
	
	private init(name: String) {
		self.name = name
	}
	
	public static func values() -> [FullSyncPostDocumentParameter] {
		let array: [FullSyncPostDocumentParameter] = [POLICY, SUBKEY_SEPARATOR]
		return array
	}
	
}

/** <summary>
 Specific parameters for the fullSync's replicateDatabase request (push or pull).
 </summary> */

//TODO... add types
public class FullSyncReplicationParameter {
	public static let CANCEL: FullSyncReplicationParameter = FullSyncReplicationParameter(name: "cancel", action: { replication, value in
		
	}) // , type: NSObject.self)
	public static let LIVE: FullSyncReplicationParameter = FullSyncReplicationParameter(name: "live", action: { replication, value in
		replication.continuous = value as! Bool
	}) // , Boolean.Type)
	public static let DOCIDS: FullSyncReplicationParameter = FullSyncReplicationParameter(name: "docids", action: { replication, value in
		replication.documentIDs = value as? [String]
	}) // , Array[String]))
	
	public var name: String
	// public var type : type
	public var action: (CBLReplication, AnyObject) -> ()
	
	private init(name: String, action: (CBLReplication, AnyObject) -> ()) {
		self.name = name
		self.action = action
		
		// self.type = type
		
	}
	
	public static func values() -> [FullSyncReplicationParameter] {
		let array: [FullSyncReplicationParameter] = [CANCEL, LIVE, DOCIDS]
		return array
	}
}

//*** Policy ***//

/** <summary>
 The policies of the fullSync's postDocument request.
 </summary>*/
public class FullSyncPolicy {
	/*private var c8o : Queue<C8o>? = Queue<C8o>()
	 public func setC8o(c8o : C8o){
	 self.c8o?.enqueue(c8o)
	 }
	 public func getC8o()->C8o{
	 return self.c8o!.dequeue()!
	 }*/
	
	public static let NONE: FullSyncPolicy = FullSyncPolicy(value: C8o.FS_POLICY_NONE, action: { database, newProperties in
		var createdDocument: CBLDocument
		var newPropertiesMutable = newProperties
		do {
			var documentId = C8oUtils.getParameterStringValue(newPropertiesMutable, name: C8oFullSync.FULL_SYNC__ID, useName: false)
			
			newPropertiesMutable.removeValueForKey(C8oFullSync.FULL_SYNC__ID)
			if (documentId == "") {
				documentId = nil
			}
			createdDocument = (documentId == nil) ? database.createDocument() : database.documentWithID(documentId!)!
			
			try createdDocument.putProperties(newPropertiesMutable)
			
		}
		catch let e as NSError {
			throw c8oCouchbaseLiteException(message: C8oExceptionMessage.fullSyncPutProperties(newProperties), exception: e)
		}
		return createdDocument
	})
	public static let CREATE: FullSyncPolicy = FullSyncPolicy(value: C8o.FS_POLICY_CREATE, action: { database, newProperties in
		var createdDocument: CBLDocument
		var newPropertiesMutable = newProperties
		do {
			newPropertiesMutable.removeValueForKey(C8oFullSync.FULL_SYNC__ID)
			newPropertiesMutable.removeValueForKey(C8oFullSync.FULL_SYNC__REV)
			createdDocument = database.createDocument()
			try createdDocument.putProperties(newPropertiesMutable)
		}
		catch let e as NSError {
			throw c8oCouchbaseLiteException(message: C8oExceptionMessage.fullSyncPutProperties(newProperties), exception: e)
		}
		
		return createdDocument
	})
	public static let OVERRIDE: FullSyncPolicy = FullSyncPolicy(value: C8o.FS_POLICY_OVERRIDE, action: { database, newProperties in
		var createdDocument: CBLDocument
		var newPropertiesMutable = newProperties
		do {
			let documentId: String? = C8oUtils.getParameterStringValue(newPropertiesMutable, name: C8oFullSync.FULL_SYNC__ID, useName: false)!
			newPropertiesMutable.removeValueForKey(C8oFullSync.FULL_SYNC__ID)
			newPropertiesMutable.removeValueForKey(C8oFullSync.FULL_SYNC__REV)
			
			if (documentId == nil) {
				createdDocument = database.createDocument()
			} else {
				createdDocument = database.documentWithID(documentId!)!
				var currentRevision = createdDocument.currentRevision
				if (currentRevision != nil) {
					newPropertiesMutable[C8oFullSync.FULL_SYNC__REV] = currentRevision?.revisionID
				}
			}
			try createdDocument.putProperties(newPropertiesMutable)
		}
		catch let e as NSError {
			throw c8oCouchbaseLiteException(message: C8oExceptionMessage.fullSyncPutProperties(newProperties), exception: e)
		}
		
		return createdDocument
	})
	public static let MERGE: FullSyncPolicy = FullSyncPolicy(value: C8o.FS_POLICY_MERGE, action: { database, newProperties in
		var createdDocument: CBLDocument
		var newPropertiesMutable = newProperties
		do {
			let documentId: String? = C8oUtils.getParameterStringValue(newPropertiesMutable, name: C8oFullSync.FULL_SYNC__ID, useName: false)!
			newPropertiesMutable.removeValueForKey(C8oFullSync.FULL_SYNC__ID)
			newPropertiesMutable.removeValueForKey(C8oFullSync.FULL_SYNC__REV)
			
			if (documentId == nil) {
				createdDocument = database.createDocument()
			} else {
				createdDocument = database.documentWithID(documentId!)!
			}
			var oldProperties = createdDocument.properties
			if (oldProperties != nil) {
				C8oFullSyncCbl.mergeProperties(&newPropertiesMutable, oldProperties: oldProperties!)
			}
			try createdDocument.putProperties(newPropertiesMutable)
		}
		catch let e as NSError {
			throw c8oCouchbaseLiteException(message: C8oExceptionMessage.fullSyncPutProperties(newProperties), exception: e)
		}
		return createdDocument
	})
	
	public var value: String?
	public var action: (CBLDatabase, Dictionary<String, AnyObject>) throws -> (CBLDocument)
	
	private init(value: String?, action: (CBLDatabase, Dictionary<String, AnyObject>) throws -> (CBLDocument)) {
		self.value = value
		self.action = action
		
		// abstract void setReplication(Replication replication, Object parameterValue)
	}
	
	public static func values() -> [FullSyncPolicy] {
		let array: [FullSyncPolicy] = [NONE, CREATE, OVERRIDE, MERGE]
		return array
	}
	
	public static func getFullSyncPolicy(value: String?) -> FullSyncPolicy {
		if (value != nil) {
			let fullSyncPolicyValues: [FullSyncPolicy] = FullSyncPolicy.values()
			for fullSyncPolicy in fullSyncPolicyValues {
				
				if (fullSyncPolicy.value == value) {
					return fullSyncPolicy
				}
			}
		}
		return NONE
	}
}

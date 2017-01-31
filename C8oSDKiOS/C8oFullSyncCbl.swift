//
//  C8oFullSyncCbl.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 23/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class C8oFullSyncCbl: C8oFullSync {
    private static let ATTACHMENT_PROPERTY_KEY_CONTENT_URL: String = "content_url"
    internal var manager: CBLManager?
    private var fullSyncDatabases: Dictionary<String, C8oFullSyncDatabase>
    private var fullSyncChangeListeners: Dictionary<String, Set<C8oFullSyncChangeListener>>
    private var cblChangeListeners: Dictionary<String, (notification: NSNotification) -> ()>
    private var viewDDocRev: Dictionary<String, String>
    private var mapVersions: Dictionary<String, String>
    private var condition: NSCondition = NSCondition()
    internal static var th: NSThread? = nil
    private var block: Queue<dispatch_block_t> = Queue<dispatch_block_t>()
    internal var errorFs: [NSError] = [NSError]()
    
    internal override init(c8o: C8o) {
        fullSyncDatabases = Dictionary<String, C8oFullSyncDatabase>()
        fullSyncChangeListeners = Dictionary()
        cblChangeListeners = Dictionary()
        viewDDocRev = Dictionary()
        mapVersions = Dictionary()
        super.init(c8o: c8o)
        if (C8oFullSyncCbl.th == nil) {
            condition.lock()
            C8oFullSyncCbl.th = NSThread(target: self, selector: #selector(C8oFullSyncCbl.cbl), object: nil)
            C8oFullSyncCbl.th!.start()
            condition.wait()
            condition.unlock()
        } else if (self.manager == nil) {
            condition.lock()
            self.performSelector(#selector(C8oFullSyncCbl.managerInstanciate), onThread: C8oFullSyncCbl.th!, withObject: nil, waitUntilDone: false)
            condition.wait()
            condition.unlock()
        }
    }
    internal func performOnCblThread(block: dispatch_block_t) {
        self.block.enqueue(block)
        self.performSelector(#selector(C8oFullSyncCbl.doBlock), onThread: C8oFullSyncCbl.th!, withObject: errorFs, waitUntilDone: true)
    }
    
    @objc private func doBlock() {
        (self.block.dequeue()! as dispatch_block_t)()
        
    }
    @objc internal func managerInstanciate() {
        self.manager = CBLManager()
        condition.signal()
        
    }
    @objc internal func cbl(){
        NSThread.currentThread().name = "CBLThread"
        self.manager = CBLManager()
        condition.signal()
        while (true) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, true)
            
        }
    }
    
    private func getOrCreateFullSyncDatabase(databaseName: String) throws -> C8oFullSyncDatabase {
        let localDatabaseName: String = databaseName + localSuffix!
        
        if let _ = fullSyncDatabases[localDatabaseName] {
            
        } else {
            fullSyncDatabases[localDatabaseName] = try C8oFullSyncDatabase(c8o: self.c8o!, manager: self.manager!, databaseName: databaseName, fullSyncDatabases: fullSyncDatabaseUrlBase!, localSuffix: localSuffix!)
            if let listener = cblChangeListeners[databaseName] {
                NSNotificationCenter.defaultCenter().addObserverForName(kCBLDatabaseChangeNotification, object: fullSyncDatabases[localDatabaseName]?.getDatabase(), queue: nil, usingBlock: listener)
            }
        }
        return fullSyncDatabases[localDatabaseName]!
    }
    
    internal override func handleFullSyncResponse(response: AnyObject, listener: C8oResponseListener) throws -> AnyObject {
        var response = response
        let maVar: C8oJSON = C8oJSON()
        response = try! super.handleFullSyncResponse(response, listener: listener)
        if (response.isMemberOfClass(VoidResponse)) {
            return response
        }
        
        if (listener is C8oResponseJsonListener) {
            if (response.isMemberOfClass(CBLDocument)) {
                maVar.myJSON = C8oFullSyncTranslator.documentToJson(response as! CBLDocument)
                return maVar
            } else if (response.isMemberOfClass(FullSyncDocumentOperationResponse)) {
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDocumentOperationResponseToJson((response as! FullSyncDocumentOperationResponse))
                return maVar
            } else if (response.isMemberOfClass(CBLQueryEnumerator)) {
                (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                    maVar.myJSON = C8oFullSyncTranslator.queryEnumeratorToJson(response as! CBLQueryEnumerator)
                }
                return maVar
            } else if response.isMemberOfClass(FullSyncDefaultResponse) {
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDefaultResponseToJson(response as! FullSyncDefaultResponse)
                return maVar
            } else if (response.isMemberOfClass(C8oJSON)) {
                return response
            }
            else if(response is Dictionary<String, AnyObject>){
                
                (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                    maVar.myJSON = C8oFullSyncTranslator.dictionaryToJson(response as! Dictionary<String, AnyObject>)
                }
                return maVar
            }
        } else if (listener is C8oResponseXmlListener) {
            if (response.isMemberOfClass(CBLDocument)) {
                return C8oFullSyncTranslator.documentToXml(response as! CBLDocument)
            } else if (response.isMemberOfClass(FullSyncDocumentOperationResponse)) {
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDocumentOperationResponseToJson(response as! FullSyncDocumentOperationResponse)
                return maVar
            } else if (response.isMemberOfClass(CBLQueryEnumerator)) {
                do {
                    return try C8oFullSyncTranslator.queryEnumeratorToXml(response as! CBLQueryEnumerator)
                }
                catch let e as C8oException {
                    throw C8oException(message: C8oExceptionMessage.queryEnumeratorToXML(), exception: e)
                }
            } else if (response.isMemberOfClass(FullSyncDefaultResponse)) {
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDefaultResponseToJson(response as! FullSyncDefaultResponse)
                return maVar
            }
        } else if (listener is C8oResponseCblListener) {
            if (response.isMemberOfClass(CBLDocument) || response.isMemberOfClass(CBLQueryEnumerator)) {
                return response
            }
        }
        return response
    }
    
    func handleGetDocumentRequest(fullSyncDatatbaseName: String, docid: String, parameters: Dictionary<String, AnyObject>) throws -> Dictionary<String, AnyObject> {
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        var document: CBLDocument?
        var dictDoc : Dictionary<String, AnyObject>? = nil
        var exep: Bool = false
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try! self.getOrCreateFullSyncDatabase(fullSyncDatatbaseName)
            
            // Gets the document from the local database
            
            document = fullSyncDatabase!.getDatabase()?.existingDocumentWithID(docid)
            dictDoc = document?.properties
            // If there are attachments, compute for each one the url to local storage and add it to the attachment descriptor
            if (document != nil) {
                
                var attachments: Dictionary<String, AnyObject>? = document?.propertyForKey(C8oFullSync.FULL_SYNC__ATTACHMENTS) as? Dictionary<String, AnyObject>
                // let att = document?.properties
                
                if (attachments != nil) {
                    let rev: CBLRevision = (document?.currentRevision)!
                    
                    for attachmentName in (attachments?.keys)! {
                        let attachment: CBLAttachment = rev.attachmentNamed(attachmentName)!
                        let url: NSURL = attachment.contentURL!
                        var attachmentDesc: Dictionary<String, AnyObject>? = (attachments![attachmentName] as? Dictionary<String, AnyObject>)!
                        attachmentDesc![C8oFullSyncCbl.ATTACHMENT_PROPERTY_KEY_CONTENT_URL] = String(url).stringByRemovingPercentEncoding
                        var dictAny : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                        dictAny[attachmentName] = attachmentDesc
                        dictDoc![C8oFullSync.FULL_SYNC__ATTACHMENTS] = dictAny
                        
                    }
                }
            } else {
                exep = true
            }
        }
        if (exep) {
            throw C8oRessourceNotFoundException(message: C8oExceptionMessage.ressourceNotFound("requested document \"" + docid + "\""))
        }
        if(dictDoc == nil){
            dictDoc = Dictionary<String, AnyObject>()
        }
        return dictDoc!
    }
    
    func handleDeleteDocumentRequest(DatatbaseName: String, docid: String, parameters: Dictionary<String, AnyObject>) throws -> FullSyncDocumentOperationResponse? {
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        var document: CBLDocument?
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try! self.getOrCreateFullSyncDatabase(DatatbaseName)
        }
        let revParameterValue: String? = C8oUtils.getParameterStringValue(parameters, name: FullSyncDeleteDocumentParameter.REV.name, useName: false)
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            
            document = (fullSyncDatabase!.getDatabase()?.existingDocumentWithID(docid))!
        }
        if (document == nil) {
            throw C8oRessourceNotFoundException(message: C8oExceptionMessage.toDo())
        }
        
        let documentRevision: String = (document?.currentRevisionID)!
        
        // If the revision is specified then checks if this is the right revision
        if (revParameterValue != nil && revParameterValue != documentRevision) {
            throw C8oRessourceNotFoundException(message: C8oExceptionMessage.couchRequestInvalidRevision())
        }
        var deleted: Bool = true
        var error: NSError? = nil
        do {
            (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                do {
                    try document?.deleteDocument()
                }
                catch let e as NSError {
                    error = e
                }
            }
            if (error != nil) {
                throw error!
            }
            deleted = true
        }
        catch let e as NSError {
            deleted = false
            throw C8oException(message: C8oExceptionMessage.couchRequestDeleteDocument(), exception: e)
        }
        catch {
            
        }
        
        return FullSyncDocumentOperationResponse(documentId: docid, documentRevision: documentRevision, operationStatus: deleted)
    }
    
    func handlePostDocumentRequest(databaseName: String, fullSyncPolicy: FullSyncPolicy, parameters: Dictionary<String, AnyObject>) throws -> NSObject? {
        
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do {
                fullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName)
            }
            catch {
                
            }
            
        }
        
        // Gets the subkey separator parameter
        var subkeySeparatorParameterValue: String? = C8oUtils.getParameterStringValue(parameters, name: C8o.FS_SUBKEY_SEPARATOR, useName: false)
        if (subkeySeparatorParameterValue == nil) {
            subkeySeparatorParameterValue = "."
        }
        
        // Filters and modifies wrong properties
        var newProperties = Dictionary<String, AnyObject>()
        for parameter in parameters {
            var parameterName: String = parameter.0
            
            // Ignores parameters beginning with "__" or "_use_"
            if (!parameterName.hasPrefix("__") && !parameterName.hasPrefix("_use_")) {
                var objectParameterValue = parameter.1
                // var objectParameterValueT : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                do {
                    objectParameterValue = C8oFullSyncTranslator.toAnyObject(objectParameterValue)
                    
                    // var count = 0
                    //objectParameterValue = objectParameterValue.description
                    /*let json = JSON(objectParameterValue)
                     if let dataFromString = objectParameterValue.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                     let json = JSON(data: dataFromString)
                     for (key, value) : (String, JSON) in json {
                     objectParameterValueT[key] = value.object
                     count += 1
                     }
                     if(count > 0){
                     objectParameterValue = objectParameterValueT
                     }
                     }*/
                    
                }
                
                // !!!!!!!!!!!!!! Becarefull here cause a possible trouble due to non use of pattern.quote in swift...
                // Checks if the parameter name is splittable
                let paths: [String] = parameterName.componentsSeparatedByString(subkeySeparatorParameterValue!)
                
                if (paths.count > 1) {
                    // The first substring becomes the key
                    parameterName = paths[0]
                    // Next substrings create a hierarchy which will becomes json subkeys
                    var count: Int = paths.count - 1
                    while (count > 0) {
                        var tmpObject: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
                        tmpObject[paths[count]] = objectParameterValue
                        objectParameterValue = tmpObject
                        count = count - 1
                    }
                    let existProperty: AnyObject? = newProperties[parameterName]
                    if let ex = existProperty as? Dictionary<String, AnyObject> {
                        if var e = objectParameterValue as? Dictionary<String, AnyObject> {
                            C8oFullSyncCbl.mergeProperties(&e, oldProperties: ex)
                            objectParameterValue = e
                        }
                        
                    }
                    
                }
                
                newProperties[parameterName] = objectParameterValue
            }
        }
        
        // Execute the query depending to the policy
        var db: CBLDatabase? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            db = fullSyncDatabase!.getDatabase()!
        }
        // We passed c8o object to fullsyncpolicy to process action on CBLThread
        // fullSyncPolicy.setC8o(c8o!)
        var error: NSError? = nil
        var exception: C8oException? = nil
        var createdDocument: CBLDocument? = nil
        var documentId: String? = nil
        var currentRevision: String? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do {
                
                createdDocument = try fullSyncPolicy.action(db!, newProperties)
            }
            catch let e as C8oException {
                exception = e
            }
            catch let e as NSError {
                error = e
            }
        }
        if (error != nil) {
            throw error!
        } else if (exception != nil) {
            throw exception!
        }
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            documentId = createdDocument!.documentID
            currentRevision = createdDocument!.currentRevisionID!
        }
        return FullSyncDocumentOperationResponse(documentId: documentId!, documentRevision: currentRevision!, operationStatus: true)
        
    }
    func handlePutAttachmentRequest(databaseName : String, docid : String, attachmentName : String, attachmentType : String, attachmentContent : NSData) throws -> AnyObject {
        var document : CBLDocument? = nil
        var newRev : CBLUnsavedRevision? = nil
        var error : NSError? = nil
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do{
                let fullSyncDatabase : C8oFullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName)
                
                // Gets the document from the local database
                document = fullSyncDatabase.getDatabase()?.existingDocumentWithID(docid)
                
                if(document !=  nil){
                    newRev = (document!.currentRevision?.createRevision())!
                    newRev!.setAttachmentNamed(attachmentName, withContentType: attachmentType, content: attachmentContent)
                    do{
                        try newRev!.save()
                    }
                    catch let e as NSError{
                        throw c8oCouchbaseLiteException(message: "Unable to put the attachment " + attachmentName + " to the document " + docid + ".", exception: e)
                    }
                }
                else{
                    throw C8oRessourceNotFoundException(message: C8oExceptionMessage.toDo())
                }
            }
            catch let e as NSError{
                error = e
            }
            
        }
        if(error != nil){
            throw error!
        }
        
        
        return FullSyncDocumentOperationResponse(documentId: (document?.documentID)!, documentRevision: (document?.currentRevisionID)!, operationStatus: true)
        
    }
    
    func handleDeleteAttachmentRequest(databaseName : String, docid : String, attachmentName : String) throws ->AnyObject{
        var document : CBLDocument? = nil
        var newRev : CBLUnsavedRevision? = nil
        var error : NSError? = nil
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do{
                let fullSyncDatabase : C8oFullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName)
                
                // Gets the document from the local database
                document = fullSyncDatabase.getDatabase()?.existingDocumentWithID(docid)
                
                if(document !=  nil){
                    newRev = (document!.currentRevision?.createRevision())!
                    newRev!.removeAttachmentNamed(attachmentName)
                    do{
                        try newRev!.save()
                    }
                    catch let e as NSError{
                        throw c8oCouchbaseLiteException(message: "Unable to delete the attachment " + attachmentName + " to the document " + docid + ".", exception: e)
                    }
                }
                else{
                    throw C8oRessourceNotFoundException(message: C8oExceptionMessage.toDo())
                }
            }
            catch let e as NSError{
                error = e
            }
            
        }
        if(error != nil){
            throw error!
        }
        return FullSyncDocumentOperationResponse(documentId: (document?.documentID)!, documentRevision: (document?.currentRevisionID)!, operationStatus: true)
    }
    func handleAllDocumentsRequest(databaseName: String, parameters: Dictionary<String, AnyObject>) throws -> AnyObject? {
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        var query: CBLQuery? = nil
        // Creates the fullSync query and add parameters to it
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try! self.getOrCreateFullSyncDatabase(databaseName)
            query = fullSyncDatabase!.getDatabase()!.createAllDocumentsQuery()
        }
        do {
            try C8oFullSyncCbl.addParametersToQuery(query!, parameters: parameters)
        } catch let e as NSError {
            throw C8oException(message: C8oExceptionMessage.addparametersToQuery(), exception: e)
        }
        
        // Runs the query
        var result: CBLQueryEnumerator? = nil
        do {
            var err: NSError? = nil
            (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                do {
                    result = try query!.run()
                }
                catch let e as NSError {
                    err = e
                }
                
            }
            if (err != nil) {
                throw err!
            }
        } catch let e as NSError {
            throw C8oException(message: C8oExceptionMessage.couchRequestAllDocuments(), exception: e)
        }
        
        return result
    }
    
    func handleGetViewRequest(databaseName: String, ddocName: String?, viewName: String?, parameters: Dictionary<String, AnyObject>) throws -> CBLQueryEnumerator? {
        
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try! self.getOrCreateFullSyncDatabase(databaseName)
        }
        
        // Gets the view depending to its programming language (Javascript / Java)
        let view: CBLView?
        if (ddocName != nil) {
            // Javascript view
            view = checkAndCreateJavaScriptView(fullSyncDatabase!.getDatabase()!, ddocName: ddocName!, viewName: viewName!)
        } else {
            // Java view
            view = fullSyncDatabase!.getDatabase()?.viewNamed(viewName!)
        }
        if (view == nil) {
            throw C8oRessourceNotFoundException(message: C8oExceptionMessage.illegalArgumentNotFoundFullSyncView(viewName!, databaseName: fullSyncDatabase!.getDatabaseName()))
        }
        
        // Creates the fullSync query and add parameters to it
        let query: CBLQuery = view!.createQuery()
        do {
            try C8oFullSyncCbl.addParametersToQuery(query, parameters: parameters)
        } catch {
            // TODO...
            throw C8oException(message: C8oExceptionMessage.addparametersToQuery())
        }
        
        // Runs the query
        var bool = false
        var result: CBLQueryEnumerator? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do {
                result = try query.run()
            } catch {
                // TODO...
                bool = true
            }
        }
        if (bool) {
            throw C8oException(message: C8oExceptionMessage.couchRequestGetView())
        }
        return result
    }
    
    func handleSyncRequest(databaseName: String, parameters: Dictionary<String, AnyObject>, c8oResponseListener: C8oResponseListener) throws -> VoidResponse? {
        
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        try! fullSyncDatabase.startAllReplications(parameters, c8oResponseListener: c8oResponseListener)
        
        return VoidResponse.getInstance()
    }
    
    func handleReplicatePullRequest(databaseName: String, parameters: Dictionary<String, AnyObject>, c8oResponseListener: C8oResponseListener) throws -> VoidResponse? {
        
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        try! fullSyncDatabase.startPullReplication(parameters, c8oResponseListener: c8oResponseListener)
        
        return VoidResponse.getInstance()
    }
    
    func handleReplicatePushRequest(databaseName: String, parameters: Dictionary<String, AnyObject>, c8oResponseListener: C8oResponseListener) throws -> VoidResponse? {
        
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        try! fullSyncDatabase.startPushReplication(parameters, c8oResponseListener: c8oResponseListener)
        
        return VoidResponse.getInstance()
    }
    
    func handleResetDatabaseRequest(databaseName: String) throws -> FullSyncDefaultResponse? {
        try handleDestroyDatabaseRequest(databaseName)
        return try handleCreateDatabaseRequest(databaseName)
    }
    
    func handleCreateDatabaseRequest(databaseName: String) throws -> FullSyncDefaultResponse? {
        let _: C8oFullSyncDatabase = try getOrCreateFullSyncDatabase(databaseName)
        return FullSyncDefaultResponse(operationStatus: true)
    }
    
    func handleDestroyDatabaseRequest(databaseName: String) throws -> FullSyncDefaultResponse? {
        try getOrCreateFullSyncDatabase(databaseName).deleteDb()
        
        let localDatabaseName: String = databaseName + localSuffix!
        if let _ = fullSyncDatabases[localDatabaseName] {
            fullSyncDatabases.removeValueForKey(localDatabaseName)
        }
        
        return FullSyncDefaultResponse(operationStatus: true)
    }
    
    private func compileView (db: CBLDatabase, viewName: String, viewProps: Dictionary<String, NSObject>?) -> CBLView? {
        var language: String? = viewProps!["language"] as? String
        if (language == nil) {
            language = "javascript"
        }
        let mapSource: String? = viewProps!["map"] as? String
        if (mapSource == nil) {
            return nil
        }
        
        var mapBlock: CBLMapBlock? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            CBLRegisterJSViewCompiler()
            mapBlock = CBLView.compiler()?.compileMapFunction(mapSource!, language: language!)
            
        }
        
        if (mapBlock == nil) {
            return nil
        }
        
        var mapID = db.name + ":" + viewName + ":" + String(mapSource!.hash)
        
        let reduceSource: String? = viewProps!["reduce"] as? String
        var reduceBlock: CBLReduceBlock? = nil
        if (reduceSource != nil) {
            (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                reduceBlock = CBLView.compiler()!.compileReduceFunction(reduceSource!, language: language!)
            }
            if (reduceBlock == nil) {
                return nil
            }
            mapID = mapID + ":" + String(reduceSource!.hash)
        }
        
        var view: CBLView?
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            view = db.viewNamed(viewName)
            
            view!.setMapBlock(mapBlock!, reduceBlock: reduceBlock, version: mapID)
            self.mapVersions[db.name + ":" + viewName] = mapID
        }
        let collation: String? = viewProps!["collation"] as? String
        if ("raw" == collation) {
            // view.
            // TODO....
            fatalError("TODO ... collation not found for the moment within IOS")
        }
        return view
    }
    
    private func checkAndCreateJavaScriptView(database: CBLDatabase, ddocName: String, viewName: String) -> CBLView? {
        let tdViewName: String = ddocName + "/" + viewName
        var view: CBLView? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            view = database.existingViewNamed(tdViewName)
        }
        
        var rev: CBLRevision? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            rev = database.existingDocumentWithID(String(format: "_design/%@", ddocName))?.currentRevision
        }
        
        if (rev == nil) {
            return nil
        }
        
        let revID = rev!.revisionID!
        
        if (view != nil) {
            let mapVersion = mapVersions[database.name + ":" + tdViewName]
            if (mapVersion == nil || revID != viewDDocRev[mapVersion!]) {
                view = nil
            }
        }
        
        if (view == nil || view!.mapBlock == nil) {
            
            let views: Dictionary<String, NSObject>? = rev?.properties!["views"] as? Dictionary<String, NSObject>
            let viewProps: Dictionary<String, NSObject>? = views![viewName] as? Dictionary<String, NSObject>
            if (viewProps == nil) {
                return nil
            }
            view = self.compileView(database, viewName: tdViewName, viewProps: viewProps)
            if (view != nil) {
                let mapVersion = mapVersions[database.name + ":" + tdViewName]!
                viewDDocRev[mapVersion] = revID
            }
        }
        return view
    }
    
    private static func addParametersToQuery(query: CBLQuery, parameters: Dictionary<String, AnyObject>) throws {
        
        for fullSyncParameter in FullSyncRequestParameter.values() {
            var objectParameterValue: AnyObject? = nil
            if (fullSyncParameter.isJson) {
                objectParameterValue = C8oUtils.getParameterObjectValue(parameters, name: fullSyncParameter.name, useName: true)
                
            } else {
                objectParameterValue = C8oUtils.getParameterStringValue(parameters, name: fullSyncParameter.name, useName: true)
            }
            if (objectParameterValue != nil) {
                fullSyncParameter.action(query, objectParameterValue!)
            }
        }
    }
    
    static func mergeProperties(inout newProperties: Dictionary<String, AnyObject>, oldProperties: Dictionary<String, AnyObject>) {
        for old in oldProperties {
            // let oldProperty = old
            let oldPropertyKey = old.0
            let oldPropertyValue = old.1
            
            // let newPropertyValue : AnyObject
            if let newPropertyValue = newProperties[oldPropertyKey] {
                if var a = newPropertyValue as? Dictionary<String, AnyObject>, let b = oldPropertyValue as? Dictionary<String, AnyObject> {
                    mergeProperties(&a, oldProperties: b)
                    newProperties[oldPropertyKey] = a
                } else if var a = newPropertyValue as? [AnyObject], let b = oldPropertyValue as? [AnyObject] {
                    C8oFullSyncCbl.mergeArrayProperties(&a, oldArray: b)
                    newProperties[oldPropertyKey] = a
                } else {
                    
                }
            } else {
                newProperties[oldPropertyKey] = oldPropertyValue
            }
        }
    }
    
    static func mergeArrayProperties(inout newArray: [AnyObject], oldArray: [AnyObject]) {
        let newArraySize = newArray.count
        let oldArraySize = oldArray.count
        for i in 0..<oldArraySize {
            var newArrayValue: AnyObject? = nil
            if (i < newArraySize) {
                newArrayValue = newArray[i]
            }
            let oldArrayValue = oldArray[i]
            
            if (newArrayValue != nil) {
                if var e = newArrayValue as? Dictionary<String, AnyObject>, let f = oldArrayValue as? Dictionary<String, AnyObject> {
                    mergeProperties(&e, oldProperties: f)
                    newArrayValue = e
                } else if var g = newArrayValue as? [AnyObject], let h = oldArrayValue as? [AnyObject] {
                    mergeArrayProperties(&g, oldArray: h)
                    newArrayValue = g
                } else {
                    
                }
            } else {
                newArray.append(oldArrayValue)
            }
        }
    }
    
    internal func getDocucmentFromDatabase(c8o: C8o, databaseName: String, documentId: String) throws -> CBLDocument {
        var c8oFullSyncDatabase: C8oFullSyncDatabase
        do {
            c8oFullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName)
        } catch {
            throw C8oException(message: C8oExceptionMessage.fullSyncGetOrCreateDatabase(databaseName))
        }
        return (c8oFullSyncDatabase.getDatabase()?.existingDocumentWithID(documentId))!
    }
    
    internal static func overrideDocument(document: CBLDocument, properties: Dictionary<String, NSObject>) throws {
        var propertiesMutable = properties
        let currentRevision: CBLSavedRevision? = document.currentRevision
        if (currentRevision != nil) {
            propertiesMutable[C8oFullSync.FULL_SYNC__REV] = currentRevision?.revisionID
        }
        
        do {
            try document.putProperties(propertiesMutable)
        }
        catch {
            throw C8oException(message: "TODO")
        }
    }
    
    func getResponseFromLocalCache(c8oCallRequestIdentifier: String) throws -> C8oLocalCacheResponse? {
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(C8o.LOCAL_CACHE_DATABASE_NAME)
        
        var localCacheDocument: CBLDocument? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            localCacheDocument = fullSyncDatabase.getDatabase()?.existingDocumentWithID(c8oCallRequestIdentifier)
        }
        
        if (localCacheDocument == nil) {
            throw C8oUnavailableLocalCacheException(message: C8oExceptionMessage.localCacheDocumentJustCreated())
        }
        
        let response = localCacheDocument?.propertyForKey(C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE)
        let responseType = localCacheDocument?.propertyForKey(C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE)
        let expirationDate = localCacheDocument?.propertyForKey(C8o.LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE)
        var responseString: String? = nil
        var responseTypeString: String? = nil
        var expirationDateLong: Double = -1
        
        if (response != nil) {
            if let e = response as! String? {
                responseString = e
            }
        } else {
            throw C8oException(message: C8oExceptionMessage.InvalidLocalCacheResponseInformation())
        }
        if (responseType != nil) {
            if let e = responseType as! String? {
                responseTypeString = e
            }
        } else {
            throw C8oException(message: C8oExceptionMessage.InvalidLocalCacheResponseInformation())
        }
        if (expirationDate != nil) {
            if let e = expirationDate as! Double? {
                expirationDateLong = e
                let currentTime = NSDate().timeIntervalSince1970 * 1000
                if (Double(expirationDateLong) < currentTime) {
                    throw C8oUnavailableLocalCacheException(message: C8oExceptionMessage.timeToLiveExpired())
                }
            } else {
                throw C8oException(message: C8oExceptionMessage.InvalidLocalCacheResponseInformation())
            }
        }
        return C8oLocalCacheResponse(response: responseString!, responseType: responseTypeString!, expirationDate: expirationDateLong)
    }
    
    func saveResponseToLocalCache(c8oCallRequestIdentifier: String, localCacheResponse: C8oLocalCacheResponse) throws {
        
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(C8o.LOCAL_CACHE_DATABASE_NAME)
        
        var localCacheDocument: CBLDocument? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            localCacheDocument = fullSyncDatabase.getDatabase()?.documentWithID(c8oCallRequestIdentifier)
            // }
            var properties: Dictionary<String, NSObject> = Dictionary<String, NSObject>()
            properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE] = localCacheResponse.getResponse()
            properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE] = localCacheResponse.getResponseType()
            if (localCacheResponse.getExpirationDate() > 0) {
                properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE] = localCacheResponse.getExpirationDate()
            }
            let currentRevision: CBLSavedRevision? = localCacheDocument!.currentRevision
            if (currentRevision != nil) {
                properties[C8oFullSyncCbl.FULL_SYNC__REV] = currentRevision?.revisionID
            }
            
            // do {
            // (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do {
                try localCacheDocument!.putProperties(properties)
            } catch {
                
            }
        }
        /*} catch {
         throw C8oException(message: "TODO")
         }*/
    }
    
    internal override func addFullSyncChangeListener(db: String?, listener: C8oFullSyncChangeListener) throws {
        var _db = db
        if (_db == nil || _db!.isEmpty) {
            _db = c8o!.defaultDatabaseName
        }
        
        if let _ = fullSyncChangeListeners[_db!] {
        } else {
            fullSyncChangeListeners[_db!] = Set<C8oFullSyncChangeListener>()
            let evtHandler = {(notification: NSNotification) -> () in
                var changes: JSON = [:]
                var docs = Array<JSON>()
                changes["isExternal"].boolValue = notification.userInfo!["external"] as! Bool
                
                for change in notification.userInfo!["changes"] as! Array<CBLDatabaseChange> {
                    var doc: JSON = [:]
                    doc["id"].stringValue = change.documentID
                    doc["isConflict"].boolValue = change.inConflict
                    doc["isCurrentRevision"].boolValue = change.isCurrentRevision
                    doc["revisionId"].stringValue = change.revisionID
                    if (change.source != nil) {
                        doc["sourceUrl"].stringValue = change.source!.absoluteString!
                    }
                    docs.append(doc)
                }
                changes["changes"] = JSON(docs)
                for handler in self.fullSyncChangeListeners[_db!]! {
                    handler.handler(changes: changes)
                }
            }
            NSNotificationCenter.defaultCenter().addObserverForName(kCBLDatabaseChangeNotification, object: try getOrCreateFullSyncDatabase(_db!).getDatabase(), queue: nil, usingBlock: evtHandler)
            cblChangeListeners[_db!] = evtHandler
        }
        
        fullSyncChangeListeners[_db!]!.insert(listener)
    }
    
    internal override func removeFullSyncChangeListener(db: String?, listener: C8oFullSyncChangeListener) throws {
        var _db = db
        if (_db == nil || _db!.isEmpty) {
            _db = c8o!.defaultDatabaseName
        }
        
        if var listeners = fullSyncChangeListeners[_db!] {
            listeners.remove(listener)
            if (listeners.isEmpty) {
                try getOrCreateFullSyncDatabase(_db!).getDatabase()?.removeObserver(kCBLDatabaseChangeNotification, forKeyPath: "")
            }
        }
    }
}

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
import CouchbaseLite.All
import CouchbaseLite.JSView

class C8oFullSyncCbl: C8oFullSync {
    fileprivate static let ATTACHMENT_PROPERTY_KEY_CONTENT_URL: String = "content_url"
    internal var manager: CBLManager?
    fileprivate var fullSyncDatabases: Dictionary<String, C8oFullSyncDatabase>
    fileprivate var fullSyncChangeListeners: Dictionary<String, Set<C8oFullSyncChangeListener>>
    fileprivate var cblChangeListeners: Dictionary<String, (_ notification: Notification) -> ()>
    fileprivate var viewDDocRev: Dictionary<String, String>
    fileprivate var mapVersions: Dictionary<String, String>
    fileprivate var condition: NSCondition = NSCondition()
    internal static var th: Thread? = nil
    fileprivate var block: Queue<() throws ->()> = Queue<()throws ->()>()
    internal var errorFs: [NSError] = [NSError]()
    fileprivate let serialQueue = DispatchQueue(label: "accessBlock")
    
    internal override init(c8o: C8o) {
        fullSyncDatabases = Dictionary<String, C8oFullSyncDatabase>()
        fullSyncChangeListeners = Dictionary()
        cblChangeListeners = Dictionary()
        viewDDocRev = Dictionary()
        mapVersions = Dictionary()
        super.init(c8o: c8o)
        if (C8oFullSyncCbl.th == nil) {
            condition.lock()
            C8oFullSyncCbl.th = Thread(target: self, selector: #selector(C8oFullSyncCbl.cbl), object: nil)
            C8oFullSyncCbl.th!.start()
            condition.wait()
            condition.unlock()
        } else if (self.manager == nil) {
            condition.lock()
            self.perform(#selector(C8oFullSyncCbl.managerInstanciate), on: C8oFullSyncCbl.th!, with: nil, waitUntilDone: false)
            condition.wait()
            condition.unlock()
        }
    }
    internal func performOnCblThread(_ block: @escaping () throws ->()) {
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        serialQueue.sync {
            self.block.enqueue(block)
            syncMutex[0] = true
            condition.signal()
        }
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        self.perform(#selector(C8oFullSyncCbl.doBlock), on: C8oFullSyncCbl.th!, with: errorFs, waitUntilDone: true)
    }
    
    @objc fileprivate func doBlock() throws {
        var block : AnyObject? = nil;
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        serialQueue.sync {
            block = self.block.dequeue() as AnyObject;
            syncMutex[0] = true
            condition.signal()
        }
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        if block != nil{
            try (block as! () throws ->())()
        }
    }
    @objc internal func managerInstanciate() {
        self.manager = CBLManager()
        condition.signal()
    }
    @objc internal func cbl(){
        Thread.current.name = "CBLThread"
        self.manager = CBLManager()
        condition.signal()
        while (true) {
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 1, true)
            
        }
    }
    
    fileprivate func getOrCreateFullSyncDatabase(_ databaseName: String) throws -> C8oFullSyncDatabase {
        let localDatabaseName: String = databaseName + localSuffix!
        
        if let _ = fullSyncDatabases[localDatabaseName] {
            
        } else {
            fullSyncDatabases[localDatabaseName] = try C8oFullSyncDatabase(c8o: self.c8o!, manager: self.manager!, databaseName: databaseName, fullSyncDatabases: fullSyncDatabaseUrlBase!, localSuffix: localSuffix!)
            if let listener = cblChangeListeners[databaseName] {
                NotificationCenter.default.addObserver(forName: NSNotification.Name.cblDatabaseChange, object: fullSyncDatabases[localDatabaseName]?.getDatabase(), queue: nil, using: listener)
            }
        }
        return fullSyncDatabases[localDatabaseName]!
    }
    
    internal override func handleFullSyncResponse(_ response: Any, listener: C8oResponseListener) throws -> Any {
        var response = response
        let maVar: C8oJSON = C8oJSON()
        response = try! super.handleFullSyncResponse(response, listener: listener)
        if ((response as AnyObject).isMember(of: VoidResponse.self)) {
            return response
        }
        
        if (listener is C8oResponseJsonListener) {
            if ((response as AnyObject).isMember(of: CBLDocument.self)) {
                maVar.myJSON = C8oFullSyncTranslator.documentToJson(response as! CBLDocument)
                return maVar
            } else if ((response as AnyObject).isMember(of: FullSyncDocumentOperationResponse.self)) {
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDocumentOperationResponseToJson((response as! FullSyncDocumentOperationResponse))
                return maVar
            } else if ((response as AnyObject).isMember(of:CBLQueryEnumerator.self)) {
                // Lock
                var syncMutex: [Bool] = [Bool]()
                syncMutex.append(false)
                let condition: NSCondition = NSCondition()
                condition.lock()
                // Call on CBL thread
                (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                    maVar.myJSON = C8oFullSyncTranslator.queryEnumeratorToJson(response as! CBLQueryEnumerator)
                    // Signal
                    syncMutex[0] = true
                    condition.signal()
                }
                // Waiting for signal
                if(!syncMutex[0]){
                    condition.wait()
                }
                condition.unlock()
                
                return maVar
            } else if (response as AnyObject).isMember(of: FullSyncDefaultResponse.self) {
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDefaultResponseToJson(response as! FullSyncDefaultResponse)
                return maVar
            } else if ((response as AnyObject).isMember(of: C8oJSON.self)) {
                return response
            }
            else if(response is Dictionary<String, Any>){
                // Lock
                var syncMutex: [Bool] = [Bool]()
                syncMutex.append(false)
                let condition: NSCondition = NSCondition()
                condition.lock()
                (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                    maVar.myJSON = C8oFullSyncTranslator.dictionaryToJson(response as! Dictionary<String, Any>)
                    // Signal
                    syncMutex[0] = true
                    condition.signal()
                }
                // Waiting for signal
                if(!syncMutex[0]){
                    condition.wait()
                }
                condition.unlock()
                return maVar
            }
        } else if (listener is C8oResponseXmlListener) {
            if ((response as AnyObject).isMember(of: CBLDocument.self)) {
                return C8oFullSyncTranslator.documentToXml(response as! CBLDocument)
            } else if ((response as AnyObject).isMember(of: FullSyncDocumentOperationResponse.self)) {
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDocumentOperationResponseToJson(response as! FullSyncDocumentOperationResponse)
                return maVar
            } else if ((response as AnyObject).isMember(of: CBLQueryEnumerator.self)) {
                do {
                    return try C8oFullSyncTranslator.queryEnumeratorToXml(response as! CBLQueryEnumerator)
                }
                catch let e as C8oException {
                    throw C8oException(message: C8oExceptionMessage.queryEnumeratorToXML(), exception: e)
                }
            } else if ((response as AnyObject).isMember(of: FullSyncDefaultResponse.self)) {
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDefaultResponseToJson(response as! FullSyncDefaultResponse)
                return maVar
            }
        } else if (listener is C8oResponseCblListener) {
            if ((response as AnyObject).isMember(of:CBLDocument.self) || (response as AnyObject).isMember(of: CBLQueryEnumerator.self)) {
                return response
            }
        }
        return response
    }
    
    func handleGetDocumentRequest(_ fullSyncDatatbaseName: String, docid: String, parameters: Dictionary<String, Any>) throws -> Dictionary<String, Any> {
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        var document: CBLDocument?
        var dictDoc : Dictionary<String, Any>? = nil
        var exep: Bool = false
        
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try! self.getOrCreateFullSyncDatabase(fullSyncDatatbaseName)
            
            // Gets the document from the local database
            _ = fullSyncDatabase?.getDatabase()!.existingLocalDocument(withID: docid)
            _ = fullSyncDatabase?.getDatabase()?.document(withID: docid)
            _ = fullSyncDatabase?.getDatabase()?.documentCount
            _ = fullSyncDatabase?.getDatabase()?.createAllDocumentsQuery().allDocsMode.rawValue
            document = fullSyncDatabase!.getDatabase()?.existingDocument(withID: docid)
            dictDoc = document?.properties
            // If there are attachments, compute for each one the url to local storage and add it to the attachment descriptor
            if (document != nil) {
                
                var attachments: Dictionary<String, Any>? = document?.property(forKey: C8oFullSync.FULL_SYNC__ATTACHMENTS) as? Dictionary<String, Any>
                // let att = document?.properties
                
                if (attachments != nil) {
                    let rev: CBLRevision = (document?.currentRevision)!
                    
                    for attachmentName in (attachments?.keys)! {
                        let attachment: CBLAttachment = rev.attachmentNamed(attachmentName)!
                        let url: URL = attachment.contentURL!
                        var attachmentDesc: Dictionary<String, Any>? = (attachments![attachmentName] as? Dictionary<String, Any>)!
                        attachmentDesc![C8oFullSyncCbl.ATTACHMENT_PROPERTY_KEY_CONTENT_URL] = String(describing: url).removingPercentEncoding
                        var dictAny : Dictionary<String, Any> = Dictionary<String, Any>()
                        dictAny[attachmentName] = attachmentDesc as Any
                        dictDoc![C8oFullSync.FULL_SYNC__ATTACHMENTS] = dictAny as Any
                        
                    }
                }
            } else {
                exep = true
            }
            // Signal
            syncMutex[0] = true
            condition.signal()
        }
        
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        if (exep) {
            throw C8oRessourceNotFoundException(message: C8oExceptionMessage.ressourceNotFound("requested document \"" + docid + "\""))
        }
        if(dictDoc == nil){
            dictDoc = Dictionary<String, Any>()
        }
        return dictDoc!
    }
    
    func handleDeleteDocumentRequest(_ DatatbaseName: String, docid: String, parameters: Dictionary<String, Any>) throws -> FullSyncDocumentOperationResponse? {
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        var document: CBLDocument?
        
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try! self.getOrCreateFullSyncDatabase(DatatbaseName)
            // Signal
            syncMutex[0] = true
            condition.signal()
        }
        
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        let revParameterValue: String? = C8oUtils.getParameterStringValue(parameters, name: FullSyncDeleteDocumentParameter.REV.name, useName: false)
        
        // Lock
        var syncMutex2: [Bool] = [Bool]()
        syncMutex2.append(false)
        let condition2: NSCondition = NSCondition()
        condition2.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            document = (fullSyncDatabase!.getDatabase()?.existingDocument(withID: docid))!
            // Signal
            syncMutex2[0] = true
            condition2.signal()
        }
        // Waiting for signal
        if(!syncMutex2[0]){
            condition2.wait()
        }
        condition2.unlock()
        
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
            // Lock
            var syncMutex3: [Bool] = [Bool]()
            syncMutex3.append(false)
            let condition3: NSCondition = NSCondition()
            condition3.lock()
            
            (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                do {
                    try document?.delete()
                    // Signal
                    syncMutex3[0] = true
                    condition3.signal()
                }
                catch let e as NSError {
                    error = e
                    // Signal
                    syncMutex3[0] = true
                    condition3.signal()
                }
            }
            // Waiting for signal
            if(!syncMutex3[0]){
                condition3.wait()
            }
            condition3.unlock()
            
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
    
    func handlePostDocumentRequest(_ databaseName: String, fullSyncPolicy: FullSyncPolicy, parameters: Dictionary<String, Any>) throws -> NSObject? {
        
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName)
            // Signal
            syncMutex[0] = true
            condition.signal()
        }
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        // Gets the subkey separator parameter
        var subkeySeparatorParameterValue: String? = C8oUtils.getParameterStringValue(parameters, name: C8o.FS_SUBKEY_SEPARATOR, useName: false)
        if (subkeySeparatorParameterValue == nil) {
            subkeySeparatorParameterValue = "."
        }
        
        // Filters and modifies wrong properties
        var newProperties = [String: Any]()
        for parameter in parameters {
            var parameterName: String = parameter.0
            
            // Ignores parameters beginning with "__" or "_use_"
            if (!parameterName.hasPrefix("__") && !parameterName.hasPrefix("_use_")) {
                var objectParameterValue = parameter.1
                // var objectParameterValueT : Dictionary<String, Any> = Dictionary<String, Any>()
                do {
                    objectParameterValue = C8oFullSyncTranslator.toAnyObject(obj: objectParameterValue)
                }
                // !!!!!!!!!!!!!! Becarefull here cause a possible trouble due to non use of pattern.quote in swift...
                // Checks if the parameter name is splittable
                let paths: [String] = parameterName.components(separatedBy: subkeySeparatorParameterValue!)
                
                if (paths.count > 1) {
                    // The first substring becomes the key
                    parameterName = paths[0]
                    // Next substrings create a hierarchy which will becomes json subkeys
                    var count: Int = paths.count - 1
                    while (count > 0) {
                        var tmpObject: Dictionary<String, Any> = Dictionary<String, Any>()
                        tmpObject[paths[count]] = objectParameterValue
                        objectParameterValue = tmpObject as Any
                        count = count - 1
                    }
                    let existProperty: Any? = newProperties[parameterName]
                    if let ex = existProperty as? Dictionary<String, Any> {
                        if var e = objectParameterValue as? Dictionary<String, Any> {
                            C8oFullSyncCbl.mergeProperties(&e, oldProperties: ex)
                            objectParameterValue = e as Any
                        }
                    }
                }
                newProperties[parameterName] = objectParameterValue
            }
        }
        // Lock
        var syncMutex2: [Bool] = [Bool]()
        syncMutex2.append(false)
        let condition2: NSCondition = NSCondition()
        condition2.lock()
        
        // Execute the query depending to the policy
        var db: CBLDatabase? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            db = fullSyncDatabase!.getDatabase()!
            // Signal
            syncMutex2[0] = true
            condition2.signal()
        }
        // Waiting for signal
        if(!syncMutex2[0]){
            condition2.wait()
        }
        condition2.unlock()
        // We passed c8o object to fullsyncpolicy to process action on CBLThread
        // fullSyncPolicy.setC8o(c8o!)
        var error: NSError? = nil
        var exception: C8oException? = nil
        var createdDocument: CBLDocument? = nil
        var documentId: String? = nil
        var currentRevision: String? = nil
        
        // Lock
        var syncMutex3: [Bool] = [Bool]()
        syncMutex3.append(false)
        let condition3: NSCondition = NSCondition()
        condition3.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do {
                createdDocument = try fullSyncPolicy.action(db!, newProperties)
                // Signal
                syncMutex3[0] = true
                condition3.signal()
            }
            catch let e as C8oException {
                exception = e
                // Signal
                syncMutex3[0] = true
                condition3.signal()
            }
            catch let e as NSError {
                error = e
                // Signal
                syncMutex3[0] = true
                condition3.signal()
            }
        }
        // Waiting for signal
        if(!syncMutex3[0]){
            condition3.wait()
        }
        condition3.unlock()
        
        if (error != nil) {
            throw error!
        } else if (exception != nil) {
            throw exception!
        }
        
        // Lock
        var syncMutex4: [Bool] = [Bool]()
        syncMutex4.append(false)
        let condition4: NSCondition = NSCondition()
        condition4.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            documentId = createdDocument!.documentID
            currentRevision = createdDocument!.currentRevisionID!
            // Signal
            syncMutex4[0] = true
            condition4.signal()
        }
        // Waiting for signal
        if(!syncMutex4[0]){
            condition4.wait()
        }
        condition4.unlock()
        
        return FullSyncDocumentOperationResponse(documentId: documentId!, documentRevision: currentRevision!, operationStatus: true)
        
    }
    func handlePutAttachmentRequest(_ databaseName : String, docid : String, attachmentName : String, attachmentType : String, attachmentContent : Data) throws -> Any {
        var document : CBLDocument? = nil
        var newRev : CBLUnsavedRevision? = nil
        var error : NSError? = nil
        
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do{
                let fullSyncDatabase : C8oFullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName)
                
                // Gets the document from the local database
                document = fullSyncDatabase.getDatabase()?.existingDocument(withID: docid)
                
                if(document !=  nil){
                    newRev = (document!.currentRevision?.createRevision())!
                    newRev!.setAttachmentNamed(attachmentName, withContentType: attachmentType, content: attachmentContent)
                    do{
                        try newRev!.save()
                        // Signal
                        syncMutex[0] = true
                        condition.signal()
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
                // Signal
                syncMutex[0] = true
                condition.signal()
            }
            
        }
        
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        if(error != nil){
            throw error!
        }
        
        return FullSyncDocumentOperationResponse(documentId: (document?.documentID)!, documentRevision: (document?.currentRevisionID)!, operationStatus: true)
        
    }
    
    func handleDeleteAttachmentRequest(_ databaseName : String, docid : String, attachmentName : String) throws ->Any{
        var document : CBLDocument? = nil
        var newRev : CBLUnsavedRevision? = nil
        var error : NSError? = nil
        
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do{
                let fullSyncDatabase : C8oFullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName)
                
                // Gets the document from the local database
                document = fullSyncDatabase.getDatabase()?.existingDocument(withID: docid)
                
                if(document !=  nil){
                    newRev = (document!.currentRevision?.createRevision())!
                    newRev!.removeAttachmentNamed(attachmentName)
                    do{
                        try newRev!.save()
                        // Signal
                        syncMutex[0] = true
                        condition.signal()
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
                // Signal
                syncMutex[0] = true
                condition.signal()
            }
            
        }
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        if(error != nil){
            throw error!
        }
        return FullSyncDocumentOperationResponse(documentId: (document?.documentID)!, documentRevision: (document?.currentRevisionID)!, operationStatus: true)
    }
    func handleAllDocumentsRequest(_ databaseName: String, parameters: Dictionary<String, Any>) throws -> Any? {
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        var query: CBLQuery? = nil
        // Creates the fullSync query and add parameters to it
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try! self.getOrCreateFullSyncDatabase(databaseName)
            query = fullSyncDatabase!.getDatabase()!.createAllDocumentsQuery()
            // Signal
            syncMutex[0] = true
            condition.signal()
        }
        
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        do {
            try C8oFullSyncCbl.addParametersToQuery(query!, parameters: parameters as Dictionary<String, AnyObject>)
        } catch let e as NSError {
            throw C8oException(message: C8oExceptionMessage.addparametersToQuery(), exception: e)
        }
        
        // Runs the query
        var result: CBLQueryEnumerator? = nil
        do {
            // Lock
            var syncMutex2: [Bool] = [Bool]()
            syncMutex2.append(false)
            let condition2: NSCondition = NSCondition()
            condition2.lock()
            
            var err: NSError? = nil
            (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                do {
                    result = try query!.run()
                    // Signal
                    syncMutex2[0] = true
                    condition2.signal()
                }
                catch let e as NSError {
                    err = e
                    // Signal
                    syncMutex2[0] = true
                    condition2.signal()
                }
                
            }
            // Waiting for signal
            if(!syncMutex2[0]){
                condition2.wait()
            }
            condition2.unlock()
            
            if (err != nil) {
                throw err!
            }
        } catch let e as NSError {
            throw C8oException(message: C8oExceptionMessage.couchRequestAllDocuments(), exception: e)
        }
        
        return result
    }
    
    func handleGetViewRequest(_ databaseName: String, ddocName: String?, viewName: String?, parameters: Dictionary<String, Any>) throws -> CBLQueryEnumerator? {
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        // CBL Thread
        var fullSyncDatabase: C8oFullSyncDatabase? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            fullSyncDatabase = try! self.getOrCreateFullSyncDatabase(databaseName)
            // Signal
            syncMutex[0] = true
            condition.signal()
        }
        
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
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
            try C8oFullSyncCbl.addParametersToQuery(query, parameters: parameters as Dictionary<String, AnyObject>)
        } catch {
            throw C8oException(message: C8oExceptionMessage.addparametersToQuery())
        }
        
        // Lock
        var syncMutex2: [Bool] = [Bool]()
        syncMutex2.append(false)
        let condition2: NSCondition = NSCondition()
        condition2.lock()
        
        // Runs the query
        var bool = false
        var result: CBLQueryEnumerator? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            do {
                result = try query.run()
                // Signal
                syncMutex2[0] = true
                condition2.signal()
            } catch {
                bool = true
                // Signal
                syncMutex2[0] = true
                condition2.signal()
            }
        }
        // Waiting for signal
        if(!syncMutex2[0]){
            condition2.wait()
        }
        condition2.unlock()
        if (bool) {
            throw C8oException(message: C8oExceptionMessage.couchRequestGetView())
        }
        return result
    }
    
    func handleSyncRequest(_ databaseName: String, parameters: Dictionary<String, Any>, c8oResponseListener: C8oResponseListener) throws -> VoidResponse? {
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        try! fullSyncDatabase.startAllReplications(parameters, c8oResponseListener: c8oResponseListener)
        return VoidResponse.getInstance()
    }
    
    func handleReplicatePullRequest(_ databaseName: String, parameters: Dictionary<String, Any>, c8oResponseListener: C8oResponseListener) throws -> VoidResponse? {
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        try! fullSyncDatabase.startPullReplication(parameters, c8oResponseListener: c8oResponseListener)
        return VoidResponse.getInstance()
    }
    
    func handleReplicatePushRequest(_ databaseName: String, parameters: Dictionary<String, Any>, c8oResponseListener: C8oResponseListener) throws -> VoidResponse? {
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        try! fullSyncDatabase.startPushReplication(parameters, c8oResponseListener: c8oResponseListener)
        return VoidResponse.getInstance()
    }
    
    func handleResetDatabaseRequest(_ databaseName: String) throws -> FullSyncDefaultResponse? {
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            _ = try self.handleDestroyDatabaseRequest(databaseName)
            // Signal
            syncMutex[0] = true
            condition.signal()
        }
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        
        return try handleCreateDatabaseRequest(databaseName)
    }
    
    func handleCreateDatabaseRequest(_ databaseName: String) throws -> FullSyncDefaultResponse? {
        let _: C8oFullSyncDatabase = try getOrCreateFullSyncDatabase(databaseName)
        return FullSyncDefaultResponse(operationStatus: true)
    }
    
    func handleDestroyDatabaseRequest(_ databaseName: String) throws -> FullSyncDefaultResponse? {
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            try self.getOrCreateFullSyncDatabase(databaseName).deleteDb()
            // Signal
            syncMutex[0] = true
            condition.signal()
        }
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        let localDatabaseName: String = databaseName + localSuffix!
        if let _ = fullSyncDatabases[localDatabaseName] {
            fullSyncDatabases.removeValue(forKey: localDatabaseName)
        }
        return FullSyncDefaultResponse(operationStatus: true)
    }
    
    fileprivate func compileView (_ db: CBLDatabase, viewName: String, viewProps: Dictionary<String, NSObject>?) -> CBLView? {
        
        var language: String? = viewProps!["language"] as? String
        if (language == nil) {
            language = "javascript"
        }
        let mapSource: String? = viewProps!["map"] as? String
        if (mapSource == nil) {
            return nil
        }
        
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        var mapBlock: CBLMapBlock? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            CBLRegisterJSViewCompiler()
            mapBlock = CBLView.compiler()?.compileMapFunction(mapSource!, language: language!)
            // Signal
            syncMutex[0] = true
            condition.signal()
            
        }
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        if (mapBlock == nil) {
            return nil
        }
        
        var mapID = db.name + ":" + viewName + ":" + String(mapSource!.hash)
        
        let reduceSource: String? = viewProps!["reduce"] as? String
        var reduceBlock: CBLReduceBlock? = nil
        if (reduceSource != nil) {
            // Lock
            var syncMutex2: [Bool] = [Bool]()
            syncMutex2.append(false)
            let condition2: NSCondition = NSCondition()
            condition2.lock()
            (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                reduceBlock = CBLView.compiler()!.compileReduceFunction(reduceSource!, language: language!)
                // Signal
                syncMutex2[0] = true
                condition2.signal()
            }
            
            // Waiting for signal
            if(!syncMutex2[0]){
                condition.wait()
            }
            condition2.unlock()
            
            if (reduceBlock == nil) {
                return nil
            }
            mapID = mapID + ":" + String(reduceSource!.hash)
        }
        // Lock
        var syncMutex3: [Bool] = [Bool]()
        syncMutex3.append(false)
        let condition3: NSCondition = NSCondition()
        condition3.lock()
        var view: CBLView?
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            view = db.viewNamed(viewName)
            view!.setMapBlock(mapBlock!, reduce: reduceBlock, version: mapID)
            self.mapVersions[db.name + ":" + viewName] = mapID
            // Signal
            syncMutex3[0] = true
            condition3.signal()
        }
        // Waiting for signal
        if(!syncMutex3[0]){
            condition3.wait()
        }
        condition3.unlock()
        
        let collation: String? = viewProps!["collation"] as? String
        if ("raw" == collation) {
            // TODO
            fatalError("TODO ... collation not found for the moment within IOS")
        }
        return view
    }
    
    fileprivate func checkAndCreateJavaScriptView(_ database: CBLDatabase, ddocName: String, viewName: String) -> CBLView? {
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        
        let tdViewName: String = ddocName + "/" + viewName
        var view: CBLView? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            view = database.existingViewNamed(tdViewName)
            // Signal
            syncMutex[0] = true
            condition.signal()
        }
        
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        // Lock
        var syncMutex2: [Bool] = [Bool]()
        syncMutex2.append(false)
        let condition2: NSCondition = NSCondition()
        condition2.lock()
        
        var rev: CBLRevision? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            rev = database.existingDocument(withID: String(format: "_design/%@", ddocName))?.currentRevision
            // Signal
            syncMutex2[0] = true
            condition2.signal()
        }
        
        // Waiting for signal
        if(!syncMutex2[0]){
            condition2.wait()
        }
        condition2.unlock()
        
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
    
    fileprivate static func addParametersToQuery(_ query: CBLQuery, parameters: Dictionary<String, AnyObject>) throws {
        
        for fullSyncParameter in FullSyncRequestParameter.values() {
            var objectParameterValue: AnyObject? = nil
            if (fullSyncParameter.isJson) {
                objectParameterValue = C8oUtils.getParameterObjectValue(parameters, name: fullSyncParameter.name, useName: true) as AnyObject?
                
            } else {
                objectParameterValue = C8oUtils.getParameterStringValue(parameters, name: fullSyncParameter.name, useName: true) as AnyObject?
            }
            if (objectParameterValue != nil) {
                fullSyncParameter.action(query, objectParameterValue!)
            }
        }
    }
    
    static func mergeProperties(_ newProperties: inout Dictionary<String, Any>, oldProperties: Dictionary<String, Any>) {
        for old in oldProperties {
            // let oldProperty = old
            let oldPropertyKey = old.0
            let oldPropertyValue = old.1
            
            // let newPropertyValue : Any
            if let newPropertyValue = newProperties[oldPropertyKey] {
                if var a = newPropertyValue as? Dictionary<String, Any>, let b = oldPropertyValue as? Dictionary<String, Any> {
                    mergeProperties(&a, oldProperties: b)
                    newProperties[oldPropertyKey] = a as Any
                } else if var a = newPropertyValue as? [Any], let b = oldPropertyValue as? [Any] {
                    C8oFullSyncCbl.mergeArrayProperties(&a, oldArray: b)
                    newProperties[oldPropertyKey] = a as Any
                } else {
                    
                }
            } else {
                newProperties[oldPropertyKey] = oldPropertyValue
            }
        }
    }
    
    static func mergeArrayProperties(_ newArray: inout [Any], oldArray: [Any]) {
        let newArraySize = newArray.count
        let oldArraySize = oldArray.count
        for i in 0..<oldArraySize {
            var newArrayValue: Any? = nil
            if (i < newArraySize) {
                newArrayValue = newArray[i]
            }
            let oldArrayValue = oldArray[i]
            
            if (newArrayValue != nil) {
                if var e = newArrayValue as? Dictionary<String, Any>, let f = oldArrayValue as? Dictionary<String, Any> {
                    mergeProperties(&e, oldProperties: f)
                    newArrayValue = e as Any
                } else if var g = newArrayValue as? [Any], let h = oldArrayValue as? [Any] {
                    mergeArrayProperties(&g, oldArray: h)
                    newArrayValue = g as Any
                } else {
                    
                }
            } else {
                newArray.append(oldArrayValue)
            }
        }
    }
    
    internal func getDocucmentFromDatabase(_ c8o: C8o, databaseName: String, documentId: String) throws -> CBLDocument {
        var c8oFullSyncDatabase: C8oFullSyncDatabase
        do {
            c8oFullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName)
        } catch {
            throw C8oException(message: C8oExceptionMessage.fullSyncGetOrCreateDatabase(databaseName))
        }
        return (c8oFullSyncDatabase.getDatabase()?.existingDocument(withID: documentId))!
    }
    
    internal static func overrideDocument(_ document: CBLDocument, properties: Dictionary<String, NSObject>) throws {
        var propertiesMutable = properties
        let currentRevision: CBLSavedRevision? = document.currentRevision
        if (currentRevision != nil) {
            propertiesMutable[C8oFullSync.FULL_SYNC__REV] = (currentRevision?.revisionID! as NSObject?)
        }
        
        do {
            try document.putProperties(propertiesMutable)
        }
        catch {
            throw C8oException(message: "TODO")
        }
    }
    
    func getResponseFromLocalCache(_ c8oCallRequestIdentifier: String) throws -> C8oLocalCacheResponse? {
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(C8o.LOCAL_CACHE_DATABASE_NAME)
        let condition: NSCondition = NSCondition()
        var locker: Bool = true
        condition.lock()
        var localCacheDocument: CBLDocument? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            localCacheDocument = fullSyncDatabase.getDatabase()?.existingDocument(withID: c8oCallRequestIdentifier)
            locker = false
            condition.signal()
        }
        if(locker){
            condition.wait()
        }
        
        condition.unlock()
        if (localCacheDocument == nil) {
            throw C8oUnavailableLocalCacheException(message: C8oExceptionMessage.localCacheDocumentJustCreated())
        }
        
        let response = localCacheDocument?.property(forKey: C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE)
        let responseType = localCacheDocument?.property(forKey: C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE)
        let expirationDate = localCacheDocument?.property(forKey: C8o.LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE)
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
                let currentTime = C8oUtils.getUnixEpochTime()
                if (expirationDateLong < currentTime!) {
                    throw C8oUnavailableLocalCacheException(message: C8oExceptionMessage.timeToLiveExpired())
                }
            } else {
                throw C8oException(message: C8oExceptionMessage.InvalidLocalCacheResponseInformation())
            }
        }
        return C8oLocalCacheResponse(response: responseString!, responseType: responseTypeString!, expirationDate: expirationDateLong)
    }
    
    func saveResponseToLocalCache(_ c8oCallRequestIdentifier: String, localCacheResponse: C8oLocalCacheResponse) throws {
        // Lock
        var syncMutex: [Bool] = [Bool]()
        syncMutex.append(false)
        let condition: NSCondition = NSCondition()
        condition.lock()
        var e: C8oException? = nil
        let fullSyncDatabase: C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(C8o.LOCAL_CACHE_DATABASE_NAME)
        var localCacheDocument: CBLDocument? = nil
        (c8o!.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            localCacheDocument = fullSyncDatabase.getDatabase()?.document(withID: c8oCallRequestIdentifier)
            var properties: Dictionary<String, NSObject> = Dictionary<String, NSObject>()
            properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE] = localCacheResponse.getResponse() as NSObject
            properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE] = localCacheResponse.getResponseType() as NSObject
            if (localCacheResponse.getExpirationDate() > 0) {
                properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE] = localCacheResponse.getExpirationDate() as NSObject
            }
            let currentRevision: CBLSavedRevision? = localCacheDocument!.currentRevision
            if (currentRevision != nil) {
                properties[C8oFullSyncCbl.FULL_SYNC__REV] = currentRevision?.revisionID! as NSObject?
            }
            do {
                try localCacheDocument!.putProperties(properties)
                // Signal
                syncMutex[0] = true
                condition.signal()
            } catch {
                e = C8oException(message: "Can't save response to local cache")
                // Signal
                syncMutex[0] = true
                condition.signal()
            }
        }
        
        // Waiting for signal
        if(!syncMutex[0]){
            condition.wait()
        }
        condition.unlock()
        
        if(e != nil){
            throw e!
        }
    }
    
    internal override func addFullSyncChangeListener(_ db: String?, listener: C8oFullSyncChangeListener) throws {
        var _db = db
        if (_db == nil || _db!.isEmpty) {
            _db = c8o!.defaultDatabaseName
        }
        
        if let _ = fullSyncChangeListeners[_db!] {
        } else {
            fullSyncChangeListeners[_db!] = Set<C8oFullSyncChangeListener>()
            let evtHandler = {(notification: Notification) -> () in
                var changes: JSON = [:]
                var docs = Array<JSON>()
                changes["isExternal"].boolValue = notification.userInfo!["external"] as! Bool
                
                for change in notification.userInfo!["changes"] as! Array<CBLDatabaseChange> {
                    var doc: JSON = [:]
                    doc["id"].stringValue = change.documentID
                    doc["isConflict"].boolValue = change.inConflict
                    doc["isCurrentRevision"].boolValue = change.isCurrentRevision
                    doc["revisionId"].stringValue = change.revisionID!
                    if (change.source != nil) {
                        doc["sourceUrl"].stringValue = change.source!.absoluteString
                    }
                    docs.append(doc)
                }
                changes["changes"] = JSON(docs)
                for handler in self.fullSyncChangeListeners[_db!]! {
                    handler.handler(changes)
                }
            }
            NotificationCenter.default.addObserver(forName: NSNotification.Name.cblDatabaseChange, object: try getOrCreateFullSyncDatabase(_db!).getDatabase(), queue: nil, using: evtHandler)
            cblChangeListeners[_db!] = evtHandler
        }
        
        fullSyncChangeListeners[_db!]!.insert(listener)
    }
    
    internal override func removeFullSyncChangeListener(_ db: String?, listener: C8oFullSyncChangeListener) throws {
        var _db = db
        if (_db == nil || _db!.isEmpty) {
            _db = c8o!.defaultDatabaseName
        }
        
        if var listeners = fullSyncChangeListeners[_db!] {
            listeners.remove(listener)
            if (listeners.isEmpty) {
                let db = try getOrCreateFullSyncDatabase(_db!).getDatabase()
                NotificationCenter.default.removeObserver(db as Any, name: NSNotification.Name.cblDatabaseChange, object: nil)
            }
        }
    }
}


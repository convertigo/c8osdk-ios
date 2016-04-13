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
import CouchbaseLite

class C8oFullSyncCbl : C8oFullSync{
    private static let ATTACHMENT_PROPERTY_KEY_CONTENT_URL : String = "content_url"
    private var manager : CBLManager?
    private var fullSyncDatabases : Dictionary<String, C8oFullSyncDatabase>?
    
    internal override init(c8o: C8o) {
        super.init(c8o: c8o)
        self.fullSyncDatabases = Dictionary<String, C8oFullSyncDatabase>()
        self.manager = CBLManager()
    }
    
    private func getOrCreateFullSyncDatabase(databaseName : String) throws -> C8oFullSyncDatabase{
        let localDatabaseName : String = databaseName + localSuffix!
        if let _ = fullSyncDatabases?[localDatabaseName] {
            
        } else {
            fullSyncDatabases![localDatabaseName] = try! C8oFullSyncDatabase(c8o: self.c8o!, manager: self.manager!, databaseName: databaseName, fullSyncDatabases: fullSyncDatabaseUrlBase!,localSuffix:  localSuffix!)
        }
        return fullSyncDatabases![localDatabaseName]!
    }
    
    internal func handleFullSyncResponse(response : NSObject, listener : C8oResponseListener) throws->AnyObject?{
        var response = response
        let maVar : C8oJSON = C8oJSON()
        response = super.handleFullSyncResponse(response, listener: listener)
        /*if(response.isMemberOfClass(Void)){
        return response
        }*/
        
        if(listener is C8oResponseJsonListener){
            if(response.isMemberOfClass(CBLDocument)){
                maVar.myJSON = C8oFullSyncTranslator.documentToJson(response as! CBLDocument)
                return maVar
            }
            else if (response.isMemberOfClass(FullSyncDocumentOperationResponse)){
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDocumentOperationResponseToJson((response as! FullSyncDocumentOperationResponse))
                return maVar
            }
            else if(response.isMemberOfClass(CBLQueryEnumerator)){
                do{
                    maVar.myJSON = try C8oFullSyncTranslator.queryEnumeratorToJson(response as! CBLQueryEnumerator)
                }
                catch let e as C8oException{
                    throw C8oException(message: C8oExceptionMessage.queryEnumeratorToJSON(), exception: e)
                }
                
            }
            else if response.isMemberOfClass(FullSyncDefaultResponse){
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDefaultResponseToJson(response as! FullSyncDefaultResponse)
                return maVar
            }
            else if(response.isMemberOfClass(C8oJSON)){
                return response
            } else {
                fatalError("handleFullSyncResponse function must implement throwing error")
                //throw C8oException(C8oExceptionMessage.illegalArgumentIncompatibleListener(listener., responseType: <#T##String#>)
            }
        }
        else if(listener is C8oResponseXmlListener){
            if(response.isMemberOfClass(CBLDocument)){
                return C8oFullSyncTranslator.documentToXml(response as! CBLDocument)
            }
            else if(response.isMemberOfClass(FullSyncDocumentOperationResponse)){
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDocumentOperationResponseToJson(response as! FullSyncDocumentOperationResponse)
                return maVar
            }
            else if(response.isMemberOfClass(CBLQueryEnumerator)){
                do{
                    return try C8oFullSyncTranslator.queryEnumeratorToXml(response as! CBLQueryEnumerator)
                }
                catch let e as C8oException{
                    throw C8oException(message: C8oExceptionMessage.queryEnumeratorToXML(), exception: e)
                }
            }
            else if(response.isMemberOfClass(FullSyncDefaultResponse)){
                maVar.myJSON = C8oFullSyncTranslator.fullSyncDefaultResponseToJson(response as! FullSyncDefaultResponse)
                return maVar
            }
            else{
                //throw
                fatalError("must be implemented")
            }
        }
        else if(listener is C8oResponseCblListener){
            if(response.isMemberOfClass(CBLDocument) || response.isMemberOfClass(CBLQueryEnumerator)){
                return response
            }
            else{
                //throw
                fatalError("must be implemented")
            }
            
        }
        else{
            //throw
            let c : AnyObject? = nil
            return c
            fatalError("must be implemented")
            
        }
        //TO be removen
        let c : AnyObject? = nil
        return c
    }
    
    func handleGetDocumentRequest(fullSyncDatatbaseName: String, docid: String, parameters: Dictionary<String, NSObject>)throws -> CBLDocument {
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(fullSyncDatatbaseName)
        
        // Gets the document from the local database
        let document : CBLDocument? = fullSyncDatabase.getDatabase()?.existingDocumentWithID(docid)
        // If there are attachments, compute for each one the url to local storage and add it to the attachment descriptor
        if (document != nil) {
            
            let attachments : Dictionary<String, NSObject>? = document?.propertyForKey(C8oFullSync.FULL_SYNC__ATTACHMENTS) as?  Dictionary<String, NSObject>
            
            if (attachments != nil) {
                let rev : CBLRevision = (document?.currentRevision)!
                
                for attachmentName in  (attachments?.keys)!{
                    let attachment : CBLAttachment  = rev.attachmentNamed(attachmentName)!
                    let url : NSURL  = attachment.contentURL!
                    var attachmentDesc : Dictionary<String, NSObject>? = (attachments![attachmentName] as? Dictionary<String, NSObject>)!
                    attachmentDesc![C8oFullSyncCbl.ATTACHMENT_PROPERTY_KEY_CONTENT_URL] =  String(url).stringByRemovingPercentEncoding
                }
            }
        } else {
            throw C8oException(message: C8oExceptionMessage.ressourceNotFound("requested document \"" + docid + "\""))
        }
        return document!
    }
    
    func handleDeleteDocumentRequest(DatatbaseName: String, docid: String, parameters: Dictionary<String, NSObject>)throws -> FullSyncDocumentOperationResponse? {
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(DatatbaseName)
        //TODO...
        fatalError("Must be implemented")
        let revParameterValue : String? = C8oUtils.getParameterStringValue(parameters, name: /*FullSyncEnum.FullSyncDeleteDocumentParameter.REV.name*/ "TODO", useName: false)!
        
        let document = fullSyncDatabase.getDatabase()?.existingDocumentWithID(docid)
        if (document == nil) {
            
            //throw new C8oRessourceNotFoundException(C8oExceptionMessage.toDo())
            fatalError("must implement")
            
        }
        
        let documentRevision : String = (document?.currentRevisionID)!
        
        // If the revision is specified then checks if this is the right revision
        if (revParameterValue != nil && revParameterValue != documentRevision) {
            // throw C8oRessourceNotFoundException(C8oExceptionMessage.couchRequestInvalidRevision())
            fatalError()
        }
        var deleted : Bool
        
        
        do {
            try document?.deleteDocument()
            deleted = true
        } catch let e as NSError {
            deleted = false
            throw C8oException(message: C8oExceptionMessage.couchRequestDeleteDocument(), exception: e)
            
        }
        catch{
            fatalError("error not handled")
        }
        
        return FullSyncDocumentOperationResponse(documentId: docid, documentRevision: documentRevision, operationStatus: deleted)
    }
    
    func handlePostDocumentRequest(databaseName: String, fullSyncPolicy: FullSyncPolicy, parameters: Dictionary<String, NSObject>)throws -> NSObject? {
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        // Gets the subkey separator parameter
        var subkeySeparatorParameterValue : String? = C8oUtils.getParameterStringValue(parameters, name: C8o.FS_SUBKEY_SEPARATOR, useName: false)!
        if (subkeySeparatorParameterValue == nil) {
            subkeySeparatorParameterValue = "."
        }
        
        // Filters and modifies wrong properties
        var newProperties : Dictionary<String, AnyObject> = Dictionary<String, NSObject>()
        for parameter in parameters {
            var parameterName : String = parameter.0
            
            // Ignores parameters beginning with "__" or "_use_"
            if (!parameterName.hasPrefix("__") && !parameterName.hasPrefix("_use_")) {
                var objectParameterValueTemp = parameter.1
                var objectParameterValue : AnyObject
                
                do {
                    let objectParameterValuetemp2 = JSON(String(objectParameterValueTemp))
                    let mavar : C8oJSON = C8oJSON()
                    mavar.myJSON = objectParameterValuetemp2
                    objectParameterValue = mavar
                    /*if (objectParameterValue.isKindOfClass(JSON) {
                    objectParameterValue = ObjectMapper().readValue(objectParameterValue.toString(), LinkedHashMap.class)
                    } else if (objectParameterValue.isKindOfClass(JSONArray)) {
                    objectParameterValue = new ObjectMapper().readValue(objectParameterValue.toString(), ArrayList.class)
                    }*/
                } catch let e as NSError {
                    //throw C8oException(message: C8oExceptionMessage.InvalidParameterValue(parameterName, details: String(objectParameterValue)), exception: e)
                }
                
                // !!!!!!!!!!!!!! Becarefull here cause a possible trouble due to non use of pattern.quote in swift...
                // Checks if the parameter name is splittable
                let paths : [String] = parameterName.componentsSeparatedByString(subkeySeparatorParameterValue!)
                
                if (paths.count > 1) {
                    // The first substring becomes the key
                    parameterName = paths[0]
                    // Next substrings create a hierarchy which will becomes json subkeys
                    var count : Int = paths.count - 1
                    while (count > 0) {
                        var tmpObject : Dictionary<String, AnyObject>  = Dictionary<String, AnyObject>()
                        let mavar2 : C8oJSON = C8oJSON()
                        mavar2.myJSON = (objectParameterValue as! C8oJSON).myJSON
                        tmpObject[paths[count]] =  mavar2
                        objectParameterValue = tmpObject
                        count = count - 1
                    }
                    let existProperty : AnyObject? = newProperties[parameterName]
                    if let e = existProperty as! Dictionary<NSObject,NSObject>? {
                        //TODO...
                        //mergeProperties(objectParameterValue, existProperty)
                    }
                    
                    
                }
                
                newProperties[parameterName] =  objectParameterValue
            }
        }
        
        // Execute the query depending to the policy
        
        let createdDocument : CBLDocument? = nil//try! fullSyncPolicy.postDocument(fullSyncDatabase.getDatabase()!, newProperties: newProperties)
        let documentId : String = createdDocument!.documentID
        let currentRevision : String = createdDocument!.currentRevisionID!
        return FullSyncDocumentOperationResponse(documentId: documentId, documentRevision: currentRevision, operationStatus: true)
    }
    
    func handleAllDocumentsRequest(databaseName: String, parameters: Dictionary<String, NSObject>)throws -> NSObject? {
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        // Creates the fullSync query and add parameters to it
        let query : CBLQuery = fullSyncDatabase.getDatabase()!.createAllDocumentsQuery()
        do{
            //addParametersToQuery(query, parameters)
        }catch{
            // throw C8oException(C8oExceptionMessage.addparametersToQuery(), e)
        }
        
        // Runs the query
        var result : CBLQueryEnumerator? = nil
        do {
            result = try query.run()
        } catch{
            //throw new C8oException(C8oExceptionMessage.couchRequestAllDocuments(), e)
        }
        
        return result
    }
    
    func handleGetViewRequest(databaseName: String, ddocName: String?, viewName : String?, parameters: Dictionary<String, NSObject>) throws -> CBLQueryEnumerator? {
        
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        // Gets the view depending to its programming language (Javascript / Java)
        let view : CBLView?
        if (ddocName != nil) {
            // Javascript view
            view = checkAndCreateJavaScriptView(fullSyncDatabase.getDatabase()!, ddocName: ddocName!, viewName: viewName!)
        } else {
            // Java view
            view = fullSyncDatabase.getDatabase()?.viewNamed(viewName!)
        }
        if (view == nil) {
            throw C8oException(message: C8oExceptionMessage.illegalArgumentNotFoundFullSyncView(viewName!, databaseName: fullSyncDatabase.getDatabaseName()))
        }
        
        // Creates the fullSync query and add parameters to it
        let query : CBLQuery = view!.createQuery()
        do {
            try C8oFullSyncCbl.addParametersToQuery(query, parameters: parameters)
        } catch {
            //TODO...
            throw C8oException(message: C8oExceptionMessage.addparametersToQuery())
        }
        
        // Runs the query
        let result : CBLQueryEnumerator
        do {
            result = try query.run()
        } catch {
            //TODO...
            throw C8oException(message: C8oExceptionMessage.couchRequestGetView())
        }
        return result
    }
    
    func handleSyncRequest(databaseName: String, parameters: Dictionary<String, NSObject>, c8oResponseListener: C8oResponseListener)throws -> VoidResponse? {
        
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        try! fullSyncDatabase.startAllReplications(parameters, c8oResponseListener: c8oResponseListener)
        
        return VoidResponse.getInstance()
    }
    
    func handleReplicatePullRequest(databaseName: String, parameters: Dictionary<String, NSObject>, c8oResponseListener: C8oResponseListener) throws -> VoidResponse? {
        
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        try! fullSyncDatabase.startPullReplication(parameters, c8oResponseListener: c8oResponseListener)
        
        return VoidResponse.getInstance()
    }
    
    func handleReplicatePushRequest(databaseName: String, parameters: Dictionary<String, NSObject>, c8oResponseListener: C8oResponseListener) throws -> VoidResponse? {
        
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        
        try! fullSyncDatabase.startPushReplication(parameters, c8oResponseListener: c8oResponseListener)
        
        return VoidResponse.getInstance()
    }
    
    func handleResetDatabaseRequest(databaseName: String) throws -> FullSyncDefaultResponse? {
        let localDatabaseName = databaseName + localSuffix!
        if let _ = fullSyncDatabases![localDatabaseName] {
            fullSyncDatabases?.removeValueForKey(localDatabaseName)
        }
        
        do{
            
        }catch{
            //TODO...
            C8oException(message: "TODO")
        }
        return FullSyncDefaultResponse(operationStatus: true)
    }
    
    func handleCreateDatabaseRequest(databaseName: String)throws->FullSyncDefaultResponse? {
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName)
        return FullSyncDefaultResponse(operationStatus: true)
    }
    
    func handleDestroyDatabaseRequest(databaseName : String)throws->FullSyncDefaultResponse? {
        let localDatabaseName : String = databaseName + localSuffix!
        if let _ = fullSyncDatabases![localDatabaseName]{
            fullSyncDatabases?.removeValueForKey(localDatabaseName)
        }
        
        do {
            let db : CBLDatabase? = try self.manager?.databaseNamed(databaseName + localSuffix!)
            if (db != nil) {
                try db?.deleteDatabase()
            }
        } catch {
            C8oException(message: "TODO")
        }
        return FullSyncDefaultResponse(operationStatus: true);
    }
    
    private func compileView(db : CBLDatabase, viewName : String, viewProps : Dictionary<String, NSObject>?)->CBLView?{
        var language : String? = viewProps!["language"] as? String
        if(language == nil){
            language = "javascript"
        }
        let mapSource : String? = viewProps!["map"] as? String
        if (mapSource == nil){
            return nil
        }
        
        let mapBlock : CBLMapBlock? = CBLView.compiler()?.compileMapFunction(mapSource!, language: language!)
        if(mapBlock == nil){
            return nil
        }
        
        let reduceSource : String? = viewProps!["reduce"] as? String
        var reduceBlock : CBLReduceBlock? = nil
        if(reduceSource != nil){
            reduceBlock = CBLView.compiler()?.compileReduceFunction(reduceSource!, language: language!)
            if(reduceBlock == nil){
                return nil
            }
        }
        
        let view : CBLView = db.viewNamed(viewName)
        view.setMapBlock(mapBlock!, reduceBlock: reduceBlock, version: "1")
        let collation : String? = viewProps!["collation"] as? String
        if("raw" == collation){
            //TODO....
            fatalError("TODO ... collation not found for the moment within IOS")
        }
        return view
    }
    
    private func checkAndCreateJavaScriptView(database : CBLDatabase, ddocName : String, viewName : String)->CBLView?{
        let tdViewName : String = ddocName + "/" + viewName
        var view : CBLView? = database.existingViewNamed(tdViewName)
        
        if(view == nil || view!.mapBlock == nil){
            //TODO...
            fatalError("must be implemented")
            let rev : CBLRevision? //= database.documentWithID(String(format: "_design/%s", ddocName))?.revisionWithID()
            if (rev == nil){
                return nil
            }
            
            let views : Dictionary<String, NSObject>? = rev?.properties!["views"] as? Dictionary<String, NSObject>
            let viewProps : Dictionary<String, NSObject>? = views![viewName] as? Dictionary<String, NSObject>
            if(viewProps == nil){
                return nil
            }
            
            view = compileView(database, viewName: tdViewName, viewProps: viewProps)
            if(view == nil){
                return nil
            }
            
            return view
        }
        return view
    }
    
    private static func addParametersToQuery(query : CBLQuery, parameters : Dictionary<String, NSObject>) throws{
        //TODO...
        fatalError("must be Implemented")
        /*for fullSyncParameter in FullSyncEnum.FullSyncRequestable{
            
        }*/
    }
    
    static func mergeProperties( newProperties : Dictionary<String, NSObject>, oldProperties : Dictionary<String, NSObject>){
        
    }
    
    public func getDocucmentFromDatabase(c8o :C8o, databaseName : String, documentId : String)throws->CBLDocument {
        var c8oFullSyncDatabase : C8oFullSyncDatabase
        do {
            c8oFullSyncDatabase = try self.getOrCreateFullSyncDatabase(databaseName);
        } catch{
            throw C8oException(message: C8oExceptionMessage.fullSyncGetOrCreateDatabase(databaseName))
        }
        return (c8oFullSyncDatabase.getDatabase()?.documentWithID(documentId))!
    }
    
    public static func overrideDocument(document : CBLDocument, var properties : Dictionary<String, NSObject>)throws{
        let currentRevision : CBLSavedRevision? = document.currentRevision
        if (currentRevision != nil){
            properties[C8oFullSync.FULL_SYNC__REV] = currentRevision?.revisionID
        }
        
        do{
            try document.putProperties(properties)
        }
        catch{
            throw C8oException(message: "TODO")
        }
    }
    
    func getResponseFromLocalCache(c8oCallRequestIdentifier: String) throws -> C8oLocalCacheResponse? {
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(C8o.LOCAL_CACHE_DATABASE_NAME)
        let localCacheDocument : CBLDocument? = fullSyncDatabase.getDatabase()?.existingDocumentWithID(c8oCallRequestIdentifier)
        
        if(localCacheDocument == nil){
            fatalError("todo")
        }
        
        let response  = localCacheDocument?.propertyForKey(C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE)
        let responseType  = localCacheDocument?.propertyForKey(C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE)
        let expirationDate  = localCacheDocument?.propertyForKey(C8o.LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE)
        var responseString : String? = nil
        var responseTypeString : String? = nil
        var expirationDateLong : Int = -1
        
        if(response != nil){
            if let e = response as! String?{
                responseString = e
            }
        }
        else{
            throw C8oException(message: C8oExceptionMessage.InvalidLocalCacheResponseInformation())
        }
        if(responseType != nil){
            if let e = responseType as! String?{
                responseTypeString = e
            }
        }
        else{
            throw C8oException(message: C8oExceptionMessage.InvalidLocalCacheResponseInformation())
        }
        if(expirationDate != nil){
            if let e = expirationDate as! Int?{
                expirationDateLong = e
                let currentTime = NSDate().timeIntervalSince1970 * 1000
                if(Double(expirationDateLong) < currentTime){
                    throw C8oException(message: C8oExceptionMessage.timeToLiveExpired())
                }
            }
            else{
                throw C8oException(message: C8oExceptionMessage.InvalidLocalCacheResponseInformation())
            }
        }
        return C8oLocalCacheResponse(response: responseString!, responseType: responseTypeString!, expirationDate: expirationDateLong)
    }
    
    func saveResponseToLocalCache(c8oCalRequestIdentifier : String, localCacheResponse : C8oLocalCacheResponse) throws{
        
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(C8o.LOCAL_CACHE_DATABASE_NAME);
        let localCacheDocument : CBLDocument =  (fullSyncDatabase.getDatabase()?.documentWithID(c8oCalRequestIdentifier))!;
        var properties : Dictionary<String, NSObject> = Dictionary<String, NSObject>();
        properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE] =  localCacheResponse.getResponse()
        properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE] = localCacheResponse.getResponseType()
        if (localCacheResponse.getExpirationDate() > 0) {
            properties[C8o.LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE] = localCacheResponse.getExpirationDate()
        }
        let currentRevision : CBLSavedRevision? = localCacheDocument.currentRevision
        if (currentRevision != nil) {
            properties[C8oFullSyncCbl.FULL_SYNC__REV] =  currentRevision?.revisionID
        }
        
        do {
            try localCacheDocument.putProperties(properties);
        } catch {
            throw C8oException(message: "TODO")
        }
    }
}
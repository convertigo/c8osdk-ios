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
import Fuzi

class C8oFullSyncCbl : C8oFullSync{
    private static let ATTACHMENT_PROPERTY_KEY_CONTENT_URL : String = "content_url"
    private var manager : CBLManager?
    private var fullSyncDatabases : Dictionary<String, C8oFullSyncDatabase>?;
    
    internal override init(){
        
    }
    internal override func Init(c8o: C8o) {
        super.Init(c8o)
        self.fullSyncDatabases = Dictionary<String, C8oFullSyncDatabase>();
        self.manager = CBLManager()
    }
    
    private func getOrCreateFullSyncDatabase(databaseName : String) throws -> C8oFullSyncDatabase{
        let localDatabaseName : String = databaseName + localSuffix!
        if let _ = fullSyncDatabases?[localDatabaseName]{
            
        }
        else{
            fullSyncDatabases![localDatabaseName] = try! C8oFullSyncDatabase(c8o: self.c8o!, manager: self.manager!, databaseName: databaseName, fullSyncDatabases: fullSyncDatabaseUrlBase!,localSuffix:  localSuffix!)
        }
        return fullSyncDatabases![localDatabaseName]!
    }
    
    internal func handleFullSyncResponse(var response : NSObject, listener : C8oResponseListener) throws->AnyObject?{
        let maVar : C8oJSON = C8oJSON()
        response = super.HandleFullSyncResponse(response, listener: listener)
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
                return response;
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
    
    override func HandleGetDocumentRequest(fullSyncDatatbaseName: String, docid: String, parameters: Dictionary<String, NSObject>)throws -> CBLDocument {
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(fullSyncDatatbaseName);
        
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
            throw C8oException(message: C8oExceptionMessage.RessourceNotFound("requested document \"" + docid + "\""));
        }
        return document!;
    }
    
    override func HandleDeleteDocumentRequest(DatatbaseName: String, docid: String, parameters: Dictionary<String, NSObject>)throws -> FullSyncDocumentOperationResponse? {
        let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(DatatbaseName);
        
        let revParameterValue : String? = C8oUtils.GetParameterStringValue(parameters, name: FullSyncDeleteDocumentParameter.REV.name, useName: false)!
        
        let document = fullSyncDatabase.getDatabase()?.existingDocumentWithID(docid)
        if (document == nil) {
            
            //throw new C8oRessourceNotFoundException(C8oExceptionMessage.toDo());
            fatalError("must implement")
            
        }
        
        let documentRevision : String = (document?.currentRevisionID)!
        
        // If the revision is specified then checks if this is the right revision
        if (revParameterValue != nil && revParameterValue != documentRevision) {
           // throw C8oRessourceNotFoundException(C8oExceptionMessage.couchRequestInvalidRevision());
            fatalError()
        }
        var deleted : Bool
        

        do {
           try document?.deleteDocument()
            deleted = true
        } catch let e as NSError {
            deleted = false
            throw C8oException(message: C8oExceptionMessage.couchRequestDeleteDocument(), exception: e);
            
        }
        catch{
            fatalError("error not handled")
        }
        
        return FullSyncDocumentOperationResponse(documentId: docid, documentRevision: documentRevision, operationStatus: deleted);
    }
    
    /*override func HandlePostDocumentRequest(databaseName: String, fullSyncPolicy: FullSyncPolicy, parameters: Dictionary<String, NSObject>)throws -> NSObject? {
        /*let fullSyncDatabase : C8oFullSyncDatabase = try! getOrCreateFullSyncDatabase(databaseName);
        
        // Gets the subkey separator parameter
        var subkeySeparatorParameterValue : String? = C8oUtils.GetParameterStringValue(parameters, name: C8o.FS_SUBKEY_SEPARATOR, useName: false)!;
        if (subkeySeparatorParameterValue == nil) {
            subkeySeparatorParameterValue = ".";
        }
        
        // Filters and modifies wrong properties
        let newProperties : Dictionary<String, NSObject> = Dictionary<String, NSObject>();
        for parameter in parameters {
            let parameterName : String = parameter.0
            
            // Ignores parameters beginning with "__" or "_use_"
            if (!parameterName.hasPrefix("__") && !parameterName.hasPrefix("_use_")) {
                var objectParameterValueTemp = parameter.1
                
                do {
                    let objectParameterValuetemp2 = JSON(String(objectParameterValueTemp))
                    let objectParameterValue = objectParameterValuetemp2
                    /*if (objectParameterValue.isKindOfClass(JSON) {
                        objectParameterValue = ObjectMapper().readValue(objectParameterValue.toString(), LinkedHashMap.class);
                    } else if (objectParameterValue.isKindOfClass(JSONArray)) {
                        objectParameterValue = new ObjectMapper().readValue(objectParameterValue.toString(), ArrayList.class);
                    }*/
                } catch let e as NSError {
                    //throw C8oException(message: C8oExceptionMessage.InvalidParameterValue(parameterName, details: String(objectParameterValue)), exception: e);
                }
                
                // Checks if the parameter name is splittable
                let paths : [String] = parameterName.split(Pattern.quote(subkeySeparatorParameterValue));
                
                if (paths.length > 1) {
                    // The first substring becomes the key
                    parameterName = paths[0];
                    // Next substrings create a hierarchy which will becomes json subkeys
                    int count = paths.length - 1;
                    while (count > 0) {
                        Map<String, Object> tmpObject = new HashMap<String, Object>();
                        tmpObject.put(paths[count], objectParameterValue);
                        objectParameterValue = tmpObject;
                        count--;
                    }
                    Object existProperty = newProperties.get(parameterName);
                    if (existProperty != null && existProperty instanceof Map) {
                        mergeProperties((Map) objectParameterValue, (Map) existProperty);
                    }
                }
             
                newProperties.put(parameterName, objectParameterValue);
            }
        }
        
        // Execute the query depending to the policy
        Document createdDocument = fullSyncPolicy.postDocument(fullSyncDatabase.getDatabase(), newProperties);
        String documentId = createdDocument.getId();
        String currentRevision = createdDocument.getCurrentRevisionId();
        return new FullSyncDocumentOperationResponse(documentId, currentRevision, true);*/
    }*/
}
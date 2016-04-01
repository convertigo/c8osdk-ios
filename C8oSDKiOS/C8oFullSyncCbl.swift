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
        let document : CBLDocument? =  (fullSyncDatabase.getDatabase()?.existingDocumentWithID(docid)!)!;
        if(document != nil){
            let attachements : AnyObject? = document?.propertyForKey(C8oFullSync.FULL_SYNC__ATTACHMENTS)
            if(attachements != nil){
                let rev : CBLRevision = document!.currentRevision!
                
                for attachementName in (attachements?.keys)!{
                    let attachment : CBLAttachment = rev.attachmentNamed(attachementName as! String)!
                    let url : NSURL = attachment.contentURL!
                    var attachmentDesc : Dictionary<String, AnyObject> = attachements?.valueForKey(attachementName as! String) as! Dictionary<String, NSObject>
                    attachmentDesc[C8oFullSyncCbl.ATTACHMENT_PROPERTY_KEY_CONTENT_URL] =  String(url)
                }
            }
        }
        else{
            throw C8oException(message: C8oExceptionMessage.RessourceNotFound("requested document \"" + docid + "\""));
        }
        return document!
    }
}
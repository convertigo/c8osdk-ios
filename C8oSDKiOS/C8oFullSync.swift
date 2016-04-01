//
//  C8oFullSync.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

import CouchbaseLite


internal class C8oFullSync
{
    public static var FULL_SYNC_URL_PATH : String = "/fullsync/";
    /// <summary>
    /// The project requestable value to execute a fullSync request.
    /// </summary>
    public static var FULL_SYNC_PROJECT : String = "fs://";
    public static var FULL_SYNC__ID : String = "_id";
    public static var FULL_SYNC__REV : String = "_rev";
    public static var FULL_SYNC__ATTACHMENTS : String = "_attachments";
    
    public static var FULL_SYNC_DDOC_PREFIX : String = "_design";
    public static var FULL_SYNC_VIEWS : String = "views";
    
    internal var c8o : C8o?;
    internal var fullSyncDatabaseUrlBase : String?
    internal var localSuffix : String?;
    
    internal func Init(c8o : C8o)
    {
        self.c8o = c8o;
        fullSyncDatabaseUrlBase = c8o.EndpointConvertigo + C8oFullSync.FULL_SYNC_URL_PATH;
        localSuffix = (c8o.FullSyncLocalSuffix != nil) ? c8o.FullSyncLocalSuffix : "_device";
    }

    
    internal func HandleFullSyncRequest(parameters : Dictionary<String, NSObject>, listener : C8oResponseListener)throws ->NSObject?
    {
        // Checks if this is really a fullSync request (even if this is normally already checked)
        var projectParameterValue = try! C8oUtils.PeekParameterStringValue(parameters, name: C8o.ENGINE_PARAMETER_PROJECT, exceptionIfMissing: true);
        
        if (!projectParameterValue!.hasPrefix(C8oFullSync.FULL_SYNC_PROJECT))
        {
            throw C8oException(message: C8oExceptionMessage.InvalidParameterValue(projectParameterValue!, details: "its don't start with " + C8oFullSync.FULL_SYNC_PROJECT));
        }

        // Gets the sequence parameter to know which fullSync requestable to use
        var fullSyncRequestableValue : String = try! C8oUtils.PeekParameterStringValue(parameters, name: C8o.ENGINE_PARAMETER_SEQUENCE, exceptionIfMissing: true)!;
        var fullSyncRequestable : FullSyncRequestable? = FullSyncRequestable.GetFullSyncRequestable(fullSyncRequestableValue);
        if (fullSyncRequestable == nil)
        {
            throw C8oException(message: C8oExceptionMessage.InvalidParameterValue(C8o.ENGINE_PARAMETER_PROJECT, details: C8oExceptionMessage.UnknownValue("fullSync requestable", value: fullSyncRequestableValue)));
        }
        
        // Gets the database name if this is not specified then if takes the default database name
        var index1 = projectParameterValue!.startIndex.advancedBy(C8oFullSync.FULL_SYNC_PROJECT.characters.count)
        var databaseName : String? = projectParameterValue!.substringFromIndex(index1)
        if (databaseName!.length < 1)
        {
            databaseName = c8o!.DefaultDatabaseName;
            if (databaseName == nil)
            {
                throw C8oException(message: C8oExceptionMessage.InvalidParameterValue(C8o.ENGINE_PARAMETER_PROJECT, details: C8oExceptionMessage.MissingValue("fullSync database name")));
            }
        }
        
        var response : NSObject?;
        do
        {
            response = fullSyncRequestable!.HandleFullSyncRequest(self, databaseNameName: databaseName!, parameters: parameters, c8oResponseListner: listener);
        }
        catch let e as C8oException
        {
            throw  C8oException(message: C8oExceptionMessage.FullSyncRequestFail(), exception: e);
        }
        
        if (response == nil)
        {
            throw C8oException(message: C8oExceptionMessage.couchNullResult());
        }

        response = HandleFullSyncResponse(response!,listener:  listener);
        return response;
    }
    
  internal func HandleFullSyncResponse(var response : AnyObject, listener : C8oResponseListener)->NSObject
    {
        /*if (response is JSON)
        {
            if (listener is C8oResponseXmlListener)
            {
                //response = C8oFullSyncTranslator.FullSyncJsonToXml(response as JSON);
            }
        }*/
        
        return response as! NSObject;
    }
    

    internal func HandleGetDocumentRequest(fullSyncDatatbaseName : String, docid : String, parameters : Dictionary<String, NSObject>)throws ->CBLDocument
    {
        fatalError("Must Override")
    }

  internal func HandleDeleteDocumentRequest(fullSyncDatatbaseName : String, docid :  String, parameters : Dictionary<String, NSObject>)->NSObject?//Task<object>
    {
        fatalError("Must Override")
    }
    

    
  internal func HandlePostDocumentRequest(fullSyncDatatbaseName : String, fullSyncPolicy : FullSyncPolicy, parameters : Dictionary<String, NSObject>)->NSObject?//Task<object>
    {
        fatalError("Must Override")
    }
    

    
  internal func HandleAllDocumentsRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }

    
    internal func HandleGetViewRequest(fullSyncDatatbaseName : String, ddoc : String, view : String, parameters : Dictionary<String, NSObject>)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    

    
    internal func HandleSyncRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    internal func HandleReplicatePullRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    internal func HandleReplicatePushRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    

    
    internal func HandleResetDatabaseRequest(fullSyncDatatbaseName : String)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }

    internal func HandleCreateDatabaseRequest(fullSyncDatatbaseName : String)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    

    internal func HandleDestroyDatabaseRequest(fullSyncDatatbaseName : String)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    

    internal func GetResponseFromLocalCache(c8oCallRequestIdentifier : String)->NSObject?//->Task<C8oLocalCacheResponse>
    {
        fatalError("Must Override")
    }
    

    internal func SaveResponseToLocalCache(c8oCallRequestIdentifier : String, localCacheResponse : NSObject?/*C8oLocalCacheResponse*/)->NSObject?//->Task
    {
        fatalError("Must Override")
    }
    

    internal static func IsFullSyncRequest(requestParameters : Dictionary<String, NSObject>)->Bool
    {
        // Check if there is one parameter named "__project" and if its value starts with "fs://"
        if let parameterValue : String = C8oUtils.GetParameterStringValue(requestParameters, name: C8o.ENGINE_PARAMETER_PROJECT, useName: false){
            return parameterValue.hasPrefix(C8oFullSync.FULL_SYNC_PROJECT);
        }
            return false;
       

    }
}
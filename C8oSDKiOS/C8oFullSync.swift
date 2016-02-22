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
    /*public static var FULL_SYNC_URL_PATH : String = "/fullsync/";
    /// <summary>
    /// The project requestable value to execute a fullSync request.
    /// </summary>
    public static var FULL_SYNC_PROJECT : String = "fs://";
    public static var FULL_SYNC__ID : String = "_id";
    public static var FULL_SYNC__REV : String = "_rev";
    public static var FULL_SYNC__ATTACHMENTS : String = "_attachments";
    
    public static var FULL_SYNC_DDOC_PREFIX : String = "_design";
    public static var FULL_SYNC_VIEWS : String = "views";
    
    internal var c8o : C8o;
    internal var fullSyncDatabaseUrlBase : String;
    internal var localSuffix : String;*/
    
    internal init(/*c8o : C8o*/)
    {
        /*self.c8o = c8o;
        fullSyncDatabaseUrlBase = c8o.EndpointConvertigo + C8oFullSync.FULL_SYNC_URL_PATH;*/
        //localSuffix = (c8o.FullSyncLocalSuffix != nil) ? c8o.FullSyncLocalSuffix : "_device";
    }
    
    //*** Request handlers ***//
    
    public func HandleFullSyncRequest(parameters : Dictionary<String, NSObject>, listener : C8oResponseListener)->NSObject?//Task<object>
    {
        /*
        // Gets the project and the sequence parameter in order to know which database and which fullSyncrequestable to use
        var projectParameterValue = C8oUtils.PeekParameterStringValue(parameters, name: C8o.ENGINE_PARAMETER_PROJECT, exceptionIfMissing: true);
        
        if (!projectParameterValue.StartsWith(FULL_SYNC_PROJECT))
        {
            //throw new ArgumentException(C8oExceptionMessage.InvalidParameterValue(projectParameterValue, "its don't start with " + FULL_SYNC_PROJECT));
        }
        
        var fullSyncRequestableValue : String = C8oUtils.PeekParameterStringValue(parameters, C8o.ENGINE_PARAMETER_SEQUENCE, true);
        // Gets the fullSync requestable and gets the response from this requestable
        var fullSyncRequestable : FullSyncRequestable? = FullSyncRequestable.GetFullSyncRequestable(fullSyncRequestableValue);
        if (fullSyncRequestable == nil)
        {
            //throw new ArgumentException(C8oExceptionMessage.InvalidParameterValue(C8o.ENGINE_PARAMETER_PROJECT, C8oExceptionMessage.UnknownValue("fullSync requestable", fullSyncRequestableValue)));
        }
        
        // Gets the database name if this is not specified then if takes the default database name
        var databaseName : String = projectParameterValue.Substring(C8oFullSync.FULL_SYNC_PROJECT.Length);
        if (databaseName.length < 1)
        {
            databaseName = c8o.DefaultDatabaseName;
            if (databaseName == nil)
            {
                //throw new ArgumentException(C8oExceptionMessage.InvalidParameterValue(C8o.ENGINE_PARAMETER_PROJECT, C8oExceptionMessage.MissingValue("fullSync database name")));
            }
        }
        
        var response : NSObject?;
        do
        {
            response = fullSyncRequestable.HandleFullSyncRequest(self, databaseName, parameters, listener);
        }
        catch //(Exception e)
        {
            //throw new C8oException(C8oExceptionMessage.FullSyncRequestFail(), e);
        }
        
        if (response == nil)
        {
            //throw new C8oException(C8oExceptionMessage.couchNullResult());
        }

        response = HandleFullSyncResponse(response, listener);
        return response;*/
        return nil
    }
    
    /// <summary>
    /// Handles the fullSync response depending to the C8oResponseListener.
    /// </summary>
    /// <param name="response"></param>
    /// <param name="parameters"></param>
    /// <param name="c8oResponseListener"></param>
    public func HandleFullSyncResponse(var response : NSObject, listener : C8oResponseListener)->NSObject
    {
        if (response is JSON)
        {
            if (listener is C8oResponseXmlListener)
            {
                //response = C8oFullSyncTranslator.FullSyncJsonToXml(response as JSON);
            }
        }
        
        return response;
    }
    
    /// <summary>
    /// Returns the requested document.
    /// </summary>
    /// <param name="fullSyncDatatbase"></param>
    /// <param name="parameters"></param>
    /// <returns></returns>
    public func HandleGetDocumentRequest(fullSyncDatatbaseName : String, docid : String, parameters : Dictionary<String, NSObject>)->String
    {
        fatalError("Must Override")
    }
    
    //*** DeleteDocument ***//
    
    /// <summary>
    /// Deletes an existing document from the local database.
    /// </summary>
    /// <param name="fullSyncDatabase"></param>
    /// <param name="parameters"></param>
    /// <returns></returns>
    public func HandleDeleteDocumentRequest(fullSyncDatatbaseName : String, docid :  String, parameters : Dictionary<String, NSObject>)->NSObject?//Task<object>
    {
        fatalError("Must Override")
    }
    
    //*** PostDocument ***//
    
    public func HandlePostDocumentRequest(fullSyncDatatbaseName : String, fullSyncPolicy : NSObject? /*FullSyncPolicy*/, parameters : Dictionary<String, NSObject>)->NSObject?//Task<object>
    {
        fatalError("Must Override")
    }
    
    //*** GetAllDocuments ***//
    
    public func HandleAllDocumentsRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    //*** GetView ***//
    
    public func HandleGetViewRequest(fullSyncDatatbaseName : String, ddoc : String, view : String, parameters : Dictionary<String, NSObject>)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    //*** Sync, ReplicatePull, ReplicatePush ***//
    
    public func HandleSyncRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    public func HandleReplicatePullRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    public func HandleReplicatePushRequest(fullSyncDatatbaseName : String, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    //*** Reset ***//
    
    public func HandleResetDatabaseRequest(fullSyncDatatbaseName : String)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    //*** Create ***//
    public func HandleCreateDatabaseRequest(fullSyncDatatbaseName : String)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    //*** Destroy ***//
    public func HandleDestroyDatabaseRequest(fullSyncDatatbaseName : String)->NSObject?//->Task<object>
    {
        fatalError("Must Override")
    }
    
    //*** Local cache ***//
    
    /// <summary>
    /// Gets the c8o call response stored into the local cache thanks to the c8o call request identifier.
    /// </summary>
    /// <param name="c8oCallRequestIdentifier"></param>
    /// <returns></returns>
    public func GetResponseFromLocalCache(c8oCallRequestIdentifier : String)->NSObject?//->Task<C8oLocalCacheResponse>
    {
        fatalError("Must Override")
    }
    
    /// <summary>
    /// Saves the c8o call response into the local cache.
    /// </summary>
    /// <param name="c8oCallRequestIdentifier"></param>
    /// <param name="responseString"></param>
    /// <param name="responseType"></param>
    /// <param name="localCacheTimeToLive"></param>
    public func SaveResponseToLocalCache(c8oCallRequestIdentifier : String, localCacheResponse : NSObject?/*C8oLocalCacheResponse*/)->NSObject?//->Task
    {
        fatalError("Must Override")
    }
    
    /// <summary>
    /// Checks if request parameters correspond to a fullSync request.
    /// </summary>
    public static func IsFullSyncRequest(requestParameters : Dictionary<String, NSObject>)->Bool
    {
        // Check if there is one parameter named "__project" and if its value starts with "fs://"
        //var parameterValue : String? = C8oUtils.GetParameterStringValue(requestParameters, C8o.ENGINE_PARAMETER_PROJECT, false);
        /*if (parameterValue != nil)
        {
            //return parameterValue.StartsWith(FULL_SYNC_PROJECT);
        }*/
        return false;
    }
}
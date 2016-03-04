//
//  C8oCallTask.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import ObjectiveC
import Alamofire
import SwiftyJSON
import Fuzi

import CouchbaseLite

internal class C8oCallTask
{
    private var c8o : C8o;
    private var parameters : Dictionary<String, NSObject>;
    private var c8oResponseListener : C8oResponseListener?;
    private var c8oExceptionListener : C8oExceptionListener;
    private var c8oCallUrl : String?
    
    
    internal init(c8o : C8o, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener, c8oExceptionListener : C8oExceptionListener)
    {
        self.c8o = c8o;
        self.parameters = parameters;
        self.c8oResponseListener = c8oResponseListener;
        self.c8oExceptionListener = c8oExceptionListener;
        self.c8oCallUrl = nil
        
        c8o.c8oLogger!.LogMethodCall("C8oCallTask", parameters: parameters);
    }
    
    internal func Execute()-> Void
    {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)){
            
            self.DoInBackground();
            
        }
    }
    
    private func DoInBackground()->Void
    {
        do
        {
            let response =  try HandleRequest();
            HandleResponse(response!);
        }
        catch
        {
            //c8oExceptionListener.OnException(e, null);
        }
    }
    
    
    private func HandleRequest() throws ->AnyObject? //Task<object>
    {
        let isFullSyncRequest : Bool = C8oFullSync.IsFullSyncRequest(parameters);
        var responseType : String = ""
        
        if (isFullSyncRequest)
        {
            c8o.Log._Debug("Is FullSync request", exceptions: nil);
            // The result cannot be handled here because it can be different depending to the platform
            // But it can be useful bor debug
            do
            {
                let fullSyncResult = c8o.c8oFullSync!.HandleFullSyncRequest(parameters, listener: c8oResponseListener!);
                return fullSyncResult;
            }
            catch //(Exception e)
            {
                //throw new C8oException(C8oExceptionMessage.FullSyncRequestFail(), e);
            }
        }
        else
        {
            
            if (c8oResponseListener == nil || c8oResponseListener is C8oResponseXmlListener)
            {
                responseType = C8o.RESPONSE_TYPE_XML;
            }
            else if (c8oResponseListener is C8oResponseJsonListener)
            {
                responseType = C8o.RESPONSE_TYPE_JSON;
            }
            else
            {
                throw C8oSDKiOS.Error.C8oException("Wrong listener")
            }
            
            /** Local cache */
            
            var c8oCallRequestIdentifier : String? = nil;
            
            // Allows to enable or disable the local cache on a Convertigo requestable, default value is true
            let localCache : C8oLocalCache? = (C8oUtils.GetParameterObjectValue(parameters, name: C8oLocalCache.PARAM, useName: false) as! C8oLocalCache?);
            let localCacheEnabled : Bool = false;
            
            // If the engine parameter for local cache is specified
            if (localCache != nil)
            {
                print("local cache actif (Le code n'est pas implémenté)")
                /* // Removes local cache parameters and build the c8o call request identifier
                parameters.removeValueForKey(C8oLocalCache.PARAM);
                
                if (localCacheEnabled == localCache!.enabled)
                {
                c8oCallRequestIdentifier = C8oUtils.IdentifyC8oCallRequest(parameters, responseType: responseType);
                
                if (localCache!.priority.IsAvailable(c8o))
                {
                do
                {
                var localCacheResponse : C8oLocalCacheResponse = c8o.c8oFullSync.GetResponseFromLocalCache(c8oCallRequestIdentifier);
                if (!localCacheResponse.Expired)
                {
                if (responseType == C8o.RESPONSE_TYPE_XML)
                {
                return C8oTranslator.StringToXml(localCacheResponse.Response);
                }
                else if (responseType == C8o.RESPONSE_TYPE_JSON)
                {
                return C8oTranslator.StringToJson(localCacheResponse.Response);
                }
                }
                }
                catch //(C8oUnavailableLocalCacheException)
                {
                // no entry
                }
                }
                }*/
            }
            
            /** Get response */
        
            parameters[C8o.ENGINE_PARAMETER_DEVICE_UUID] = c8o.DeviceUUID;
            
            // Build the c8o call URL
            c8oCallUrl = c8o.Endpoint + "/." + responseType;
            
            let httpResponse : NSData
            
            do
            {
                httpResponse = (c8o.httpInterface?.HandleRequest(c8oCallUrl!, parameters: parameters)!)!
                
            }
            catch //(Exception e)
            {
               /* if (localCacheEnabled)
                {
                    do
                    {
                        var localCacheResponse : C8oLocalCacheResponse = c8o.c8oFullSync.GetResponseFromLocalCache(c8oCallRequestIdentifier);
                        if (!localCacheResponse.Expired)
                        {
                            if (responseType == C8o.RESPONSE_TYPE_XML)
                            {
                                return C8oTranslator.StringToXml(localCacheResponse.Response);
                            }
                            else if (responseType == C8o.RESPONSE_TYPE_JSON)
                            {
                                return C8oTranslator.StringToJson(localCacheResponse.Response);
                            }
                        }
                    }
                    catch //(C8oUnavailableLocalCacheException)
                    {
                        // no entry
                    }
                }
                return C8oException(C8oExceptionMessage.handleC8oCallRequest(), e);*/
            }
            
            
            var response : AnyObject? = nil;
            var responseString : String? = nil;
            if (c8oResponseListener is C8oResponseXmlListener)
            {
                
                response = C8oTranslator.DataToXml(httpResponse)!
                print(response)
                if(localCacheEnabled)
                {
                    responseString = (response as! XMLDocument).description
                }
               
            }
            else if (c8oResponseListener is C8oResponseJsonListener)
            {
                //responseString = C8oTranslator.StreamToString(responseStream);
                 C8oTranslator.DataToJson(httpResponse)!;
            }
            else
            {
                //return C8oException("wrong listener");
            }
            
            if (localCacheEnabled)
            {
                // String responseString = C8oTranslator.StreamToString(responseStream);
                var expirationDate : Int = -1;
                if (localCache!.ttl > 0) {
                //    expirationDate = localCache.ttl + C8oUtils.GetUnixEpochTime(NSDate.Now);
                }
               // var localCacheResponse = C8oLocalCacheResponse(responseString, responseType, expirationDate);
               // c8o.c8oFullSync.SaveResponseToLocalCache(c8oCallRequestIdentifier, localCacheResponse);
            }
            
            return response;
            
            }
            //return nil

        }
    
    
    internal func HandleResponse(result :AnyObject?)->Void {
        do{
        
            if (result == nil)
            {
                return;
            }
            
            if (c8oResponseListener == nil)
            {
                return;
            }
            
            if (result is XMLDocument)
            {
                
                c8o.c8oLogger!.LogC8oCallXMLResponse(result as! XMLDocument, url: c8oCallUrl!,  parameters : self.parameters);
                //let onXmlReponseVar  = (Pair<XMLDocument?, Dictionary<String, NSObject>?>?((result as! XMLDocument) ,  parameters as Dictionary<String, NSObject>))
                //let onXmlReponseVar : (Pair<AnyObject?, Dictionary<String, NSObject>?>?) =
                (c8oResponseListener as! C8oResponseXmlListener).OnXmlResponse(Pair(key: result!, value: parameters))
            }
            else if (result is JSON)
            {
                c8o.c8oLogger!.LogC8oCallJSONResponse(result as! JSON, url: c8oCallUrl!, parameters: parameters);
                let onJsonReponseVar : (Dictionary<NSObject, Dictionary<String, NSObject>>?) = [result as! NSObject : parameters]
                (c8oResponseListener as! C8oResponseJsonListener).OnJsonResponse(onJsonReponseVar);
            }
            else if ( result is ErrorType || result is NSException){
                c8o.HandleCallException(c8oExceptionListener, requestParameters: parameters, exception: (result as! C8oSDKiOS.Error))
            }
            else {
                c8o.HandleCallException(c8oExceptionListener, requestParameters: parameters, exception: C8oSDKiOS.Error.C8oException(C8oExceptionMessage.wrongResult(result!)))
            }
            
        }
        catch //(Exception e)
        {
            //c8o.HandleCallException(c8oExceptionListener, parameters, e);
        }
    }
    
}
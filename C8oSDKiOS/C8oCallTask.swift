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
import AEXML
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
        
        c8o.c8oLogger!.logMethodCall("C8oCallTask", parameters: parameters);
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
        catch let e as C8oException
        {
            c8oExceptionListener.onException(Pair<C8oException, Dictionary<String, NSObject>?>(key: e, value: nil));
        }
        catch let e as AnyObject{
            let a = e
        }
        catch{
            var a = "salut"
            a = a + "eee"
        }
        
    }
    
    
    private func HandleRequest() throws ->AnyObject? //Task<object>
    {
        let isFullSyncRequest : Bool = C8oFullSync.isFullSyncRequest(parameters);
        
        if (isFullSyncRequest)
        {
            c8o.log._debug("Is FullSync request", exceptions: nil);
            // The result cannot be handled here because it can be different depending to the platform
            // But it can be useful bor debug
            do
            {
                let fullSyncResult = try c8o.c8oFullSync!.handleFullSyncRequest(parameters, listener: c8oResponseListener!);
                return fullSyncResult;
            }
            catch let e as NSError//(Exception e)
            {
                throw C8oException(message: C8oExceptionMessage.FullSyncRequestFail(), exception: e);
            }
            catch{
                let a = 10
            }
        }
        else
        {
            var responseType : String = ""
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
                throw C8oSDKiOS.C8oError.C8oException("Wrong listener")
            }
            
            /** Local cache */
            
            var c8oCallRequestIdentifier : String? = nil;
            
            // Allows to enable or disable the local cache on a Convertigo requestable, default value is true
            let localCache : C8oLocalCache? = (C8oUtils.getParameterObjectValue(parameters, name: C8oLocalCache.PARAM, useName: false) as! C8oLocalCache?);
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
        
            parameters[C8o.ENGINE_PARAMETER_DEVICE_UUID] = c8o.deviceUUID;
            
            // Build the c8o call URL
            c8oCallUrl = c8o.endpoint + "/." + responseType;
            
            let httpResponse : NSData?
            var httpResponseDataError : (data : NSData?, error : NSError?)
            
            do
            {
                httpResponseDataError = (c8o.httpInterface?.handleRequest(c8oCallUrl!, parameters: parameters))!
                if(httpResponseDataError.error != nil){
                    httpResponse = httpResponseDataError.data
                    return C8oException(message: C8oExceptionMessage.handleC8oCallRequest(), exception: httpResponseDataError.error! );
                    
                }
                else{
                    httpResponse = httpResponseDataError.data
                }
                
            }
            catch let e as NSError
            {
               if (localCacheEnabled)
                {
                    /*do
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
                    }*/
                }
                return C8oException(message: C8oExceptionMessage.handleC8oCallRequest(), exception: e );
            }
            
            
            var response : AnyObject? = nil;
            var responseString : String? = nil;
            if (c8oResponseListener is C8oResponseXmlListener)
            {
                
                response = C8oTranslator.dataToXml(httpResponse!)!
                if(localCacheEnabled)
                {
                    responseString = (response as! AEXMLDocument).description
                    
                }
               
            }
            else if (c8oResponseListener is C8oResponseJsonListener)
            {
                //responseString = C8oTranslator.StreamToString(responseStream);
                var myc8 = C8oJSON()
                myc8.myJSON = C8oTranslator.dataToJson(httpResponse!)!
                response = myc8

                
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
            return nil

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
            
            if (result is AEXMLDocument)
            {
                
                c8o.c8oLogger!.logC8oCallXMLResponse(result as! AEXMLDocument, url: c8oCallUrl!,  parameters : self.parameters);
                (c8oResponseListener as! C8oResponseXmlListener).onXmlResponse(Pair(key: result!, value: parameters))
            }
            else {
                if (result is C8oJSON) {
                c8o.c8oLogger!.logC8oCallJSONResponse((result as!C8oJSON).myJSON! , url: c8oCallUrl!, parameters: parameters);
                (c8oResponseListener as! C8oResponseJsonListener).onJsonResponse(Pair(key: (result as!C8oJSON).myJSON!, value: parameters));
                }
                else{
                    if result is C8oException{
                        c8o.handleCallException(c8oExceptionListener, requestParameters: self.parameters, exception: result as! C8oException)
                    }
                    else{
                        /*c8o.HandleCallException(c8oExceptionListener, requestParameters: parameters, exception: C8oSDKiOS.C8oError.C8oException(C8oExceptionMessage.wrongResult(result!)))*/
                    }
                }
            }
            
        }
        catch //(Exception e)
        {
            //c8o.HandleCallException(c8oExceptionListener, parameters, e);
        }
    }
    
}
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

internal class C8oCallTask {
    fileprivate var c8o: C8o
    fileprivate var parameters: Dictionary<String, Any>
    fileprivate var c8oResponseListener: C8oResponseListener?
    fileprivate var c8oExceptionListener: C8oExceptionListener
    fileprivate var c8oCallUrl: String?
    
    internal init(c8o: C8o, parameters: Dictionary<String, Any>, c8oResponseListener: C8oResponseListener, c8oExceptionListener: C8oExceptionListener) {
        self.c8o = c8o
        self.parameters = parameters
        
        self.c8oResponseListener = c8oResponseListener
        self.c8oExceptionListener = c8oExceptionListener
        self.c8oCallUrl = nil
        
        c8o.c8oLogger!.logMethodCall("C8oCallTask", parameters: parameters as NSObject)
    }
    
    internal func execute() -> Void {
        c8o.runBG(DispatchWorkItem{
            self.doInBackground()
        });
    }
    
    internal func executeFromLive() {
        parameters.removeValue(forKey: C8o.FS_LIVE)
        parameters[C8o.ENGINE_PARAMETER_FROM_LIVE] = true as Any
        execute()
    }
    
    fileprivate func doInBackground() -> Void {
        do {
            let response = try handleRequest()
            handleResponse(response!)
        }
        catch let e as C8oException {
            c8oExceptionListener.onException(e, parameters)
        }
        catch {
        }
        
    }
    
    fileprivate func handleRequest() throws -> Any? {
        let isFullSyncRequest: Bool = C8oFullSync.isFullSyncRequest(parameters)
        
        if (isFullSyncRequest) {
            c8o.log._debug("Is FullSync request", exceptions: nil)
            
            let liveid = C8oUtils.getParameterStringValue(parameters, name: C8o.FS_LIVE)
            if (liveid != nil) {
                let dbName = C8oUtils.getParameterStringValue(parameters, name: C8o.ENGINE_PARAMETER_PROJECT)![C8oFullSync.FULL_SYNC_PROJECT.endIndex...]
                try c8o.addLive(liveid!, db: String(dbName), task: self)
            }
            // The result cannot be handled here because it can be different depending to the platform
            // But it can be useful bor debug
            var fullSyncResult: Any? = nil
            do {
                fullSyncResult = try self.c8o.c8oFullSync!.handleFullSyncRequest(self.parameters, listener: self.c8oResponseListener!)
                return fullSyncResult
            }
            catch let e as C8oException {
                throw e
            }
            catch let e as NSError {
                print("err2")
                throw C8oException(message: C8oExceptionMessage.FullSyncRequestFail(), exception: e)
            }
        } else {
            var responseType: String = ""
            if (c8oResponseListener == nil || c8oResponseListener is C8oResponseXmlListener) {
                responseType = C8o.RESPONSE_TYPE_XML
            } else if (c8oResponseListener is C8oResponseJsonListener) {
                responseType = C8o.RESPONSE_TYPE_JSON
            } else {
                throw C8oError.c8oException("Wrong listener")
            }
            
            /** Local cache */
            
            var c8oCallRequestIdentifier: String? = nil
            
            // Allows to enable or disable the local cache on a Convertigo requestable, default value is true
            let localCache: C8oLocalCache? = (C8oUtils.getParameterObjectValue(parameters, name: C8oLocalCache.PARAM, useName: false) as! C8oLocalCache?)
            var localCacheEnabled: Bool = false
            
            // If the engine parameter for local cache is specified
            if (localCache != nil) {
                
                // Removes local cache parameters and build the c8o call request identifier
                parameters.removeValue(forKey: C8oLocalCache.PARAM)
                
                localCacheEnabled = localCache!.enabled
                if (localCacheEnabled) {
                    c8oCallRequestIdentifier = C8oUtils.identifyC8oCallRequest(parameters, responseType: responseType)
                    
                    if (localCache!.priority!.isAvailable(c8o)) {
                        do {
                            let localCacheResponse: C8oLocalCacheResponse = try (c8o.c8oFullSync as! C8oFullSyncCbl).getResponseFromLocalCache(c8oCallRequestIdentifier!)!
                            if (!localCacheResponse.isExpired()) {
                                if (responseType == C8o.RESPONSE_TYPE_XML) {
                                    return try C8oTranslator.stringToXml(localCacheResponse.getResponse())
                                } else if (responseType == C8o.RESPONSE_TYPE_JSON) {
                                    let myJson: C8oJSON = C8oJSON()
                                    myJson.myJSON = C8oTranslator.stringToJson(localCacheResponse.getResponse())
                                    return myJson
                                }
                            }
                        } catch {
                            // no entry
                        }
                    }
                }
            }
            
            /** Get response */
            
            parameters[C8o.ENGINE_PARAMETER_DEVICE_UUID] = c8o.deviceUUID as Any
            
            // Build the c8o call URL
            c8oCallUrl = c8o.endpoint + "/." + responseType
            
            let httpResponse: Data?
            var httpResponseDataError: (data: Data?, error: NSError?)
            
            do {
                httpResponseDataError = (c8o.httpInterface?.handleRequest(c8oCallUrl!, parameters: parameters))!
                if (httpResponseDataError.error != nil) {
                    if (localCacheEnabled) {
                        do {
                            let localCacheResponse: C8oLocalCacheResponse = try (c8o.c8oFullSync as! C8oFullSyncCbl).getResponseFromLocalCache(c8oCallRequestIdentifier!)!
                            if (!localCacheResponse.isExpired()) {
                                if (responseType == C8o.RESPONSE_TYPE_XML) {
                                    return try C8oTranslator.stringToXml(localCacheResponse.getResponse())
                                } else if (responseType == C8o.RESPONSE_TYPE_JSON) {
                                    let myJson: C8oJSON = C8oJSON()
                                    myJson.myJSON = C8oTranslator.stringToJson(localCacheResponse.getResponse())
                                    return myJson
                                }
                            }
                        }
                        catch _ as C8oUnavailableLocalCacheException {
                            // no entry
                        }
                    }
                    httpResponse = httpResponseDataError.data
                    return C8oException(message: C8oExceptionMessage.handleC8oCallRequest(), exception: httpResponseDataError.error!)
                    
                } else {
                    httpResponse = httpResponseDataError.data
                }
                
            }
            
            var response: Any? = nil
            var responseString: String? = nil
            if (c8oResponseListener is C8oResponseXmlListener) {
                
                response = C8oTranslator.dataToXml(httpResponse!)!
                if (localCacheEnabled) {
                    responseString = (response as! AEXMLDocument).xml
                }
                
            } else if (c8oResponseListener is C8oResponseJsonListener) {
                let myc8 = C8oJSON()
                myc8.myJSON = try C8oTranslator.dataToJson(httpResponse! as NSData)!
                response = myc8
                responseString = C8oTranslator.jsonToString(myc8.myJSON!)
            } else {
                return C8oException(message: "wrong listener")
            }
            
            if (localCacheEnabled) {
                var expirationDate: Double = -1
                if (localCache!.ttl > 0) {
                    expirationDate = Double(localCache!.ttl) + C8oUtils.getUnixEpochTime()!
                }
                let localCacheResponse = C8oLocalCacheResponse(response: responseString!, responseType: responseType, expirationDate: expirationDate)
                try! (c8o.c8oFullSync as! C8oFullSyncCbl).saveResponseToLocalCache(c8oCallRequestIdentifier!, localCacheResponse: localCacheResponse)
            }
            return response
            
        }
    }
    
    internal func handleResponse(_ result: Any?) -> Void {
        if (result == nil) {
            return
        }
        if (c8oResponseListener == nil) {
            return
        }
        if (result is JSON) {
            
        }
        if (result is AEXMLDocument) {
            
            c8o.c8oLogger!.logC8oCallXMLResponse(result as! AEXMLDocument, url: c8oCallUrl, parameters: self.parameters)
            (c8oResponseListener as! C8oResponseXmlListener).onXmlResponse(result!, parameters)
        } else {
            if (result is C8oJSON) {
                c8o.c8oLogger!.logC8oCallJSONResponse((result as!C8oJSON).myJSON!, url: c8oCallUrl, parameters: parameters)
                (c8oResponseListener as! C8oResponseJsonListener).onJsonResponse((result as!C8oJSON).myJSON!.dictionaryObject! as AnyObject, parameters)
            } else {
                if result is C8oException {
                    c8o.handleCallException(c8oExceptionListener, requestParameters: self.parameters, exception: result as! C8oException)
                } else {
                    c8o.handleCallException(c8oExceptionListener, requestParameters: parameters, exception: C8oError.c8oException(C8oExceptionMessage.wrongResult(result!)) as! C8oException)
                }
            }
        }
    }
    
}

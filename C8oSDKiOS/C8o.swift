//
//  C8o.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 03/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import AEXML

//import CouchbaseLite

@objc public class C8o : C8oBase {
    
    /** Regular Expression */
     
     /**
     The regex used to handle the c8o requestable syntax ("<project>.<sequence>" or "<project>.<connector>.<transaction>")
     */
    private static let RE_REQUESTABLE : NSRegularExpression =  try! NSRegularExpression(pattern: "^([^.]*)\\.(?:([^.]+)|(?:([^.]+)\\.([^.]+)))$", options: [])
    
    /**
     The regex used to get the part of the endpoint before '/projects/'
     */
    public static let RE_ENDPOINT : NSRegularExpression =  try! NSRegularExpression(pattern: "^(http(s)?://([^:]+)(:[0-9]+)?/?.*?)/projects/([^/]+)$", options: [])
    
    /** Engine reserved parameters */
    
    internal static var ENGINE_PARAMETER_PROJECT : String = "__project"
    internal static var ENGINE_PARAMETER_SEQUENCE : String = "__sequence"
    internal static var ENGINE_PARAMETER_CONNECTOR : String = "__connector"
    internal static var ENGINE_PARAMETER_TRANSACTION : String = "__transaction"
    internal static var ENGINE_PARAMETER_ENCODED : String = "__encoded"
    internal static var ENGINE_PARAMETER_DEVICE_UUID : String = "__uuid"
    internal static var ENGINE_PARAMETER_PROGRESS : String = "__progress"
    
    /** FULLSYNC parameters */
    
    public static var FS_POLICY : String =  "_use_policy"
    public static var FS_POLICY_NONE : String =  "none"
    public static var FS_POLICY_CREATE : String =  "create"
    public static var FS_POLICY_OVERRIDE : String =  "override"
    public static var FS_POLICY_MERGE : String =  "merge"
    public static var FS_SUBKEY_SEPARATOR : String =  "_use_subkey_separator"
    
    /** Local cache keys */
    
    internal static var LOCAL_CACHE_DOCUMENT_KEY_RESPONSE : String =  "response"
    internal static var LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE : String =  "responseType"
    internal static var LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE : String =  "expirationDate"
    
    public static var LOCAL_CACHE_DATABASE_NAME : String =  "c8olocalcache"
    
    /** Response type */
    
    internal static var RESPONSE_TYPE_XML : String =  "pxml"
    internal static var RESPONSE_TYPE_JSON : String =  "json"
    
    /** Static configuration */
    internal static var defaultUiDispatcher : AnyObject?//ACTION<ACTION>?
    internal static var deviceUUID : String = UIDevice.currentDevice().identifierForVendor!.UUIDString
    
    /**
     Gets the SDK version.
     Example usage:
     @code
     myc8o : C8o = C8o()
     sdkVersion : String = myC8o.GetSdkVersion()
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @param nil
     @return A string containing the sdk version.
     */
    public static func getSdkVersion()-> String
    {
        return "2.0.0"
    }
    
    /** Attributes */
     
     
     /** The Convertigo endpoint
     @code
     <protocol>://<server>:<port>/<Convertigo web app path>/projects/<project name>
     http://127.0.0.1:18080/convertigo/projects/MyProject
     @endcode
     */
    private var _endpoint : String?
    private var _endpointConvertigo: String?
    private var _endpointIsSecure : Bool?
    private var _endpointHost : String?
    private var _endpointPort : String?
    private var _endpointProject : String?
    
    
    
    
    /** Used to run HTTP requests.*/
    internal var httpInterface : C8oHttpInterface?
    
    /** Allows to log locally and remotely to the Convertigo server.*/
    internal var c8oLogger : C8oLogger?
    
    /** Allows to make fullSync calls. */
    internal var c8oFullSync :C8oFullSync?
    
    /** Constructors */
     
     /**
     This is the base object representing a Convertigo Server end point. This object should be instanciated
     when the apps starts and be accessible from any class of the app. Although this is not common , you may have
     several C8o objects instanciated in your app.
     Example usage:
     @code
     myc8o : C8o = C8o()
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     */
    public override init() {
        super.init()
    }
    
    
    /**
     This is the base object representing a Convertigo Server end point. This object should be instanciated
     when the apps starts and be accessible from any class of the app. Although this is not common , you may have
     several C8o objects instanciated in your app.
     Example usage:
     @code
     myc8o : C8o = C8o()
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @param endpoint : String
     The End point url to you convertigo server. Can be :
     - http(s)://your_server_address/convertigo/projects/your_project_name (if using an on premises server)
     - http(s)://your_cloud_server.convertigo.net/cems/projects/your_project_name (if using a Convertigo cloud server)
     @param c8oSettings : C8oSettings?
     A C8oSettings object describing the endpoint configuration parameters such as authorizations credentials,
     cookies, client certificates and various other settings.
     */
    public init(endpoint :String, c8oSettings : C8oSettings?) throws
    {
        super.init()
        // Checks the URL validity
        if (!C8oUtils.isValidUrl(endpoint)){
            //throw NSC8oError(domain: NSURLC8oErrorDomain, code: NSURLC8oErrorCannotOpenFile, userInfo: nil)
            throw C8oError.ArgumentException(C8oExceptionMessage.InvalidArgumentInvalidURL(endpoint))
        }
        
        // Checks the endpoint validty
        let regex : NSRegularExpression = C8o.RE_ENDPOINT
        let regexV  = regex.matchesInString(endpoint, options: [], range: NSMakeRange(0, endpoint.characters.count ))
        
        if(regexV.first == nil){
            throw C8oError.ArgumentException(C8oExceptionMessage.InvalidArgumentInvalidEndpoint(endpoint))
        }
        
        _endpoint = endpoint
        _endpointConvertigo = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(1))
        
        if(regexV[0].rangeAtIndex(2).location != NSNotFound){
            _endpointIsSecure  = !(endpoint as NSString?)!.substringWithRange(regexV[0].rangeAtIndex(2)).isEmpty
        }
        else {
            _endpointIsSecure  = false
        }
        _endpointHost = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(3))
        _endpointPort = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(4))
        _endpointProject = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(5))
        
        if (c8oSettings != nil){
            copyProperties(c8oSettings!)
        }
        
        self.httpInterface  =  C8oHttpInterface(c8o: self)
        self.c8oLogger = C8oLogger(c8o: self)
        self.c8oLogger!.logMethodCall("C8o constructor")
        self.c8oFullSync = C8oFullSyncCbl(c8o: self)
    }
    
    /**
     This calls a Convertigo requestable.
     Example usage:
     @code
     myc8o : C8o = C8o()
     myC8o.Call(requestable, parameters, c8oResponseXmlListener, c8oExceptionListener)
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     */
    public func call(requestable :String?, parameters : Dictionary<String, AnyObject>? = nil , c8oResponseListener : C8oResponseListener , c8oExceptionListener  : C8oExceptionListener )-> Void
    {
        var parameters = parameters
        do
        {
            if(requestable == nil)
            {
                throw C8oError.ArgumentNilException(C8oExceptionMessage.InvalidArgumentNullParameter("requestable")) //System.ArgumentNullException(C8oExceptionMessage.InvalidArgumentNullParameter("requestable"))*/
            }
            
            // Checks parameters validity
            if (parameters == nil)
            {
                parameters = Dictionary<String, AnyObject>()
            }
            else
            {
                // Clone parameters in order to modify them
                parameters = Dictionary<String, AnyObject>?(parameters!)
            }
            
            // Use the requestable string to add parameters corresponding to the c8o project, sequence, connector and transaction (<project>.<sequence> or <project>.<connector>.<transaction>)
            let regex : NSRegularExpression = C8o.RE_REQUESTABLE
            let regexV  = regex.matchesInString(requestable!, options: [], range: NSMakeRange(0, requestable!.characters.count ))
            
            if(regexV.first == nil){
                throw C8oError.ArgumentException(C8oExceptionMessage.InvalidArgumentInvalidEndpoint(_endpoint!)) //Exception(C8oExceptionMessage.InvalidArgumentInvalidEndpoint(endpoint))
            }
            
            
            // If the project name is specified
            if ((requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(1)) != "")
            {
                parameters![C8o.ENGINE_PARAMETER_PROJECT] =  (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(1))
            }
            
            
            // If the C8o call use a sequence
            
            if (((requestable! as NSString?)!.substringWithRange(regexV[0].rangeAtIndex(2)) as String?) !=  "")
            {
                parameters![C8o.ENGINE_PARAMETER_SEQUENCE ] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(2))
            }
            else
            {
                parameters![C8o.ENGINE_PARAMETER_CONNECTOR] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(3))
                
                parameters![C8o.ENGINE_PARAMETER_TRANSACTION] = (requestable! as NSString).substringWithRange(regexV[0].rangeAtIndex(4))
                
            }
            
            try! call(parameters, c8oResponseListener: c8oResponseListener, c8oExceptionListener: c8oExceptionListener)
        }
        catch let e as C8oException
        {
            handleCallException(c8oExceptionListener, requestParameters: parameters!, exception: e)
        }
        catch {
            let _ : String
        }
    }
    
    public func call(parameters : Dictionary<String, AnyObject>?  = nil, c8oResponseListener :  C8oResponseListener? = nil, c8oExceptionListener : C8oExceptionListener? = nil) throws
    {
        var parameters = parameters
        // IMPORTANT : all c8o calls have to end here !
        //TODO... no error are thrown in do block
        do
        {
            c8oLogger!.logMethodCall("Call", parameters: parameters!)
            
            // Checks parameters validity
            if (parameters == nil)
            {
                parameters = Dictionary<String, AnyObject>()
            }
            else
            {
                // Clones parameters in order to modify them
                //parameters = parameters
                parameters = Dictionary<String, AnyObject>?(parameters!)
            }
            
            // Creates a async task running on another thread
            // Exceptions have to be handled by the C8oExceptionListener
            let task = C8oCallTask(c8o: self, parameters: parameters!, c8oResponseListener: c8oResponseListener!, c8oExceptionListener: c8oExceptionListener!)
            task.execute()
        }
        /*catch let e as C8oException
        {
            handleCallException(c8oExceptionListener, requestParameters: parameters!, exception: e)
        }*/
    }
    
    /**
     Call a Convertigo Server backend service and return data in a JSON Object.
     CallJSON will asynchrously call a "requestable" (Sequence, transaction or FullSync database) and return a C8oPromise object.
     Example usage:
     @code
     myc8o : C8o = C8o()
     myC8o.CallJSON(requestable, parameters)
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @param requestable : String
     A "requestable" object of this form :
     <list type ="bullet">
     <item>project.sequence to call a Sequence in the convertigo server. If project is not specified explicitly here,
     (.sequence) the default project specified in the enpoint will be used.</item>
     <item>
     project.connector.transaction to call a transaction in the convertigo server. if project is not specified explicitly here,
     (.connector.transaction) the default project specified in the enpoint will be used. If
     connector is not specified (..transaction) the default connector will be used.</item>
     <item>fs://database.fullsync_verb   to call the local NoSQL database for quering, updating and syncing according to the full_sync
     verb used. See FullSync documentation for a list of verbs and parameters.</item>
     </list>
     @return A C8oPromise object on which you can chain other requests to get the data with the Then(), ThenUI() methods or
     use the Async() to wait for the server response without blocking the request thread. You can also use the .Fail() and
     FailUI() methods to handle C8oErrors.
     
     */
    public func callJson (requestable : String, parameters : Dictionary<String, AnyObject>?)-> C8oPromise<JSON>?
    {
        let promise = C8oPromise<JSON>(c8o: self)
        
        call(requestable,
            parameters: parameters,
            c8oResponseListener : C8oResponseJsonListener(onJsonResponse:{
                (params: Pair<JSON?, Dictionary<String, AnyObject>?>?)->() in
                
                if((params!.key) == nil ){
                    if((params!.value)!.keys.contains(C8o.ENGINE_PARAMETER_PROGRESS) == true){
                        
                        promise.onProgress(((((params!.value)! as Dictionary<String, AnyObject>?)![C8o.ENGINE_PARAMETER_PROGRESS]) as? C8oProgress)!)
                    }
                }
                else{
                    promise.onResponse((params?.key)! , parameters: (params!.value)!)
                }
                
            })
            , c8oExceptionListener : C8oExceptionListener(onException:{
                (params : Pair<C8oException, Dictionary<String, AnyObject>?>?)->() in
                
                promise.onFailure(params?.key as C8oException?, parameters: params?.value)
                
            }))
        return promise
    }
    
    
    public func callJson(requestable : String, parameters : AnyObject...)->C8oPromise<JSON>?{
        
        return try! callJson(requestable, parameters: C8o.toParameters(parameters))
        
    }
    
    
    public func callJson(requestable : String, parameters : JSON)-> C8oPromise<JSON>?{
        
        return callJson(requestable, parameters: (parameters.object as! Dictionary<String, NSObject>))
    }
    
    
    public func callXml(requestable : String, parameters :Dictionary<String, NSObject>)->C8oPromise<AEXMLDocument>
    {
        
        let promise = C8oPromise<AEXMLDocument>(c8o: self)
        
        call(requestable,
            parameters: parameters,
            c8oResponseListener : C8oResponseXmlListener(onXmlResponse:{
                (params : Pair<AnyObject?, Dictionary<String, AnyObject>?>?)->() in
                
                if((params!.key) == nil ){
                    if((params!.value)!.keys.contains(C8o.ENGINE_PARAMETER_PROGRESS) == true){
                        
                        promise.onProgress(((((params!.value)! as Dictionary<String, AnyObject>?)![C8o.ENGINE_PARAMETER_PROGRESS]) as? C8oProgress)!)
                    }
                }
                else{
                    promise.onResponse((params?.key)! as! AEXMLDocument, parameters: (params?.value)!)
                }
                
            })
            , c8oExceptionListener : C8oExceptionListener(onException:{
                (params : Pair<C8oException, Dictionary<String, AnyObject>?>?)->() in
                
                promise.onFailure(((params?.key) as C8oException?)!, parameters: (params?.value)!)
                
            }))
        return promise
        
    }
    
    public func callXml(requestable : String, parameters : AnyObject...)->C8oPromise<AEXMLDocument>
    {
        return try! callXml(requestable, parameters: C8o.toParameters(parameters))
    }
    /*public func CallXml(requestable : String)->C8oPromise<XMLDocument>
    {
    
    return CallXml(requestable, parameters: Dictionary<String, NSObject>())
    }*/
    
    public func addCookie(name : String, value : String)->Void
    {
        httpInterface!.addCookie(name, value: value)
    }
    
    public override var logC8o : Bool
        {
        get { return _logC8o! }
        set(value) { _logC8o = value }
    }
    
    public override var logRemote:Bool
        {
        get { return _logRemote! }
        set(value){ _logRemote = value }
    }
    
    public override var logLevelLocal : C8oLogLevel
        {
        get { return _logLevelLocal }
        set(value) { _logLevelLocal = value }
    }
    
    
    /*public func Log(C8oLogLevel c8oLogLevel, string message)
    {
    c8oLogger.Log(c8oLogLevel, message)
    }*/
    
    
    public var log : C8oLogger{
        get { return c8oLogger! }
    }
    
    
    public func runUI (block: dispatch_block_t) {
        if(NSThread.isMainThread())
        {
            block()
        }
        else {
            dispatch_async(dispatch_get_main_queue(), {
                block()
            })
        }
        
        
    }
    public func toString()->String
    {
        return "C8o[" + _endpoint! + "] " //+ super.description()
    }
    
    
    public var endpoint: String
        {
        get { return _endpoint! }
    }
    
    
    public var endpointConvertigo : String
        {
        get { return _endpointConvertigo! }
    }
    
    
    public var endpointIsSecure :  Bool
        {
        get { return _endpointIsSecure! }
    }
    
    
    public var endpointHost : String
        {
        get { return _endpointHost! }
    }
    
    
    public var endpointPort :  String
        {
        get { return _endpointPort! }
    }
    
    public var endpointProject :  String
        {
        get { return _endpointProject! }
    }
    
    
    public var deviceUUID : String{
        get { return C8o.deviceUUID }
    }
    
    public var cookieStore : NSObject
        {
        get { return httpInterface!.cookieStore! }
    }
    
    private static func toParameters(parameters : [AnyObject]?)throws ->Dictionary<String, NSObject>
    {   
        if (parameters!.count % 2 != 0)
        {
            throw C8oError.InvalidArgument(C8oExceptionMessage.invalidParameterValue("parameters", details: "needs pairs of values"))
        }
        
        var newParameters = Dictionary<String, NSObject>()

        for i in 0.stride(to: parameters!.count, by: 2)
        {
            newParameters[String(parameters![i])] = parameters![i + 1] as? NSObject
        }
        
        return newParameters
    }
    
    internal func handleCallException(c8oExceptionListener: C8oExceptionListener?, requestParameters : Dictionary<String, AnyObject>, exception : C8oException)
    {
        c8oLogger!._warn("Handle a call exception", exceptions: exception)
        
        if (c8oExceptionListener != nil)
        {
            c8oExceptionListener!.onException(Pair<C8oException, Dictionary<String, AnyObject>?>(key: exception, value: requestParameters))
        }
    }
}



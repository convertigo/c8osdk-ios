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
import Fuzi

import CouchbaseLite

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
    internal static var C8oHttpInterfaceUsed : Type?
    internal static var C8oFullSyncUsed : Type?
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
    public static func GetSdkVersion()-> String
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
    private var endpoint : String?
    private var endpointConvertigo: String?
    private var endpointIsSecure : Bool?
    private var endpointHost : String?
    private var endpointPort : String?
    private var endpointProject : String?
    
    
    
    
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
        if (!C8oUtils.IsValidUrl(endpoint)){
            //throw NSC8oError(domain: NSURLC8oErrorDomain, code: NSURLC8oErrorCannotOpenFile, userInfo: nil)
            throw C8oError.ArgumentException(C8oExceptionMessage.InvalidArgumentInvalidURL(endpoint))
        }
        
        // Checks the endpoint validty
        let regex : NSRegularExpression = C8o.RE_ENDPOINT
        let regexV  = regex.matchesInString(endpoint, options: [], range: NSMakeRange(0, endpoint.characters.count ))
        
        if(regexV.first == nil){
            throw C8oError.ArgumentException(C8oExceptionMessage.InvalidArgumentInvalidEndpoint(endpoint))
        }
        
        self.endpoint = endpoint
        self.endpointConvertigo = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(1))

        if(regexV[0].rangeAtIndex(2).location != NSNotFound){
            self.endpointIsSecure  = !(endpoint as NSString?)!.substringWithRange(regexV[0].rangeAtIndex(2)).isEmpty
        }
        else {
            self.endpointIsSecure  = false
        }
        self.endpointHost = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(3))
        self.endpointPort = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(4))
        self.endpointProject = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(5))
        
        if (c8oSettings != nil){
            self.Copy(c8oSettings!)
        }
        if (UiDispatcher == nil){
           // uiDispatcher = self.defaultUiDispatcher
        }

        self.httpInterface  =  C8oHttpInterface(c8o: self)
        self.c8oLogger = C8oLogger(c8o: self)
        self.c8oLogger!.LogMethodCall("C8o constructor")
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
    public func Call(requestable :String?, var parameters : Dictionary<String, NSObject>? = nil , c8oResponseListener : C8oResponseListener , c8oExceptionListener  : C8oExceptionListener )-> Void
    {
        do
        {
            if(requestable == nil)
            {
                throw C8oError.ArgumentNilException(C8oExceptionMessage.InvalidArgumentNullParameter("requestable")) //System.ArgumentNullException(C8oExceptionMessage.InvalidArgumentNullParameter("requestable"))*/
            }
            
            // Checks parameters validity
            if (parameters == nil)
            {
                parameters = Dictionary<String, NSObject>()
            }
            else
            {
                // Clone parameters in order to modify them
                parameters = Dictionary<String, NSObject>?(parameters!)
            }
            
            // Use the requestable string to add parameters corresponding to the c8o project, sequence, connector and transaction (<project>.<sequence> or <project>.<connector>.<transaction>)
            let regex : NSRegularExpression = C8o.RE_REQUESTABLE
            let regexV  = regex.matchesInString(requestable!, options: [], range: NSMakeRange(0, requestable!.characters.count ))
            
            if(regexV.first == nil){
                throw C8oError.ArgumentException(C8oExceptionMessage.InvalidArgumentInvalidEndpoint(endpoint!)) //Exception(C8oExceptionMessage.InvalidArgumentInvalidEndpoint(endpoint))
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
            
            try! Call(parameters, c8oResponseListener: c8oResponseListener, c8oExceptionListener: c8oExceptionListener)
        }
        catch let e as C8oException
        {
            HandleCallException(c8oExceptionListener, requestParameters: parameters!, exception: e)
        }
        catch {
            let e : String
        }
    }
    
    public func Call(var parameters : Dictionary<String, NSObject>?  = nil, c8oResponseListener :  C8oResponseListener? = nil, c8oExceptionListener : C8oExceptionListener? = nil) throws
    {
        // IMPORTANT : all c8o calls have to end here !
        do
        {
            c8oLogger!.LogMethodCall("Call", parameters: parameters!)
            
            // Checks parameters validity
            if (parameters == nil)
            {
                parameters = Dictionary<String, NSObject>()
            }
            else
            {
                // Clones parameters in order to modify them
                //parameters = parameters
                parameters = Dictionary<String, NSObject>?(parameters!)
            }
            
            // Creates a async task running on another thread
            // Exceptions have to be handled by the C8oExceptionListener
            let task = C8oCallTask(c8o: self, parameters: parameters!, c8oResponseListener: c8oResponseListener!, c8oExceptionListener: c8oExceptionListener!)
            task.Execute()
        }
        catch let e as C8oException
        {
            HandleCallException(c8oExceptionListener, requestParameters: parameters!, exception: e)
        }
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
    public func CallJson (requestable : String, parameters : Dictionary<String, NSObject>?)-> C8oPromise<JSON>?
    {
        let promise = C8oPromise<JSON>(c8o: self)
        
        Call(requestable,
            parameters: parameters,
            c8oResponseListener : C8oResponseJsonListener(onJsonResponse:{
                (params: Pair<JSON?, Dictionary<String, NSObject>?>?)->() in
                
                if((params!.key) == nil ){
                    if((params!.value)!.keys.contains(C8o.ENGINE_PARAMETER_PROGRESS) == true){
                        
                        promise.OnProgress(((((params!.value)! as Dictionary<String, NSObject>?)![C8o.ENGINE_PARAMETER_PROGRESS]) as? C8oProgress)!)
                    }
                }
                else{
                    promise.OnResponse((params?.key)! , parameters: (params?.value)!)
                }
                
                })
            , c8oExceptionListener : C8oExceptionListener(OnException:{
                (params : Pair<C8oException, Dictionary<String, NSObject>?>?)->() in
                
                promise.OnFailure(((params?.key) as C8oException?)!, parameters: (params?.value)!)
                
            }))
        return promise
    }
    
    
    public func CallJson(requestable : String, parameters : NSObject...)->C8oPromise<JSON>?{
        
        return try! CallJson(requestable, parameters: C8o.ToParameters(parameters))
        
    }
    
    
    public func CallJson(requestable : String, parameters : JSON)-> C8oPromise<JSON>?{
        
            return CallJson(requestable, parameters: (parameters.object as! Dictionary<String, NSObject>))
    }
    
    
    public func CallXml(requestable : String, parameters :Dictionary<String, NSObject>)->C8oPromise<XMLDocument>
    {
        
        let promise = C8oPromise<XMLDocument>(c8o: self)
        
        Call(requestable,
            parameters: parameters,
            c8oResponseListener : C8oResponseXmlListener(onXmlResponse:{
                (params : Pair<AnyObject?, Dictionary<String, NSObject>?>?)->() in
                
                if((params!.key) == nil ){
                    if((params!.value)!.keys.contains(C8o.ENGINE_PARAMETER_PROGRESS) == true){
                        
                        promise.OnProgress(((((params!.value)! as Dictionary<String, NSObject>?)![C8o.ENGINE_PARAMETER_PROGRESS]) as? C8oProgress)!)
                    }
                }
                else{
                    promise.OnResponse((params?.key)! as! XMLDocument, parameters: (params?.value)!)
                }
                
            })
            , c8oExceptionListener : C8oExceptionListener(OnException:{
                (params : Pair<C8oException, Dictionary<String, NSObject>?>?)->() in
                
                promise.OnFailure(((params?.key) as C8oException?)!, parameters: (params?.value)!)
                
            }))
        return promise
        
    }
    
    public func CallXml(requestable : String, parameters : NSObject...)->C8oPromise<XMLDocument>
    {
        
        return try! CallXml(requestable, parameters: C8o.ToParameters(parameters))
    }
    /*public func CallXml(requestable : String)->C8oPromise<XMLDocument>
    {
        
        return CallXml(requestable, parameters: Dictionary<String, NSObject>())
    }*/
    
    public func AddCookie(name : String, value : String)->Void
    {
        httpInterface!.AddCookie(name, value: value)
    }
    
    public override var LogC8o : Bool
        {
        get { return logC8o! }
        set(value) { logC8o = value }
    }
    
    public  override var LogRemote:Bool
        {
        get { return logRemote! }
        set(value){ logRemote = value }
    }

    public override var LogLevelLocal : C8oLogLevel
        {
        get { return logLevelLocal }
        set(value) { logLevelLocal = value }
    }

    
    /*public func Log(C8oLogLevel c8oLogLevel, string message)
    {
    c8oLogger.Log(c8oLogLevel, message)
    }*/
    
    
    public var Log : C8oLogger{
        get { return c8oLogger! }
    }
    

    public func RunUI (block: dispatch_block_t) {
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
        return "C8o[" + endpoint! + "] " //+ super.description()
    }
    

    public var Endpoint: String
        {
        get { return endpoint! }
    }
    

    public var EndpointConvertigo : String
        {
        get { return endpointConvertigo! }
    }
    

    public var EndpointIsSecure :  Bool
        {
        get { return endpointIsSecure! }
    }
    

    public var EndpointHost : String
        {
        get { return endpointHost! }
    }
    

    public var EndpointPort :  String
        {
        get { return endpointPort! }
    }
    
    public var EndpointProject :  String
        {
        get { return endpointProject! }
    }
    

    public var DeviceUUID : String{
        get { return C8o.deviceUUID }
    }
    

    public var CookieStore : NSObject//CookieContainer
        {
        get { return httpInterface!.CookieStore! }
    }
    
    private static func ToParameters(parameters : [NSObject]?)throws ->Dictionary<String, NSObject>
    {
        if (parameters!.count % 2 != 0)
        {
            throw C8oError.InvalidArgument(C8oExceptionMessage.InvalidParameterValue("parameters", details: "needs pairs of values")) //throw System.ArgumentException(C8oExceptionMessage.InvalidParameterValue("parameters", "needs pairs of values"))
        }
        
        var newParameters = Dictionary<String, NSObject>()
        
        for var i = 0; i < parameters!.count; i += 2
        {
            newParameters[String(parameters![i])] = parameters![i + 1]
        }
        return newParameters
    }
    
    internal func HandleCallException(c8oExceptionListener: C8oExceptionListener?, requestParameters : Dictionary<String, NSObject>, exception : C8oException)
    {
        c8oLogger!._Warn("Handle a call exception", exceptions: exception)
        
        if (c8oExceptionListener != nil)
        {
            c8oExceptionListener!.OnException(Pair<C8oException, Dictionary<String, NSObject>?>(key: exception, value: requestParameters))
        }
    }
}



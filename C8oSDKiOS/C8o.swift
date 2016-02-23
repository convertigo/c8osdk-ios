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

import CouchbaseLite

@objc public class C8o : C8oBase {
    
    
    
    
    /*************** Tests ***************/
    

    
    public func createDB() {
       
        print("Hello C8o SDK!");
        
        
        
        var options = CBLManagerOptions(readOnly: false, fileProtection:NSDataWritingOptions.AtomicWrite )
        
        do {
            let manager = try CBLManager(directory: CBLManager.defaultDirectory(), options: &options)
            let database = try manager.databaseNamed("testdatabase")
            database.maxRevTreeDepth = 10

            
            
            let properties = [
                "test" : "data",
                "test2": "data"
            ]
            
            let document = database.createDocument()
            try document.putProperties(properties)
            print(document)
            
        } catch _ {
            print("manager Creation failed")
        }
        
        print("Manager initialized");
    }
    
    public func makeRequest()  {
        
        
        Alamofire.request(.GET, "https://httpbin.org/get", parameters: ["foo": "bar"])
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
    
                if let JSon = response.result.value {
                    print("JSON: \(JSon)")
                    var data = JSON(JSon)
                }
                
                if let JSon = response.result.value {
                    print("JSON: \(JSon)")
                    var data = JSON(JSon)
                }
                
        }
    }
    
    
    
    
    /*************** Fin de tests ***************/
    
    
    //*** Regular Expression ***//
    
    /// <summary>
    /// The regex used to handle the c8o requestable syntax ("<project>.<sequence>" or "<project>.<connector>.<transaction>")
    /// </summary>
    private static let RE_REQUESTABLE : NSRegularExpression =  try! NSRegularExpression(pattern: "^([^.]*)\\.(?:([^.]+)|([^.]+)\\.([^.]+))$", options: []);
    /// <summary>
    /// The regex used to get the part of the endpoint before '/projects/'
    /// </summary>
    public static let RE_ENDPOINT : NSRegularExpression =  try! NSRegularExpression(pattern: "^(http(s)?://([^:]+)(:[0-9]+)?/?.*?)/projects/[^/]+$", options: []);
    
    //*** Engine reserved parameters ***//
    
    internal static var ENGINE_PARAMETER_PROJECT : String = "__project";
    internal static var ENGINE_PARAMETER_SEQUENCE : String = "__sequence";
    internal static var ENGINE_PARAMETER_CONNECTOR : String = "__connector";
    internal static var ENGINE_PARAMETER_TRANSACTION : String = "__transaction";
    internal static var ENGINE_PARAMETER_ENCODED : String = "__encoded";
    internal static var ENGINE_PARAMETER_DEVICE_UUID : String = "__uuid";
    internal static var ENGINE_PARAMETER_PROGRESS : String = "__progress";

     //*** FULLSYNC parameters ***//

    public static var FS_POLICY : String =  "_use_policy";
    public static var FS_POLICY_NONE : String =  "none";
    public static var FS_POLICY_CREATE : String =  "create";
    public static var FS_POLICY_OVERRIDE : String =  "override";
    public static var FS_POLICY_MERGE : String =  "merge";
    public static var FS_SUBKEY_SEPARATOR : String =  "_use_subkey_separator";
    
    //*** Local cache keys ***//
    
    internal static var LOCAL_CACHE_DOCUMENT_KEY_RESPONSE : String =  "response";
    internal static var LOCAL_CACHE_DOCUMENT_KEY_RESPONSE_TYPE : String =  "responseType";
    internal static var LOCAL_CACHE_DOCUMENT_KEY_EXPIRATION_DATE : String =  "expirationDate";
    
    public static var LOCAL_CACHE_DATABASE_NAME : String =  "c8olocalcache";
    
    //*** Response type ***//
    
    internal static var RESPONSE_TYPE_XML : String =  "pxml";
    internal static var RESPONSE_TYPE_JSON : String =  "json";
    
    //*** Static configuration ***//
    internal static var C8oHttpInterfaceUsed : Type?;
    internal static var C8oFullSyncUsed : Type?;
    internal static var defaultUiDispatcher : NSObject?//ACTION<ACTION>?;
    internal static var deviceUUID : String?;
    
    public static func GetSdkVersion()-> String
    {
        return "2.0.0";
    }
    
    //*** Attributes ***//
    
    /// <summary>
    /// The Convertigo endpoint, syntax : <protocol>://<server>:<port>/<Convertigo web app path>/projects/<project name> (Example : http://127.0.0.1:18080/convertigo/projects/MyProject)
    /// </summary>
    private var endpoint : String?;
    private var endpointConvertigo: String?;
    private var endpointIsSecure : Bool?;
    private var endpointHost : String?;
    private var endpointPort : String?;
    
    
    
    /// <summary>
    /// Used to run HTTP requests.
    /// </summary>
    internal var httpInterface : C8oHttpInterface?;
    
    /// <summary>
    /// Allows to log locally and remotely to the Convertigo server.
    /// </summary>
    internal var c8oLogger : C8oLogger? ;
    
    /// <summary>
    /// Allows to make fullSync calls.
    /// </summary>
    internal var c8oFullSync :C8oFullSync?;
    
    //*** Constructors ***//
    
    /// <summary>
    /// This is the base object representing a Convertigo Server end point. This object should be instanciated
    /// when the apps starts and be accessible from any class of the app. Although this is not common , you may have
    /// several C8o objects instanciated in your app.
    /// </summary>
    /// <param name="endpoint">The End point url to you convertigo server. Can be :
    ///     - http(s)://your_server_address/convertigo/projects/your_project_name (if using an on premises server)
    ///     - http(s)://your_cloud_server.convertigo.net/cems/projects/your_project_name (if using a Convertigo cloud server)
    /// </param>
    /// <param name="c8oSettings">
    /// A C8oSettings object describing the endpoint configuration parameters such as authorizations credentials,
    /// cookies, client certificates and various other settings.
    /// </param>
    public override init() {
        super.init()
    }
    
    
    
    public init(endpoint :String, c8oSettings : C8oSettings?) throws
    {
        super.init()
        
        // Checks the URL validity
        if (!C8oUtils.IsValidUrl(endpoint))
        {
            throw Error.InvalidArgument
            //print(endpoint + "is not a valid Url")
        }
    
        // Checks the endpoint validty

        let regex : NSRegularExpression = C8o.RE_ENDPOINT
        let regexV  = regex.matchesInString(endpoint, options: [], range: NSMakeRange(0, endpoint.characters.count ))
        
        if(regexV.first == nil){
            throw Error.InvalidArgument
        }

        self.endpoint = endpoint;
        
        //var matchRange = matches![0].rangeAtIndex(1)
        self.endpointConvertigo = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(1))
        //matchRange = matches![0].rangeAtIndex(2)
        self.endpointIsSecure  = !(endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(2)).isEmpty
        //matchRange = matches![0].rangeAtIndex(3)
        self.endpointHost = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(3))
        //matchRange = matches![0].rangeAtIndex(4)
        self.endpointPort = (endpoint as NSString).substringWithRange(regexV[0].rangeAtIndex(4))
        
        if (c8oSettings != nil)
        {
            
            self.Copy(c8oSettings!);
        }
    
        self.httpInterface  =  C8oHttpInterface(c8o: self)
        self.c8oLogger = C8oLogger(c8o: self)
        self.c8oLogger!.LogMethodCall("C8o constructor")
        self.c8oFullSync = C8oFullSyncCbl(c8o: self)
        
        /*do
            {
                if (self.httpInterface != nil)
                {
                    httpInterface = try! httpInterface.GetTypeInfo().DeclaredConstructors.ElementAt(1).Invoke([NSObject] { self }) as C8oHttpInterface;
                }
                else
                {
                    httpInterface = try! C8oHttpInterface(self);
                }
        }
        catch
        {
            //throw C8oException(C8oExceptionMessage.InitHttpInterface(), e);
        }
    
    
        do
            {
                if (C8oFullSyncUsed != nil)
                {
                    c8oFullSync = try! C8oFullSyncUsed.GetTypeInfo().DeclaredConstructors.ElementAt(0).Invoke(object[0]) as C8oFullSync;
                }
                else
                {
                    c8oFullSync = try! C8oFullSyncHttp(FullSyncServerUrl, FullSyncUsername, FullSyncPassword);
                }
                c8oFullSync.self);
        }
        catch
        {
            //throw  C8oException(C8oExceptionMessage.FullSyncInterfaceInstance(), e);
        }*/
        
    }
    
    //*** C8o calls ***//
    public func Call(requestable :String?, var parameters : Dictionary<String, NSObject>? = nil , c8oResponseListener : C8oResponseListener? = nil, c8oExceptionListener  : C8oExceptionListener? = nil)-> Void
    {
        do
        {
            if(requestable == nil)
            {
                //throw System.ArgumentNullException(C8oExceptionMessage.InvalidArgumentNullParameter("requestable"));*/
            }
    
            // Checks parameters validity
            if (parameters == nil)
            {
                 parameters = Dictionary<String, NSObject>();
            }
            else
            {
                // Clone parameters in order to modify them
                //parameters = Dictionary<String, NSObject>?(parameters);
            }
    
            // Use the requestable string to add parameters corresponding to the c8o project, sequence, connector and transaction (<project>.<sequence> or <project>.<connector>.<transaction>)
            let matches : NSArray? = C8o.RE_REQUESTABLE.matchesInString(requestable!, options :[], range: NSMakeRange(0, endpoint!.characters.count ));
            if (matches == nil){
                //throw Exception(C8oExceptionMessage.InvalidArgumentInvalidEndpoint(endpoint));
            }
            
            var matchRange = matches![1].rangeAtIndex(1)

            // If the project name is specified
            if ((endpoint! as NSString).substringWithRange(matchRange) != "")
            {
                parameters = ["ENGINE_PARAMETER_PROJECT" :(endpoint! as NSString).substringWithRange(matchRange)];
            }
            
            matchRange = matches![1].rangeAtIndex(2)
            
            // If the C8o call use a sequence
            if ((endpoint! as NSString).substringWithRange(matchRange) != "")
            {
                parameters = ["ENGINE_PARAMETER_SEQUENCE" :(endpoint! as NSString).substringWithRange(matchRange)];
            }
            else
            {
                matchRange = matches![1].rangeAtIndex(3)
                parameters = ["ENGINE_PARAMETER_CONNECTOR" :(endpoint! as NSString).substringWithRange(matchRange)];
                
                matchRange = matches![1].rangeAtIndex(4)
                parameters = ["ENGINE_PARAMETER_TRANSACTION" :(endpoint! as NSString).substringWithRange(matchRange)];

            }
    
            //Call(parameters, c8oResponseListener, c8oExceptionListener);
        }
        catch
        {
            //HandleCallException(c8oExceptionListener, parameters, e);
        }
    }
    
    public func Call(var parameters : Dictionary<String, NSObject>?  = nil, c8oResponseListener :  C8oResponseListener? = nil, c8oExceptionListener : C8oExceptionListener? = nil)
    {
        // IMPORTANT : all c8o calls have to end here !
        do
        {
            //c8oLogger.LogMethodCall("Call", var parameters: parameters!);
    
            // Checks parameters validity
            if (parameters == nil)
            {
                parameters = Dictionary<String, NSObject>();
            }
            else
            {
                // Clones parameters in order to modify them
            //    parameters = Dictionary<String, NSObject>(parameters);
            }
    
            // Creates a async task running on another thread
            // Exceptions have to be handled by the C8oExceptionListener
            //var task = C8oCallTask(this, parameters, c8oResponseListener, c8oExceptionListener);
           // task.Execute();
        }
        catch
        {
            //HandleCallException(c8oExceptionListener, parameters, e);
        }
    }
    
    
    
    /// <summary>
    /// Call a Convertigo Server backend service and return data in a JSON Object.
    /// CallJSON will asynchrously call a "requestable" (Sequence, transaction or FullSync database) and return a
    /// C8oPromise object.
    /// </summary>
    /// <param name="requestable">
    /// A "requestable" object of this form :
    /// <list type ="bullet">
    ///     <item>project.sequence to call a Sequence in the convertigo server. If project is not specified explicitly here,
    ///     (.sequence) the default project specified in the enpoint will be used.</item>
    ///     <item>
    ///     project.connector.transaction to call a transaction in the convertigo server. if project is not specified explicitly here,
    ///     (.connector.transaction) the default project specified in the enpoint will be used. If
    ///     connector is not specified (..transaction) the default connector will be used.</item>
    ///     <item>fs://database.fullsync_verb   to call the local NoSQL database for quering, updating and syncing according to the full_sync
    ///     verb used. See FullSync documentation for a list of verbs and parameters.</item>
    /// </list>
    /// </param>
    /// <param name="parameters">
    /// A IDictionary of Key/Value pairs mapped on Sequence/transaction/fullsync variables.
    /// </param>
    /// <returns>
    /// A C8oPromise object on which you can chain other requests to get the data with the Then(), ThenUI() methods or
    /// use the Async() to wait for the server response without blocking the request thread. You can also use the .Fail() and
    /// FailUI() methods to handle errors.
    /// </returns>
    public func CallJson (requestable : String, parameters : Dictionary<String, NSObject>)-> C8oPromise<JSON>?
    {
        /*var promise = C8oPromise<JSON>(self);
    
        Call(requestable, parameters, C8oResponseJsonListener((response, requestParameters) =>
            {
                if (response == nil && requestParameters.ContainsKey(ENGINE_PARAMETER_PROGRESS))
                {
                    promise.OnProgress(requestParameters[ENGINE_PARAMETER_PROGRESS] as C8oProgress);
                }
                else
                {
                    promise.OnResponse(response, requestParameters);
                }
            }), C8oExceptionListener((exception, requestParameters) =>
                {
                    promise.OnFailure(exception, requestParameters);
                }));
    
        return promise;*/
        return nil
    }
    
    /// <summary>
    /// Call a Convertigo Server backend service and return data in a JSON Object.
    /// CallJSON will asynchrously call a "requestable" (Sequence, transaction or FullSync database) and return a
    /// C8oPromise object.
    /// </summary>
    /// <param name="requestable">
    /// A "requestable" object of this form :
    /// <list type ="bullet">
    ///     <item>project.sequence to call a Sequence in the convertigo server. If project is not specified explicitly here,
    ///     (.sequence) the default project specified in the enpoint will be used.</item>
    ///     <item>
    ///     project.connector.transaction to call a transaction in the convertigo server. if project is not specified explicitly here,
    ///     (.connector.transaction) the default project specified in the enpoint will be used. If
    ///     connector is not specified (..transaction) the default connector will be used.</item>
    ///     <item>fs://database.fullsync_verb   to call the local NoSQL database for quering, updating and syncing according to the full_sync
    ///     verb used. See FullSync documentation for a list of verbs and parameters.</item>
    /// </list>
    /// </param>
    /// <param name="parameters">
    /// A a list of Key/Value pairs mapped on Sequence/transaction/fullsync variables.
    /// </param>
    /// <returns>
    /// A C8oPromise object on which you can chain other requests to get the data with the Then(), ThenUI() methods or
    /// use the Async() to wait for the server response without blocking the request thread. You can also use the .Fail() and
    /// FailUI() methods to handle errors.
    /// </returns>
    /// <sample>
    /// This is a sample usage of CallJSON to call a "select_shop" sequence providing a shopCode variable ste to "42". We use the
    /// Async() method to wait without blocking the calling thread with the await operator.
    /// <code>
    ///     JObject data = await myC8o.CallJSON(".select_shop", "shopCode, "42").Async();
    /// </code>
    /// or this code to use the promise :
    /// <code>
    ///    myC8o.CallJson (".select_shop",							 // This is the requestable
    ///        "shopCode", "42"										 // The key/value parameters to the sequence
    ///    ).Then((response, parameters) => {						 // This will run as soon as the Convertigo server responds
    ///        // do my stuff in a	 worker thread					 // This is worker thread not suitable to update UI
    ///        String sc = (String)response["document"]["shopCode"]; // Get the data using Linq
    ///        myC8o.Log (C8oLogLevel.DEBUG, sc);					 // Log data on the Convertigo Server
    ///        return null;											 // last step of the promise chain, return null
    ///    });
    /// </code>
    /// </sample>
    public func CallJson(requestable : String, parameters : [NSObject]...)->C8oPromise<NSObject>? //C8oPromise<JObject>
    {
        //return CallJson(requestable, ToParameters(parameters));
        return nil
    }
    
    /// <summary>
    /// Call a Convertigo Server backend service and return data in a JSON Object.
    /// CallJSON will asynchrously call a "requestable" (Sequence, transaction or FullSync database) and return a
    /// C8oPromise object.
    /// </summary>
    /// <param name="requestable">
    /// A "requestable" object of this form :
    /// <list type ="bullet">
    ///     <item>project.sequence to call a Sequence in the convertigo server. If project is not specified explicitly here,
    ///     (.sequence) the default project specified in the enpoint will be used.</item>
    ///     <item>
    ///     project.connector.transaction to call a transaction in the convertigo server. if project is not specified explicitly here,
    ///     (.connector.transaction) the default project specified in the enpoint will be used. If
    ///     connector is not specified (..transaction) the default connector will be used.</item>
    ///     <item>fs://database.fullsync_verb   to call the local NoSQL database for quering, updating and syncing according to the full_sync
    ///     verb used. See FullSync documentation for a list of verbs and parameters.</item>
    /// </list>
    /// </param>
    /// <param name="parameters">
    /// A JObject of Key/Value pairs mapped on Sequence/transaction/fullsync variables.
    /// </param>
    /// <returns>
    /// A C8oPromise object on which you can chain other requests to get the data with the Then(), ThenUI() methods or
    /// use the Async() to wait for the server response without blocking the request thread. You can also use the .Fail() and
    /// FailUI() methods to handle errors.
    /// </returns>
    /// <sample>
    /// This is a sample usage of CallJSON to call a "select_shop" sequence providing a shopCode variable ste to "42". We use the
    /// Async() method to wait without blocking the calling thread with the await operator.
    /// <code>
    ///     JObject parameter = new JObject() {{"shopCode", "42"}};
    ///     JObject data = await myC8o.CallJSON(".select_shop", parameter).Async();
    /// </code>
    /// or this code to use the promise :
    /// <code>
    ///    myC8o.CallJson (".select_shop",							 // This is the requestable
    ///        parameter	    									 // The key/value parameters to the sequence
    ///    ).Then((response, parameters) => {						 // This will run as soon as the Convertigo server responds
    ///        // do my stuff in a	 worker thread					 // This is worker thread not suitable to update UI
    ///        String sc = (String)response["document"]["shopCode"]; // Get the data using Linq
    ///        myC8o.Log (C8oLogLevel.DEBUG, sc);					 // Log data on the Convertigo Server
    ///        return null;											 // last step of the promise chain, return null
    ///    });
    /// </code>
    /// </sample>
    public func CallJson(requestable : String, parameters : JSON)-> C8oPromise<NSObject>?//C8oPromise<JObject>
    {
        //return CallJson(requestable, parameters.ToObject<Dictionary<String, NSObject>>());
        return nil
    }
    
    
    /// <summary>
    /// Call a Convertigo Server backend service and return data as an XML Document.
    /// CallXML will asynchrously call a "requestable" (Sequence, transaction or FullSync database) and return a
    /// C8oPromise object.
    /// </summary>
    /// <param name="requestable">
    /// A "requestable" object of this form :
    /// <list type ="bullet">
    ///     <item>project.sequence to call a Sequence in the convertigo server. If project is not specified explicitly here,
    ///     (.sequence) the default project specified in the enpoint will be used.</item>
    ///     <item>
    ///     project.connector.transaction to call a transaction in the convertigo server. if project is not specified explicitly here,
    ///     (.connector.transaction) the default project specified in the enpoint will be used. If
    ///     connector is not specified (..transaction) the default connector will be used.</item>
    ///     <item>fs://database.fullsync_verb   to call the local NoSQL database for quering, updating and syncing according to the full_sync
    ///     verb used. See FullSync documentation for a list of verbs and parameters.</item>
    /// </list>
    /// </param>
    /// <param name="parameters">
    /// A IDictionary of Key/Value pairs mapped on Sequence/transaction/fullsync variables.
    /// </param>
    /// <returns>
    /// A C8oPromise object on which you can chain other requests to get the data with the Then(), ThenUI() methods or
    /// use the Async() to wait for the server response without blocking the request thread. You can also use the .Fail() and
    /// FailUI() methods to handle errors.
    /// </returns>
    public func CallXml(requestable : String, parameters :Dictionary<String, NSObject>)->C8oPromise<NSObject>?//C8oPromise<XDocument>
    {
        /*var promise = C8oPromise<XDocument>(self);
    
        Call(requestable, parameters, C8oResponseXmlListener((response, requestParameters) =>
            {
                if (response == null && requestParameters.ContainsKey(ENGINE_PARAMETER_PROGRESS))
                {
                    promise.OnProgress(requestParameters[ENGINE_PARAMETER_PROGRESS] as C8oProgress);
                }
                else
                {
                    promise.OnResponse(response, requestParameters);
                }
            }), C8oExceptionListener((NSException, requestParameters) =>
                {
                    promise.OnFailure(NSException, requestParameters);
                }));
    
        return promise;*/
        return nil
    }
    
    
    /// <summary>
    /// Call a Convertigo Server backend service and return data as an XML Document.
    /// CallXML will asynchrously call a "requestable" (Sequence, transaction or FullSync database) and return a
    /// C8oPromise object.
    /// </summary>
    /// <param name="requestable">
    /// A "requestable" object of this form :
    /// <list type ="bullet">
    ///     <item>project.sequence to call a Sequence in the convertigo server. If project is not specified explicitly here,
    ///     (.sequence) the default project specified in the enpoint will be used.</item>
    ///     <item>
    ///     project.connector.transaction to call a transaction in the convertigo server. if project is not specified explicitly here,
    ///     (.connector.transaction) the default project specified in the enpoint will be used. If
    ///     connector is not specified (..transaction) the default connector will be used.</item>
    ///     <item>fs://database.fullsync_verb   to call the local NoSQL database for quering, updating and syncing according to the full_sync
    ///     verb used. See FullSync documentation for a list of verbs and parameters.</item>
    /// </list>
    /// </param>
    /// <param name="parameters">
    /// A a list of Key/Value pairs mapped on Sequence/transaction/fullsync variables.
    /// </param>
    /// <returns>
    /// A C8oPromise object on which you can chain other requests to get the data with the Then(), ThenUI() methods or
    /// use the Async() to wait for the server response without blocking the request thread. You can also use the .Fail() and
    /// FailUI() methods to handle errors.
    /// </returns>
    public func CallXml(requestable : String, parameters : [NSObject] ...)->C8oPromise<NSObject>?//C8oPromise<XDocument>
    {
        //return CallXml(requestable, ToParameters(parameters));
        return nil
    }
    
    /// <summary>
    /// You can use this method to add cookies to the HTTP interface. This can be very useful if you have to use some
    /// pre-initialized cookies coming from a global SSO Authentication for example.
    /// </summary>
    /// <param name="name">The cookie name</param>
    /// <param name="value">The cookie value</param>
    public func AddCookie(name : String, value : String)->Void
    {
        //httpInterface.AddCookie(name, value);
    }
    
    public override var LogC8o : Bool
    {
        get { return logC8o!; }
        set(value) { logC8o = value; }
    }
    
    /// <summary>
    /// Gets a value indicating if logs are sent to the Convertigo server.
    /// </summary>
    /// <value>
    ///   <c>true</c> if logs are sent to the Convertigo server; otherwise, <c>false</c>.
    /// </value>
    public  override var LogRemote:Bool
    {
        get { return logRemote!; }
        set(value){ logRemote = value; }
    }
    
    /// <summary>
    /// Sets a value indicating the log level you want in the device console.
    /// </summary>
    /// <value>
    ///   <c>true</c> if logs are sent to the Convertigo server; otherwise, <c>false</c>.
    /// </value>
    public override var LogLevelLocal : C8oLogLevel
    {
        get { return logLevelLocal; }
        set(value) { logLevelLocal = value; }
    }
    
    /// <summary>
    /// Logs a message to Convertigo Server. the message will be seen in Convertigo Server Device logger. Logging messages to the server
    /// helps in monitoring Mobile apps in production.
    /// </summary>
    /// <param name="c8oLogLevel">Log level such as C8oLogLevel.DEBUG</param>
    /// <param name="message">The messe to be logged</param>
    /// <sample>
    ///     <code>myC8o.Log (C8oLogLevel.DEBUG, "This is my message");</code>
    /// </sample>
    /*
    public void Log(C8oLogLevel c8oLogLevel, string message)
    {
    c8oLogger.Log(c8oLogLevel, message);
    }
    */
    
    public var Log : C8oLogger
    {
        get { return c8oLogger!; }
    }
    
    /// <summary>
    /// An utility method to run a worker thread on UI. This method is Cross-platform and works on all the supported
    /// platforms (iOS, Android, WPF)
    /// </summary>
    /// <param name="code">The code to run on the UI thread</param>
    public func RunUI(code : NSObject/*Action*/)->Void
    {
        /*if (UiDispatcher != nil)
        {
            UiDispatcher.Invoke(code);
        }
        else
        {
            code.Invoke();
        }*/
    }
    
    public func toString()->String
    {
        return "C8o[" + endpoint! + "] " //+ super.description();
    }
    
    /// <summary>
    /// The endpoint of this C8O object as initialized in the constructor
    /// </summary>
    public var Endpoint: String
    {
        get { return endpoint!; }
    }
    
    /// <summary>
    /// The name of the Convertigo server coming from the endpoint url.
    /// </summary>
    public var EndpointConvertigo : String
    {
    get { return endpointConvertigo!; }
    }
    
    /// <summary>
    /// true if the endpoint has been initialized with a https:// url
    /// </summary>
    public var EndpointIsSecure :  Bool
    {
        get { return endpointIsSecure!; }
    }
    
    /// <summary>
    /// The target server hostname ,coming from the endpoint url.
    /// </summary>
    public var EndpointHost : String
    {
        get { return endpointHost!; }
    }
    
    /// <summary>
    /// The target server hostname ,coming from the endpoint url.
    /// </summary>
    public var EndpointPort :  String
    {
    get { return endpointPort!; }
    }
    
    /// <summary>
    /// The Unique device ID for this mobile device. This value will be used in logs, analytics and billing tables
    /// The Device mode licence model is based on these unique devices Ids.
    /// </summary>
    public var DeviceUUID : String
    {
        get { return " "/*deviceUUID*/; }
    }
    
    /// <summary>
    /// The Cookie Store for this endpoint. All the cookies for this end point will be held here.
    /// </summary>
    public var CookieStore : NSObject//CookieContainer
    {
        get { return httpInterface!.CookieStore!; }
    }
    
    private static func ToParameters(parameters : [NSObject])->Dictionary<String, NSObject>
    {
        if (parameters.count % 2 != 0)
        {
            //throw System.ArgumentException(C8oExceptionMessage.InvalidParameterValue("parameters", "needs pairs of values"));
        }
    
        var newParameters = Dictionary<String, NSObject>();
    
        for (var i = 0; i < parameters.count; i += 2)
        {
            newParameters["" + String(parameters[i])] = parameters[i + 1];
        }
    
        return newParameters;
    }
    
    internal func HandleCallException(c8oExceptionListener: C8oExceptionListener?, requestParameters : Dictionary<String, NSObject>, exception : NSException)
    {
        c8oLogger!._Warn("Handle a call exception", exceptions: exception);
    
        if (c8oExceptionListener != nil)
        {
            //c8oExceptionListener.OnException(exception, requestParameters);
        }
    }
}



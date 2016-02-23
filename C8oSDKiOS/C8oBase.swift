//
//  C8oBase.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 04/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

public class C8oBase : NSObject
{
    public override init(){
        super.init()
        
    }

    //*** HTTP ***//
    
    
    internal var  timeout : Int?  = -1;
    internal var trustAllCetificates :Bool? = false;
    internal var cookies :Dictionary<String, String>?
    public typealias Byte = UInt8?
    //internal var clientCertificateBinaries : [Byte: String]? = [:];
    //internal var  clientCertificateFiles :[String: String]? = [:];
    internal var clientCertificateBinaries : Dictionary<NSObject,String>?
    internal var clientCertificateFiles : Dictionary<String,String>?

    
    //*** Log ***//
    
    internal var logRemote : Bool?  = true;
    internal var logLevelLocal : C8oLogLevel = C8oLogLevel.NONE;
    internal var logC8o :Bool? = true;
    internal var logOnFail : NSObject? //C8oOnFail;
    
    //*** FullSync ***//
    
    internal var  defaultDatabaseName : String?;
    internal var authenticationCookieValue: String?;
    internal var fullSyncLocalSuffix: String?;
    
    internal var fullSyncServerUrl :String = "http://localhost:5984";
    internal var fullSyncUsername :String?;
    internal var fullSyncPassword :String?;
    

    //*** Getter ***//
    
    /// <summary>
    /// Gets the connection timeout to Convertigo in milliseconds. A value of zero means the timeout is not used.
    /// Default is <c>0</c>.
    /// </summary>
    /// <value>
    /// The timeout.
    /// </value>
    public var Timeout :Int
    {
        get { return timeout!; }
    }
    /// <summary>
    /// Gets a value indicating whether https calls trust all certificates or not.
    /// Default is <c>false</c>.
    /// </summary>
    /// <value>
    ///   <c>true</c> if https calls trust all certificates; otherwise, <c>false</c>.
    /// </value>
    public var TrustAllCetificates: Bool
    {
        get { return trustAllCetificates!; }
    }
    
    /// <summary>
    /// Gets initial cookies to send to the Convertigo server.
    /// Default is <c>null</c>.
    /// </summary>
    /// <value>
    /// A collection of cookies.
    /// </value>
    public var  Cookies :Dictionary<String, String>?
    {
        get { return cookies; }
    }
    
    public var ClientCertificateBinaries :[NSObject:String]?
    {
        get { return clientCertificateBinaries!; }
    }
    
    public var ClientCertificateFiles : [String:String]?
    {
        get { return clientCertificateFiles; }
    }
    
    /// <summary>
    /// Gets a value indicating if logs are sent to the Convertigo server.
    /// </summary>
    /// <value>
    ///   <c>true</c> if logs are sent to the Convertigo server; otherwise, <c>false</c>.
    /// </value>
    public var LogRemote : Bool
    {
        get { return logRemote!; }
    }
    
    /// <summary>
    /// Sets a value indicating the log level you want in the device console.
    /// </summary>
    /// <value>
    ///   <c>true</c> if logs are sent to the Convertigo server; otherwise, <c>false</c>.
    /// </value>
    public var LogLevelLocal: C8oLogLevel
    {
        get { return logLevelLocal; }
    }
    
    public var LogC8o: Bool
    {
        get { return logC8o!; }
    }
    
    public var LogOnFail : NSObject//C8oOnFail
    {
        get { return logOnFail!; }
    }
    
    public var DefaultDatabaseName:String
    {
        get { return defaultDatabaseName!; }
    }
    
    public var AuthenticationCookieValue :String
    {
        get { return authenticationCookieValue!; }
    }
    
    public var FullSyncLocalSuffix:String
    {
        get { return fullSyncLocalSuffix!; }
    }
    
    public var FullSyncServerUrl:String
    {
        get { return fullSyncServerUrl; }
    }
    
    public var FullSyncUsername:String
    {
        get { return fullSyncUsername!; }
    }
    
    public var FullSyncPassword:String
    {
        get { return fullSyncPassword!; }
    }
    
    public var UiDispatcher: NSObject?//process
    {
        get { return nil/*uiDispatcher;*/ }
    }
    
    internal func Copy (c8oBase : C8oBase) ->Void
    {
    //*** HTTP ***//
    
    timeout = c8oBase.timeout;
    trustAllCetificates = c8oBase.trustAllCetificates;
    
    if (c8oBase.cookies != nil)
    {
        if (cookies == nil)
        {
            cookies = NSObject() as? Dictionary<String, String>//CookieCollection();
        }
        //cookies.Add(c8oBase.cookies);
    }
    
    if (c8oBase.clientCertificateBinaries != nil)
    {
        if (clientCertificateBinaries == nil)
        {
            clientCertificateBinaries = c8oBase.clientCertificateBinaries;
        }
        else
        {
            for var entry in c8oBase.clientCertificateBinaries!
            {
                
                clientCertificateBinaries?.updateValue(entry.1,  forKey :entry.0);
            }
        }
    }
        
    if (c8oBase.clientCertificateFiles != nil)
    {
        if (clientCertificateFiles == nil)
        {
            clientCertificateFiles = c8oBase.clientCertificateFiles;
        }
        else
        {
            for var entry in c8oBase.clientCertificateFiles!
            {
                clientCertificateFiles?.updateValue(entry.1, forKey : entry.0);
            }
        }
    }
    
    //*** Log ***//
    
    logRemote = c8oBase.logRemote;
    logLevelLocal = c8oBase.logLevelLocal;
    logC8o = c8oBase.logC8o;
    logOnFail = c8oBase.logOnFail;
    
    //*** FullSync ***//
    
    defaultDatabaseName = c8oBase.defaultDatabaseName;
    authenticationCookieValue = c8oBase.authenticationCookieValue;
    fullSyncLocalSuffix = c8oBase.fullSyncLocalSuffix;
    
    fullSyncServerUrl = c8oBase.fullSyncServerUrl;
    fullSyncUsername = c8oBase.fullSyncUsername;
    fullSyncPassword = c8oBase.fullSyncPassword;
    
    //uiDispatcher = c8oBase.uiDispatcher;
    }
    
    

}

/*extension Dictionary {
    init(_ elements: [Element]){
        self.init()
        for (k, v) in elements {
            self[k] = v
        }
    }
    
    func map<U>(transform: Value -> U) -> [Key : U] {
        return Dictionary<Key, U>(self.map({ (key, value) in (key, transform(value)) }))
    }
    
    func map<T : Hashable, U>(transform: (Key, Value) -> (T, U)) -> [T : U] {
        return Dictionary<T, U>(self.map(transform))
    }
    
    func filter(includeElement: Element -> Bool) -> [Key : Value] {
        return Dictionary(self.filter( includeElement))
    }
    
    func reduce<U>(initial: U, @noescape combine: (U, Element) -> U) -> U {
        return self.reduce(initial, combine)
    }

}*/
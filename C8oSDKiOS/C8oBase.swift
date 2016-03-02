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
    internal var clientCertificateBinaries : Dictionary<UInt8, String>?
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
    
    /**
    Gets the connection timeout to Convertigo in milliseconds. A value of zero means the timeout is not used (Default is 0).
    Example usage:
    @code
    myc8o : C8o = C8o()
    timeout : Int = myC8o.Timeout
    @endcode
    @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
    @return The timeout.
    */
    public var Timeout :Int
        {
        get { return timeout!; }
    }
    
    /**
     Gets a value indicating whether https calls trust all certificates or not. (Default is false).
     Example usage:
     @code
     myc8o : C8o = C8o()
     trustAllCertificates : Bool = myC8o.TrustAllCetificates
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return <c>true</c> if https calls trust all certificates; otherwise, <c>false</c>.
     */
    public var TrustAllCetificates: Bool
        {
        get { return trustAllCetificates!; }
    }
    
    /**
     Gets initial cookies to send to the Convertigo server (Default is <c>null</c>).
     Example usage:
     @code
     myc8o : C8o = C8o()
     cookies : Dictionary<String, String>? = myC8o.Cookies
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A collection of cookies.
     */
    public var Cookies :Dictionary<String, String>?
        {
        get { return cookies; }
    }
    
    /**
     Gets the client certificate binaries.
     Example usage:
     @code
     myc8o : C8o = C8o()
     clientCertificateBinaries : Dictionary<UInt8, String>? = myC8o.ClientCertificateBinaries
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A Dictionary of client certificate binaries
     */
    public var ClientCertificateBinaries :Dictionary<UInt8, String>?
        {
        get { return clientCertificateBinaries!; }
    }
    
    /**
     Gets the client certificate files.
     Example usage:
     @code
     myc8o : C8o = C8o()
     clientCertificateFiles : Dictionary<String, String>? = myc8o.ClientCertificateFiles
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A Dictionary of client certificate files
     */
    public var ClientCertificateFiles : Dictionary<String, String>?
        {
        get { return clientCertificateFiles; }
    }
    
    /**
     Gets a value indicating if logs are sent to the Convertigo server.
     Example usage:
     @code
     myc8o : C8o = C8o()
     logRemote : Bool = myC8o.LogRemote
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return <c>true</c> if logs are sent to the Convertigo server; otherwise, <c>false</c>
     */
    public var LogRemote : Bool
        {
        get { return logRemote!; }
    }
    
    /**
     Gets a value indicating the log level you want in the device console.
     Example usage:
     @code
     myc8o : C8o = C8o()
     logLevelLocal : Bool = myC8o.LogLevelLocal
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return <c>true</c> if logs are sent to the Convertigo server; otherwise, <c>false</c>.
     */
    public var LogLevelLocal: C8oLogLevel
        {
        get { return logLevelLocal; }
    }
    
    /**
     Gets a value indicating if C8o is log.
     Example usage:
     @code
     myc8o : C8o = C8o()
     logC8o : Bool = myC8o.LogC8o
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return <c>true</c> if c8o is log; otherwise, <c>false</c>.
     */
    public var LogC8o: Bool
        {
        get { return logC8o!; }
    }
    
    /**
     Gets the log on failure.
     Example usage:
     @code
     myc8o : C8o = C8o()
     logOnFail : NSObject = myC8o.LogOnFail
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return NSObject.
     */
    public var LogOnFail : NSObject//C8oOnFail
        {
        get { return logOnFail!; }
    }
    
    /**
     Gets the default database's name.
     Example usage:
     @code
     myc8o : C8o = C8o()
     defaultDatabaseName : String = myC8o.DefaultDatabaseName
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A string containing the default database's name.
     */
    public var DefaultDatabaseName:String
        {
        get { return defaultDatabaseName!; }
    }
    
    /**
     Gets the authentification cookie value.
     Example usage:
     @code
     myc8o : C8o = C8o()
     authenticationCookieValue : String = myC8o.AuthenticationCookieValue
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A string containing the authentification cookie value.
     */
    public var AuthenticationCookieValue :String
        {
        get { return authenticationCookieValue!; }
    }
    
    /**
     Gets the fullSync local suffix.
     Example usage:
     @code
     myc8o : C8o = C8o()
     fullSyncLocalSuffix : String = myC8o.FullSyncLocalSuffix
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A string containing the fullSync local suffix.
     */
    public var FullSyncLocalSuffix:String
        {
        get { return fullSyncLocalSuffix!; }
    }
    
    /**
     Gets the fullSync server url.
     Example usage:
     @code
     myc8o : C8o = C8o()
     fullSyncServerUrl : String = myC8o.FullSyncServerUrl
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A string containing the fullSync server url.
     */
    public var FullSyncServerUrl:String
        {
        get { return fullSyncServerUrl; }
    }
    
    /**
     Gets the fullSync username.
     Example usage:
     @code
     myc8o : C8o = C8o()
     fullSyncUsername : String = myC8o.FullSyncUsername
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A string containing the fullSync username.
     */
    public var FullSyncUsername:String
        {
        get { return fullSyncUsername!; }
    }
    
    /**
     Gets the fullSync password.
     Example usage:
     @code
     myc8o : C8o = C8o()
     fullSyncPassword : String = myC8o.FullSyncPassword
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A string containing the fullSync password.
     */
    public var FullSyncPassword:String
        {
        get { return fullSyncPassword!; }
    }
    
    /**
     Gets the uiDispatcher.
     Example usage:
     @code
     myc8o : C8o = C8o()
     uiDispatcher : NSObject? = myC8o.UiDispatcher
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @return A NSObject? containing the uiDispatcher.
     */
    public var UiDispatcher: NSObject?//process
        {
        get { return nil/*uiDispatcher;*/ }
    }
    
    /**
     Copy any c8oBase object into another.
     Example usage:
     @code
     myc8o : C8o = C8o()
     mySecondC8o : C8o
     mySecondC8o.Copy(myC8o)
     @endcode
     @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
     @param c8oBase
            any C8oBase object that yout wants to copy
     @return Void.
     */
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
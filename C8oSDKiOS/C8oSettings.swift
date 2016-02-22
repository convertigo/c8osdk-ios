//
//  C8oSettings.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

import CouchbaseLite

/// <summary>
/// This class manages various settings to configure Convertigo SDK. You can use an instance of this object in a
/// new C8o endpoint object to initialize the endpoint with the correct settings
/// </summary>
public class C8oSettings : C8oBase
{
    public override init()
    {
    }
    
    public init(c8oSettings : C8oBase)
    {
        super.init()
        self.Copy(c8oSettings);
    }
    
    public func Clone()-> C8oSettings
    {
        return C8oSettings(c8oSettings: self);
    }
    
    /// <summary>
    /// Sets the connection timeout to Convertigo in milliseconds. A value of zero means the timeout is not used.
    /// Default is <c>0</c>.
    /// </summary>
    /// <param name="timeout">
    /// The timeout.
    /// </param>
    /// <returns>The current <c>C8oSettings</c>, for chaining.</returns>
    public func  SetTimeout(var timeout : Int)->C8oSettings
    {
        if (timeout <= 0)
        {
            timeout = -1;
        }
        self.timeout = timeout;
        return self;
    }
    
    /// <summary>
    /// Gets a value indicating whether https calls trust all certificates or not.
    /// Default is <c>false</c>.
    /// </summary>
    /// <param name="trustAllCetificates">
    ///   <c>true</c> if https calls trust all certificates; otherwise, <c>false</c>.
    /// </param>
    /// <returns>The current <c>C8oSettings</c>, for chaining.</returns>
    public func SetTrustAllCertificates(trustAllCetificates : Bool)->C8oSettings
    {
        self.trustAllCetificates = trustAllCetificates;
        return self;
    }
    
    /// <summary>
    /// When using https TLS/SSL connections you may have to provide client certificates. Use this setting to add a client certificate
    /// that the SDK will use connecting to Convertigo Server.
    /// </summary>
    /// <param name="certificate">A PKCS#12 Binary certificate</param>
    /// <param name="password">the password to use this certificate</param>
    /// <returns>The current <c>C8oSettings</c>, for chaining.</returns>
    public func AddClientCertificate(certificate :Byte, password : String)->C8oSettings
    {
        if (clientCertificateBinaries == nil)
        {
            clientCertificateBinaries = Dictionary</*[UInt8]*/NSObject, String>();
        }
        //clientCertificateBinaries = [certificate! as NSObject: password]
        
        return self;
    }
    
    /// <summary>
    /// When using https TLS/SSL connections you may have to provide client certificates. Use this setting to add a client certificate
    /// that the SDK will use connecting to Convertigo Server.
    /// </summary>
    /// <param name="certificate">The path to a .P12 certificate file</param>
    /// <param name="password">the password to use this certificate</param>
    /// <returns>The current <c>C8oSettings</c>, for chaining.</returns>
    public func  AddClientCertificate(certificatePath : String, password : String)->C8oSettings
    {
        if (clientCertificateFiles == nil)
        {
            clientCertificateFiles = Dictionary<String, String>();
        }
        clientCertificateFiles = [certificatePath:password];
        
        return self;
    }
    
    /// <summary>
    /// Add a new cookie to the initial cookies send to the Convertigo server.
    /// </summary>
    /// <param name="name">
    /// The name of the new cookie.
    /// </param>
    /// <param name="value">
    /// The value of the new cookie.
    /// </param>
    /// <returns>The current <c>C8oSettings</c>, for chaining.</returns>
    public func AddCookie(name : String, Value : String)-> C8oSettings
    {
        /*
        if (cookies == nil)
        {
            cookies = CookieCollection();
        }
        cookies.Add(Cookie(name, value));*/
        
        return self;
    }
    
    //*** Log ***//
    
    /// <summary>
    /// Set logging to remote. If true, logs will be sent to Convertigo MBaaS server.
    /// </summary>
    /// <param name="logRemote"></param>
    /// <returns>The current<c>C8oSettings</c>, for chaining.</returns>
    public func SetLogRemote(logRemote : Bool)->C8oSettings
    {
        self.logRemote = logRemote;
        return self;
    }
    
    /// <summary>
    /// Sets a value indicating the log level you want in the device console
    /// You should use C8oLogLevel constants
    /// </summary>
    /// <param name="logLevelLocal"></param>
    /// <returns>The current<c>C8oSettings</c>, for chaining.</returns>
    public func SetLogLevelLocal(logLevelLocal : C8oLogLevel)->C8oSettings
    {
        self.logLevelLocal = logLevelLocal;
        return self;
    }
    
    public func SetLogC8o(logC8o : Bool)->C8oSettings
    {
        self.logC8o = logC8o;
        return self;
    }
    
    public func SetLogOnFail(logOnFail : NSObject/*C8oOnFail*/)->C8oSettings
    {
        self.logOnFail = logOnFail;
        return self;
    }
    //*** FullSync ***//
    
    /// <summary>
    /// When you use FullSync request in the form fs://database.verb, you can use this setting if you want to have a default
    /// database. In this case using fs://.verb will automatically use the database configured with this setting.
    /// </summary>
    /// <param name="defaultDatabaseName">The default data base</param>
    /// <returns>The current<c>C8oSettings</c>, for chaining.</returns>
    public func SetDefaultDatabaseName(defaultDatabaseName: String)->C8oSettings
    {
        self.defaultDatabaseName = defaultDatabaseName;
        return self;
    }
    
    public func SetAuthenticationCookieValue(authenticationCookieValue : String)->C8oSettings
    {
        self.authenticationCookieValue = authenticationCookieValue;
        return self;
    }
    
    public func SetFullSyncServerUrl(fullSyncServerUrl : String)->C8oSettings
    {
        self.fullSyncServerUrl = fullSyncServerUrl;
        return self;
    }
    
    public func SetFullSyncUsername(fullSyncUsername : String)->C8oSettings
    {
        self.fullSyncUsername = fullSyncUsername;
        return self;
    }
    
    public func SetFullSyncPassword(fullSyncPassword : String)->C8oSettings
    {
        self.fullSyncPassword = fullSyncPassword;
        return self;
    }
    
    public func SetFullSyncLocalSuffix(fullSyncLocalSuffix : String)->C8oSettings
    {
        self.fullSyncLocalSuffix = fullSyncLocalSuffix;
        return self;
    }
    
    public func SetUiDispatcher(uiDispatcher : NSObject)->C8oSettings
    {
        /*self.uiDispatcher = uiDispatcher;*/
        return self;
    }
}
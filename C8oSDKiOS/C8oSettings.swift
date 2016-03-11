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
    
    public func  SetTimeout(var timeout : Int)->C8oSettings
    {
        if (timeout <= 0)
        {
            timeout = -1;
        }
        self.timeout = timeout;
        return self;
    }
    

    public func SetTrustAllCertificates(trustAllCetificates : Bool)->C8oSettings
    {
        self.trustAllCetificates = trustAllCetificates;
        return self;
    }
    

    public func AddClientCertificate(certificate :Byte, password : String)->C8oSettings
    {
        if (clientCertificateBinaries == nil)
        {
            clientCertificateBinaries = Dictionary<UInt8, String>?();
        }
        //clientCertificateBinaries = [certificate! as NSObject: password]
        
        return self;
    }
    

    public func  AddClientCertificate(certificatePath : String, password : String)->C8oSettings
    {
        if (clientCertificateFiles == nil)
        {
            clientCertificateFiles = Dictionary<String, String>();
        }
        clientCertificateFiles = [certificatePath:password];
        
        return self;
    }
    

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
    
    /** Log */
    

    public func SetLogRemote(logRemote : Bool)->C8oSettings
    {
        self.logRemote = logRemote;
        return self;
    }
    

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
    
    public func SetLogOnFail(logOnFail :(NSException, Dictionary<String, NSObject>) throws ->()) ->C8oSettings
    {
        self.logOnFail = logOnFail;
        return self;
    }
    /** FullSync */

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
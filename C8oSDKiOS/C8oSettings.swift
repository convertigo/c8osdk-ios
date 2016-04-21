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

public class C8oSettings : C8oBase
{
    public override init()
    {
    }
    
    public init(c8oSettings : C8oBase)
    {
        super.init()
        copyProperties(c8oSettings)
    }
    
    public func clone()-> C8oSettings
    {
        return C8oSettings(c8oSettings: self)
    }
    
    public func  setTimeout(timeout : Int)->C8oSettings
    {
        var timeout = timeout
        if (timeout <= 0)
        {
            timeout = -1
        }
        _timeout = timeout
        return self
    }
    

    public func setTrustAllCertificates(trustAllCertificates : Bool)->C8oSettings
    {
        _trustAllCertificates = trustAllCertificates
        return self
    }
    

    public func addClientCertificate(certificate :Byte, password : String)->C8oSettings
    {
        if (_clientCertificateBinaries == nil)
        {
            _clientCertificateBinaries = Dictionary<UInt8, String>?()
        }
        //clientCertificateBinaries = [certificate! as NSObject: password]
        
        return self
    }
    

    public func  addClientCertificate(certificatePath : String, password : String)->C8oSettings
    {
        if (_clientCertificateFiles == nil)
        {
            _clientCertificateFiles = Dictionary<String, String>()
        }
        _clientCertificateFiles = [certificatePath:password]
        
        return self
    }
    

    public func addCookie(name : String, Value : String)-> C8oSettings
    {
        
        if (_cookies == nil)
        {
            _cookies = Dictionary<String, String>()
        }
        _cookies = [name : Value]
        
        return self
    }
    
    /** Log */
    

    public func setLogRemote(logRemote : Bool)->C8oSettings
    {
        _logRemote = logRemote
        return self
    }
    

    public func setLogLevelLocal(logLevelLocal : C8oLogLevel)->C8oSettings
    {
        _logLevelLocal = logLevelLocal
        return self
    }
    
    public func setLogC8o(logC8o : Bool)->C8oSettings
    {
        _logC8o = logC8o
        return self
    }
    
    public func setLogOnFail(logOnFail :((exception :C8oException, parameters : Dictionary<String, NSObject>?) ->(Void))?) ->C8oSettings{
        _logOnFail = logOnFail
        return self
    }
    /** FullSync */

    public func setDefaultDatabaseName(defaultDatabaseName: String)->C8oSettings
    {
        _defaultDatabaseName = defaultDatabaseName
        return self
    }
    
    public func setAuthenticationCookieValue(authenticationCookieValue : String)->C8oSettings
    {
        _authenticationCookieValue = authenticationCookieValue
        return self
    }
    
    public func setFullSyncServerUrl(fullSyncServerUrl : String)->C8oSettings
    {
        _fullSyncServerUrl = fullSyncServerUrl
        return self
    }
    
    public func setFullSyncUsername(fullSyncUsername : String)->C8oSettings
    {
        _fullSyncUsername = fullSyncUsername
        return self
    }
    
    public func setFullSyncPassword(fullSyncPassword : String)->C8oSettings
    {
        _fullSyncPassword = fullSyncPassword
        return self
    }
    
    public func setFullSyncLocalSuffix(fullSyncLocalSuffix : String)->C8oSettings
    {
        _fullSyncLocalSuffix = fullSyncLocalSuffix
        return self
    }
    
    public func setUiDispatcher(uiDispatcher : NSObject)->C8oSettings
    {
        /*_uiDispatcher = uiDispatcher*/
        return self
    }
}
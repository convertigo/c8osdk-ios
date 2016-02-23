//
//  Exceptions.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation


public class C8oException : NSException
{
    required public init?(coder aDecoder: NSCoder, message: String) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required public init?(coder aDecoder: NSCoder, message: String, exception: NSException) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init (message : String, exception : NSException)
    {
      super.init(name: "", reason: nil, userInfo: nil)
        
    }
    
    private static func FilterMessage(var message : String, exception : NSException)->String
    {
        if (exception is C8oException)
        {
            message = String(exception) + " | " + message;
        }
        return message;
    }
    
    private static func FilterException(exception : NSException)->NSException
    {
    /*if (exception is C8oException)
    {
    return null;
    }*/
    return exception;
    }
}

public class C8oHttpException : NSException
{
    public init(message : String, innerException : NSException)
    {
        super.init(name: "", reason: nil, userInfo: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class C8oRessourceNotFoundException : NSException
{
    public init(message : String)  {
        
        super.init(name: "", reason: nil, userInfo: nil)    }
    
    public init(message : String, innerException : NSException) {
        
        super.init(name: "", reason: nil, userInfo: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class C8oUnavailableLocalCacheException : NSException
{
    
    public init(message : String) {
        
        super.init(name: "", reason: nil, userInfo: nil)
    }
    public init(message : String, innerException : NSException) {
    
        super.init(name: "", reason: nil, userInfo: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum Error : ErrorType {
        case InvalidArgument
    }

    
         
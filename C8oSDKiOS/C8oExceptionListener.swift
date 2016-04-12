//
//  C8oExceptionListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation


public class C8oExceptionListener
{
    public var onException :  (Pair<C8oException, Dictionary<String, NSObject>?>?)->()
    
    init(onException : (params : Pair<C8oException, Dictionary<String, NSObject>?>?)->())
    {
        self.onException = onException;
    }
}
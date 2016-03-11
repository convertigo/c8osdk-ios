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
    public var OnException :  (Pair<Errs, Dictionary<String, NSObject>>?)->()
    
    init(OnException : (params : Pair<Errs, Dictionary<String, NSObject>>?)->())
    {
        self.OnException = OnException;
    }
}
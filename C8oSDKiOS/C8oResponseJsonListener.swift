//
//  C8oResponseJsonListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON


public class C8oResponseJsonListener : C8oResponseListener
{
    public var OnJsonResponse : (Pair<JSON?, Dictionary<String, NSObject>?>?)->()
    
    public init(onJsonResponse : (params :Pair<JSON?, Dictionary<String, NSObject>?>?)->())
    {
        OnJsonResponse = onJsonResponse
    }
}       
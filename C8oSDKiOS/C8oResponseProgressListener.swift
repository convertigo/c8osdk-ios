//
//  C8oResponseProgressListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

internal class C8oResponseProgressListener : C8oResponseListener
{
    public var OnProgressResponse : NSObject?//<C8oProgress, Dictionary<String, NSObject>>;
    
    public func C8oResponseProgressListener(onProgressResponse : NSObject )
    {
        OnProgressResponse = onProgressResponse;
    }
    //uiDispatcher//Action<C8oProgress, Dictionary<String, NSObject>>)
    internal init()
    {
        OnProgressResponse = nil
    }
}

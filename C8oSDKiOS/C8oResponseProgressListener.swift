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
    internal var onProgressResponse : (C8oProgress, Dictionary<String, NSObject>)->()
    
    internal init(onProgressResponse : (C8oProgress, Dictionary<String, NSObject>)->())
    {
        self.onProgressResponse = onProgressResponse;
    }


}

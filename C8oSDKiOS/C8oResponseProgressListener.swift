//
//  C8oResponseProgressListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//
import Foundation

@objc internal class C8oResponseProgressListener: NSObject,C8oResponseListener {
    internal var onProgressResponse: (C8oProgress, Dictionary<String, Any>) -> ()
    
    internal init(onProgressResponse: @escaping (C8oProgress, Dictionary<String, Any>) -> ()) {
        self.onProgressResponse = onProgressResponse;
    }
    
}

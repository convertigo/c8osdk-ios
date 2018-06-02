//
//  C8oResponseJsonListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//
import Foundation
import SwiftyJSON

@objc open class C8oResponseJsonListener: NSObject, C8oResponseListener {
    open var onJsonResponse: (AnyObject?, Dictionary<String, Any>?) -> ()
    
    @objc public init(onJsonResponse: @escaping (AnyObject?, Dictionary<String, Any>?) -> ()) {
        self.onJsonResponse = onJsonResponse
    }
}

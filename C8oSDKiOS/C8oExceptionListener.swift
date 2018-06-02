//
//  C8oExceptionListener.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

@objc open class C8oExceptionListener: NSObject {
    open var onException: (_ exep:C8oException, _ params:Dictionary<String, Any>?) -> ()
    
    @objc public init(onException: @escaping (_ exep:C8oException, _ params:Dictionary<String, Any>?) -> ()) {
        self.onException = onException;
    }
}
